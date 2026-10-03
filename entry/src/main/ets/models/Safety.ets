import { BoundaryState, GeofenceTracker } from './GeofenceTracker';

export enum GeofenceStatus {
  Inside,
  Outside,
  Unknown
}

export enum AlertType {
  Sos,
  SafeAreaExit,
  DoseMissed,
  MonitoringLost,
  Fall,
  LowBattery,
  HeartRate
}

export interface RemoteAlertCopy {
  type: AlertType;
  title: string;
  detail: string;
}

export function remoteAlertCopy(kind: string): RemoteAlertCopy {
  switch (kind) {
    case 'sos':
      return {
        type: AlertType.Sos,
        title: 'SOS requested',
        detail: 'The senior requested help.'
      };
    case 'area_exit':
      return {
        type: AlertType.SafeAreaExit,
        title: 'Safe area exit',
        detail: 'The senior left the safe area.'
      };
    case 'dose_missed':
      return {
        type: AlertType.DoseMissed,
        title: 'Medication missed',
        detail: 'A scheduled dose was not taken on time.'
      };
    case 'monitoring_lost':
      return {
        type: AlertType.MonitoringLost,
        title: 'Monitoring lost',
        detail: 'Location updates stopped. Check on the senior.'
      };
    case 'fall':
      return {
        type: AlertType.Fall,
        title: 'Possible fall',
        detail: 'A possible fall was reported. Check on the senior now.'
      };
    case 'low_battery':
      return {
        type: AlertType.LowBattery,
        title: 'Low battery',
        detail: 'One of the senior\'s devices is running low on battery.'
      };
    case 'heart_rate':
      return {
        type: AlertType.HeartRate,
        title: 'Heart rate outside the set range',
        detail: 'The watch reported a heart rate outside the set range. This is not a medical assessment; consider calling to check in.'
      };
    default:
      return {
        type: AlertType.SafeAreaExit,
        title: 'Care alert',
        detail: 'Open the alert for details.'
      };
  }
}

export enum DeliveryState {
  Queued,
  Sending,
  LocalOnly
}

export class CareAlert {
  id: string;
  type: AlertType;
  title: string;
  detail: string;
  source: string;
  createdAt: number;
  deliveryState: DeliveryState;
  acknowledged: boolean = false;
  remote: boolean = false;

  constructor(id: string, type: AlertType, title: string, detail: string, source: string) {
    this.id = id;
    this.type = type;
    this.title = title;
    this.detail = detail;
    this.source = source;
    this.createdAt = Date.now();
    this.deliveryState = DeliveryState.Queued;
  }
}

export function formatClockTime(timestamp: number): string {
  const date = new Date(timestamp);
  return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
}

export function formatAlertTime(timestamp: number): string {
  const minutes = Math.floor((Date.now() - timestamp) / 60000);
  const relative = minutes < 1 ? 'just now'
    : minutes < 60 ? `${minutes} min ago`
      : `${Math.floor(minutes / 60)} h ago`;
  return `${formatClockTime(timestamp)} · ${relative}`;
}

export function deliveryLabel(state: DeliveryState): string {
  if (state === DeliveryState.Queued) {
    return 'Saved on this device';
  }
  if (state === DeliveryState.Sending) {
    return 'Sending…';
  }
  return 'Demo only, not delivered';
}

export class SafetyStore {
  private readonly tracker: GeofenceTracker = new GeofenceTracker();
  safeAreaConfigured: boolean = false;
  lastTransition: string = '';
  private nextId: number = 1;
  homeLatitude: number = 52.2297;
  homeLongitude: number = 21.0122;
  homeRadiusMeters: number = 300;
  alerts: CareAlert[] = [];
  geofenceStatus: GeofenceStatus = GeofenceStatus.Unknown;
  didLeaveSafeArea: boolean = false;
  lastLocationMessage: string = 'Location has not been checked yet.';

  unacknowledgedCount(): number {
    return this.alerts.filter((alert: CareAlert) => !alert.acknowledged).length;
  }

  createSos(source: string): CareAlert {
    const alert = new CareAlert(`sos-${this.nextId++}`, AlertType.Sos, 'SOS requested',
      'The senior requested help.', source);
    this.alerts.unshift(alert);
    return alert;
  }

  recordLiveLocation(latitude: number, longitude: number, accuracy: number, createLocalAlert: boolean = true,
    sampledAt: number = Date.now()): CareAlert | undefined {
    this.lastTransition = '';
    this.didLeaveSafeArea = false;
    if (!this.safeAreaConfigured) {
      this.geofenceStatus = GeofenceStatus.Unknown;
      this.lastLocationMessage = 'No safe area is available. Ask your guardian to set one.';
      return undefined;
    }
    const distance = this.distanceMeters(this.homeLatitude, this.homeLongitude, latitude, longitude);
    this.lastTransition = this.tracker.observe(distance, this.homeRadiusMeters, accuracy, sampledAt, Date.now());
    this.geofenceStatus = this.tracker.confirmed === BoundaryState.Inside ? GeofenceStatus.Inside
      : this.tracker.confirmed === BoundaryState.Outside ? GeofenceStatus.Outside : GeofenceStatus.Unknown;
    this.didLeaveSafeArea = this.lastTransition === 'area_exit';
    this.lastLocationMessage = accuracy > this.homeRadiusMeters ? 'Location is not precise enough to confirm a crossing.'
      : `About ${Math.round(distance)} m from home. Boundary changes need two clear readings.`;
    if (this.didLeaveSafeArea && createLocalAlert) {
      const alert = new CareAlert(`area-${this.nextId++}`, AlertType.SafeAreaExit, 'Safe area exit',
        'The senior moved outside the configured home circle.', 'Phone location');
      this.alerts.unshift(alert);
      return alert;
    }
    return undefined;
  }

  configureHomeCircle(latitude: number, longitude: number, radiusMeters: number): boolean {
    if (!isFinite(latitude) || !isFinite(longitude) || !isFinite(radiusMeters) ||
      latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 || radiusMeters < 50) {
      return false;
    }
    if (!this.safeAreaConfigured || this.homeLatitude !== latitude || this.homeLongitude !== longitude ||
      this.homeRadiusMeters !== radiusMeters) {
      this.resetBoundary();
    }
    this.safeAreaConfigured = true;
    this.homeLatitude = latitude;
    this.homeLongitude = longitude;
    this.homeRadiusMeters = radiusMeters;
    return true;
  }

  resetBoundary(): void {
    this.tracker.reset();
    this.geofenceStatus = GeofenceStatus.Unknown;
    this.didLeaveSafeArea = false;
    this.lastTransition = '';
    this.lastLocationMessage = 'Waiting for fresh location readings.';
  }

  clearSafeArea(): void {
    this.safeAreaConfigured = false;
    this.resetBoundary();
  }

  setSending(alert: CareAlert): void {
    alert.deliveryState = DeliveryState.Sending;
  }

  markLocalOnly(alert: CareAlert): void {
    alert.deliveryState = DeliveryState.LocalOnly;
  }

  acknowledge(alert: CareAlert): void {
    alert.acknowledged = true;
  }

  private distanceMeters(latitudeA: number, longitudeA: number, latitudeB: number, longitudeB: number): number {
    const earthRadiusMeters = 6371000;
    const toRadians = Math.PI / 180;
    const latitudeDifference = (latitudeB - latitudeA) * toRadians;
    const longitudeDifference = (longitudeB - longitudeA) * toRadians;
    const value = Math.sin(latitudeDifference / 2) * Math.sin(latitudeDifference / 2) +
      Math.cos(latitudeA * toRadians) * Math.cos(latitudeB * toRadians) *
      Math.sin(longitudeDifference / 2) * Math.sin(longitudeDifference / 2);
    return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
  }
}

export const safetyStore: SafetyStore = new SafetyStore();

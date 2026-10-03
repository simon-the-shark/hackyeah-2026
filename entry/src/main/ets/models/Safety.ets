export enum GeofenceStatus {
  Inside,
  Outside,
  Unknown
}

export enum AlertType {
  Sos,
  SafeAreaExit
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
  private nextId: number = 1;
  homeLatitude: number = 52.2297;
  homeLongitude: number = 21.0122;
  homeRadiusMeters: number = 300;
  developerMode: boolean = false;
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

  recordDemoLocation(status: GeofenceStatus): CareAlert | undefined {
    const message = status === GeofenceStatus.Inside
      ? 'Demo trace: inside the configured home circle'
      : status === GeofenceStatus.Outside
        ? 'Demo trace: outside the configured home circle'
        : 'Demo trace: location is unavailable';
    return this.recordGeofenceStatus(status, message);
  }

  private recordGeofenceStatus(status: GeofenceStatus, message: string, createLocalAlert: boolean = true): CareAlert | undefined {
    const previousStatus = this.geofenceStatus;
    this.geofenceStatus = status;
    this.lastLocationMessage = message;
    this.didLeaveSafeArea = status === GeofenceStatus.Outside && previousStatus !== GeofenceStatus.Outside;

    if (this.didLeaveSafeArea && createLocalAlert) {
      const alert = new CareAlert(`area-${this.nextId++}`, AlertType.SafeAreaExit, 'Safe area exit',
        'The senior moved outside the configured home circle.', 'Phone location');
      this.alerts.unshift(alert);
      return alert;
    }
    return undefined;
  }

  recordLiveLocation(latitude: number, longitude: number, accuracy: number, createLocalAlert: boolean = true): CareAlert | undefined {
    if (accuracy > this.homeRadiusMeters) {
      return this.recordGeofenceStatus(GeofenceStatus.Unknown, 'Location is not precise enough yet.');
    }

    const distance = this.distanceMeters(this.homeLatitude, this.homeLongitude, latitude, longitude);
    const message = `About ${Math.round(distance)} m from home.`;
    return this.recordGeofenceStatus(distance <= this.homeRadiusMeters ? GeofenceStatus.Inside : GeofenceStatus.Outside, message, createLocalAlert);
  }

  configureHomeCircle(latitude: number, longitude: number, radiusMeters: number): boolean {
    if (!isFinite(latitude) || !isFinite(longitude) || !isFinite(radiusMeters) ||
      latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 || radiusMeters < 50) {
      return false;
    }
    this.homeLatitude = latitude;
    this.homeLongitude = longitude;
    this.homeRadiusMeters = radiusMeters;
    return true;
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

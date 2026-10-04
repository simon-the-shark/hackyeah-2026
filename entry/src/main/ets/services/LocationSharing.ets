import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from './CareApi';
import { pendingSafetyEvents } from './PendingSafetyEvents';
import { SafePreferences } from './SafePreferences';
import { BackgroundLocation } from '../platform/BackgroundLocation';
import { ApiError } from '../providers/backend/BackendClient';
import { notifications } from '../platform/Notifications';
import { batteryPercent } from '../platform/Battery';

type StateListener = () => void;

export class LocationPoint {
  lat: number;
  lng: number;
  accuracyM: number;
  sampledAt: string;
  measuredBy: string = 'phone';

  constructor(lat: number, lng: number, accuracyM: number, sampledAt: number) {
    this.lat = lat;
    this.lng = lng;
    this.accuracyM = accuracyM;
    this.sampledAt = new Date(sampledAt).toISOString();
  }
}

function pointFrom(location: geoLocationManager.Location): LocationPoint | undefined {
  if (!isFinite(location.latitude) || Math.abs(location.latitude) > 90 ||
    !isFinite(location.longitude) || Math.abs(location.longitude) > 180 ||
    !isFinite(location.accuracy) || location.accuracy < 0 ||
    !isFinite(location.timeStamp) || location.timeStamp <= 0 || location.timeStamp > Date.now() + 5000) {
    return undefined;
  }
  return new LocationPoint(location.latitude, location.longitude, location.accuracy, location.timeStamp);
}

class StatusReport {
  monitoringState: string;
  location?: LocationPoint;
  battery?: number;

  constructor(state: string, point?: LocationPoint) {
    this.monitoringState = state;
    this.location = point;
    const battery = batteryPercent();
    if (battery >= 0) {
      this.battery = battery;
    }
  }
}

class SavedSafeArea {
  lat: number;
  lng: number;
  radiusM: number;

  constructor(lat: number, lng: number, radiusM: number) {
    this.lat = lat;
    this.lng = lng;
    this.radiusM = radiusM;
  }
}

/** Phone-only, user-enabled continuous location task. No boot/force-stop restart claim. */
export class LocationSharing {
  enabled: boolean = false;
  starting: boolean = false;
  permissionDenied: boolean = false;
  locationSwitchOff: boolean = false;
  errorMessage: string = '';
  configMessage: string = '';
  private requested: boolean = false;
  private foreground: boolean = false;
  private context: common.UIAbilityContext | undefined = undefined;
  private listeners: StateListener[] = [];
  private lastFix: LocationPoint | undefined = undefined;
  private generation: number = 0;
  private lifecycle: Promise<void> = Promise.resolve();
  private samples: Promise<void> = Promise.resolve();
  private unsavedEvents: SafetyEventRequest[] = [];
  private timer: number = -1;
  private ticking: boolean = false;
  private lastConfigCheck: number = 0;
  private owner: string = '';
  private readonly store = new SafePreferences('carely_location_sharing');
  private readonly background = new BackgroundLocation(() => {
    this.stop();
    this.errorMessage = 'The system stopped location sharing. Open Carely and turn sharing on again.';
    this.notify();
  });

  private readonly locationCallback: (location: geoLocationManager.Location) => void = (location) => {
    const point = pointFrom(location);
    if (!this.enabled || point === undefined || Date.now() - Date.parse(point.sampledAt) > 120000) return;
    if (this.lastFix !== undefined && Date.parse(point.sampledAt) <= Date.parse(this.lastFix.sampledAt)) return;
    this.lastFix = point;
    safetyStore.recordLiveLocation(point.lat, point.lng, point.accuracyM, false, Date.parse(point.sampledAt));
    const transition = safetyStore.lastTransition;
    const context = this.context;
    // Persist transitions independently of status uploads; preserve exit/enter order.
    if (transition !== '' && context !== undefined) {
      const event = new SafetyEventRequest(generateEventId(), transition, point.sampledAt);
      event.location = point;
      this.unsavedEvents.push(event);
      this.saveEvents(context).catch(() => {
        this.errorMessage = 'A safe-area event is held in memory because storage is unavailable. Keep Carely running to retry.';
        this.notify();
      });
    }
    this.notify();
  };

  subscribe(listener: StateListener): void {
    if (this.listeners.indexOf(listener) < 0) this.listeners.push(listener);
  }

  unsubscribe(listener: StateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) this.listeners.splice(index, 1);
  }

  /** Called after pairing restoration, independently of whether the Safe Area page is opened. */
  async restore(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    const owner = apiSession.seniorId;
    const token = apiSession.token;
    if (!apiSession.configured() || apiSession.role !== 'senior') return;
    const savedOwner = await this.store.getString(context, 'owner', '');
    const requested = await this.store.getString(context, 'requested', 'false');
    const raw = await this.store.getString(context, 'safeArea', '');
    if (apiSession.token !== token) return;
    this.owner = owner;
    if (savedOwner === owner) {
      this.requested = requested === 'true';
      this.restoreSafeArea(raw);
    }
    if (this.foreground && this.requested) this.begin(context, false);
  }

  private restoreSafeArea(raw: string): void {
    try {
      const area = JSON.parse(raw) as SavedSafeArea;
      if (area !== null) safetyStore.configureHomeCircle(area.lat, area.lng, area.radiusM);
    } catch (_) {
      // Missing cache is an unknown boundary, never a default home location.
    }
  }

  start(context: common.UIAbilityContext): void {
    this.begin(context, true);
  }

  private begin(context: common.UIAbilityContext, askPermission: boolean): void {
    if (this.enabled || this.starting) return;
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      this.errorMessage = 'Pair this phone as a senior before sharing location.';
      this.notify();
      return;
    }
    this.context = context;
    this.owner = apiSession.seniorId;
    this.requested = true;
    this.starting = true;
    this.errorMessage = '';
    const epoch = ++this.generation;
    const token = apiSession.token;
    this.notify();
    this.lifecycle = this.lifecycle.then(async () => {
      if (epoch !== this.generation) return;
      try {
        if (askPermission) {
          await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context,
            ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']);
        }
        if (epoch !== this.generation || token !== apiSession.token) return;
        this.permissionDenied = !this.hasPermission(context);
        if (this.permissionDenied) throw new Error('Allow precise location in Settings before sharing.');
        this.locationSwitchOff = !geoLocationManager.isLocationEnabled();
        if (this.locationSwitchOff) throw new Error('Turn on the phone’s Location switch before sharing.');
        // Permission dialogs can temporarily background the ability. Never start a task while hidden.
        if (!this.foreground) throw new Error('Return to Carely and turn on sharing to start the background task.');
        if (askPermission && !await notifications.ensureEnabled(context, true)) {
          throw new Error('Allow Carely notifications so the system can show active location sharing.');
        }
        await this.refreshSafeArea(context);
        if (epoch !== this.generation || token !== apiSession.token) return;
        if (!this.foreground) throw new Error('Open Carely to finish starting background sharing.');
        safetyStore.resetBoundary();
        await this.background.start(context);
        if (epoch !== this.generation || token !== apiSession.token) {
          await this.background.stop(context);
          return;
        }
        const request: geoLocationManager.LocationRequest = {
          priority: geoLocationManager.LocationRequestPriority.ACCURACY,
          scenario: geoLocationManager.LocationRequestScenario.UNSET,
          timeInterval: 30,
          distanceInterval: 0,
          maxAccuracy: 0
        };
        geoLocationManager.on('locationChange', request, this.locationCallback);
        this.enabled = true;
        this.timer = setInterval(() => { this.tick(); }, 30000);
        await this.persistIntent();
        this.tick();
      } catch (error) {
        this.unsubscribeFromLocation();
        try { await this.background.stop(context); } catch (_) { /* Retry on explicit stop. */ }
        if (epoch === this.generation) {
          this.requested = false;
          // The Safe Area page has its own banner and button for missing permission or a switched-off Location.
          this.errorMessage = this.permissionDenied || this.locationSwitchOff ? '' :
            `Sharing did not start. ${(error as Error).message}`;
          await this.persistIntent();
        }
      } finally {
        if (epoch === this.generation) {
          this.starting = false;
          this.notify();
        }
      }
    }).catch(() => {
      this.starting = false;
      this.errorMessage = 'Could not start background location sharing. Try again.';
      this.notify();
    });
  }

  private hasPermission(context: common.UIAbilityContext): boolean {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const tokenId = context.applicationInfo.accessTokenId;
      return manager.checkAccessTokenSync(tokenId, 'ohos.permission.APPROXIMATELY_LOCATION') ===
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED &&
        manager.checkAccessTokenSync(tokenId, 'ohos.permission.LOCATION') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (_) {
      return false;
    }
  }

  async requestLocationSwitch(context: common.UIAbilityContext): Promise<void> {
    try {
      const enabled = await abilityAccessCtrl.createAtManager().requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION);
      if (enabled) this.start(context);
    } catch (error) {
      // Error codes can arrive as strings, so compare numerically.
      const code = Number((error as BusinessError).code);
      if (code === 12100013) this.start(context);
      else {
        this.errorMessage = `Could not open the location switch (error ${code}).`;
        this.notify();
      }
    }
  }

  async openPermissionSettings(context: common.UIAbilityContext): Promise<void> {
    try {
      await abilityAccessCtrl.createAtManager().requestPermissionOnSetting(context,
        ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']);
      this.start(context);
    } catch (error) {
      this.errorMessage = `Could not open location settings (error ${(error as BusinessError).code}).`;
      this.notify();
    }
  }

  lastKnownLocation(): LocationPoint | undefined {
    let system: LocationPoint | undefined = undefined;
    try { system = pointFrom(geoLocationManager.getLastLocation()); } catch (_) { /* No cached fix or permission. */ }
    if (system === undefined || this.lastFix === undefined) return system ?? this.lastFix;
    return Date.parse(system.sampledAt) > Date.parse(this.lastFix.sampledAt) ? system : this.lastFix;
  }

  stop(): void {
    this.requested = false;
    this.shutdown(true);
  }

  /** Backgrounding does not stop an established continuous task. */
  pause(): void {
    this.foreground = false;
  }

  resume(context: common.UIAbilityContext): void {
    this.foreground = true;
    this.context = context;
    if (this.enabled) this.tick();
    else if (this.requested) this.begin(context, false);
  }

  destroy(): void {
    this.foreground = false;
    this.shutdown(false);
  }

  private shutdown(saveIntent: boolean): void {
    ++this.generation;
    this.starting = false;
    this.unsubscribeFromLocation();
    safetyStore.resetBoundary();
    const context = this.context;
    this.lifecycle = this.lifecycle.then(async () => {
      if (context !== undefined) await this.background.stop(context);
    }).catch(() => {
      this.errorMessage = 'Location updates stopped, but the system task could not be released. Reopen Carely to retry.';
      this.notify();
    }).then(async () => {
      if (saveIntent) await this.persistIntent();
    });
    this.notify();
  }

  async reset(context: common.UIAbilityContext): Promise<void> {
    this.stop();
    await this.lifecycle;
    await this.samples.catch(() => {});
    this.unsavedEvents = [];
    this.lastFix = undefined;
    this.owner = '';
    safetyStore.clearSafeArea();
    await this.store.clear(context);
    await pendingSafetyEvents.clear(context).catch(() => {
      this.errorMessage = 'Could not clear saved events. They will not be sent under another senior’s account.';
    });
  }

  private unsubscribeFromLocation(): void {
    if (this.timer !== -1) clearInterval(this.timer);
    this.timer = -1;
    if (this.enabled) {
      try { geoLocationManager.off('locationChange', this.locationCallback); } catch (_) { /* Callback is gated below. */ }
    }
    this.enabled = false;
  }

  private async persistIntent(): Promise<void> {
    if (this.context !== undefined) {
      await this.store.putStrings(this.context, { 'owner': this.owner, 'requested': this.requested ? 'true' : 'false' });
    }
  }

  private saveEvents(context: common.Context): Promise<void> {
    this.samples = this.samples.catch(() => {}).then(async () => {
      while (this.unsavedEvents.length > 0) {
        await pendingSafetyEvents.enqueue(context, this.unsavedEvents[0]);
        this.unsavedEvents.shift();
      }
    });
    return this.samples;
  }

  private async refreshSafeArea(context: common.UIAbilityContext): Promise<void> {
    this.lastConfigCheck = Date.now();
    const token = apiSession.token;
    try {
      const result = await careApi.request(`/seniors/${apiSession.seniorId}/safe-area`, http.RequestMethod.GET) as Record<string, Object>;
      if (apiSession.token !== token) return;
      if (!safetyStore.configureHomeCircle(result['lat'] as number, result['lng'] as number, result['radiusM'] as number)) {
        throw new Error('Invalid safe area');
      }
      const area = new SavedSafeArea(safetyStore.homeLatitude, safetyStore.homeLongitude, safetyStore.homeRadiusMeters);
      await this.store.putStrings(context, { 'owner': this.owner, 'safeArea': JSON.stringify(area) });
      this.configMessage = '';
    } catch (error) {
      if (apiSession.token !== token) return;
      if (error instanceof ApiError && (error.status === 401 || error.status === 403)) throw error;
      if (error instanceof ApiError && error.status === 404) {
        safetyStore.clearSafeArea();
        await this.store.putStrings(context, { 'safeArea': '' });
      }
      this.configMessage = safetyStore.safeAreaConfigured
        ? 'Could not refresh the safe area. Using the last saved boundary.'
        : 'No safe area is available yet. Location can be shared, but boundary alerts are unavailable.';
    }
    this.notify();
  }

  /** Single in-flight heartbeat/retry lane. Fix timestamps are never replaced with heartbeat time. */
  private async tick(): Promise<void> {
    const context = this.context;
    if (this.ticking || !this.enabled || context === undefined) return;
    if (!apiSession.configured() || apiSession.role !== 'senior' || apiSession.seniorId !== this.owner) {
      this.stop();
      return;
    }
    const epoch = this.generation;
    this.ticking = true;
    try {
      this.permissionDenied = !this.hasPermission(context);
      this.locationSwitchOff = !geoLocationManager.isLocationEnabled();
      if (this.permissionDenied || this.locationSwitchOff) {
        this.stop();
        this.errorMessage = 'Sharing stopped because location access is unavailable. Restore access and turn sharing on again.';
        return;
      }
      if (Date.now() - this.lastConfigCheck >= 60000) await this.refreshSafeArea(context);
      if (epoch !== this.generation) return;
      await this.saveEvents(context);
      let eventDeliveryFailed = false;
      try {
        await pendingSafetyEvents.flush(context);
      } catch (error) {
        if (error instanceof ApiError && (error.status === 401 || error.status === 403)) throw error;
        eventDeliveryFailed = true;
      }
      if (epoch !== this.generation) return;
      const point = this.lastFix;
      const fresh = point !== undefined && Date.now() - Date.parse(point.sampledAt) <= 120000;
      if (!fresh) {
        safetyStore.geofenceStatus = GeofenceStatus.Unknown;
        safetyStore.lastLocationMessage = 'Waiting for a fresh location. The phone is still checking in.';
      }
      await careApi.request(`/seniors/${this.owner}/status`, http.RequestMethod.PUT,
        new StatusReport(fresh ? this.backendStatus() : 'unavailable', fresh ? point : undefined));
      if (epoch === this.generation) this.errorMessage = eventDeliveryFailed
        ? 'Location was shared, but saved boundary events could not be delivered. They will be retried.' : '';
    } catch (error) {
      if (epoch === this.generation) {
        if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
          this.stop();
          this.errorMessage = 'The care service no longer allows this phone to share. Check your pairing in Settings.';
        } else {
          this.errorMessage = this.unsavedEvents.length > 0
            ? 'A boundary event is still in memory. Storage will be retried; keep Carely running.'
            : 'Could not reach the care service. Saved boundary events will be retried while sharing is on.';
        }
      }
    } finally {
      this.ticking = false;
      this.notify();
    }
  }

  private backendStatus(): string {
    if (safetyStore.geofenceStatus === GeofenceStatus.Inside) return 'inside';
    if (safetyStore.geofenceStatus === GeofenceStatus.Outside) return 'outside';
    return 'unknown';
  }

  private notify(): void {
    this.listeners.forEach((listener: StateListener) => listener());
  }
}

export const locationSharing: LocationSharing = new LocationSharing();

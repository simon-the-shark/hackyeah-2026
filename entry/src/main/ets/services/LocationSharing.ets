import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from './CareApi';
import { pendingSafetyEvents } from './PendingSafetyEvents';

type StateListener = () => void;

class LocationPoint {
  lat: number;
  lng: number;
  accuracyM: number;
  sampledAt: string;
  measuredBy: string = 'phone';

  constructor(lat: number, lng: number, accuracyM: number) {
    this.lat = lat;
    this.lng = lng;
    this.accuracyM = accuracyM;
    this.sampledAt = new Date().toISOString();
  }
}

class StatusReport {
  monitoringState: string;
  location: LocationPoint;

  constructor(monitoringState: string, location: LocationPoint) {
    this.monitoringState = monitoringState;
    this.location = location;
  }
}

// Owns the foreground-only LocationKit subscription so navigation cannot stop sharing.
export class LocationSharing {
  enabled: boolean = false;
  starting: boolean = false;
  permissionDenied: boolean = false;
  locationSwitchOff: boolean = false;
  errorMessage: string = '';
  private requested: boolean = false;
  private context: common.UIAbilityContext | undefined = undefined;
  private listeners: StateListener[] = [];
  private readonly locationCallback: (location: geoLocationManager.Location) => void =
    (location: geoLocationManager.Location): void => {
      safetyStore.recordLiveLocation(location.latitude, location.longitude, location.accuracy, false);
      this.reportLocation(location.latitude, location.longitude, location.accuracy, safetyStore.didLeaveSafeArea);
      this.notify();
    };

  subscribe(listener: StateListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unsubscribe(listener: StateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  start(context: common.UIAbilityContext): void {
    this.context = context;
    if (this.enabled) {
      this.requested = true;
      this.notify();
      return;
    }
    this.requested = true;
    this.starting = true;
    this.errorMessage = '';
    this.locationSwitchOff = false;
    this.notify();
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ]).then((result) => {
      this.starting = false;
      if (result.authResults[0] !== 0 || result.authResults[1] !== 0) {
        this.permissionDenied = true;
        this.requested = false;
        this.notify();
        return;
      }
      this.permissionDenied = false;
      this.subscribeToLocation();
    }).catch((error: BusinessError) => {
      this.starting = false;
      this.requested = false;
      this.errorMessage = `Location permission request failed (error ${error.code}).`;
      this.notify();
    });
  }

  requestLocationSwitch(context: common.UIAbilityContext): void {
    this.starting = true;
    this.errorMessage = '';
    this.notify();
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION).then((enabled: boolean) => {
      this.starting = false;
      if (!enabled) {
        this.errorMessage = 'Location needs to be turned on before sharing can start.';
        this.notify();
        return;
      }
      this.locationSwitchOff = false;
      this.start(context);
    }).catch((error: BusinessError) => {
      this.starting = false;
      if (error.code === 12100013) {
        this.locationSwitchOff = false;
        this.start(context);
        return;
      }
      this.errorMessage = `Could not open the location switch (error ${error.code}).`;
      this.notify();
    });
  }

  openPermissionSettings(context: common.UIAbilityContext): void {
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionOnSetting(context, [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ]).then((result) => {
      if (result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.permissionDenied = false;
        this.start(context);
      }
    }).catch((error: BusinessError) => {
      this.errorMessage = `Could not open location settings (error ${error.code}).`;
      this.notify();
    });
  }

  stop(): void {
    this.requested = false;
    this.unsubscribeFromLocation();
  }

  pause(): void {
    this.unsubscribeFromLocation();
  }

  resume(context: common.UIAbilityContext): void {
    this.context = context;
    if (this.requested && !this.enabled) {
      this.subscribeToLocation();
    }
  }

  private subscribeToLocation(): void {
    const request: geoLocationManager.LocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      timeInterval: 10,
      distanceInterval: 20,
      maxAccuracy: 300
    };
    try {
      geoLocationManager.on('locationChange', request, this.locationCallback);
      this.enabled = true;
      safetyStore.lastLocationMessage = 'Checking where you are…';
    } catch (error) {
      const businessError = error as BusinessError;
      this.requested = false;
      if (businessError.code === 3301100) {
        this.locationSwitchOff = true;
        this.errorMessage = 'Location is turned off on this phone. Turn it on to share your location.';
      } else {
        this.errorMessage = `Location sharing could not start (error ${businessError.code}).`;
      }
    }
    this.notify();
  }

  private unsubscribeFromLocation(): void {
    if (!this.enabled) {
      this.notify();
      return;
    }
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
      this.enabled = false;
    } catch (error) {
      const businessError = error as BusinessError;
      this.errorMessage = `Location sharing could not stop (error ${businessError.code}).`;
    }
    this.notify();
  }

  private async reportLocation(latitude: number, longitude: number, accuracy: number, exited: boolean): Promise<void> {
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      return;
    }
    const point = new LocationPoint(latitude, longitude, accuracy);
    const context = this.context;
    try {
      await careApi.request(`/seniors/${apiSession.seniorId}/status`, http.RequestMethod.PUT,
        new StatusReport(this.backendStatus(), point));
      if (context !== undefined) {
        await pendingSafetyEvents.flush(context);
      }
      if (exited) {
        const event = new SafetyEventRequest(generateEventId(), 'area_exit');
        event.location = point;
        try {
          await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event);
        } catch (postError) {
          if (context !== undefined) {
            await pendingSafetyEvents.enqueue(context, event);
          }
          this.errorMessage = 'Left the safe area, but the alert is queued until the care service is reachable.';
        }
      } else {
        this.errorMessage = '';
      }
    } catch (error) {
      if (exited && context !== undefined) {
        const event = new SafetyEventRequest(generateEventId(), 'area_exit');
        event.location = point;
        await pendingSafetyEvents.enqueue(context, event);
      }
      this.errorMessage = exited
        ? 'Left the safe area. The alert is saved and will be sent when connection returns.'
        : 'Location was checked, but could not reach the care service.';
    }
    this.notify();
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

import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from '../services/CareApi';
import { pendingSafetyEvents } from '../services/PendingSafetyEvents';

@Component
export struct SafetyPage {
  @State private status: GeofenceStatus = safetyStore.geofenceStatus;
  @State private locationMessage: string = safetyStore.lastLocationMessage;
  @State private monitoringEnabled: boolean = false;
  @State private starting: boolean = false;
  @State private locationPermissionDenied: boolean = false;
  @State private locationSwitchOff: boolean = false;
  @State private errorMessage: string = '';
  private readonly locationCallback: (location: geoLocationManager.Location) => void =
    (location: geoLocationManager.Location): void => {
      safetyStore.recordLiveLocation(location.latitude, location.longitude, location.accuracy, false);
      this.syncFromStore();
      this.reportLocation(location.latitude, location.longitude, location.accuracy, safetyStore.didLeaveSafeArea);
    };

  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  /**
   * The guardian owns the safe area, so the senior's phone must monitor the same
   * boundary the backend raises alerts against. Without this the app geofences
   * against its local default while the backend uses the configured area, which
   * produces false exits.
   */
  private async loadSafeAreaFromBackend(): Promise<void> {
    try {
      const result = await careApi.request(`/seniors/${apiSession.seniorId}/safe-area`, http.RequestMethod.GET) as Record<string, Object>;
      if (safetyStore.configureHomeCircle(result['lat'] as number, result['lng'] as number, result['radiusM'] as number)) {
        this.syncFromStore();
      }
    } catch (error) {
      // No stored area yet, or the service is unreachable: keep the current boundary.
      console.error(`[SafetyPage] safe area load failed: ${JSON.stringify(error)}`);
    }
  }

  private async reportLocation(latitude: number, longitude: number, accuracy: number, exited: boolean): Promise<void> {
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      return;
    }
    const point = new LocationPoint(latitude, longitude, accuracy);
    const context = this.hostContext();
    try {
      await careApi.request(`/seniors/${apiSession.seniorId}/status`, http.RequestMethod.PUT,
        new StatusReport(this.backendStatus(), point));
      await pendingSafetyEvents.flush(context);
      if (exited) {
        const event = new SafetyEventRequest(generateEventId(), 'area_exit');
        event.location = point;
        try {
          await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event);
        } catch (postError) {
          await pendingSafetyEvents.enqueue(context, event);
          this.errorMessage = 'Left the safe area, but the alert is queued until the care service is reachable.';
        }
      } else {
        this.errorMessage = '';
      }
    } catch (error) {
      if (exited) {
        const event = new SafetyEventRequest(generateEventId(), 'area_exit');
        event.location = point;
        await pendingSafetyEvents.enqueue(context, event);
        this.errorMessage = 'Left the safe area. The alert is saved and will be sent when connection returns.';
      } else {
        this.errorMessage = 'Location was checked, but could not reach the care service.';
      }
    }
  }

  private backendStatus(): string {
    if (this.status === GeofenceStatus.Inside) return 'inside';
    if (this.status === GeofenceStatus.Outside) return 'outside';
    return 'unknown';
  }

  private syncFromStore(): void {
    this.status = safetyStore.geofenceStatus;
    this.locationMessage = safetyStore.lastLocationMessage;
  }

  private startLocationMonitoring(): void {
    this.starting = true;
    this.errorMessage = '';
    this.locationSwitchOff = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ]).then((result) => {
      this.starting = false;
      if (result.authResults[0] !== 0 || result.authResults[1] !== 0) {
        this.locationPermissionDenied = true;
        return;
      }
      this.locationPermissionDenied = false;
      const request: geoLocationManager.LocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        timeInterval: 10,
        distanceInterval: 20,
        maxAccuracy: 300
      };
      try {
        geoLocationManager.on('locationChange', request, this.locationCallback);
        this.monitoringEnabled = true;
        this.locationMessage = 'Checking where you are…';
      } catch (error) {
        const businessError = error as BusinessError;
        if (businessError.code === 3301100) {
          this.locationSwitchOff = true;
          this.errorMessage = 'Location is turned off on this phone. Turn it on to share your location.';
        } else {
          this.errorMessage = `Location sharing could not start (error ${businessError.code}).`;
        }
      }
    }).catch((error: BusinessError) => {
      this.starting = false;
      this.errorMessage = `Location permission request failed (error ${error.code}).`;
    });
  }

  private requestLocationSwitch(): void {
    this.starting = true;
    this.errorMessage = '';
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestGlobalSwitch(this.hostContext(), abilityAccessCtrl.SwitchType.LOCATION).then((enabled: boolean) => {
      this.starting = false;
      if (!enabled) {
        this.errorMessage = 'Location needs to be turned on before sharing can start.';
        return;
      }
      this.locationSwitchOff = false;
      this.startLocationMonitoring();
    }).catch((error: BusinessError) => {
      this.starting = false;
      if (error.code === 12100013) {
        this.locationSwitchOff = false;
        this.startLocationMonitoring();
        return;
      }
      this.errorMessage = `Could not open the location switch (error ${error.code}).`;
    });
  }

  private openLocationSettings(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionOnSetting(context, [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ]).then((result) => {
      if (result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.locationPermissionDenied = false;
        this.startLocationMonitoring();
      }
    }).catch((error: BusinessError) => {
      this.errorMessage = `Could not open location settings (error ${error.code}).`;
    });
  }

  private stopLocationMonitoring(): void {
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
    } catch (error) {
      const businessError = error as BusinessError;
      this.errorMessage = `Location sharing could not stop (error ${businessError.code}).`;
      return;
    }
    this.monitoringEnabled = false;
  }

  aboutToDisappear(): void {
    if (this.monitoringEnabled) {
      this.stopLocationMonitoring();
    }
  }

  private statusTitle(): string {
    if (this.status === GeofenceStatus.Inside) {
      return 'You are at home';
    }
    if (this.status === GeofenceStatus.Outside) {
      return 'You are outside your safe area';
    }
    return this.monitoringEnabled ? 'Finding your location' : 'Location not checked';
  }

  private statusDetail(): string {
    if (this.status === GeofenceStatus.Outside) {
      return `${this.locationMessage} An alert was created for your guardian.`;
    }
    if (this.status === GeofenceStatus.Unknown && !this.monitoringEnabled) {
      return 'Turn on location sharing below to check.';
    }
    return this.locationMessage;
  }

  private statusIcon(): Resource {
    if (this.status === GeofenceStatus.Inside) {
      return $r('sys.symbol.house_fill');
    }
    if (this.status === GeofenceStatus.Outside) {
      return $r('sys.symbol.exclamationmark_triangle_fill');
    }
    return $r('sys.symbol.questionmark_circle_fill');
  }

  private statusAccent(): Resource {
    if (this.status === GeofenceStatus.Inside) {
      return $r('app.color.senior_accent');
    }
    if (this.status === GeofenceStatus.Outside) {
      return $r('app.color.sos');
    }
    return $r('app.color.text_secondary');
  }

  private statusTint(): Resource {
    if (this.status === GeofenceStatus.Inside) {
      return $r('app.color.senior_tint');
    }
    if (this.status === GeofenceStatus.Outside) {
      return $r('app.color.sos_tint');
    }
    return $r('app.color.surface');
  }

  @Builder
  statusCard() {
    Column({ space: 16 }) {
      IconBadge({
        icon: this.statusIcon(),
        accent: this.statusAccent(),
        tint: this.status === GeofenceStatus.Unknown ? $r('app.color.page_background') : $r('app.color.surface'),
        badgeSize: 64
      })
      Column({ space: 6 }) {
        Text(this.statusTitle())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.statusDetail())
          .fontSize(17)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)

      Divider()
        .color($r('app.color.divider'))

      Text(`Safe area: ${safetyStore.homeRadiusMeters} m around home`)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(28)
    .backgroundColor(this.statusTint())
    .border({ width: this.status === GeofenceStatus.Unknown ? 1 : 0, color: $r('app.color.divider') })
    .accessibilityGroup(true)
  }

  @Builder
  sharingCard() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        IconBadge({ icon: $r('sys.symbol.location_up_fill') })
        Text('Location sharing')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(this.monitoringEnabled ? 'On' : 'Off')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.monitoringEnabled ? $r('app.color.senior_accent') : $r('app.color.text_secondary'))
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.monitoringEnabled ? $r('app.color.senior_tint') : $r('app.color.page_background'))
      }
      .width('100%')

      Text('When on, your guardian is alerted if you leave the safe area. Active only while this app is open on screen.')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))

      if (this.locationPermissionDenied) {
        NoticeBanner({
          icon: $r('sys.symbol.exclamationmark_circle_fill'),
          text: 'Location access is turned off for this app. Allow it in Settings to share your location.'
        })
      }

      if (this.locationSwitchOff) {
        NoticeBanner({
          icon: $r('sys.symbol.exclamationmark_circle_fill'),
          text: 'Location is turned off for this phone. Turn it on to share your location.',
          accent: $r('app.color.sos'),
          tint: $r('app.color.sos_tint')
        })
      }

      if (this.errorMessage !== '') {
        NoticeBanner({
          icon: $r('sys.symbol.exclamationmark_circle_fill'),
          text: this.errorMessage,
          accent: $r('app.color.sos'),
          tint: $r('app.color.sos_tint')
        })
      }

      Button(this.starting ? 'Starting…'
        : this.monitoringEnabled ? 'Turn off sharing'
          : this.locationPermissionDenied ? 'Open Settings'
            : this.locationSwitchOff ? 'Turn on location' : 'Turn on sharing')
        .width('100%')
        .height(56)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.starting)
        .fontColor(this.monitoringEnabled ? $r('app.color.text_primary') : Color.White)
        .backgroundColor(this.monitoringEnabled ? $r('app.color.page_background') : $r('app.color.senior_accent'))
        .onClick(() => {
          if (this.monitoringEnabled) {
            this.stopLocationMonitoring();
          } else if (this.locationPermissionDenied) {
            this.openLocationSettings();
          } else if (this.locationSwitchOff) {
            this.requestLocationSwitch();
          } else {
            this.startLocationMonitoring();
          }
        })
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor($r('app.color.surface'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          this.statusCard()
          this.sharingCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title('Safe Area')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => {
      this.syncFromStore();
      if (apiSession.configured() && apiSession.role === 'senior') {
        this.loadSafeAreaFromBackend();
        pendingSafetyEvents.flush(this.hostContext());
      }
    })
  }
}

class LocationPoint {
  lat: number;
  lng: number;
  accuracyM: number;
  sampledAt: string;
  // This fix comes from the phone's own LocationKit, never from a watch.
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

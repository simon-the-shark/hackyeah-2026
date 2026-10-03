import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { apiSession, careApi } from '../services/CareApi';
import { locationSharing } from '../services/LocationSharing';
import { pendingSafetyEvents } from '../services/PendingSafetyEvents';

@Component
export struct SafetyPage {
  @State private status: GeofenceStatus = safetyStore.geofenceStatus;
  @State private locationMessage: string = safetyStore.lastLocationMessage;
  @State private monitoringEnabled: boolean = locationSharing.enabled;
  @State private starting: boolean = locationSharing.starting;
  @State private locationPermissionDenied: boolean = locationSharing.permissionDenied;
  @State private locationSwitchOff: boolean = locationSharing.locationSwitchOff;
  @State private errorMessage: string = locationSharing.errorMessage;
  private readonly locationStateListener: () => void = () => this.syncFromStore();

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

  private syncFromStore(): void {
    this.status = safetyStore.geofenceStatus;
    this.locationMessage = safetyStore.lastLocationMessage;
    this.monitoringEnabled = locationSharing.enabled;
    this.starting = locationSharing.starting;
    this.locationPermissionDenied = locationSharing.permissionDenied;
    this.locationSwitchOff = locationSharing.locationSwitchOff;
    this.errorMessage = locationSharing.errorMessage;
  }

  private startLocationMonitoring(): void {
    locationSharing.start(this.hostContext());
  }

  private requestLocationSwitch(): void {
    locationSharing.requestLocationSwitch(this.hostContext());
  }

  private openLocationSettings(): void {
    locationSharing.openPermissionSettings(this.hostContext());
  }

  private stopLocationMonitoring(): void {
    locationSharing.stop();
  }

  aboutToAppear(): void {
    locationSharing.subscribe(this.locationStateListener);
    this.syncFromStore();
  }

  aboutToDisappear(): void {
    locationSharing.unsubscribe(this.locationStateListener);
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

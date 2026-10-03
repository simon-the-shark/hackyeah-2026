import { common } from '@kit.AbilityKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { apiSession } from '../services/CareApi';
import { locationSharing } from '../services/LocationSharing';
import { pendingSafetyEvents } from '../services/PendingSafetyEvents';
import { CareButtonStyle } from '../components/DesignSystem';

@Component
export struct SafetyPage {
  @State private status: GeofenceStatus = safetyStore.geofenceStatus;
  @State private locationMessage: string = safetyStore.lastLocationMessage;
  @State private monitoringEnabled: boolean = locationSharing.enabled;
  @State private starting: boolean = locationSharing.starting;
  @State private locationPermissionDenied: boolean = locationSharing.permissionDenied;
  @State private locationSwitchOff: boolean = locationSharing.locationSwitchOff;
  @State private errorMessage: string = locationSharing.errorMessage;
  @State private configMessage: string = locationSharing.configMessage;
  private readonly locationStateListener: () => void = () => this.syncFromStore();

  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private syncFromStore(): void {
    this.status = safetyStore.geofenceStatus;
    this.locationMessage = safetyStore.lastLocationMessage;
    this.monitoringEnabled = locationSharing.enabled;
    this.starting = locationSharing.starting;
    this.locationPermissionDenied = locationSharing.permissionDenied;
    this.locationSwitchOff = locationSharing.locationSwitchOff;
    this.errorMessage = locationSharing.errorMessage;
    this.configMessage = locationSharing.configMessage;
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
      return 'Last confirmed inside your safe area';
    }
    if (this.status === GeofenceStatus.Outside) {
      return 'Last confirmed outside your safe area';
    }
    return this.monitoringEnabled ? 'Finding your location' : 'Location not checked';
  }

  private statusDetail(): string {
    if (this.status === GeofenceStatus.Outside) {
      return `${this.locationMessage} Check sharing status below for delivery problems.`;
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

      Text(safetyStore.safeAreaConfigured ? `Safe area: ${safetyStore.homeRadiusMeters} m around home` : 'Safe area not available')
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

      Text('When on, this phone shares location and checks your safe area even with the screen locked or another app open. A system notification shows that sharing is active. You can turn it off here.')
        .fontSize(19)
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

      if (this.configMessage !== '') {
        NoticeBanner({ icon: $r('sys.symbol.exclamationmark_circle_fill'), text: this.configMessage })
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
        .attributeModifier(new CareButtonStyle(this.monitoringEnabled ? 'secondary' : 'primary'))
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
        pendingSafetyEvents.flush(this.hostContext()).catch(() => {
          this.errorMessage = 'Saved safe-area events could not be sent. They will retry while sharing is on.';
        });
      }
    })
  }
}

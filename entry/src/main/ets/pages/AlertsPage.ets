import { common } from '@kit.AbilityKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { MapMarker, MapScene, SeniorMap } from '../components/SeniorMap';
import {
  accuracyLabel,
  AlertLocation,
  alertLocationFrom,
  fixTimeLabel,
  formatCoordinates,
  RemoteGeoPoint,
  sourceLabel
} from '../models/AlertLocation';
import {
  AlertType,
  CareAlert,
  deliveryLabel,
  formatAlertTime,
  remoteAlertCopy,
} from '../models/Safety';
import { http } from '@kit.NetworkKit';
import { MapsHandOff, openInMaps } from '../platform/MapsLauncher';
import { apiSession, careApi } from '../services/CareApi';
import { guardianAlertWatcher } from '../services/GuardianAlertWatcher';
import { CareButtonStyle, CareFocusStyle } from '../components/DesignSystem';
import { WELLBEING_REPORT_ROUTE, WELLBEING_REPORTS_ROUTE, WellbeingReportTarget } from './WellbeingReportsPage';

interface RemoteAlert {
  id: string;
  kind: string;
  createdAt: string;
  // The care service sends null, not an absent field, for an unacknowledged alert.
  acknowledgedAt?: string | null;
  // Null for server-raised alerts such as a missed dose.
  event?: RemoteEvent | null;
  details?: RemoteAlertDetails | null;
}

/** Only the fields this screen uses; `details` differs per alert kind. */
interface RemoteAlertDetails {
  reportId?: string | null;
}

interface RemoteEvent {
  type: string;
  occurredAt: string;
  location?: RemoteGeoPoint | null;
}

enum LocationLoad {
  Loading,
  Loaded,
  Failed
}

interface RemoteAlertList {
  items: RemoteAlert[];
}

function alertIcon(alert: CareAlert): Resource {
  if (alert.type === AlertType.Sos || alert.type === AlertType.Fall) {
    return $r('sys.symbol.exclamationmark_shield_fill');
  }
  if (alert.type === AlertType.DoseMissed) {
    return $r('sys.symbol.calendar_badge_clock');
  }
  if (alert.type === AlertType.MonitoringLost || alert.type === AlertType.LowBattery) {
    return $r('sys.symbol.watch_fill');
  }
  if (alert.type === AlertType.HeartRate) {
    return $r('sys.symbol.heart_fill');
  }
  if (alert.type === AlertType.Wellbeing) {
    return $r('sys.symbol.message_fill');
  }
  return $r('sys.symbol.house_shield_fill');
}

function isUrgent(alert: CareAlert): boolean {
  return alert.type === AlertType.Sos || alert.type === AlertType.Fall;
}

function alertAccent(alert: CareAlert): Resource {
  return isUrgent(alert) ? $r('app.color.sos') : $r('app.color.warning');
}

function alertTint(alert: CareAlert): Resource {
  return isUrgent(alert) ? $r('app.color.sos_tint') : $r('app.color.warning_tint');
}

/** Guardian alert inbox; used both as a standalone page and as the guardian Alerts tab. */
@Component
export struct AlertsList {
  @Consume('navStack') navStack: NavPathStack;
  /** Bump to reload, e.g. when the tab or page becomes visible again. */
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  @State private alerts: CareAlert[] = [];
  @State private pendingCount: number = 0;
  @State private loadError: string = '';
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  private requestSeq: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  private onRefresh(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    const seq = ++this.requestSeq;
    this.loading = this.alerts.length === 0;
    if (!apiSession.configured() || apiSession.role !== 'guardian') {
      this.alerts = [];
      this.loadError = 'This phone is not paired as a guardian.';
      this.loading = false;
      this.refreshing = false;
      return;
    }
    try {
      const response = await careApi.request('/alerts?limit=50', http.RequestMethod.GET) as RemoteAlertList;
      if (seq !== this.requestSeq) return;
      this.alerts = response.items.map((item: RemoteAlert) => this.fromRemote(item));
      this.pendingCount = this.alerts.filter((alert: CareAlert) => !alert.acknowledged).length;
      this.loadError = '';
    } catch (error) {
      if (seq !== this.requestSeq) return;
      this.loadError = this.alerts.length > 0 ? 'Could not refresh alerts. Showing the last loaded list. Try again.' :
        'Could not load alerts from the care service. Check your connection and try again.';
    } finally {
      if (seq === this.requestSeq) {
        this.loading = false;
        this.refreshing = false;
      }
    }
  }

  private fromRemote(item: RemoteAlert): CareAlert {
    const copy = remoteAlertCopy(item.kind);
    const alert = new CareAlert(item.id, copy.type, copy.title, copy.detail, 'Care service');
    alert.createdAt = Date.parse(item.createdAt);
    alert.acknowledged = item.acknowledgedAt !== undefined && item.acknowledgedAt !== null;
    alert.remote = true;
    return alert;
  }

  @Builder
  statusPill(alert: CareAlert) {
    Text(alert.acknowledged ? 'Seen' : 'New')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(alert.acknowledged ? $r('app.color.text_secondary') : Color.White)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(12)
      .backgroundColor(alert.acknowledged ? $r('app.color.page_background') : $r('app.color.action_danger'))
  }

  @Builder
  alertRow(alert: CareAlert, showDivider: boolean) {
    Column() {
      Row({ space: 14 }) {
        IconBadge({ icon: alertIcon(alert), accent: alertAccent(alert), tint: alertTint(alert) })
        Column({ space: 3 }) {
          Text(alert.title)
            .fontSize(18)
            .fontWeight(alert.acknowledged ? FontWeight.Medium : FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(formatAlertTime(alert.createdAt))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        this.statusPill(alert)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 76 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 78 })
      }
    }
    .accessibilityGroup(true)
    .attributeModifier(new CareFocusStyle())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
    .onClick(() => this.navStack.pushPathByName('alert-detail', alert))
  }

  @Builder
  emptyState() {
    Column({ space: 12 }) {
      IconBadge({
        icon: $r('sys.symbol.bell_fill'),
        accent: $r('app.color.guardian_accent'),
        tint: $r('app.color.guardian_tint'),
        badgeSize: 80
      })
      Text('No alerts')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text('SOS, safe-area, medication, and monitoring alerts will appear here.')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 64, bottom: 32, left: 16, right: 16 })
  }

  build() {
    Refresh({ refreshing: $$this.refreshing }) {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) {
          Text('Loading alerts…').fontSize(19).fontColor($r('app.color.text_secondary'))
        } else if (this.loadError !== '' && this.alerts.length === 0) {
          NoticeBanner({ text: this.loadError })
          Button('Retry loading alerts')
            .width('100%')
            .attributeModifier(new CareButtonStyle())
            .onClick(() => this.reload())
        } else if (this.alerts.length === 0) {
          this.emptyState()
        } else {
          if (this.loadError !== '') {
            NoticeBanner({ text: this.loadError })
          }
          if (this.pendingCount > 0) {
            NoticeBanner({
              icon: $r('sys.symbol.exclamationmark_circle_fill'),
              text: this.pendingCount === 1 ? '1 alert needs your attention' : `${this.pendingCount} alerts need your attention`,
              accent: $r('app.color.sos'),
              tint: $r('app.color.sos_tint')
            })
          }

          Column() {
            ForEach(this.alerts, (alert: CareAlert, index: number) => {
              this.alertRow(alert, index < this.alerts.length - 1)
            }, (alert: CareAlert, index: number) =>
              `${alert.id}-${alert.acknowledged}-${alert.deliveryState}-${index === this.alerts.length - 1}`)
          }
          .width('100%')
          .borderRadius(20)
          .clip(true)
          .backgroundColor($r('app.color.surface'))
        }

        Button(this.refreshing || this.loading ? 'Refreshing alerts…' : 'Refresh alerts')
          .width('100%')
          .attributeModifier(new CareButtonStyle('secondary'))
          .enabled(!this.refreshing && !this.loading)
          .onClick(() => {
            this.refreshing = true;
            this.reload();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .width('100%')
    .height('100%')
    .onRefreshing(() => {
      this.refreshing = true;
      this.reload();
    })
  }
}

@Component
export struct AlertsPage {
  @State private shownCount: number = 0;

  build() {
    NavDestination() {
      AlertsList({ refreshKey: this.shownCount })
    }
    .title('Alerts')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.shownCount++)
  }
}

@Component
export struct AlertDetailPage {
  @Consume('navStack') navStack: NavPathStack;
  alert: CareAlert = new CareAlert('', AlertType.Sos, '', '', '');
  /** The check-in summary a wellbeing alert points to, once it exists. */
  @State private reportId: string = '';
  @State private acknowledged: boolean = false;
  @State private acknowledging: boolean = false;
  @State private acknowledgementError: string = '';
  @State private location: AlertLocation | undefined = undefined;
  @State private locationScene: MapScene = new MapScene();
  @State private locationLoad: LocationLoad = LocationLoad.Loading;
  /** When the senior's device raised the event, on its own clock; 0 when unknown. */
  private occurredAt: number = 0;

  aboutToAppear(): void {
    this.acknowledged = this.alert.acknowledged;
    this.loadLocation();
  }

  /** Every entry point (inbox, SOS banner, notification) passes only the alert id, so read the event here. */
  private async loadLocation(): Promise<void> {
    if (!this.alert.remote || !apiSession.configured() || apiSession.role !== 'guardian') {
      this.locationLoad = LocationLoad.Loaded;
      return;
    }
    try {
      const item = await careApi.request(`/alerts/${encodeURIComponent(this.alert.id)}`,
        http.RequestMethod.GET) as RemoteAlert;
      const reportId = item.details?.reportId;
      this.reportId = typeof reportId === 'string' ? reportId : '';
      const event = item.event;
      if (event !== undefined && event !== null) {
        const occurredAt = Date.parse(event.occurredAt);
        this.occurredAt = isFinite(occurredAt) ? occurredAt : 0;
        this.location = alertLocationFrom(event.location);
        const scene = new MapScene();
        if (this.location !== undefined) {
          const marker = new MapMarker();
          marker.kind = this.location.measuredBy;
          marker.lat = this.location.lat;
          marker.lng = this.location.lng;
          marker.accuracyM = this.location.accuracyM;
          scene.markers = [marker];
        }
        this.locationScene = scene;
      }
      this.locationLoad = LocationLoad.Loaded;
    } catch (error) {
      this.locationLoad = LocationLoad.Failed;
    }
  }

  private async openMap(location: AlertLocation): Promise<void> {
    const handOff = await openInMaps(this.getUIContext().getHostContext() as common.UIAbilityContext,
      location.lat, location.lng, this.alert.title);
    if (handOff === MapsHandOff.None) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: 'No maps app or browser could open this location' });
      } catch (toastError) {
        console.error('[AlertDetail] toast failed');
      }
    }
  }

  /** For SOS and falls the guardian needs to know a location is missing, not just see nothing. */
  private locationStatusText(): string {
    if (this.locationLoad === LocationLoad.Loading) {
      return 'Loading the location…';
    }
    if (this.locationLoad === LocationLoad.Failed) {
      return 'Could not load the location from the care service.';
    }
    return 'No location was shared with this alert. Check the Location tab or call the senior.';
  }

  @Builder
  locationCard() {
    Column({ space: 14 }) {
      Row({ space: 14 }) {
        IconBadge({
          icon: $r('sys.symbol.map_badge_local'),
          accent: $r('app.color.guardian_accent'),
          tint: $r('app.color.guardian_tint')
        })
        Column({ space: 3 }) {
          Text('Last known location')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          if (this.location !== undefined) {
            Text(`${sourceLabel(this.location)} · ${fixTimeLabel(this.location, this.occurredAt)}`)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .accessibilityGroup(true)

      if (this.location !== undefined) {
        SeniorMap({ scene: this.locationScene })

        Text(`${formatCoordinates(this.location.lat, this.location.lng)} · ${accuracyLabel(this.location)}`)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .copyOption(CopyOptions.LocalDevice)
          .width('100%')

        Button() {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.map'))
              .fontSize(20)
              .fontColor([$r('app.color.guardian_accent')])
            Text('Open in Maps')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.guardian_accent'))
          }
        }
        .width('100%')
        .height(56)
        .attributeModifier(new CareButtonStyle('secondary'))
        .accessibilityText('Open the last known location in Maps')
        .onClick(() => {
          if (this.location !== undefined) {
            this.openMap(this.location);
          }
        })
      } else {
        Text(this.locationStatusText())
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  infoRow(label: string, value: string, showDivider: boolean) {
    Column() {
      Row({ space: 16 }) {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
        Text(value)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 16, right: 16 })
      }
    }
    .accessibilityGroup(true)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 12 }) {
            IconBadge({
              icon: alertIcon(this.alert),
              accent: alertAccent(this.alert),
              tint: $r('app.color.surface'),
              badgeSize: 64
            })
            Text(this.alert.detail)
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .opacity(0.8)
          }
          .width('100%')
          .padding(24)
          .alignItems(HorizontalAlign.Start)
          .borderRadius(28)
          .backgroundColor(alertTint(this.alert))

          if (this.location !== undefined || isUrgent(this.alert)) {
            this.locationCard()
          }

          if (this.alert.type === AlertType.Wellbeing) {
            Button(this.reportId !== '' ? 'Read the check-in summary' : 'Open wellbeing reports')
              .width('100%')
              .height(56)
              .attributeModifier(new CareButtonStyle('secondary'))
              .onClick(() => {
                if (this.reportId !== '') {
                  this.navStack.pushPathByName(WELLBEING_REPORT_ROUTE, new WellbeingReportTarget(this.reportId));
                } else {
                  this.navStack.pushPathByName(WELLBEING_REPORTS_ROUTE, null);
                }
              })
            if (this.reportId === '') {
              Text('The summary appears in Wellbeing reports once the check-in ends.')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
          }

          Column() {
            this.infoRow('Time', formatAlertTime(this.alert.createdAt), true)
            this.infoRow('Source', this.alert.source, true)
            this.infoRow('Delivery', deliveryLabel(this.alert.deliveryState), true)
            Row({ space: 16 }) {
              Text('Status')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
              Text(this.acknowledged ? 'Seen by you' : 'Not yet seen')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.acknowledged ? $r('app.color.text_primary') : $r('app.color.sos'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .accessibilityGroup(true)
          }
          .width('100%')
          .borderRadius(20)
          .backgroundColor($r('app.color.surface'))

          Button() {
            Row({ space: 8 }) {
              if (this.acknowledged) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(20)
                  .fontColor([$r('app.color.guardian_accent')])
              }
              Text(this.acknowledged ? 'Marked as seen' : this.acknowledging ? 'Saving…' : 'Mark as seen')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.acknowledged ? $r('app.color.guardian_accent') : Color.White)
            }
          }
          .width('100%')
          .height(56)
          .enabled(!this.acknowledged && !this.acknowledging)
          .attributeModifier(new CareButtonStyle(this.acknowledged ? 'secondary' : 'primary'))
          .onClick(() => {
            this.acknowledge();
          })

          if (this.acknowledgementError !== '') {
            NoticeBanner({ text: this.acknowledgementError })
          }

          Column({ space: 8 }) {
            Button('Call senior')
              .width('100%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.surface'))
              .attributeModifier(new CareButtonStyle('secondary'))
              .enabled(false)
              .opacity(0.5)
            Text('Calling is not set up yet.')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title(this.alert.title)
    .backgroundColor($r('app.color.page_background'))
  }

  private async acknowledge(): Promise<void> {
    if (this.acknowledging) return;
    this.acknowledging = true;
    this.acknowledgementError = '';
    try {
      if (this.alert.remote && apiSession.configured() && apiSession.role === 'guardian') {
        await careApi.request(`/alerts/${this.alert.id}/ack`, http.RequestMethod.POST);
        guardianAlertWatcher.onAcknowledged(this.alert.id);
      }
      this.acknowledged = true;
    } catch (error) {
      this.acknowledgementError = 'Could not mark this alert as seen. Check your connection and try again.';
    } finally {
      this.acknowledging = false;
    }
  }
}

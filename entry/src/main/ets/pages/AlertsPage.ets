import { IconBadge, NoticeBanner } from '../components/Common';
import {
  AlertType,
  CareAlert,
  deliveryLabel,
  formatAlertTime,
} from '../models/Safety';
import { http } from '@kit.NetworkKit';
import { apiSession, careApi } from '../services/CareApi';

interface RemoteAlert {
  id: string;
  kind: string;
  createdAt: string;
  acknowledgedAt?: string;
  event?: RemoteEvent;
}

interface RemoteEvent {
  type: string;
}

interface RemoteAlertList {
  items: RemoteAlert[];
}

function alertIcon(alert: CareAlert): Resource {
  return alert.type === AlertType.Sos ? $r('sys.symbol.exclamationmark_shield_fill') : $r('sys.symbol.house_shield_fill');
}

function alertAccent(alert: CareAlert): Resource {
  return alert.type === AlertType.Sos ? $r('app.color.sos') : $r('app.color.warning');
}

function alertTint(alert: CareAlert): Resource {
  return alert.type === AlertType.Sos ? $r('app.color.sos_tint') : $r('app.color.warning_tint');
}

@Component
export struct AlertsPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private alerts: CareAlert[] = [];
  @State private pendingCount: number = 0;
  @State private loadError: string = '';

  private async reload(): Promise<void> {
    if (!apiSession.configured() || apiSession.role !== 'guardian') {
      this.alerts = [];
      this.loadError = 'This phone is not paired as a guardian.';
      return;
    }
    try {
      const response = await careApi.request('/alerts?limit=50', http.RequestMethod.GET) as RemoteAlertList;
      this.alerts = response.items.map((item: RemoteAlert) => this.fromRemote(item));
      this.pendingCount = this.alerts.filter((alert: CareAlert) => !alert.acknowledged).length;
      this.loadError = '';
    } catch (error) {
      this.alerts = [];
      this.loadError = 'Could not load alerts from the care service.';
    }
  }

  private fromRemote(item: RemoteAlert): CareAlert {
    const type = item.kind === 'sos' ? AlertType.Sos : AlertType.SafeAreaExit;
    const alert = new CareAlert(item.id, type, item.kind === 'sos' ? 'SOS requested' : 'Safe area exit',
      item.kind === 'sos' ? 'The senior requested help.' : 'The senior left the safe area.', 'Care service');
    alert.createdAt = Date.parse(item.createdAt);
    alert.acknowledged = item.acknowledgedAt !== undefined;
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
      .backgroundColor(alert.acknowledged ? $r('app.color.page_background') : $r('app.color.sos'))
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
      Text('SOS requests and safe-area exits will appear here.')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 64, bottom: 32, left: 16, right: 16 })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          if (this.alerts.length === 0) {
            this.emptyState()
          } else {
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

          if (this.loadError !== '') {
            NoticeBanner({ text: this.loadError })
          }
          Text('Alerts are shown from the care service.')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ left: 8, right: 8 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title('Alerts')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.reload())
  }
}

@Component
export struct AlertDetailPage {
  alert: CareAlert = new CareAlert('', AlertType.Sos, '', '', '');
  @State private acknowledged: boolean = false;

  aboutToAppear(): void {
    this.acknowledged = this.alert.acknowledged;
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
            Text(this.alert.title)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
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
              Text(this.acknowledged ? 'Marked as seen' : 'Mark as seen')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.acknowledged ? $r('app.color.guardian_accent') : Color.White)
            }
          }
          .width('100%')
          .height(56)
          .enabled(!this.acknowledged)
          .backgroundColor(this.acknowledged ? $r('app.color.guardian_tint') : $r('app.color.guardian_accent'))
          .onClick(() => {
            this.acknowledge();
          })

          Column({ space: 8 }) {
            Button('Call senior')
              .width('100%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.surface'))
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
    .title('Alert')
    .backgroundColor($r('app.color.page_background'))
  }

  private async acknowledge(): Promise<void> {
    try {
      if (this.alert.remote && apiSession.configured() && apiSession.role === 'guardian') {
        await careApi.request(`/alerts/${this.alert.id}/ack`, http.RequestMethod.POST);
      }
      this.acknowledged = true;
    } catch (error) {
      // Keep the server state unchanged if acknowledgement cannot be sent.
    }
  }
}

import { IconBadge, NoticeBanner } from '../components/Common';
import { formatClockTime, safetyStore } from '../models/Safety';

@Component
export struct WatchSafetyPage {
  @State private connected: boolean = false;
  @State private lastSosAt: number = 0;

  private activateSos(): void {
    this.lastSosAt = safetyStore.createSos('Watch simulation').createdAt;
  }

  @Builder
  watchFace() {
    Column({ space: 14 }) {
      Row({ space: 6 }) {
        Circle()
          .width(8)
          .height(8)
          .fill(this.connected ? '#34D399' : '#9CA3AF')
        Text(this.connected ? 'Connected' : 'Not connected')
          .fontSize(13)
          .fontColor(Color.White)
          .opacity(0.85)
      }

      Column() {
        Text('SOS')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(116)
      .height(116)
      .borderRadius(58)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.sos'))
      .opacity(this.connected ? 1 : 0.35)
      .enabled(this.connected)
      .accessibilityText('Watch SOS')
      .onClick(() => this.activateSos())

      Text(this.lastSosAt === 0 ? (this.connected ? 'Tap for help' : 'Connect first') : `Sent ${formatClockTime(this.lastSosAt)}`)
        .fontSize(13)
        .fontColor(Color.White)
        .opacity(0.85)
    }
    .width(248)
    .height(248)
    .borderRadius(124)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#111111')
    .border({ width: 10, color: '#3F3F46' })
    .shadow({ radius: 24, color: $r('app.color.card_shadow'), offsetY: 8 })
  }

  build() {
    NavDestination() {
      if (!safetyStore.developerMode) {
        Column({ space: 16 }) {
          IconBadge({
            icon: $r('sys.symbol.watch_fill'),
            accent: $r('app.color.text_secondary'),
            tint: $r('app.color.surface'),
            badgeSize: 80
          })
          Text('Developer Mode required')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('Turn on Developer Mode in Settings to use the watch simulation.')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 24 }) {
            NoticeBanner({
              text: 'Simulation on this phone. A real watch, its connection and packaging have not been verified.'
            })

            this.watchFace()

            if (this.lastSosAt !== 0) {
              NoticeBanner({
                icon: $r('sys.symbol.checkmark_circle_fill'),
                text: 'SOS alert saved on this phone. Open Alerts in the Guardian view to see it.',
                accent: $r('app.color.senior_accent'),
                tint: $r('app.color.senior_tint')
              })
            }

            Button(this.connected ? 'Disconnect watch' : 'Connect watch')
              .width('100%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.connected ? $r('app.color.text_primary') : Color.White)
              .backgroundColor(this.connected ? $r('app.color.surface') : $r('app.color.senior_accent'))
              .onClick(() => {
                this.connected = !this.connected;
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 8, bottom: 32 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
      }
    }
    .title('Watch Simulation')
    .backgroundColor($r('app.color.page_background'))
  }
}

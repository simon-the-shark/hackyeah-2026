import { NoticeBanner } from '../components/Common';
import { formatClockTime, safetyStore } from '../models/Safety';

const COUNTDOWN_SECONDS: number = 5;

@Component
export struct SosPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private secondsLeft: number = COUNTDOWN_SECONDS;
  @State private sentAt: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.secondsLeft--;
      if (this.secondsLeft <= 0) {
        this.send();
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    this.stopTimer();
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private send(): void {
    this.stopTimer();
    this.sentAt = safetyStore.createSos('Senior phone').createdAt;
  }

  @Builder
  countdown() {
    Column({ space: 32 }) {
      Column({ space: 8 }) {
        Text('Calling for help')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('Your guardian will be alerted when the countdown ends.')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
      }

      Stack() {
        Progress({ value: this.secondsLeft, total: COUNTDOWN_SECONDS, type: ProgressType.Ring })
          .width(232)
          .height(232)
          .color($r('app.color.sos'))
          .backgroundColor($r('app.color.sos_tint'))
          .style({ strokeWidth: 14 })
        Column() {
          Text(`${this.secondsLeft}`)
            .fontSize(88)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(180)
        .height(180)
        .borderRadius(90)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.sos'))
      }
      .accessibilityGroup(true)
      .accessibilityText(`SOS will be sent in ${this.secondsLeft} seconds`)

      Column({ space: 12 }) {
        Button('Send now')
          .width('100%')
          .height(64)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.sos'))
          .onClick(() => this.send())
        Button('Cancel')
          .width('100%')
          .height(64)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .border({ width: 2, color: $r('app.color.divider') })
          .onClick(() => this.navStack.pop())
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  sent() {
    Column({ space: 24 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(72)
          .fontColor([$r('app.color.sos')])
      }
      .width(128)
      .height(128)
      .borderRadius(64)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.sos_tint'))

      Column({ space: 8 }) {
        Text('Help requested')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(`SOS sent at ${formatClockTime(this.sentAt)}`)
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
      }

      NoticeBanner({
        text: 'Demo: the alert is saved on this phone and shown in the Guardian view. Delivery to your guardian\'s phone is not connected yet.'
      })

      Button('Done')
        .width('100%')
        .height(64)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.senior_accent'))
        .onClick(() => this.navStack.pop())
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        if (this.sentAt === 0) {
          this.countdown()
        } else {
          this.sent()
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 24, right: 24, top: 12, bottom: 32 })
    }
    .title('SOS')
    .backgroundColor($r('app.color.page_background'))
  }
}

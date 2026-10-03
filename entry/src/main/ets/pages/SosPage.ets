import { NoticeBanner } from '../components/Common';
import { http } from '@kit.NetworkKit';
import { formatClockTime } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from '../services/CareApi';

const COUNTDOWN_SECONDS: number = 5;

@Component
export struct SosPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private secondsLeft: number = COUNTDOWN_SECONDS;
  @State private sentAt: number = 0;
  @State private deliveryMessage: string = '';
  @State private sendState: string = '';
  private timerId: number = -1;
  private sosEventId: string = '';

  aboutToAppear(): void {
    this.sosEventId = generateEventId();
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

  private async send(): Promise<void> {
    this.stopTimer();
    this.sentAt = Date.now();
    this.sendState = 'sending';
    this.deliveryMessage = 'Sending SOS to the care service...';
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      this.deliveryMessage = 'This phone is not paired. SOS cannot be sent.';
      this.sendState = 'failed';
      return;
    }
    try {
      const event = new SafetyEventRequest(this.sosEventId, 'sos');
      const result = await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event) as Record<string, Object>;
      this.deliveryMessage = result['alert'] === undefined
        ? 'SOS accepted by the care service.'
        : 'SOS accepted. Guardian notification delivery was requested.';
      this.sendState = 'sent';
    } catch (error) {
      this.deliveryMessage = 'SOS could not reach the care service. Please try again.';
      this.sendState = 'failed';
    }
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
        SymbolGlyph(this.sendState === 'sent' ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.exclamationmark_circle_fill'))
          .fontSize(72)
          .fontColor([$r('app.color.sos')])
      }
      .width(128)
      .height(128)
      .borderRadius(64)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.sos_tint'))

      Column({ space: 8 }) {
        Text(this.sendState === 'sent' ? 'Help requested' : this.sendState === 'sending' ? 'Sending SOS' : 'SOS not sent')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.sendState === 'sent' ? `SOS sent at ${formatClockTime(this.sentAt)}` : 'Your guardian has not been notified yet.')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
      }

      NoticeBanner({
        text: this.deliveryMessage
      })

      Button(this.sendState === 'failed' ? 'Try again' : 'Done')
        .width('100%')
        .height(64)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.senior_accent'))
        .onClick(() => {
          if (this.sendState === 'failed') {
            this.send();
          } else {
            this.navStack.pop();
          }
        })
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

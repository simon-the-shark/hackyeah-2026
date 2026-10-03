import { http } from '@kit.NetworkKit';
import { formatClockTime } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from '../services/CareApi';
import { CareButtonStyle } from '../components/DesignSystem';
import { locationSharing } from '../services/LocationSharing';

const COUNTDOWN_SECONDS: number = 5;

@Component
export struct SosPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private secondsLeft: number = COUNTDOWN_SECONDS;
  @State private sentAt: number = 0;
  @State private sendState: string = '';
  /** Fix time of the location attached to the SOS; 0 when none was available. */
  @State private locationAt: number = 0;
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
    if (this.sendState === 'sending' || this.sendState === 'sent') return;
    this.stopTimer();
    this.sentAt = Date.now();
    this.sendState = 'sending';
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      this.sendState = 'failed';
      return;
    }
    try {
      const event = new SafetyEventRequest(this.sosEventId, 'sos');
      const location = locationSharing.lastKnownLocation();
      if (location !== undefined) {
        event.location = location;
      }
      await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event);
      this.locationAt = location !== undefined ? Date.parse(location.sampledAt) : 0;
      this.sendState = 'sent';
    } catch (error) {
      this.sendState = 'failed';
    }
  }

  @Builder
  countdown() {
    Column({ space: 32 }) {
      Column({ space: 8 }) {
        Text('Requesting help')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('We will send an SOS with your last known location, if available, to the care service when the countdown ends. This does not call emergency services.')
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
        .backgroundColor($r('app.color.action_danger'))
      }
      .accessibilityGroup(true)
      .accessibilityText(`SOS will be sent in ${this.secondsLeft} seconds`)

      Column({ space: 12 }) {
        Button('Send now')
          .width('100%')
          .height(64)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .attributeModifier(new CareButtonStyle('danger'))
          .onClick(() => this.send())
        Button('Cancel SOS')
          .width('100%')
          .height(64)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .attributeModifier(new CareButtonStyle('secondary'))
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
        if (this.sendState === 'sending') {
          LoadingProgress().width(72).height(72).color($r('app.color.senior_accent'))
        } else {
        SymbolGlyph(this.sendState === 'sent' ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.exclamationmark_circle_fill'))
          .fontSize(72)
          .fontColor([$r('app.color.sos')])
        }
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
        Text(this.sendState === 'sent' ? `Care service accepted your SOS at ${formatClockTime(this.sentAt)}. This does not confirm that your guardian has seen it.` :
          this.sendState === 'sending' ? 'Please wait while we contact the care service.' : 'Could not send your SOS. Check your connection and try again.')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
        if (this.sendState === 'sent') {
          Text(this.locationAt > 0 ? `Your location from ${formatClockTime(this.locationAt)} was included.`
            : 'Your location was not available, so it was not included.')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
        }
      }

      Button(this.sendState === 'failed' ? 'Retry SOS' : this.sendState === 'sending' ? 'Sending SOS…' : 'Return home')
        .width('100%')
        .height(64)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .attributeModifier(new CareButtonStyle())
        .enabled(this.sendState !== 'sending')
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
      Scroll() {
      Column() {
        if (this.sentAt === 0) {
          this.countdown()
        } else {
          this.sent()
        }
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
      .justifyContent(FlexAlign.Center)
      .padding({ left: 24, right: 24, top: 12, bottom: 32 })
      }.width('100%').height('100%')
    }
    .title('SOS')
    .backgroundColor($r('app.color.page_background'))
  }
}

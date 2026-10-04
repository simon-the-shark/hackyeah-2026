import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { formatClockTime } from '../models/Safety';
import { apiSession, careApi, generateEventId, SafetyEventRequest } from '../services/CareApi';
import { CareButtonStyle } from '../components/DesignSystem';
import { SosOutcome, sosService } from '../services/SosService';

const COUNTDOWN_SECONDS: number = 5;
/** How often the sent screen checks whether a guardian has seen the SOS. */
const ACK_POLL_MS: number = 10000;

interface SeniorAlertEvent {
  id?: string;
}

interface SeniorAlert {
  acknowledgedAt?: string | null;
  acknowledgedBy?: string | null;
  cancelledAt?: string | null;
  event?: SeniorAlertEvent | null;
}

interface SeniorAlertList {
  items?: SeniorAlert[];
}

interface LinkedGuardian {
  id?: string;
  displayName?: string;
}

interface LinkedPeople {
  guardians?: LinkedGuardian[];
}

interface SeniorMe {
  linked?: LinkedPeople | null;
}

@Component
export struct SosPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private secondsLeft: number = COUNTDOWN_SECONDS;
  @State private sentAt: number = 0;
  @State private sendState: string = '';
  /** Fix time of the location attached to the SOS; 0 when none was available. */
  @State private locationAt: number = 0;
  /** "Anna has seen your SOS at 07:12."; empty until a guardian acknowledges it. */
  @State private seenMessage: string = '';
  @State private cancelState: string = '';
  private timerId: number = -1;
  private ackTimerId: number = -1;
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
    this.stopAckPolling();
  }

  private stopAckPolling(): void {
    if (this.ackTimerId !== -1) {
      clearInterval(this.ackTimerId);
      this.ackTimerId = -1;
    }
  }

  private startAckPolling(): void {
    this.stopAckPolling();
    this.ackTimerId = setInterval(() => this.checkSeen(), ACK_POLL_MS);
  }

  /** Reads this SOS's alert; the backend records which guardian acknowledged it first. */
  private async checkSeen(): Promise<void> {
    try {
      const since = new Date(this.sentAt - 60000).toISOString();
      const list = await careApi.request(`/seniors/${apiSession.seniorId}/alerts?since=${encodeURIComponent(since)}&limit=20`,
        http.RequestMethod.GET) as SeniorAlertList;
      const alert = (list.items ?? []).find((item: SeniorAlert) =>
        item.event !== undefined && item.event !== null && item.event.id === this.sosEventId);
      if (alert === undefined || alert.acknowledgedAt === undefined || alert.acknowledgedAt === null) {
        return;
      }
      this.stopAckPolling();
      const name = await this.guardianName(alert.acknowledgedBy ?? '');
      this.seenMessage = `${name} has seen your SOS at ${formatClockTime(Date.parse(alert.acknowledgedAt))}.`;
    } catch (error) {
      // Keep polling; the SOS itself was delivered.
    }
  }

  private async guardianName(guardianId: string): Promise<string> {
    try {
      const me = await careApi.request('/me', http.RequestMethod.GET) as SeniorMe;
      const guardian = (me.linked?.guardians ?? []).find((item: LinkedGuardian) => item.id === guardianId);
      if (guardian !== undefined && typeof guardian.displayName === 'string' && guardian.displayName !== '') {
        return guardian.displayName;
      }
    } catch (error) {
      // Fall back to a generic name.
    }
    return 'Your guardian';
  }

  private confirmCancel(): void {
    this.getUIContext().showAlertDialog({
      title: 'Cancel your SOS?',
      message: 'Your guardian will be told that you are OK and no longer need help.',
      autoCancel: true,
      primaryButton: {
        value: 'Keep SOS',
        action: () => {
        }
      },
      secondaryButton: {
        value: 'I\'m OK, cancel',
        fontColor: $r('app.color.sos'),
        action: () => {
          this.cancelSos();
        }
      }
    });
  }

  private async cancelSos(): Promise<void> {
    if (this.cancelState === 'sending' || this.cancelState === 'cancelled') return;
    this.cancelState = 'sending';
    try {
      const event = new SafetyEventRequest(generateEventId(), 'cancel');
      event.cancelsEventId = this.sosEventId;
      await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event);
      this.stopAckPolling();
      this.cancelState = 'cancelled';
    } catch (error) {
      this.cancelState = 'failed';
    }
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async send(): Promise<void> {
    if (this.sendState === 'sending' || this.sendState === 'sent') return;
    // A queued SOS keeps its id, so retrying it now cannot alert the guardian twice.
    this.stopTimer();
    this.sentAt = Date.now();
    this.sendState = 'sending';
    const result = await sosService.send(this.getUIContext().getHostContext() as common.Context, this.sosEventId);
    this.locationAt = result.locationAt;
    this.sendState = result.outcome === SosOutcome.Sent ? 'sent' : result.outcome === SosOutcome.Queued ? 'queued' :
      'failed';
    if (this.sendState === 'sent') {
      this.startAckPolling();
    }
  }

  private screenTitle(): string {
    if (this.sentAt === 0) {
      return 'Requesting help';
    }
    if (this.cancelState === 'cancelled') {
      return 'SOS cancelled';
    }
    return this.sendState === 'sent' ? 'Help requested' : this.sendState === 'sending' ? 'Sending SOS' :
      this.sendState === 'queued' ? 'SOS waiting to send' : 'SOS not sent';
  }

  @Builder
  countdown() {
    Column({ space: 32 }) {
      Column({ space: 8 }) {
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
        SymbolGlyph(this.sendState === 'sent' ? $r('sys.symbol.checkmark_circle_fill') :
          $r('sys.symbol.exclamationmark_circle_fill'))
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
        if (this.cancelState === 'cancelled') {
          Text('Your SOS was cancelled. Your guardian is being told that you are OK.')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
        } else if (this.seenMessage !== '') {
          Text(this.seenMessage)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        Text(this.sendState === 'sent' ? (this.seenMessage !== '' ?
          `Care service accepted your SOS at ${formatClockTime(this.sentAt)}.` :
          `Care service accepted your SOS at ${formatClockTime(this.sentAt)}. Waiting for your guardian to see it…`) :
          this.sendState === 'sending' ? 'Please wait while we contact the care service.' :
          this.sendState === 'queued' ? 'The care service cannot be reached right now. Your SOS is saved on this phone and will be sent automatically when the connection returns. If you are in danger, call emergency services.' :
          'Could not send your SOS. Check your connection and try again.')
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

      Button(this.sendState === 'failed' || this.sendState === 'queued' ? 'Retry SOS now' : this.sendState === 'sending' ? 'Sending SOS…' : 'Return home')
        .width('100%')
        .height(64)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .attributeModifier(new CareButtonStyle())
        .enabled(this.sendState !== 'sending')
        .onClick(() => {
          if (this.sendState === 'failed' || this.sendState === 'queued') {
            this.send();
          } else {
            this.navStack.pop();
          }
        })

      if (this.sendState === 'sent' && this.cancelState !== 'cancelled') {
        Button(this.cancelState === 'sending' ? 'Cancelling…' : 'I\'m OK, cancel SOS')
          .width('100%')
          .height(64)
          .fontSize(20)
          .attributeModifier(new CareButtonStyle('danger-secondary'))
          .enabled(this.cancelState !== 'sending')
          .onClick(() => this.confirmCancel())
        if (this.cancelState === 'failed') {
          Text('Could not cancel the SOS. Check the internet connection and try again, or call your guardian.')
            .fontSize(17)
            .fontColor($r('app.color.sos'))
        }
      }
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
    .title(this.screenTitle())
    .backgroundColor($r('app.color.page_background'))
  }
}

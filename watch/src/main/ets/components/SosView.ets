import { formatClock } from '../models/WatchState';
import { generateEventId, WatchApiError } from '../services/WatchApi';
import { watchMonitor } from '../services/WatchMonitor';

const COUNTDOWN_SECONDS = 3;

enum SosPhase {
  Ready,
  Counting,
  Sending,
  Sent,
  /** Not reachable now; the watch keeps resending it in the background. */
  Queued,
  Failed
}

/**
 * One large SOS target. A short countdown lets an accidental touch be cancelled;
 * after that the event goes to the care service. "Sent" means the service
 * accepted it, not that a guardian has seen it.
 */
@Component
export struct SosView {
  @State private phase: SosPhase = SosPhase.Ready;
  @State private remaining: number = COUNTDOWN_SECONDS;
  @State private sentAt: number = 0;
  @State private failure: string = '';
  private timer: number = -1;
  /** Kept across retries so the service never creates a second alert for the same press. */
  private eventId: string = '';
  private pressedAt: number = 0;

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private onTap(): void {
    if (this.phase === SosPhase.Ready || this.phase === SosPhase.Sent) {
      this.startCountdown();
    } else if (this.phase === SosPhase.Counting) {
      this.cancel();
    } else if (this.phase === SosPhase.Failed || this.phase === SosPhase.Queued) {
      this.send();
    }
  }

  private startCountdown(): void {
    this.eventId = generateEventId();
    this.pressedAt = Date.now();
    this.remaining = COUNTDOWN_SECONDS;
    this.phase = SosPhase.Counting;
    this.timer = setInterval(() => {
      this.remaining -= 1;
      if (this.remaining <= 0) {
        this.clearTimer();
        this.send();
      }
    }, 1000);
  }

  private cancel(): void {
    this.clearTimer();
    this.phase = SosPhase.Ready;
  }

  private async send(): Promise<void> {
    this.phase = SosPhase.Sending;
    try {
      if (await watchMonitor.sendSos(this.eventId, this.pressedAt)) {
        this.sentAt = Date.now();
        this.phase = SosPhase.Sent;
      } else {
        this.phase = SosPhase.Queued;
      }
    } catch (error) {
      const status = error instanceof WatchApiError ? error.status : 0;
      this.failure = status === 0 ? 'Not sent. Check your connection.' : 'Not sent. Please try again.';
      this.phase = SosPhase.Failed;
    }
  }

  private circleLabel(): string {
    if (this.phase === SosPhase.Counting) {
      return `${this.remaining}`;
    }
    if (this.phase === SosPhase.Sending) {
      return '…';
    }
    if (this.phase === SosPhase.Failed || this.phase === SosPhase.Queued) {
      return 'Retry';
    }
    return 'SOS';
  }

  private caption(): string {
    switch (this.phase) {
      case SosPhase.Counting:
        return 'Tap to cancel';
      case SosPhase.Sending:
        return 'Sending SOS to the care service…';
      case SosPhase.Sent:
        return `Accepted by care service at ${formatClock(this.sentAt)}. This does not confirm your guardian has seen it.`;
      case SosPhase.Queued:
        return 'No connection. SOS saved; it will be sent automatically.';
      case SosPhase.Failed:
        return `${this.failure} Tap Retry.`;
      default:
        return 'Tap for help';
    }
  }

  build() {
    Column({ space: 10 }) {
      Column() {
        Text(this.circleLabel())
          .fontSize(this.phase === SosPhase.Failed || this.phase === SosPhase.Queued ? 26 : 38)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(124)
      .height(124)
      .borderRadius(62)
      .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.watch_sos'))
      .enabled(this.phase !== SosPhase.Sending)
        .accessibilityText(this.phase === SosPhase.Counting ? 'Cancel SOS' : 'Send SOS to your guardian')
        .accessibilityRole(AccessibilityRoleType.BUTTON)
      .onClick(() => this.onTap())

      Text(this.caption())
        .fontSize(15)
        .fontColor($r('app.color.watch_text'))
        .textAlign(TextAlign.Center)
        .width(160)
        .maxLines(3)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

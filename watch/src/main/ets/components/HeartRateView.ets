import { common } from '@kit.AbilityKit';
import { formatClock, MonitorState } from '../models/WatchState';
import { HEALTH_PERMISSIONS, requestPermissionsInSettings } from '../platform/Permissions';
import { watchMonitor } from '../services/WatchMonitor';

/** A reading older than this is shown as "no reading" instead of a stale number. */
const STALE_AFTER_MS = 60 * 1000;

@Component
export struct HeartRateView {
  @StorageProp('hrBpm') bpm: number = 0;
  @StorageProp('hrAt') readAt: number = 0;
  @StorageProp('hrState') state: string = MonitorState.OFF;
  @StorageProp('hrSimulated') simulated: boolean = false;
  @StorageProp('hrAlerting') alerting: boolean = false;
  @StorageProp('hrSharedAt') sharedAt: number = 0;
  /** Ticks so a reading that stopped arriving turns into "--" instead of staying on screen. */
  @State private now: number = Date.now();
  private clock: number = -1;

  aboutToAppear(): void {
    this.clock = setInterval(() => {
      this.now = Date.now();
    }, 10 * 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.clock);
  }

  private hasReading(): boolean {
    return this.bpm > 0 && this.now - this.readAt < STALE_AFTER_MS;
  }

  private headline(): string {
    if (this.state === MonitorState.DENIED) {
      return 'Heart rate not allowed';
    }
    if (this.state === MonitorState.MISSING) {
      return 'No heart-rate sensor';
    }
    if (this.state === MonitorState.FAILED) {
      return 'Sensor not available';
    }
    return this.hasReading() ? `${this.bpm}` : '--';
  }

  private caption(): string {
    if (this.state === MonitorState.STARTING) {
      return 'Starting…';
    }
    if (this.state === MonitorState.ACTIVE && !this.hasReading()) {
      return 'Waiting for a reading. Is the watch worn?';
    }
    if (this.sharedAt > 0) {
      return `Shared with your guardian ${formatClock(this.sharedAt)}`;
    }
    return this.state === MonitorState.ACTIVE ? 'Not shared yet' : '';
  }

  private async allowInSettings(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (await requestPermissionsInSettings(context, HEALTH_PERMISSIONS)) {
      watchMonitor.pause();
      await watchMonitor.resume();
    }
  }

  build() {
    Column({ space: 4 }) {
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.heart_fill'))
          .fontSize(18)
          .fontColor([$r('app.color.watch_heart')])
        if (this.simulated) {
          Text('SIMULATED')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .backgroundColor($r('app.color.watch_simulated'))
            .borderRadius(6)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .accessibilityText('Simulated sensor data')
        }
      }

      Text(this.headline())
        .fontSize(this.hasReading() || this.headline() === '--' ? 48 : 18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.alerting ? $r('app.color.watch_warning') : $r('app.color.watch_text'))
        .textAlign(TextAlign.Center)
        .width(170)
      if (this.hasReading()) {
        Text('bpm')
          .fontSize(16)
          .fontColor($r('app.color.watch_text_secondary'))
      }
      if (this.alerting) {
        Text('Outside the set range. This watch is trying to share an alert with the care service.')
          .fontSize(14)
          .fontColor($r('app.color.watch_warning'))
          .textAlign(TextAlign.Center)
          .width(170)
      }
      Text(this.caption())
        .fontSize(14)
        .fontColor($r('app.color.watch_text_secondary'))
        .textAlign(TextAlign.Center)
        .width(170)
      if (this.state === MonitorState.DENIED) {
        Button('Allow')
          .height(40)
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor($r('app.color.watch_accent'))
          .onClick(() => this.allowInSettings())
      }
      Text('Not a medical device')
        .fontSize(13)
        .fontColor($r('app.color.watch_text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

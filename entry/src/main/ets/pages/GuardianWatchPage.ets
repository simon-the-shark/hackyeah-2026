import { IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { formatClockTime } from '../models/Safety';
import {
  describeHeartRateAlert,
  formatAge,
  formatDistance,
  HEART_RATE_STALE_MS,
  sparklinePoints,
  WATCH_STALE_MS,
  WatchVitalsSnapshot
} from '../models/WatchVitals';
import { describeWatchVitalsError, guardianWatchVitals } from '../services/GuardianWatchVitals';

export const GUARDIAN_WATCH_ROUTE = 'guardian-watch';
const REFRESH_MS = 30 * 1000;
const CHART_WIDTH = 280;
const CHART_HEIGHT = 72;

/**
 * The guardian's view of the senior's watch: the watch's own last location and
 * battery, and the heart rate it shares. Everything is shown with its age, and
 * nothing here is a medical assessment.
 */
@Component
export struct GuardianWatchPage {
  @State private snapshot: WatchVitalsSnapshot | undefined = undefined;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  private timer: number = -1;

  private async load(): Promise<void> {
    try {
      this.snapshot = await guardianWatchVitals.load();
      this.errorMessage = '';
    } catch (error) {
      this.errorMessage = describeWatchVitalsError(error as Object);
    } finally {
      this.loading = false;
    }
  }

  private startRefreshing(): void {
    this.load();
    if (this.timer < 0) {
      this.timer = setInterval(() => this.load(), REFRESH_MS);
    }
  }

  private stopRefreshing(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  aboutToDisappear(): void {
    this.stopRefreshing();
  }

  @Builder
  simulatedBadge() {
    Text('SIMULATED')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.warning'))
      .backgroundColor($r('app.color.warning_tint'))
      .borderRadius(8)
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .accessibilityText('Simulated data, not from a real sensor')
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .accessibilityGroup(true)
  }

  @Builder
  heartRateCard(snapshot: WatchVitalsSnapshot) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        IconBadge({
          icon: $r('sys.symbol.heart_fill'),
          accent: $r('app.color.sos'),
          tint: $r('app.color.sos_tint')
        })
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(snapshot.latestBpm > 0 ? `${snapshot.latestBpm}` : '--')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('bpm')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(VerticalAlign.Bottom)
          Text(snapshot.latestBpm > 0 ? `Measured ${formatAge(snapshot.latestAgeMs)}` : 'No reading shared yet')
            .fontSize(14)
            .fontColor(snapshot.latestAgeMs > HEART_RATE_STALE_MS ? $r('app.color.warning') :
            $r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (snapshot.latestSimulated) {
          this.simulatedBadge()
        }
      }
      .width('100%')

      if (snapshot.series.length > 1) {
        Column({ space: 4 }) {
          Polyline({ width: CHART_WIDTH, height: CHART_HEIGHT })
            .points(sparklinePoints(snapshot.series, CHART_WIDTH, CHART_HEIGHT))
            .fillOpacity(0)
            .stroke($r('app.color.sos'))
            .strokeWidth(2)
            .strokeLineJoin(LineJoinStyle.Round)
            .accessibilityText(`Heart rate over the last 6 hours, from ${snapshot.seriesMin} to ${snapshot.seriesMax} bpm`)
          Text(`Last 6 hours: ${snapshot.seriesMin}–${snapshot.seriesMax} bpm`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (snapshot.alert !== undefined) {
        NoticeBanner({
          icon: $r('sys.symbol.heart_fill'),
          text: snapshot.alert.resolved
            ? `Earlier at ${formatClockTime(snapshot.alert.createdAt)}: ${describeHeartRateAlert(snapshot.alert)} It is back in the set range.`
            : `${formatClockTime(snapshot.alert.createdAt)}: ${describeHeartRateAlert(snapshot.alert)} Consider calling to check in.`
              + (snapshot.alert.simulated ? ' (simulated)' : ''),
          accent: snapshot.alert.resolved ? $r('app.color.success') : $r('app.color.warning'),
          tint: snapshot.alert.resolved ? $r('app.color.success_tint') : $r('app.color.warning_tint')
        })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  locationCard(snapshot: WatchVitalsSnapshot) {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        IconBadge({
          icon: $r('sys.symbol.watch_fill'),
          accent: $r('app.color.guardian_accent'),
          tint: $r('app.color.guardian_tint')
        })
        Column({ space: 2 }) {
          Text('Watch location')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(snapshot.heartbeatAgeMs >= WATCH_STALE_MS
            ? `No update for ${formatAge(snapshot.heartbeatAgeMs).replace(' ago', '')}`
            : `Updated ${formatAge(snapshot.heartbeatAgeMs)}`)
            .fontSize(14)
            .fontColor(snapshot.heartbeatAgeMs >= WATCH_STALE_MS ? $r('app.color.warning') :
            $r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (snapshot.locationSimulated) {
          this.simulatedBadge()
        }
      }
      .width('100%')

      if (snapshot.location !== undefined) {
        this.infoRow('Position', `${snapshot.location.lat.toFixed(5)}, ${snapshot.location.lng.toFixed(5)}`)
        if (snapshot.location.accuracyM >= 0) {
          this.infoRow('Accuracy', `±${Math.round(snapshot.location.accuracyM)} m`)
        }
        if (snapshot.location.distanceFromHomeM >= 0) {
          this.infoRow('From home', formatDistance(snapshot.location.distanceFromHomeM))
        }
        this.infoRow('Safe area', snapshot.monitoringState === 'inside' ? 'Was inside'
          : snapshot.monitoringState === 'outside' ? 'Was outside' : 'Unknown')
      } else {
        Text('The watch has not shared a location yet. Location is shared only while Carely is open on the watch.')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }
      this.infoRow('Watch battery', snapshot.battery >= 0 ? `${snapshot.battery}%` : 'Not reported')
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  content(snapshot: WatchVitalsSnapshot) {
    Scroll() {
      Column({ space: 16 }) {
        NoticeBanner({
          text: 'Watch readings are informational, not a medical assessment. If you are worried, call the senior.'
        })
        Column({ space: 8 }) {
          sectionTitle('Heart rate')
          this.heartRateCard(snapshot)
        }
        .alignItems(HorizontalAlign.Start)
        Column({ space: 8 }) {
          sectionTitle('Watch')
          this.locationCard(snapshot)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  build() {
    NavDestination() {
      if (this.loading && this.snapshot === undefined) {
        LoadingMessage({ message: 'Loading the watch…' })
      } else if (this.snapshot === undefined) {
        StatusMessage({
          icon: $r('sys.symbol.watch_fill'),
          title: 'Could not load the watch',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      } else if (!this.snapshot.hasWatch) {
        StatusMessage({
          icon: $r('sys.symbol.watch_fill'),
          title: 'No watch data yet',
          message: 'The senior can pair a watch in Settings, Smartwatch. Data appears once Carely is open on the watch.',
          onRetry: () => this.load()
        })
      } else {
        this.content(this.snapshot)
      }
    }
    .title('Watch & vitals')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.startRefreshing())
    .onHidden(() => this.stopRefreshing())
  }
}

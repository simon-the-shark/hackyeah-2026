import { IconBadge, sectionTitle } from '../components/Common';
import { CareFocusStyle } from '../components/DesignSystem';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { CareOverview, ScheduledDose } from '../models/CareOverview';
import {
  ageHeadline,
  DeviceReport,
  deviceAgeText,
  deviceIsStale,
  formatDuration,
  Freshness,
  freshnessOf,
  stateSentence
} from '../models/SeniorLocation';
import { describeOverviewError, guardianOverview } from '../services/GuardianOverview';
import { DOSE_HISTORY_ROUTE } from './DoseHistoryPage';
import { GUARDIAN_WATCH_ROUTE } from './GuardianWatchPage';
import { WELLBEING_REPORTS_ROUTE } from './WellbeingReportsPage';

export const GUARDIAN_OVERVIEW_ROUTE = 'guardian-overview';
const REFRESH_MS = 30 * 1000;
const TODAY = 'Today';
const DEVICES = 'Devices';
const CARE_SETUP = 'Care setup';

/**
 * The senior's latest known status in one place: the newest device report with
 * its age, open alerts, doses and care setup. Every state is a past
 * observation; nothing here says the senior is safe.
 */
@Component
export struct GuardianOverviewPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private overview: CareOverview | undefined = undefined;
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  @State private errorMessage: string = '';
  @State private now: number = Date.now();
  private timer: number = -1;
  private requestSeq: number = 0;

  private async load(): Promise<void> {
    const seq = ++this.requestSeq;
    try {
      const overview = await guardianOverview.overview();
      if (seq === this.requestSeq) {
        this.now = Date.now();
        this.overview = overview;
        this.errorMessage = '';
      }
    } catch (error) {
      if (seq === this.requestSeq) {
        this.errorMessage = describeOverviewError(error as Object, 'the overview');
      }
    } finally {
      if (seq === this.requestSeq) {
        this.loading = false;
        this.refreshing = false;
      }
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

  private current(): CareOverview {
    return this.overview ?? new CareOverview();
  }

  private stale(): boolean {
    return freshnessOf(this.current().snapshot, this.now) === Freshness.Stale;
  }

  private heroTint(): Resource {
    if (!this.current().snapshot.hasStatus || this.stale()) {
      return $r('app.color.warning_tint');
    }
    return this.current().snapshot.monitoringState === 'outside' ? $r('app.color.sos_tint') :
    $r('app.color.guardian_tint');
  }

  private heroAccent(): Resource {
    if (!this.current().snapshot.hasStatus || this.stale()) {
      return $r('app.color.warning');
    }
    return this.current().snapshot.monitoringState === 'outside' ? $r('app.color.sos') :
    $r('app.color.guardian_accent');
  }

  private heroIcon(): Resource {
    if (!this.current().snapshot.hasStatus || this.stale()) {
      return $r('sys.symbol.exclamationmark_triangle_fill');
    }
    return this.current().snapshot.monitoringState === 'outside' ? $r('sys.symbol.figure_walk') :
    $r('sys.symbol.clock_fill');
  }

  private alertsTitle(): string {
    const open = this.current().unacknowledgedAlerts;
    if (open === 0) {
      return 'No new alerts';
    }
    return open === 1 ? '1 new alert' : `${open} new alerts`;
  }

  private missedTitle(): string {
    const missed = this.current().missedLast24h;
    if (missed === 0) {
      return 'No missed doses in 24 h';
    }
    return missed === 1 ? '1 missed dose in 24 h' : `${missed} missed doses in 24 h`;
  }

  private nextDoseText(): string {
    const next: ScheduledDose | undefined = this.current().nextDoses[0];
    if (next === undefined) {
      return 'No upcoming doses today';
    }
    return `Next: ${next.localTime} ${next.medicationName}`;
  }

  private deviceText(device: DeviceReport | undefined): string {
    if (device === undefined) {
      return 'No update yet';
    }
    const battery = device.battery >= 0 ? ` · Battery ${device.battery}%` : '';
    return `${deviceAgeText(device, this.current().snapshot, this.now)}${battery}`;
  }

  private deviceAccent(device: DeviceReport | undefined): Resource {
    return device === undefined || deviceIsStale(device, this.current().snapshot, this.now) ?
    $r('app.color.warning') : $r('app.color.guardian_accent');
  }

  private reportText(): string {
    const age = this.current().latestReportAgeMs;
    if (age < 0) {
      return 'No report shared yet';
    }
    const when = age < 60000 ? 'Last shared just now' : `Last shared ${formatDuration(age)} ago`;
    return this.current().latestReportNeedsAttention ? `${when} · please read` : when;
  }

  @Builder
  hero() {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        IconBadge({
          icon: this.heroIcon(),
          accent: this.heroAccent(),
          tint: $r('app.color.surface'),
          badgeSize: 48
        })
        Text(this.current().snapshot.seniorName)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      Text(this.current().snapshot.hasStatus ? ageHeadline(this.current().snapshot, this.now) : 'No update yet')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.current().snapshot.hasStatus ? stateSentence(this.current().snapshot, this.now) :
        'Neither the senior\'s phone nor watch has reported yet, so their status is unknown.')
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .opacity(0.85)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(24)
    .backgroundColor(this.heroTint())
    .accessibilityGroup(true)
  }

  /** A row that opens `route` when set; without one it is information only. */
  @Builder
  row(icon: Resource, accent: Resource, tint: Resource, title: string, summary: string, route: string,
    showDivider: boolean) {
    Column() {
      Row({ space: 16 }) {
        IconBadge({ icon: icon, accent: accent, tint: tint, badgeSize: 44 })
        Column({ space: 2 }) {
          Text(title)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(summary)
            .fontSize(17)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        if (route !== '') {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(18)
            .fontColor([$r('app.color.text_secondary')])
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 76 })
      }
    }
    .accessibilityGroup(true)
    .accessibilityText(`${title}. ${summary}`)
    .accessibilityRole(route !== '' ? AccessibilityRoleType.BUTTON : AccessibilityRoleType.TEXT)
    .attributeModifier(new CareFocusStyle())
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor(route !== '' ? $r('app.color.pressed') : Color.Transparent)
      }
    })
    .onClick(() => {
      if (route !== '') {
        this.navStack.pushPathByName(route, null);
      }
    })
  }

  @Builder
  card(title: string) {
    Column({ space: 8 }) {
      sectionTitle(title)
      Column() {
        if (title === TODAY) {
          this.todayRows()
        } else if (title === DEVICES) {
          this.deviceRows()
        } else {
          this.setupRows()
        }
      }
      .width('100%')
      .borderRadius(20)
      .clip(true)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  todayRows() {
    this.row($r('sys.symbol.bell_fill'),
      this.current().unacknowledgedAlerts > 0 ? $r('app.color.sos') : $r('app.color.guardian_accent'),
      this.current().unacknowledgedAlerts > 0 ? $r('app.color.sos_tint') : $r('app.color.guardian_tint'),
      this.alertsTitle(), 'SOS, safe area and health alerts', 'alerts', true)
    this.row($r('sys.symbol.cross_case'),
      this.current().missedLast24h > 0 ? $r('app.color.sos') : $r('app.color.guardian_accent'),
      this.current().missedLast24h > 0 ? $r('app.color.sos_tint') : $r('app.color.guardian_tint'),
      this.missedTitle(), this.nextDoseText(), DOSE_HISTORY_ROUTE, false)
  }

  @Builder
  deviceRows() {
    this.row($r('sys.symbol.phone_fill_1'), this.deviceAccent(this.current().snapshot.phone),
      $r('app.color.guardian_tint'), 'Phone', this.deviceText(this.current().snapshot.phone), '', true)
    this.row($r('sys.symbol.watch_fill'), this.deviceAccent(this.current().snapshot.watch),
      $r('app.color.guardian_tint'), 'Watch', this.deviceText(this.current().snapshot.watch),
      GUARDIAN_WATCH_ROUTE, false)
  }

  @Builder
  setupRows() {
    this.row($r('sys.symbol.house_shield_fill'),
      this.current().hasSafeArea ? $r('app.color.guardian_accent') : $r('app.color.warning'),
      this.current().hasSafeArea ? $r('app.color.guardian_tint') : $r('app.color.warning_tint'),
      'Safe Area', this.current().hasSafeArea ? 'Set up' : 'Not set up yet', 'safe-area-setup', true)
    this.row($r('sys.symbol.doc_text_fill'),
      this.current().latestReportNeedsAttention ? $r('app.color.warning') : $r('app.color.guardian_accent'),
      this.current().latestReportNeedsAttention ? $r('app.color.warning_tint') : $r('app.color.guardian_tint'),
      'Wellbeing report', this.reportText(), WELLBEING_REPORTS_ROUTE, false)
  }

  @Builder
  content() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column({ space: 24 }) {
          this.hero()
          this.card(TODAY)
          this.card(DEVICES)
          this.card(CARE_SETUP)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
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
      this.load();
    })
  }

  build() {
    NavDestination() {
      if (this.loading && this.overview === undefined) {
        LoadingMessage({ message: 'Loading the overview…' })
      } else if (this.overview === undefined) {
        StatusMessage({
          icon: $r('sys.symbol.person_2_fill'),
          title: 'Could not load the overview',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      } else {
        this.content()
      }
    }
    .title('Overview')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.startRefreshing())
    .onHidden(() => this.stopRefreshing())
  }
}

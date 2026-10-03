import { IconBadge } from '../components/Common';
import { CareButtonStyle, CareFocusStyle } from '../components/DesignSystem';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { AttentionPill, attentionAccent, attentionTint, WellbeingReportView } from '../components/WellbeingReportView';
import { dayLabel, localDateKey } from '../models/CareOverview';
import { formatClockTime } from '../models/Safety';
import {
  answersLabel,
  Attention,
  attentionLabel,
  durationLabel,
  finishReasonLabel,
  ratingLabel,
  ratingOf,
  REPORT_TOPICS,
  ReportTopic,
  topicTitle,
  WellbeingReport
} from '../models/Wellbeing';
import { ApiError } from '../providers/backend/BackendClient';
import { describeOverviewError } from '../services/GuardianOverview';
import { guardianWellbeing } from '../services/WellbeingService';

export const WELLBEING_REPORTS_ROUTE = 'wellbeing-reports';
export const WELLBEING_REPORT_ROUTE = 'wellbeing-report';

/** Opens one report: from the list (already loaded) or from a notification or alert (by id). */
export class WellbeingReportTarget {
  readonly reportId: string;
  readonly report: WellbeingReport | undefined;

  constructor(reportId: string, report?: WellbeingReport) {
    this.reportId = reportId;
    this.report = report;
  }
}

function whenLabel(timestamp: number, now: number): string {
  return `${dayLabel(localDateKey(timestamp), now)}, ${formatClockTime(timestamp)}`;
}

const FOOTNOTE = 'Summaries are written by an AI assistant from the senior\'s check-in chat. They can be wrong ' +
  'and are not a medical assessment. The conversation itself is not shared with you.';

/** The senior's check-in summaries, newest first. */
@Component
export struct WellbeingReportsPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private reports: WellbeingReport[] = [];
  @State private loaded: boolean = false;
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  @State private errorMessage: string = '';
  @State private now: number = Date.now();
  private requestSeq: number = 0;

  private async load(): Promise<void> {
    const seq = ++this.requestSeq;
    try {
      const reports = await guardianWellbeing.reports();
      if (seq !== this.requestSeq) {
        return;
      }
      this.now = Date.now();
      this.reports = reports;
      this.loaded = true;
      this.errorMessage = '';
    } catch (error) {
      if (seq === this.requestSeq) {
        this.errorMessage = describeOverviewError(error as Object, 'the wellbeing reports');
      }
    } finally {
      if (seq === this.requestSeq) {
        this.loading = false;
        this.refreshing = false;
      }
    }
  }

  private ratingsLine(report: WellbeingReport): string {
    return REPORT_TOPICS.filter((topic: ReportTopic) => ratingOf(report, topic) !== 'unclear')
      .map((topic: ReportTopic) => `${topicTitle(topic)}: ${ratingLabel(topic, ratingOf(report, topic))}`)
      .join(' · ');
  }

  @Builder
  reportCard(report: WellbeingReport) {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        IconBadge({
          icon: report.attention === Attention.None ? $r('sys.symbol.doc_text_fill') :
          $r('sys.symbol.exclamationmark_circle_fill'),
          accent: report.attention === Attention.None ? $r('app.color.guardian_accent') :
          attentionAccent(report.attention),
          tint: report.attention === Attention.None ? $r('app.color.guardian_tint') : attentionTint(report.attention),
          badgeSize: 44
        })
        Text(whenLabel(report.createdAt, this.now))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      AttentionPill({ attention: report.attention })
      Text(report.summary !== '' ? report.summary : 'No summary could be written for this check-in.')
        .fontSize(17)
        .fontColor(report.summary !== '' ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.ratingsLine(report) !== '') {
        Text(this.ratingsLine(report))
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .accessibilityGroup(true)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`Check-in, ${whenLabel(report.createdAt, this.now)}. ${attentionLabel(report.attention)} ` +
      `${report.summary}`)
    .attributeModifier(new CareFocusStyle())
    .stateStyles({
      normal: {
        .backgroundColor($r('app.color.surface'))
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
    .onClick(() => this.navStack.pushPathByName(WELLBEING_REPORT_ROUTE, new WellbeingReportTarget(report.id, report)))
  }

  @Builder
  content() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column({ space: 16 }) {
          if (this.errorMessage !== '') {
            Text(`Showing the last loaded list. ${this.errorMessage}`)
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
          if (this.reports.length === 0) {
            Column({ space: 12 }) {
              IconBadge({
                icon: $r('sys.symbol.doc_text_fill'),
                accent: $r('app.color.guardian_accent'),
                tint: $r('app.color.guardian_tint'),
                badgeSize: 80
              })
              Text('No check-ins yet')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text('When your senior finishes a check-in chat in the Wellbeing tab, its summary appears here.')
                .fontSize(17)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 48, bottom: 16, left: 16, right: 16 })
          }
          ForEach(this.reports, (report: WellbeingReport) => {
            this.reportCard(report)
          }, (report: WellbeingReport) => report.id)
          Text(FOOTNOTE)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 4, right: 4 })
          Button(this.refreshing ? 'Refreshing…' : 'Refresh')
            .width('100%')
            .attributeModifier(new CareButtonStyle('secondary'))
            .enabled(!this.refreshing)
            .onClick(() => {
              this.refreshing = true;
              this.load();
            })
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
      this.refreshing = true;
      this.load();
    })
  }

  build() {
    NavDestination() {
      if (this.loading && !this.loaded) {
        LoadingMessage({ message: 'Loading the wellbeing reports…' })
      } else if (!this.loaded) {
        StatusMessage({
          icon: $r('sys.symbol.doc_text_fill'),
          title: 'Could not load the reports',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      } else {
        this.content()
      }
    }
    .title('Wellbeing reports')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.load())
  }
}

/** One check-in summary in full, with how and when the check-in happened. */
@Component
export struct WellbeingReportDetailPage {
  target: WellbeingReportTarget = new WellbeingReportTarget('');
  @State private report: WellbeingReport | undefined = undefined;
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private removed: boolean = false;

  aboutToAppear(): void {
    this.report = this.target.report;
    if (this.report === undefined) {
      this.load();
    }
  }

  private async load(): Promise<void> {
    this.loading = true;
    try {
      this.report = await guardianWellbeing.report(this.target.reportId);
      this.errorMessage = '';
    } catch (error) {
      this.removed = error instanceof ApiError && error.status === 404;
      this.errorMessage = describeOverviewError(error as Object, 'this report');
    } finally {
      this.loading = false;
    }
  }

  @Builder
  infoRow(label: string, value: string, showDivider: boolean) {
    if (value !== '') {
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
  }

  @Builder
  content(report: WellbeingReport) {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 14 }) {
          AttentionPill({ attention: report.attention })
          WellbeingReportView({ report: report })
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(20)
        .backgroundColor($r('app.color.surface'))

        Column() {
          this.infoRow('Shared', whenLabel(report.createdAt, Date.now()), true)
          this.infoRow('Length', durationLabel(report), true)
          this.infoRow('Answers', answersLabel(report), true)
          this.infoRow('Ended', finishReasonLabel(report.finishReason), false)
        }
        .width('100%')
        .borderRadius(20)
        .backgroundColor($r('app.color.surface'))

        Text(FOOTNOTE)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 4, right: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  build() {
    NavDestination() {
      if (this.report !== undefined) {
        this.content(this.report)
      } else if (this.loading || this.errorMessage === '') {
        LoadingMessage({ message: 'Loading the report…' })
      } else if (this.removed) {
        StatusMessage({
          icon: $r('sys.symbol.doc_text_fill'),
          title: 'Report removed',
          message: 'Your senior removed this summary, so it can no longer be shown.'
        })
      } else {
        StatusMessage({
          icon: $r('sys.symbol.doc_text_fill'),
          title: 'Could not load the report',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      }
    }
    .title(this.report !== undefined ? `Check-in · ${dayLabel(localDateKey(this.report.createdAt), Date.now())}` :
      'Check-in report')
    .backgroundColor($r('app.color.page_background'))
  }
}

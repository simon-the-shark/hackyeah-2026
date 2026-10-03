import { NoticeBanner } from '../components/Common';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { GuardianReport } from '../models/Wellbeing';
import { BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { ReportsApi } from '../providers/backend/ReportsApi';
import { apiSession } from '../services/CareApi';
import { CONCERN_LABELS, factLines } from '../services/CheckInScript';
import { describeGuardianError, isGuardianPaired, NOT_GUARDIAN_MESSAGE } from '../services/GuardianMedications';

const PAGE_SIZE = 20;

enum LoadPhase {
  Loading,
  Ready,
  Failed
}

function reportTime(report: GuardianReport): string {
  const date = new Date(report.createdAt);
  const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
  return `${date.toLocaleDateString()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function sourceLabel(source: string): string {
  if (source === 'ai') {
    return 'Note written by AI';
  }
  if (source === 'simulated') {
    return 'Simulated note (demo data)';
  }
  return 'Note built from the answers';
}

// The reports API is guardian-only; the client is built per call so sign-out takes effect immediately.
function reportsApi(): ReportsApi {
  return new ReportsApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
}

@Component
struct ReportCard {
  @Require report: GuardianReport;

  build() {
    Column({ space: 12 }) {
      Text(reportTime(this.report))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      if (this.report.facts.concerns.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.report.facts.concerns, (flag: string) => {
            Text(CONCERN_LABELS[flag] ?? flag)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.sos'))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ right: 8, bottom: 8 })
              .borderRadius(12)
              .backgroundColor($r('app.color.sos_tint'))
          }, (flag: string) => flag)
        }
        .width('100%')
      }

      // What the senior answered, kept apart from any generated text.
      Column({ space: 4 }) {
        Text('Answers')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        ForEach(factLines(this.report.facts), (line: string) => {
          Text(line)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
        }, (line: string) => line)
        if (this.report.facts.painWhere !== undefined) {
          Text(`Where it hurts: "${this.report.facts.painWhere}"`)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
        }
        if (this.report.facts.notes !== undefined) {
          Text(`In their words: "${this.report.facts.notes}"`)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.report.facts.aiCheck !== undefined) {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.checkmark_shield_fill'))
            .fontSize(18)
            .fontColor([this.report.facts.aiCheck.flagged ? $r('app.color.sos') : $r('app.color.success')])
          Text(this.report.facts.aiCheck.flagged ?
            'On-device AI check of their words: possible health worry' :
            'On-device AI check of their words: nothing worrying noticed')
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
      }

      if (this.report.summary.length > 0) {
        Column({ space: 4 }) {
          Text(sourceLabel(this.report.source))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text(this.report.summary)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .borderRadius(14)
        .backgroundColor($r('app.color.guardian_tint'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
    .accessibilityGroup(true)
  }
}

// Guardian view of the wellbeing check-ins the senior chose to share, newest first.
@Component
export struct WellbeingReportsPage {
  @State private phase: LoadPhase = LoadPhase.Loading;
  @State private reports: GuardianReport[] = [];
  @State private errorMessage: string = '';
  @State private hasMore: boolean = false;
  @State private loadingMore: boolean = false;
  @State private refreshing: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    if (!isGuardianPaired()) {
      this.errorMessage = NOT_GUARDIAN_MESSAGE;
      this.phase = LoadPhase.Failed;
      return;
    }
    try {
      const items = await reportsApi().list(apiSession.seniorId, undefined, PAGE_SIZE);
      this.reports = items;
      this.hasMore = items.length === PAGE_SIZE;
      this.phase = LoadPhase.Ready;
    } catch (err) {
      this.errorMessage = describeGuardianError(err as Object, 'Wellbeing reports could not be loaded.');
      this.phase = this.reports.length > 0 ? LoadPhase.Ready : LoadPhase.Failed;
    } finally {
      this.refreshing = false;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || this.reports.length === 0) {
      return;
    }
    this.loadingMore = true;
    try {
      const oldest = new Date(this.reports[this.reports.length - 1].createdAt);
      const items = await reportsApi().list(apiSession.seniorId, oldest, PAGE_SIZE);
      this.reports = this.reports.concat(items);
      this.hasMore = items.length === PAGE_SIZE;
    } catch (err) {
      this.errorMessage = describeGuardianError(err as Object, 'Older reports could not be loaded.');
    } finally {
      this.loadingMore = false;
    }
  }

  @Builder
  content() {
    if (this.phase === LoadPhase.Loading) {
      LoadingMessage({ message: 'Loading wellbeing reports…' })
    } else if (this.phase === LoadPhase.Failed) {
      StatusMessage({
        icon: $r('sys.symbol.doc_text_fill'),
        title: 'Reports unavailable',
        message: this.errorMessage,
        onRetry: () => {
          this.phase = LoadPhase.Loading;
          this.reload();
        }
      })
    } else if (this.reports.length === 0) {
      StatusMessage({
        icon: $r('sys.symbol.doc_text_fill'),
        title: 'No check-ins yet',
        message: 'When your senior shares a daily check-in, it appears here.'
      })
    } else {
      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 12 }) {
          ListItem() {
            NoticeBanner({
              text: 'Check-ins are voluntary and shared by the senior. They are not medical assessments; ' +
                'call them if something worries you.'
            })
          }
          ForEach(this.reports, (report: GuardianReport) => {
            ListItem() {
              ReportCard({ report: report })
            }
          }, (report: GuardianReport) => report.id)
          if (this.hasMore) {
            ListItem() {
              Button(this.loadingMore ? 'Loading…' : 'Show older check-ins')
                .width('100%')
                .height(52)
                .fontSize(17)
                .enabled(!this.loadingMore)
                .onClick(() => this.loadMore())
            }
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
        .scrollBar(BarState.Off)
      }
      .onRefreshing(() => this.reload())
    }
  }

  build() {
    NavDestination() {
      this.content()
    }
    .title('Wellbeing Reports')
    .backgroundColor($r('app.color.page_background'))
  }
}

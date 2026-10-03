import { sectionTitle } from '../components/Common';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import {
  DoseDay,
  dayLabel,
  doseStatusText,
  DoseTally,
  groupByDay,
  ScheduledDose,
  ScheduledDoseStatus,
  tallyOf
} from '../models/CareOverview';
import { describeOverviewError, DOSE_HISTORY_DAYS, guardianOverview } from '../services/GuardianOverview';

export const DOSE_HISTORY_ROUTE = 'dose-history';

function statusIcon(status: ScheduledDoseStatus): Resource {
  if (status === ScheduledDoseStatus.Taken) {
    return $r('sys.symbol.checkmark_circle_fill');
  }
  if (status === ScheduledDoseStatus.Skipped) {
    return $r('sys.symbol.xmark_circle_fill');
  }
  if (status === ScheduledDoseStatus.Snoozed) {
    return $r('sys.symbol.alarm_fill');
  }
  if (status === ScheduledDoseStatus.Missed) {
    return $r('sys.symbol.exclamationmark_triangle_fill');
  }
  return $r('sys.symbol.clock_fill');
}

function statusAccent(status: ScheduledDoseStatus): Resource {
  if (status === ScheduledDoseStatus.Taken) {
    return $r('app.color.success');
  }
  if (status === ScheduledDoseStatus.Missed) {
    return $r('app.color.sos');
  }
  if (status === ScheduledDoseStatus.Skipped || status === ScheduledDoseStatus.Snoozed) {
    return $r('app.color.warning');
  }
  return $r('app.color.text_secondary');
}

function statusTint(status: ScheduledDoseStatus): Resource {
  if (status === ScheduledDoseStatus.Taken) {
    return $r('app.color.success_tint');
  }
  if (status === ScheduledDoseStatus.Missed) {
    return $r('app.color.sos_tint');
  }
  if (status === ScheduledDoseStatus.Skipped || status === ScheduledDoseStatus.Snoozed) {
    return $r('app.color.warning_tint');
  }
  return $r('app.color.guardian_tint');
}

/** The senior's taken, skipped, snoozed and missed doses over the last week, as the server computed them. */
@Component
export struct DoseHistoryPage {
  @State private days: DoseDay[] = [];
  @State private tally: DoseTally = new DoseTally();
  @State private loaded: boolean = false;
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  @State private errorMessage: string = '';
  @State private now: number = Date.now();
  private requestSeq: number = 0;

  private async load(): Promise<void> {
    const seq = ++this.requestSeq;
    try {
      const doses = await guardianOverview.doseHistory();
      if (seq !== this.requestSeq) {
        return;
      }
      this.now = Date.now();
      this.days = groupByDay(doses);
      this.tally = tallyOf(doses);
      this.loaded = true;
      this.errorMessage = '';
    } catch (error) {
      if (seq === this.requestSeq) {
        this.errorMessage = describeOverviewError(error as Object, 'the dose history');
      }
    } finally {
      if (seq === this.requestSeq) {
        this.loading = false;
        this.refreshing = false;
      }
    }
  }

  @Builder
  tallyItem(value: number, label: string, accent: Resource) {
    Column({ space: 2 }) {
      Text(`${value}`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .accessibilityGroup(true)
    .accessibilityText(`${value} ${label}`)
  }

  @Builder
  summary() {
    Column({ space: 12 }) {
      Text(`Last ${DOSE_HISTORY_DAYS} days`)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Row() {
        this.tallyItem(this.tally.taken, 'taken', $r('app.color.success'))
        this.tallyItem(this.tally.skipped, 'skipped', $r('app.color.warning'))
        this.tallyItem(this.tally.missed, 'missed', $r('app.color.sos'))
      }
      .width('100%')
      if (this.tally.snoozed > 0) {
        Text(this.tally.snoozed === 1 ? '1 dose is snoozed and still waiting for an answer.' :
          `${this.tally.snoozed} doses are snoozed and still waiting for an answer.`)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  doseRow(dose: ScheduledDose, showDivider: boolean) {
    Column() {
      Row({ space: 14 }) {
        Text(dose.localTime)
          .fontSize(19)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width(56)
        Column({ space: 2 }) {
          Text(dose.medicationName)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (dose.doseText !== '') {
            Text(dose.doseText)
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Row({ space: 6 }) {
          SymbolGlyph(statusIcon(dose.status))
            .fontSize(18)
            .fontColor([statusAccent(dose.status)])
          Text(doseStatusText(dose, this.now))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .constraintSize({ maxWidth: 150 })
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor(statusTint(dose.status))
      }
      .width('100%')
      .constraintSize({ minHeight: 68 })
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 86 })
      }
    }
    .accessibilityGroup(true)
    .accessibilityText(`${dose.localTime}, ${dose.medicationName}` +
      `${dose.doseText === '' ? '' : `, ${dose.doseText}`}. ${doseStatusText(dose, this.now)}`)
  }

  @Builder
  daySection(day: DoseDay) {
    Column({ space: 8 }) {
      sectionTitle(dayLabel(day.date, this.now))
      Column() {
        ForEach(day.doses, (dose: ScheduledDose, index: number) => {
          this.doseRow(dose, index < day.doses.length - 1)
        }, (dose: ScheduledDose) => `${dose.occurrenceId}:${dose.status}:${dose.recordedAt}`)
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
  content() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column({ space: 20 }) {
          this.summary()
          if (this.days.length === 0) {
            Text(`No doses were scheduled in the last ${DOSE_HISTORY_DAYS} days.`)
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 16 })
          }
          ForEach(this.days, (day: DoseDay) => {
            this.daySection(day)
          }, (day: DoseDay) => `${day.date}:${day.doses.map((dose: ScheduledDose) =>
            `${dose.occurrenceId}:${dose.status}`).join(',')}`)
          Text('Doses from before the last schedule change are not listed.')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 4 })
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
        LoadingMessage({ message: 'Loading the dose history…' })
      } else if (!this.loaded) {
        StatusMessage({
          icon: $r('sys.symbol.checkmark_clipboard_fill'),
          title: 'Could not load the dose history',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      } else {
        this.content()
      }
    }
    .title('Dose History')
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.load())
  }
}

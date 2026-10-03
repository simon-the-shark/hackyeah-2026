import { common } from '@kit.AbilityKit';
import { DoseOccurrence, DoseRecord, DoseStatus } from '../models/Medication';
import { timeKey } from '../services/MedicationSchedule';
import { medicationService } from '../services/MedicationService';

// Taken / Skip answer for one dose. The backend keeps the first answer, so each one is confirmed first.
@Component
export struct DoseAction {
  @Require dose: DoseOccurrence;
  @Consume('doseRecords') doseRecords: Map<string, DoseRecord>;
  @State saving: boolean = false;

  private confirm(status: DoseStatus): void {
    const taken = status === DoseStatus.Taken;
    this.getUIContext().showAlertDialog({
      title: taken ? 'Did you take it?' : 'Skip this dose?',
      message: `${this.dose.medication.name} at ${this.dose.time}. Your guardian will see this answer, and it ` +
        'cannot be changed later.',
      primaryButton: { value: 'Cancel', action: () => {} },
      secondaryButton: {
        value: taken ? 'Yes, taken' : 'Skip dose',
        style: DialogButtonStyle.HIGHLIGHT,
        action: () => {
          this.save(status);
        }
      }
    });
  }

  private async save(status: DoseStatus): Promise<void> {
    const service = medicationService(this.getUIContext().getHostContext() as common.Context);
    if (service === undefined || this.saving) {
      return;
    }
    this.saving = true;
    try {
      const record = await service.recordDose(this.dose, status, new Date());
      this.doseRecords.set(record.occurrenceId, record);
    } catch (err) {
      this.getUIContext().showAlertDialog({
        title: 'Not saved',
        message: `${(err as Error).message} Please try again.`,
        confirm: { value: 'OK', action: () => {} }
      });
    } finally {
      this.saving = false;
    }
  }

  @Builder
  answered(record: DoseRecord) {
    Column({ space: 4 }) {
      Row({ space: 10 }) {
        SymbolGlyph(record.status === DoseStatus.Taken ? $r('sys.symbol.checkmark_circle_fill') :
          $r('sys.symbol.xmark_circle_fill'))
          .fontSize(26)
          .fontColor([record.status === DoseStatus.Taken ? $r('app.color.success') : $r('app.color.text_secondary')])
        Text(record.status === DoseStatus.Taken ? `Taken at ${timeKey(new Date(record.recordedAt))}` : 'Skipped')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(record.status === DoseStatus.Taken ? $r('app.color.success') : $r('app.color.text_secondary'))
      }

      if (!record.synced) {
        Text('Saved on this phone. It will be sent to your guardian when you are online.')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .backgroundColor(record.status === DoseStatus.Taken ? $r('app.color.success_tint') : $r('app.color.divider'))
    .accessibilityGroup(true)
  }

  build() {
    if (this.doseRecords.has(this.dose.occurrenceId)) {
      this.answered(this.doseRecords.get(this.dose.occurrenceId) as DoseRecord)
    } else {
      Row({ space: 12 }) {
        Button() {
          Row({ space: 10 }) {
            if (this.saving) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
            } else {
              SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                .fontSize(24)
                .fontColor([Color.White])
            }
            Text('Taken')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .layoutWeight(1)
        .height(56)
        .backgroundColor($r('app.color.senior_accent'))
        .enabled(!this.saving)
        .accessibilityText(`Mark ${this.dose.medication.name} at ${this.dose.time} as taken`)
        .onClick(() => this.confirm(DoseStatus.Taken))

        Button('Skip')
          .height(56)
          .padding({ left: 20, right: 20 })
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.page_background'))
          .enabled(!this.saving)
          .accessibilityText(`Skip ${this.dose.medication.name} at ${this.dose.time}`)
          .onClick(() => this.confirm(DoseStatus.Skipped))
      }
      .width('100%')
    }
  }
}

import { common } from '@kit.AbilityKit';
import { DEMO_MEDICATIONS, DoseOccurrence } from '../models/Medication';
import { saveTakenDoses } from '../platform/DoseLogStore';
import { timeKey, todaysDoses } from '../services/MedicationSchedule';

// "Taken" button for one dose; once tapped it shows when the dose was taken, with undo.
@Component
export struct DoseAction {
  dose: DoseOccurrence = todaysDoses(DEMO_MEDICATIONS, new Date())[0];
  @Consume('takenDoses') takenDoses: Map<string, number>;

  private setTaken(taken: boolean): void {
    if (taken) {
      this.takenDoses.set(this.dose.occurrenceId, Date.now());
    } else {
      this.takenDoses.delete(this.dose.occurrenceId);
    }
    saveTakenDoses(this.getUIContext().getHostContext() as common.Context, this.takenDoses);
  }

  private takenAt(): string {
    return timeKey(new Date(this.takenDoses.get(this.dose.occurrenceId) ?? 0));
  }

  build() {
    if (this.takenDoses.has(this.dose.occurrenceId)) {
      Row({ space: 10 }) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(26)
          .fontColor([$r('app.color.success')])
        Text(`Taken at ${this.takenAt()}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.success'))
          .layoutWeight(1)
        Button('Undo')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .height(40)
          .accessibilityText(`Undo taken for ${this.dose.medication.name} at ${this.dose.time}`)
          .onClick(() => this.setTaken(false))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 8 })
      .borderRadius(16)
      .backgroundColor($r('app.color.success_tint'))
    } else {
      Button() {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
            .fontSize(24)
            .fontColor([Color.White])
          Text('Taken')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor($r('app.color.senior_accent'))
      .accessibilityText(`Mark ${this.dose.medication.name} at ${this.dose.time} as taken`)
      .onClick(() => this.setTaken(true))
    }
  }
}

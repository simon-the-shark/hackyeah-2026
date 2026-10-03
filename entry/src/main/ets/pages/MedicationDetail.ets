import { DoseAction } from '../components/DoseAction';
import { DEMO_MEDICATIONS, DoseOccurrence, Medication } from '../models/Medication';
import { nextDose, todaysDoses } from '../services/MedicationSchedule';

export class MedicationDetailParams {
  readonly medication: Medication;
  readonly scannedCode: string;
  readonly simulated: boolean;

  constructor(medication: Medication, scannedCode: string, simulated: boolean) {
    this.medication = medication;
    this.scannedCode = scannedCode;
    this.simulated = simulated;
  }
}

@Component
export struct MedicationDetail {
  params: MedicationDetailParams = new MedicationDetailParams(DEMO_MEDICATIONS[0], '', false);
  @Consume('takenDoses') takenDoses: Map<string, number>;
  private now: Date = new Date();
  private doses: DoseOccurrence[] = [];

  aboutToAppear(): void {
    this.doses = todaysDoses([this.params.medication], this.now);
  }

  private isNext(dose: DoseOccurrence): boolean {
    return nextDose(this.doses, this.now, this.takenDoses)?.occurrenceId === dose.occurrenceId;
  }

  @Builder
  matchBanner() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
        .fontSize(30)
        .fontColor([$r('app.color.success')])
      Column({ space: 2 }) {
        Text('On today\'s list')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.success'))
        Text(this.params.simulated ? `Simulated scan · code ${this.params.scannedCode}` :
          `Scanned code ${this.params.scannedCode}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('app.color.success_tint'))
    .accessibilityGroup(true)
  }

  @Builder
  doseRow(dose: DoseOccurrence) {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(28)
          .fontColor([$r('app.color.senior_accent')])
        Text(dose.time)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (this.isNext(dose)) {
          Text('Next')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.senior_accent'))
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor($r('app.color.senior_tint'))
        }
      }
      .width('100%')

      DoseAction({ dose: dose })
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          if (this.params.scannedCode.length > 0) {
            this.matchBanner()
          }

          Column({ space: 6 }) {
            if (this.params.medication.photo !== undefined) {
              Image(this.params.medication.photo)
                .width('100%')
                .aspectRatio(4 / 3)
                .objectFit(ImageFit.Cover)
                .borderRadius(24)
                .accessibilityText(`Picture of the ${this.params.medication.name} box`)
            } else {
              Row() {
                SymbolGlyph($r('sys.symbol.cross_case'))
                  .fontSize(72)
                  .fontColor([$r('app.color.senior_accent')])
              }
              .width('100%')
              .aspectRatio(4 / 3)
              .borderRadius(24)
              .justifyContent(FlexAlign.Center)
              .backgroundColor($r('app.color.senior_tint'))
            }
            Text('Illustration of a demo medicine')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 4 }) {
            Text(this.params.medication.name)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.params.medication.doseText)
              .fontSize(20)
              .fontColor($r('app.color.text_primary'))
            Text(this.params.medication.instructions)
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .accessibilityGroup(true)

          Text('Today')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))

          ForEach(this.doses, (dose: DoseOccurrence) => {
            this.doseRow(dose)
          }, (dose: DoseOccurrence) => dose.occurrenceId)
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
    .title('Medicine')
    .backgroundColor($r('app.color.page_background'))
  }
}

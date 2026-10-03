import { common } from '@kit.AbilityKit';
import { DoseAction } from '../components/DoseAction';
import { DEMO_MEDICATIONS, DoseOccurrence, Medication } from '../models/Medication';
import { isBarcodeScanSupported, scanProductBarcode, ScanOutcome, ScanStatus } from '../platform/BarcodeScanner';
import { findScheduledMedication, nextDose, todaysDoses } from '../services/MedicationSchedule';
import { MedicationDetailParams } from './MedicationDetail';

// A code that cannot belong to any demo medicine, used by the simulated "not on the list" scan.
const SIMULATED_UNKNOWN_CODE = '2000000009998';

@Component
struct DoseCard {
  dose: DoseOccurrence = todaysDoses(DEMO_MEDICATIONS, new Date())[0];
  @Prop isNext: boolean = false;

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(22)
          .fontColor([$r('app.color.senior_accent')])
        Text(this.dose.time)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.senior_accent'))
          .layoutWeight(1)
        if (this.isNext) {
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

      Column({ space: 4 }) {
        Text(this.dose.medication.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.dose.medication.doseText)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
        Text(this.dose.medication.instructions)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .accessibilityGroup(true)

      DoseAction({ dose: this.dose })
    }
    .width('100%')
    .padding(20)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
    .border(this.isNext ? { width: 2, color: $r('app.color.senior_accent') } : { width: 0 })
  }
}

@Component
export struct MedicationToday {
  @Consume('navStack') navStack: NavPathStack;
  @Consume('takenDoses') takenDoses: Map<string, number>;
  @State scanning: boolean = false;
  private now: Date = new Date();
  private doses: DoseOccurrence[] = todaysDoses(DEMO_MEDICATIONS, this.now);

  private isNext(dose: DoseOccurrence): boolean {
    return nextDose(this.doses, this.now, this.takenDoses)?.occurrenceId === dose.occurrenceId;
  }

  private async scan(): Promise<void> {
    if (!isBarcodeScanSupported()) {
      this.showSimulatedScans();
      return;
    }
    this.scanning = true;
    const outcome: ScanOutcome =
      await scanProductBarcode(this.getUIContext().getHostContext() as common.Context);
    this.scanning = false;
    if (outcome.status === ScanStatus.Scanned) {
      this.checkCode(outcome.value, false);
    } else if (outcome.status === ScanStatus.Unavailable) {
      this.showSimulatedScans();
    }
  }

  private checkCode(code: string, simulated: boolean): void {
    const medication = findScheduledMedication(this.doses, code);
    if (medication !== undefined) {
      this.navStack.pushPathByName('medication-detail', new MedicationDetailParams(medication, code, simulated));
      return;
    }
    this.getUIContext().showAlertDialog({
      title: 'Not on today\'s list',
      message: `${simulated ? 'Simulated scan. ' : ''}This box (code ${code}) is not one of today's medicines. ` +
        'Do not take it unless your guardian has told you to.',
      confirm: { value: 'OK', action: () => {} }
    });
  }

  // Deterministic demo path for targets without Scan Kit; every result is labelled as simulated.
  private showSimulatedScans(): void {
    const sheets: SheetInfo[] = [];
    const seen = new Set<string>();
    this.doses.forEach((dose: DoseOccurrence) => {
      const medication: Medication = dose.medication;
      if (!seen.has(medication.id)) {
        seen.add(medication.id);
        sheets.push({ title: `${medication.name} box`, action: () => this.checkCode(medication.barcode, true) });
      }
    });
    sheets.push({ title: 'Box not on today\'s list', action: () => this.checkCode(SIMULATED_UNKNOWN_CODE, true) });
    this.getUIContext().showActionSheet({
      title: 'Scanner not available',
      message: 'Barcode scanning is not available on this device. Demo only: choose a simulated scan.',
      sheets: sheets
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 4 }) {
            Text('Today')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.now.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' }))
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.doses.length === 0) {
            Text('No medicines are scheduled for today.')
              .fontSize(18)
              .fontColor($r('app.color.text_secondary'))
          }

          ForEach(this.doses, (dose: DoseOccurrence) => {
            DoseCard({ dose: dose, isNext: this.isNext(dose) })
          }, (dose: DoseOccurrence) => dose.occurrenceId)

          Text('Demo schedule with synthetic medicines. Your guardian\'s care plan will replace it once the ' +
            'backend is connected.')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 8, bottom: 112 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      Button() {
        Row({ space: 10 }) {
          if (this.scanning) {
            LoadingProgress()
              .width(26)
              .height(26)
              .color(Color.White)
          } else {
            SymbolGlyph($r('sys.symbol.barcode_viewfinder'))
              .fontSize(26)
              .fontColor([Color.White])
          }
          Text('Scan medicine')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .height(64)
      .padding({ left: 24, right: 28 })
      .margin({ right: 20, bottom: 20 })
      .backgroundColor($r('app.color.senior_accent'))
      .shadow({ radius: 16, color: $r('app.color.card_shadow'), offsetY: 6 })
      .enabled(!this.scanning)
      .accessibilityText('Scan a medicine box to check it against today\'s list')
      .onClick(() => this.scan())
    }
    .width('100%')
    .height('100%')
  }
}

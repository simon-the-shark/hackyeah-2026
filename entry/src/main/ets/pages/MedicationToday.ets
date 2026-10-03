import { common } from '@kit.AbilityKit';
import { DoseAction } from '../components/DoseAction';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { CatalogProduct, DoseOccurrence, DoseRecord, DoseStatus, Medication } from '../models/Medication';
import { isBarcodeScanSupported, scanProductBarcode, ScanOutcome, ScanStatus } from '../platform/BarcodeScanner';
import { describeBackendError, NOT_CONFIGURED_MESSAGE } from '../services/BackendErrors';
import {
  dateKey,
  dosesOf,
  findMedicationByBarcode,
  nextDose,
  openDose,
  sortByOpenDose,
  todaysDoses
} from '../services/MedicationSchedule';
import { medicationService, MedicationService } from '../services/MedicationService';
import { MedicationDetailParams } from './MedicationDetail';

// A code that cannot belong to any medicine, used by the simulated "not on the list" scan.
const SIMULATED_UNKNOWN_CODE = '2000000009998';

enum LoadPhase {
  Loading,
  Ready,
  Failed,
  NotConfigured
}

// Changes whenever anything shown on a medication card changes (including the day), so ForEach rebuilds it.
function medicationKey(medication: Medication, day: string): string {
  return [day, medication.id, medication.name, medication.doseText, medication.instructions,
    medication.times.join(',')].join('|');
}

@Component
struct MedicationCard {
  @Require medication: Medication;
  @Require doses: DoseOccurrence[];
  @Prop isNext: boolean = false;
  @Consume('doseRecords') doseRecords: Map<string, DoseRecord>;
  onOpen: () => void = () => {};

  @Builder
  timeChip(dose: DoseOccurrence) {
    Row({ space: 4 }) {
      if (this.doseRecords.has(dose.occurrenceId)) {
        SymbolGlyph((this.doseRecords.get(dose.occurrenceId) as DoseRecord).status === DoseStatus.Taken ?
          $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.xmark_circle_fill'))
          .fontSize(16)
          .fontColor([$r('app.color.text_secondary')])
      }
      Text(dose.time)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.doseRecords.has(dose.occurrenceId) ? $r('app.color.text_secondary') :
          $r('app.color.senior_accent'))
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .margin({ right: 8, top: 8 })
    .borderRadius(12)
    .backgroundColor(this.doseRecords.has(dose.occurrenceId) ? $r('app.color.page_background') :
      $r('app.color.senior_tint'))
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(this.medication.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          if (this.medication.doseText.length > 0) {
            Text(this.medication.doseText)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
          }
          if (this.medication.instructions.length > 0) {
            Text(this.medication.instructions)
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.doses, (dose: DoseOccurrence) => {
              this.timeChip(dose)
            }, (dose: DoseOccurrence) => dose.occurrenceId)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      .accessibilityGroup(true)
      .accessibilityText(`${this.medication.name}. Open details`)
      .onClick(() => this.onOpen())

      if (openDose(this.doses, this.doseRecords) !== undefined) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(20)
              .fontColor([$r('app.color.senior_accent')])
            Text(`Dose at ${(openDose(this.doses, this.doseRecords) as DoseOccurrence).time}`)
              .fontSize(18)
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

          DoseAction({ dose: openDose(this.doses, this.doseRecords) as DoseOccurrence })
        }
        .width('100%')
      } else if (this.doses.length > 0) {
        Text('All doses answered for today.')
          .fontSize(16)
          .fontColor($r('app.color.success'))
      } else {
        Text('No doses scheduled for today.')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
      }
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
  @Consume('doseRecords') doseRecords: Map<string, DoseRecord>;
  @State phase: LoadPhase = LoadPhase.Loading;
  @State errorMessage: string = '';
  @State refreshFailed: boolean = false;
  @State refreshing: boolean = false;
  @State scanning: boolean = false;
  @State medications: Medication[] = [];
  @State doses: DoseOccurrence[] = [];
  @State now: Date = new Date();

  aboutToAppear(): void {
    this.load();
  }

  private service(): MedicationService | undefined {
    return medicationService(this.getUIContext().getHostContext() as common.Context);
  }

  private async load(): Promise<void> {
    const service = this.service();
    if (service === undefined) {
      this.phase = LoadPhase.NotConfigured;
      this.refreshing = false;
      return;
    }
    if (this.phase !== LoadPhase.Ready) {
      this.phase = LoadPhase.Loading;
    }
    const now = new Date();
    try {
      const overview = await service.loadToday(now);
      this.now = now;
      this.doses = todaysDoses(overview.medications, now);
      this.doseRecords = overview.records;
      // Ordered once per load so cards do not jump while the senior is answering doses.
      this.medications = sortByOpenDose(overview.medications, this.doses, overview.records);
      this.refreshFailed = false;
      this.phase = LoadPhase.Ready;
    } catch (err) {
      this.errorMessage = describeBackendError(err as Object, 'Something went wrong while loading your medicines.');
      // Keep showing the last loaded list; only a first load turns into the error screen.
      if (this.phase === LoadPhase.Ready) {
        this.refreshFailed = true;
      } else {
        this.phase = LoadPhase.Failed;
      }
    } finally {
      this.refreshing = false;
    }
  }

  private isNext(medication: Medication): boolean {
    return nextDose(this.doses, this.now, this.doseRecords)?.medication.id === medication.id;
  }

  private openDetail(medication: Medication, scannedCode: string, simulated: boolean): void {
    this.navStack.pushPathByName('medication-detail', new MedicationDetailParams(medication, scannedCode, simulated));
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
      await this.checkCode(outcome.value, false);
    } else if (outcome.status === ScanStatus.Unavailable) {
      this.showSimulatedScans();
    }
  }

  private async checkCode(code: string, simulated: boolean): Promise<void> {
    const medication = findMedicationByBarcode(this.medications, code);
    if (medication !== undefined) {
      this.openDetail(medication, code, simulated);
      return;
    }
    // Name the product when the catalog knows it, so the senior can tell the guardian what they hold.
    let product: CatalogProduct | undefined = undefined;
    try {
      this.scanning = true;
      product = await this.service()?.lookUpBarcode(code.trim());
    } catch (err) {
      product = undefined;
    } finally {
      this.scanning = false;
    }
    const prefix = simulated ? 'Simulated scan. ' : '';
    const what = product !== undefined ?
      `This box looks like ${product.name}${product.isSynthetic ? ' (demo catalog)' : ''}, which` :
      `This box (code ${code})`;
    this.getUIContext().showAlertDialog({
      title: 'Not on your list',
      message: `${prefix}${what} is not one of your medicines. Do not take it unless your guardian has told you to.`,
      confirm: { value: 'OK', action: () => {} }
    });
  }

  // Deterministic demo path for targets without Scan Kit; every result is labelled as simulated.
  private showSimulatedScans(): void {
    const sheets: SheetInfo[] = [];
    this.medications.forEach((medication: Medication) => {
      if (medication.barcode.length > 0) {
        sheets.push({ title: `${medication.name} box`, action: () => this.checkCode(medication.barcode, true) });
      }
    });
    sheets.push({ title: 'Box not on your list', action: () => this.checkCode(SIMULATED_UNKNOWN_CODE, true) });
    this.getUIContext().showActionSheet({
      title: 'Scanner not available',
      message: 'Barcode scanning is not available on this device. Demo only: choose a simulated scan.',
      sheets: sheets
    });
  }

  @Builder
  header() {
    Column({ space: 4 }) {
      Text('My medicines')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.now.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' }))
        .fontSize(17)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  medicationList() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column({ space: 16 }) {
          this.header()

          if (this.refreshFailed) {
            Row({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.wifi_slash'))
                .fontSize(22)
                .fontColor([$r('app.color.text_secondary')])
              Text(`Showing the last loaded list. ${this.errorMessage}`)
                .fontSize(15)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .borderRadius(16)
            .backgroundColor($r('app.color.divider'))
          }

          if (this.medications.length === 0) {
            Text('You have no medicines on your list yet. Your guardian can add them in the Carely app.')
              .fontSize(18)
              .fontColor($r('app.color.text_secondary'))
          }

          ForEach(this.medications, (medication: Medication) => {
            MedicationCard({
              medication: medication,
              doses: dosesOf(this.doses, medication.id),
              isNext: this.isNext(medication),
              onOpen: () => this.openDetail(medication, '', false)
            })
          }, (medication: Medication) => medicationKey(medication, dateKey(this.now)))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 8, bottom: 112 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .onRefreshing(() => {
      this.load();
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.phase === LoadPhase.Ready) {
        this.medicationList()
      } else if (this.phase === LoadPhase.Loading) {
        LoadingMessage({ message: 'Loading your medicines…' })
      } else if (this.phase === LoadPhase.Failed) {
        StatusMessage({
          icon: $r('sys.symbol.wifi_slash'),
          title: 'Medicines not loaded',
          message: this.errorMessage,
          onRetry: () => this.load()
        })
      } else {
        StatusMessage({
          icon: $r('sys.symbol.exclamationmark_triangle_fill'),
          title: 'Not connected yet',
          message: NOT_CONFIGURED_MESSAGE
        })
      }

      if (this.phase === LoadPhase.Ready) {
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
        .accessibilityText('Scan a medicine box to check it against your list')
        .onClick(() => this.scan())
      }
    }
    .width('100%')
    .height('100%')
  }
}

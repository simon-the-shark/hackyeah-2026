import { common } from '@kit.AbilityKit';
import { IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { CatalogProduct, Medication } from '../models/Medication';
import {
  addDoseTime,
  AddTimeResult,
  BARCODE_MAX,
  DEMO_BARCODE,
  DOSE_MAX,
  DraftErrors,
  INSTRUCTIONS_MAX,
  isValidManualBarcode,
  MedicationDraft,
  NAME_MAX,
  SUGGESTED_TIMES,
  validateDraft
} from '../models/MedicationDraft';
import { isBarcodeScanSupported, scanProductBarcode, ScanOutcome, ScanStatus } from '../platform/BarcodeScanner';
import { deviceTimeZone } from '../platform/DeviceTimeZone';
import { MedicationConflictError } from '../providers/backend/MedicationApi';
import {
  describeGuardianError,
  guardianMedications,
  isGuardianPaired,
  NOT_GUARDIAN_MESSAGE
} from '../services/GuardianMedications';

export class MedicationFormParams {
  // Medication to edit; undefined adds a new one.
  readonly medication: Medication | undefined;

  constructor(medication: Medication | undefined) {
    this.medication = medication;
  }
}

// How the barcode on the form was obtained, shown so a simulated value is never mistaken for a scan.
enum BarcodeSource {
  None,
  Scan,
  Manual,
  Demo
}

enum LookupState {
  Idle,
  Looking,
  Found,
  NotFound,
  Failed
}

function sourceLabel(source: BarcodeSource): string {
  if (source === BarcodeSource.Scan) {
    return 'Scanned with the camera';
  }
  if (source === BarcodeSource.Demo) {
    return 'Demo barcode (simulated, not a camera scan)';
  }
  if (source === BarcodeSource.Manual) {
    return 'Typed in by hand';
  }
  return '';
}

function showToast(context: UIContext, message: string): void {
  try {
    context.getPromptAction().showToast({ message: message });
  } catch (err) {
    console.error('Medication toast failed');
  }
}

// Adds a medication (scan or type the package barcode, then guardian-confirmed details) or edits one.
// A catalog match is only a candidate name; dose and times always come from the guardian.
@Component
export struct MedicationFormPage {
  @Consume('navStack') navStack: NavPathStack;
  @Require params: MedicationFormParams;

  @State private medicationId: string = '';
  @State private version: number = 0;
  @State private name: string = '';
  @State private doseText: string = '';
  @State private instructions: string = '';
  @State private times: string[] = [];
  @State private timezone: string = '';
  @State private barcode: string = '';
  @State private modelAssetKey: string = '';

  @State private barcodeSource: BarcodeSource = BarcodeSource.None;
  @State private candidate: CatalogProduct | undefined = undefined;
  @State private nameConfirmed: boolean = false;
  @State private lookupState: LookupState = LookupState.Idle;
  @State private lookupError: string = '';
  @State private scanning: boolean = false;
  @State private scanUnavailable: boolean = false;
  @State private showManualBarcode: boolean = false;
  @State private manualBarcode: string = '';
  @State private manualBarcodeError: boolean = false;

  @State private newTime: string = '';
  @State private timeError: string = '';
  @State private showErrors: boolean = false;
  @State private saving: boolean = false;
  @State private notice: string = '';
  private phoneZone: string = '';

  aboutToAppear(): void {
    this.phoneZone = deviceTimeZone();
    const medication = this.params.medication;
    if (medication !== undefined) {
      this.fill(medication);
    } else {
      this.timezone = this.phoneZone;
    }
  }

  private isEdit(): boolean {
    return this.params.medication !== undefined;
  }

  private fill(medication: Medication): void {
    const draft = MedicationDraft.fromMedication(medication);
    this.medicationId = draft.id;
    this.version = draft.version;
    this.name = draft.name;
    this.doseText = draft.doseText;
    this.instructions = draft.instructions;
    this.times = draft.times;
    // Keep the stored zone when editing so the schedule does not shift if this phone is elsewhere.
    this.timezone = draft.timezone;
    this.barcode = draft.barcode;
    this.modelAssetKey = draft.modelAssetKey;
  }

  private toDraft(): MedicationDraft {
    const draft = new MedicationDraft();
    draft.id = this.medicationId;
    draft.version = this.version;
    draft.name = this.name;
    draft.doseText = this.doseText;
    draft.instructions = this.instructions;
    draft.times = this.times;
    draft.timezone = this.timezone;
    draft.barcode = this.barcode;
    draft.modelAssetKey = this.modelAssetKey;
    return draft;
  }

  private errors(): DraftErrors {
    return validateDraft(this.toDraft());
  }

  // ---- identification ----

  private async scan(): Promise<void> {
    if (!isBarcodeScanSupported()) {
      this.scanUnavailable = true;
      this.showManualBarcode = true;
      return;
    }
    this.scanning = true;
    const outcome: ScanOutcome = await scanProductBarcode(this.getUIContext().getHostContext() as common.Context);
    this.scanning = false;
    if (outcome.status === ScanStatus.Scanned && outcome.value.trim() !== '') {
      this.scanUnavailable = false;
      await this.identify(outcome.value.trim(), BarcodeSource.Scan);
    } else if (outcome.status === ScanStatus.Unavailable) {
      this.scanUnavailable = true;
      this.showManualBarcode = true;
    }
  }

  private async lookUpManual(): Promise<void> {
    if (!isValidManualBarcode(this.manualBarcode)) {
      this.manualBarcodeError = true;
      return;
    }
    this.manualBarcodeError = false;
    await this.identify(this.manualBarcode.trim(), BarcodeSource.Manual);
  }

  private async identify(code: string, source: BarcodeSource): Promise<void> {
    this.barcode = code.substring(0, BARCODE_MAX);
    this.barcodeSource = source;
    this.candidate = undefined;
    this.modelAssetKey = '';
    this.nameConfirmed = false;
    this.lookupError = '';
    this.lookupState = LookupState.Looking;
    try {
      const product = await guardianMedications.lookUpBarcode(this.barcode);
      if (this.barcode !== code.substring(0, BARCODE_MAX)) {
        return;
      }
      if (product === undefined) {
        this.lookupState = LookupState.NotFound;
        return;
      }
      this.candidate = product;
      this.name = product.name;
      this.modelAssetKey = product.modelAssetKey;
      this.lookupState = LookupState.Found;
    } catch (err) {
      this.lookupError = describeGuardianError(err as Object, 'The catalog could not be checked.');
      this.lookupState = LookupState.Failed;
    }
  }

  private clearBarcode(): void {
    this.barcode = '';
    this.barcodeSource = BarcodeSource.None;
    this.candidate = undefined;
    this.modelAssetKey = '';
    this.nameConfirmed = false;
    this.lookupState = LookupState.Idle;
  }

  // ---- times ----

  private addTime(input: string): void {
    const result: AddTimeResult = addDoseTime(this.times, input);
    this.timeError = result.error;
    if (result.error === '') {
      this.times = result.times;
      this.newTime = '';
    }
  }

  private removeTime(time: string): void {
    this.times = this.times.filter((item: string) => item !== time);
  }

  // ---- save ----

  private confirmError(): string {
    return this.candidate !== undefined && !this.nameConfirmed ? 'Confirm the name matches the package.' : '';
  }

  private async save(): Promise<void> {
    if (!this.errors().isValid() || this.confirmError() !== '') {
      this.showErrors = true;
      return;
    }
    if (!isGuardianPaired()) {
      this.notice = NOT_GUARDIAN_MESSAGE;
      return;
    }
    this.saving = true;
    this.notice = '';
    try {
      if (this.isEdit()) {
        await guardianMedications.update(this.toDraft());
      } else {
        await guardianMedications.create(this.toDraft());
      }
      this.saving = false;
      showToast(this.getUIContext(), 'Medication saved');
      this.navStack.pop();
    } catch (err) {
      this.saving = false;
      if (err instanceof MedicationConflictError) {
        await this.handleConflict((err as MedicationConflictError).current);
      } else {
        this.notice = describeGuardianError(err as Object, 'Could not save the medication.');
      }
    }
  }

  // Someone else saved first: show the stored values instead of silently overwriting them.
  private async handleConflict(current: Medication | undefined): Promise<void> {
    let latest = current;
    if (latest === undefined) {
      try {
        latest = await guardianMedications.find(this.medicationId);
      } catch (err) {
        latest = undefined;
      }
    }
    if (latest === undefined) {
      this.notice = 'This medication was changed or deleted on another device. Go back and reopen it.';
      return;
    }
    this.fill(latest);
    this.getUIContext().showAlertDialog({
      title: 'Changed on another device',
      message: 'Someone saved this medication while you were editing. The latest saved values are now shown. ' +
        'Review them, make your changes again and save.',
      confirm: {
        value: 'OK',
        action: () => {
        }
      }
    });
  }

  // ---- UI ----

  @Builder
  errorText(message: string) {
    if (this.showErrors && message !== '') {
      Text(message)
        .fontSize(14)
        .fontColor($r('app.color.sos'))
    }
  }

  @Builder
  fieldLabel(label: string) {
    Text(label)
      .fontSize(15)
      .fontColor($r('app.color.text_secondary'))
  }

  @Builder
  identifyCard() {
    Column({ space: 8 }) {
      sectionTitle('1. Identify the medicine')
      Column({ space: 12 }) {
        Button() {
          Row({ space: 8 }) {
            if (this.scanning) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
            } else {
              SymbolGlyph($r('sys.symbol.barcode_viewfinder'))
                .fontSize(22)
                .fontColor([Color.White])
            }
            Text(this.scanning ? 'Opening scanner…' : 'Scan package barcode')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(56)
        .enabled(!this.scanning && this.lookupState !== LookupState.Looking)
        .backgroundColor($r('app.color.guardian_accent'))
        .onClick(() => this.scan())

        if (this.scanUnavailable) {
          NoticeBanner({ text: 'The camera scanner is not available on this device. Enter the barcode instead.' })
        }

        Row({ space: 8 }) {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.keyboard'))
                .fontSize(18)
                .fontColor([$r('app.color.guardian_accent')])
              Text('Enter barcode manually')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.guardian_accent'))
            }
          }
          .layoutWeight(1)
          .height(48)
          .backgroundColor($r('app.color.guardian_tint'))
          .onClick(() => {
            this.showManualBarcode = !this.showManualBarcode;
          })

          Button() {
            Text('Use demo barcode (simulated)')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(1)
          .height(48)
          .backgroundColor($r('app.color.page_background'))
          .enabled(this.lookupState !== LookupState.Looking)
          .accessibilityText('Use demo barcode. Simulated, not a real scan.')
          .onClick(() => this.identify(DEMO_BARCODE, BarcodeSource.Demo))
        }
        .width('100%')

        Text('Demo only: the demo barcode is a synthetic code for emulators without a camera. It is not a real scan.')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))

        if (this.showManualBarcode) {
          Column({ space: 6 }) {
            this.fieldLabel('Digits under the barcode')
            Row({ space: 8 }) {
              TextInput({ text: this.manualBarcode, placeholder: 'e.g. 5900000000011' })
                .layoutWeight(1)
                .height(52)
                .fontSize(18)
                .type(InputType.Number)
                .maxLength(BARCODE_MAX)
                .backgroundColor($r('app.color.page_background'))
                .border({ width: this.manualBarcodeError ? 2 : 0, color: $r('app.color.sos') })
                .onChange((value: string) => {
                  this.manualBarcode = value;
                })
                .onSubmit(() => {
                  this.lookUpManual();
                })
              Button('Look up')
                .height(52)
                .fontSize(17)
                .enabled(this.lookupState !== LookupState.Looking)
                .backgroundColor($r('app.color.guardian_accent'))
                .onClick(() => this.lookUpManual())
            }
            .width('100%')
            if (this.manualBarcodeError) {
              Text('Enter the digits printed under the barcode.')
                .fontSize(14)
                .fontColor($r('app.color.sos'))
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        this.lookupResult()

        if (this.barcode === '') {
          Text('No barcode? Fill in the details below.')
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
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  lookupResult() {
    if (this.barcode !== '') {
      Column({ space: 10 }) {
        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Text(`Barcode ${this.barcode}`)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text(sourceLabel(this.barcodeSource))
              .fontSize(14)
              .fontColor(this.barcodeSource === BarcodeSource.Demo ? $r('app.color.warning') :
                $r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(18)
              .fontColor([$r('app.color.text_secondary')])
          }
          .width(44)
          .height(44)
          .backgroundColor($r('app.color.page_background'))
          .accessibilityText('Remove barcode')
          .onClick(() => this.clearBarcode())
        }
        .width('100%')

        if (this.lookupState === LookupState.Looking) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color($r('app.color.guardian_accent'))
            Text('Checking the catalog…')
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
        } else if (this.lookupState === LookupState.Found && this.candidate !== undefined) {
          NoticeBanner({
            icon: $r('sys.symbol.info_circle'),
            text: `Catalog candidate: ${this.candidate.name}` +
              (this.candidate.form === '' ? '' : ` (${this.candidate.form})`) +
              (this.candidate.isSynthetic ? ', from the synthetic demo catalog' : '') +
              '. This is a possible match, not a prescription. Check it against the package; ' +
              'the dose and times must come from the prescription.',
            accent: $r('app.color.guardian_accent'),
            tint: $r('app.color.guardian_tint')
          })
        } else if (this.lookupState === LookupState.NotFound) {
          NoticeBanner({ text: 'This barcode is not in the catalog. Type the medicine details below.' })
        } else if (this.lookupState === LookupState.Failed) {
          NoticeBanner({ text: `${this.lookupError} Type the medicine details below.` })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  detailsCard() {
    Column({ space: 8 }) {
      sectionTitle(this.isEdit() ? 'Medicine details' : '2. Confirm the details')
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          this.fieldLabel('Medicine name')
          TextInput({ text: this.name, placeholder: 'e.g. Vitamin D' })
            .width('100%')
            .height(52)
            .fontSize(18)
            .maxLength(NAME_MAX)
            .backgroundColor($r('app.color.page_background'))
            .border({ width: this.showErrors && this.errors().name !== '' ? 2 : 0, color: $r('app.color.sos') })
            .onChange((value: string) => {
              this.name = value;
            })
          this.errorText(this.errors().name)
          if (this.candidate !== undefined) {
            Row({ space: 10 }) {
              Toggle({ type: ToggleType.Checkbox, isOn: this.nameConfirmed })
                .selectedColor($r('app.color.guardian_accent'))
                .onChange((isOn: boolean) => {
                  this.nameConfirmed = isOn;
                })
              Text('I checked this name against the package')
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .onClick(() => {
                  this.nameConfirmed = !this.nameConfirmed;
                })
            }
            .width('100%')
            this.errorText(this.confirmError())
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          this.fieldLabel('Dose')
          TextInput({ text: this.doseText, placeholder: 'e.g. 1 tablet' })
            .width('100%')
            .height(52)
            .fontSize(18)
            .maxLength(DOSE_MAX)
            .backgroundColor($r('app.color.page_background'))
            .border({ width: this.showErrors && this.errors().doseText !== '' ? 2 : 0, color: $r('app.color.sos') })
            .onChange((value: string) => {
              this.doseText = value;
            })
          Text('Write the dose exactly as prescribed. It is never taken from the barcode.')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          this.errorText(this.errors().doseText)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          this.fieldLabel('Instructions (optional)')
          TextArea({ text: this.instructions, placeholder: 'e.g. Take after breakfast with water' })
            .width('100%')
            .constraintSize({ minHeight: 96 })
            .fontSize(18)
            .maxLength(INSTRUCTIONS_MAX)
            .backgroundColor($r('app.color.page_background'))
            .onChange((value: string) => {
              this.instructions = value;
            })
          this.errorText(this.errors().instructions)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  timeChip(time: string) {
    Row({ space: 6 }) {
      Text(time)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.guardian_accent'))
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(16)
        .fontColor([$r('app.color.guardian_accent')])
    }
    .height(48)
    .padding({ left: 16, right: 12 })
    .margin({ right: 8, bottom: 8 })
    .borderRadius(24)
    .backgroundColor($r('app.color.guardian_tint'))
    .accessibilityGroup(true)
    .accessibilityText(`Remove ${time}`)
    .onClick(() => this.removeTime(time))
  }

  @Builder
  suggestionChip(time: string) {
    Row({ space: 4 }) {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(16)
        .fontColor([$r('app.color.text_primary')])
      Text(time)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
    }
    .height(44)
    .padding({ left: 14, right: 16 })
    .margin({ right: 8, bottom: 8 })
    .borderRadius(22)
    .backgroundColor($r('app.color.page_background'))
    .accessibilityGroup(true)
    .accessibilityText(`Add ${time}`)
    .onClick(() => this.addTime(time))
  }

  @Builder
  timesCard() {
    Column({ space: 8 }) {
      sectionTitle(this.isEdit() ? 'Dose times' : '3. Dose times')
      Column({ space: 14 }) {
        if (this.times.length === 0) {
          Text('No dose times yet')
            .fontSize(16)
            .fontColor(this.showErrors ? $r('app.color.sos') : $r('app.color.text_secondary'))
        } else {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.times, (time: string) => {
              this.timeChip(time)
            }, (time: string) => time)
          }
          .width('100%')
        }

        Row({ space: 8 }) {
          TextInput({ text: this.newTime, placeholder: 'HH:MM' })
            .layoutWeight(1)
            .height(52)
            .fontSize(18)
            .maxLength(5)
            .backgroundColor($r('app.color.page_background'))
            .border({ width: this.timeError !== '' ? 2 : 0, color: $r('app.color.sos') })
            .onChange((value: string) => {
              this.newTime = value;
              this.timeError = '';
            })
            .onSubmit(() => this.addTime(this.newTime))
          Button('Add time')
            .height(52)
            .fontSize(17)
            .backgroundColor($r('app.color.guardian_accent'))
            .onClick(() => this.addTime(this.newTime))
        }
        .width('100%')
        if (this.timeError !== '') {
          Text(this.timeError)
            .fontSize(14)
            .fontColor($r('app.color.sos'))
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(SUGGESTED_TIMES.filter((time: string) => this.times.indexOf(time) < 0), (time: string) => {
            this.suggestionChip(time)
          }, (time: string) => time)
        }
        .width('100%')

        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(16)
            .fontColor([$r('app.color.text_secondary')])
          Text(`Times are local to ${this.timezone}` +
            (this.timezone !== this.phoneZone ? ` (this phone: ${this.phoneZone})` : ''))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
        if (this.timezone !== this.phoneZone) {
          Button(`Use this phone's time zone`)
            .height(40)
            .fontSize(15)
            .fontColor($r('app.color.guardian_accent'))
            .backgroundColor($r('app.color.guardian_tint'))
            .onClick(() => {
              this.timezone = this.phoneZone;
            })
        }
        this.errorText(this.errors().times)
        this.errorText(this.errors().timezone)
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Row({ space: 16 }) {
            IconBadge({
              icon: $r('sys.symbol.cross_case'),
              accent: $r('app.color.guardian_accent'),
              tint: $r('app.color.guardian_tint'),
              badgeSize: 56
            })
            Text(this.isEdit() ? 'Changes appear on the senior phone the next time its list loads.' :
              'Scan the package to look up the medicine name, then set the dose and times.')
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')

          if (!isGuardianPaired()) {
            NoticeBanner({ text: NOT_GUARDIAN_MESSAGE })
          }

          if (!this.isEdit()) {
            this.identifyCard()
          } else if (this.barcode !== '') {
            Text(`Package barcode ${this.barcode}`)
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }

          this.detailsCard()
          this.timesCard()

          if (this.notice !== '') {
            NoticeBanner({ text: this.notice })
          }

          Button(this.saving ? 'Saving…' : 'Save medication')
            .width('100%')
            .height(56)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.saving && isGuardianPaired())
            .backgroundColor($r('app.color.guardian_accent'))
            .onClick(() => this.save())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title(this.isEdit() ? 'Edit Medication' : 'Add Medication')
    .backgroundColor($r('app.color.page_background'))
  }
}

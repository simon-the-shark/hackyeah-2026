import { IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { CareButtonStyle, CareFocusStyle } from '../components/DesignSystem';
import { DoseRecord, DoseStatus, Medication } from '../models/Medication';
import { sortTimes, timesLabel } from '../models/MedicationDraft';
import {
  describeGuardianError,
  guardianMedications,
  isGuardianPaired,
  NOT_GUARDIAN_MESSAGE
} from '../services/GuardianMedications';
import { MedicationFormParams } from './MedicationFormPage';

export const GUARDIAN_MEDICATION_DETAIL_ROUTE = 'guardian-medication-detail';
export const MEDICATION_FORM_ROUTE = 'medication-form';

enum LoadPhase {
  Loading,
  Ready,
  Failed
}

function showToast(context: UIContext, message: string): void {
  try {
    context.getPromptAction().showToast({ message: message });
  } catch (err) {
    console.error('Medication toast failed');
  }
}

function formatRecordedAt(timestamp: number): string {
  return new Date(timestamp).toLocaleString('en-GB', {
    weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit'
  });
}

// Changes whenever anything shown on a row changes, so ForEach rebuilds it.
function rowKey(medication: Medication, isLast: boolean): string {
  return [medication.id, `${medication.version}`, medication.name, medication.doseText, medication.times.join(','),
    `${isLast}`].join('|');
}

// Guardian Medication tab: the senior's medications with add, open details, and reload.
@Component
export struct GuardianMedicationList {
  @Consume('navStack') navStack: NavPathStack;
  // Bump to reload, e.g. when the tab becomes visible or the guardian returns from add/details.
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  @State private phase: LoadPhase = LoadPhase.Loading;
  @State private medications: Medication[] = [];
  @State private errorMessage: string = '';
  // A refresh failed while an older list is still shown.
  @State private refreshFailed: boolean = false;
  private loadId: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  private onRefresh(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    const loadId = ++this.loadId;
    if (!isGuardianPaired()) {
      this.medications = [];
      this.errorMessage = NOT_GUARDIAN_MESSAGE;
      this.phase = LoadPhase.Failed;
      return;
    }
    if (this.phase !== LoadPhase.Ready) {
      this.phase = LoadPhase.Loading;
    }
    try {
      const items = await guardianMedications.list();
      if (loadId !== this.loadId) {
        return;
      }
      this.medications = items;
      this.refreshFailed = false;
      this.phase = LoadPhase.Ready;
    } catch (err) {
      if (loadId !== this.loadId) {
        return;
      }
      this.errorMessage = describeGuardianError(err as Object, 'Could not load medications.');
      if (this.phase === LoadPhase.Ready) {
        this.refreshFailed = true;
      } else {
        this.phase = LoadPhase.Failed;
      }
    }
  }

  private openAdd(): void {
    this.navStack.pushPathByName(MEDICATION_FORM_ROUTE, new MedicationFormParams(undefined));
  }

  @Builder
  medicationRow(medication: Medication, showDivider: boolean) {
    Column() {
      Row({ space: 14 }) {
        IconBadge({
          icon: $r('sys.symbol.cross_case'),
          accent: $r('app.color.guardian_accent'),
          tint: $r('app.color.guardian_tint')
        })
        Column({ space: 3 }) {
          Text(medication.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(medication.doseText === '' ? 'No dose entered' : medication.doseText)
            .fontSize(15)
            .fontColor(medication.doseText === '' ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(15)
              .fontColor([$r('app.color.text_secondary')])
            Text(timesLabel(medication.times))
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 80 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 78 })
      }
    }
    .accessibilityGroup(true)
    .attributeModifier(new CareFocusStyle())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`${medication.name}. ${medication.doseText}. Open medication details.`)
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
    .onClick(() => this.navStack.pushPathByName(GUARDIAN_MEDICATION_DETAIL_ROUTE, medication))
  }

  @Builder
  centeredState(title: string, message: string, showRetry: boolean) {
    Column({ space: 12 }) {
      IconBadge({
        icon: $r('sys.symbol.cross_case'),
        accent: $r('app.color.guardian_accent'),
        tint: $r('app.color.guardian_tint'),
        badgeSize: 80
      })
      Text(title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
      Text(message)
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      if (showRetry) {
        Button('Try again')
          .height(56)
          .padding({ left: 28, right: 28 })
          .fontSize(17)
          .attributeModifier(new CareButtonStyle())
          .onClick(() => this.reload())
      }
    }
    .width('100%')
    .padding({ top: 48, bottom: 16, left: 16, right: 16 })
  }

  @Builder
  addButton() {
    Button() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.barcode_viewfinder'))
          .fontSize(22)
          .fontColor([Color.White])
        Text('Add medication')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(56)
    .enabled(isGuardianPaired())
    .opacity(isGuardianPaired() ? 1 : 0.5)
    .attributeModifier(new CareButtonStyle())
    .accessibilityText('Add medication: scan the package barcode or type the details')
    .onClick(() => this.openAdd())
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.phase === LoadPhase.Loading) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('app.color.guardian_accent'))
            Text('Loading medications…')
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding({ top: 64, bottom: 32 })
        } else if (this.phase === LoadPhase.Failed) {
          this.centeredState('Medications not loaded', this.errorMessage, isGuardianPaired())
        } else {
          if (this.refreshFailed) {
            NoticeBanner({ text: `Showing the last loaded list. ${this.errorMessage}` })
          }
          if (this.medications.length === 0) {
            this.centeredState('No medications yet',
              'Scan a medicine package or type its name to set dose times for your senior.', false)
          } else {
            Column() {
              ForEach(this.medications, (medication: Medication, index: number) => {
                this.medicationRow(medication, index < this.medications.length - 1)
              }, (medication: Medication, index: number) =>
                rowKey(medication, index === this.medications.length - 1))
            }
            .width('100%')
            .borderRadius(20)
            .clip(true)
            .backgroundColor($r('app.color.surface'))
          }
        }

        if (this.phase !== LoadPhase.Loading) {
          this.addButton()
        }

        Text('You set the medicines and dose times. The senior phone shows them as its daily list.')
          .fontSize(17)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }
}

// All stored fields of one medication, its recent dose answers, edit and delete.
@Component
export struct GuardianMedicationDetail {
  @Consume('navStack') navStack: NavPathStack;
  @Require medication: Medication;
  @State private current: Medication = new Medication('', '', '', '', '', [], '');
  @State private notice: string = '';
  @State private deleting: boolean = false;
  @State private removed: boolean = false;
  @State private doses: DoseRecord[] = [];
  @State private dosesLoaded: boolean = false;
  @State private dosesError: string = '';

  aboutToAppear(): void {
    this.current = this.medication;
  }

  // Refetches when first shown and after returning from the edit screen.
  private async refresh(): Promise<void> {
    if (this.deleting || this.removed) {
      return;
    }
    if (!isGuardianPaired()) {
      this.notice = NOT_GUARDIAN_MESSAGE;
      return;
    }
    try {
      const latest = await guardianMedications.find(this.current.id);
      if (latest === undefined) {
        this.removed = true;
        this.notice = 'This medication was removed on another device.';
        return;
      }
      this.current = latest;
      this.notice = '';
    } catch (err) {
      this.notice = `Showing the last loaded details. ${describeGuardianError(err as Object, '')}`;
    }
    this.loadDoses();
  }

  private async loadDoses(): Promise<void> {
    try {
      this.doses = await guardianMedications.recentDoses(this.current.id, new Date());
      this.dosesError = '';
    } catch (err) {
      this.dosesError = 'Recent doses could not be loaded.';
    }
    this.dosesLoaded = true;
  }

  private confirmDelete(): void {
    this.getUIContext().showAlertDialog({
      title: 'Delete medication?',
      message: `${this.current.name} and its dose times will be removed from the senior's list. ` +
        'Past dose answers are kept.',
      autoCancel: true,
      primaryButton: {
        value: 'Cancel',
        action: () => {
        }
      },
      secondaryButton: {
        value: 'Delete',
        fontColor: $r('app.color.sos'),
        action: () => {
          this.remove();
        }
      }
    });
  }

  private async remove(): Promise<void> {
    this.deleting = true;
    try {
      await guardianMedications.remove(this.current.id);
      this.removed = true;
      showToast(this.getUIContext(), 'Medication deleted');
      this.navStack.pop();
    } catch (err) {
      this.notice = describeGuardianError(err as Object, 'Could not delete the medication.');
    }
    this.deleting = false;
  }

  @Builder
  infoRow(label: string, value: string, showDivider: boolean) {
    Column() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
        Text(value)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 16, right: 16 })
      }
    }
    .accessibilityGroup(true)
  }

  @Builder
  timeChip(time: string) {
    Row({ space: 6 }) {
      SymbolGlyph($r('sys.symbol.clock'))
        .fontSize(18)
        .fontColor([$r('app.color.guardian_accent')])
      Text(time)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.guardian_accent'))
    }
    .height(48)
    .padding({ left: 16, right: 16 })
    .margin({ right: 8, bottom: 8 })
    .borderRadius(24)
    .backgroundColor($r('app.color.guardian_tint'))
  }

  @Builder
  doseRow(record: DoseRecord, showDivider: boolean) {
    Column() {
      Row({ space: 12 }) {
        SymbolGlyph(record.status === DoseStatus.Taken ? $r('sys.symbol.checkmark_circle_fill') :
          $r('sys.symbol.xmark_circle_fill'))
          .fontSize(22)
          .fontColor([record.status === DoseStatus.Taken ? $r('app.color.success') : $r('app.color.warning')])
        Text(record.status === DoseStatus.Taken ? 'Taken' : 'Skipped')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(formatRecordedAt(record.recordedAt))
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 16, right: 16 })
      }
    }
    .accessibilityGroup(true)
  }

  @Builder
  doseHistory() {
    Column({ space: 8 }) {
      sectionTitle('Recent answers (last 14 days)')
      Column() {
        if (!this.dosesLoaded) {
          Text('Loading…')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .padding(16)
        } else if (this.dosesError !== '') {
          Text(this.dosesError)
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .padding(16)
        } else if (this.doses.length === 0) {
          Text('No taken or skipped doses recorded yet.')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .padding(16)
        } else {
          ForEach(this.doses, (record: DoseRecord, index: number) => {
            this.doseRow(record, index < this.doses.length - 1)
          }, (record: DoseRecord) => record.occurrenceId)
        }
      }
      .width('100%')
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
          Column({ space: 12 }) {
            IconBadge({
              icon: $r('sys.symbol.cross_case'),
              accent: $r('app.color.guardian_accent'),
              tint: $r('app.color.surface'),
              badgeSize: 64
            })
            Text(this.current.doseText === '' ? 'No dose entered' : this.current.doseText)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .opacity(0.8)
          }
          .width('100%')
          .padding(24)
          .alignItems(HorizontalAlign.Start)
          .borderRadius(28)
          .backgroundColor($r('app.color.guardian_tint'))
          .accessibilityGroup(true)

          if (this.notice !== '') {
            NoticeBanner({ text: this.notice })
          }

          Column({ space: 8 }) {
            sectionTitle('Dose times')
            Column({ space: 8 }) {
              if (this.current.times.length === 0) {
                Text('No dose times set')
                  .fontSize(17)
                  .fontColor($r('app.color.text_secondary'))
              } else {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(sortTimes(this.current.times), (time: string) => {
                    this.timeChip(time)
                  }, (time: string) => time)
                }
                .width('100%')
              }
              Text(`Time zone: ${this.current.timezone === '' ? 'not set' : this.current.timezone}`)
                .fontSize(15)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding(16)
            .alignItems(HorizontalAlign.Start)
            .borderRadius(20)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column() {
            this.infoRow('Dose', this.current.doseText === '' ? 'Not entered' : this.current.doseText, true)
            this.infoRow('Instructions', this.current.instructions === '' ? 'None' : this.current.instructions, true)
            this.infoRow('Package barcode', this.current.barcode === '' ? 'Not recorded' : this.current.barcode, true)
            this.infoRow('Version', `${this.current.version}`, false)
          }
          .width('100%')
          .borderRadius(20)
          .backgroundColor($r('app.color.surface'))

          this.doseHistory()

          Button() {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.square_and_pencil'))
                .fontSize(20)
                .fontColor([Color.White])
              Text('Edit medication')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(56)
          .enabled(!this.removed && !this.deleting && isGuardianPaired())
          .opacity(!this.removed && isGuardianPaired() ? 1 : 0.5)
          .attributeModifier(new CareButtonStyle())
          .onClick(() => this.navStack.pushPathByName(MEDICATION_FORM_ROUTE, new MedicationFormParams(this.current)))

          Button() {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(20)
                .fontColor([$r('app.color.sos')])
              Text(this.deleting ? 'Deleting…' : 'Delete medication')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.sos'))
            }
          }
          .width('100%')
          .height(56)
          .enabled(!this.removed && !this.deleting && isGuardianPaired())
          .opacity(!this.removed && isGuardianPaired() ? 1 : 0.5)
          .attributeModifier(new CareButtonStyle('danger-secondary'))
          .onClick(() => this.confirmDelete())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title(this.current.name)
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.refresh())
  }
}

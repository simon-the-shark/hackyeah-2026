import { BusinessError } from '@kit.BasicServicesKit';
import { CareButtonStyle, CareFocusStyle, CareInputStyle } from '../components/DesignSystem';
import { IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { Contact } from '../models/Contact';
import { contactPickerAvailable, PickedContact, pickPhoneContact } from '../platform/PhoneContactPicker';
import { DialResult, openDialer } from '../platform/PhoneDialer';
import { ApiError } from '../providers/backend/BackendClient';
import { conflictingContact } from '../providers/backend/ContactsApi';
import {
  CONTACT_NAME_MAX_LENGTH,
  CONTACT_PHONE_MAX_LENGTH,
  contactNameError,
  contactPhoneError,
  nextSortOrder,
  normalizePhone
} from '../services/ContactForm';
import { contactInitials, dialableNumber } from '../services/ContactList';
import {
  describeGuardianContactsError,
  guardianContacts,
  guardianSessionReady,
  isNotFound,
  isVersionConflict,
  NOT_GUARDIAN_MESSAGE
} from '../services/GuardianContactsService';

// Navigation parameter of the 'contact-editor' route: an existing contact to edit, or a new one at `sortOrder`.
export class ContactEditorTarget {
  readonly contact: Contact | undefined;
  readonly sortOrder: number;

  constructor(contact: Contact | undefined, sortOrder: number) {
    this.contact = contact;
    this.sortOrder = sortOrder;
  }
}

function showToast(context: UIContext, message: string): void {
  try {
    context.getPromptAction().showToast({ message: message });
  } catch (err) {
    console.error(`Contacts toast failed: ${(err as BusinessError).code}`);
  }
}

async function callContact(context: UIContext, contact: Contact): Promise<void> {
  const result = await openDialer(dialableNumber(contact.phone));
  if (result === DialResult.Unavailable) {
    showToast(context, 'This device cannot make phone calls.');
  } else if (result === DialResult.Failed) {
    showToast(context, 'Could not open the phone app. Please try again.');
  }
}

enum ListPhase {
  Loading,
  Ready,
  Failed
}

// Guardian view of the senior's trusted contacts; used as the guardian Contacts tab.
@Component
export struct GuardianContactsList {
  @Consume('navStack') navStack: NavPathStack;
  // Bump to reload, e.g. when the tab becomes visible or the guardian returns from the editor.
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  @State private phase: ListPhase = ListPhase.Loading;
  @State private contacts: Contact[] = [];
  @State private errorMessage: string = '';
  // Set when a reload failed but an earlier list is still shown.
  @State private refreshFailed: boolean = false;
  // Ignores responses from older reloads that finish after a newer one.
  private requestSeq: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  private onRefresh(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    const seq = ++this.requestSeq;
    try {
      const contacts = await guardianContacts.list();
      if (seq !== this.requestSeq) {
        return;
      }
      this.contacts = contacts;
      this.refreshFailed = false;
      this.phase = ListPhase.Ready;
    } catch (err) {
      if (seq !== this.requestSeq) {
        return;
      }
      this.errorMessage = describeGuardianContactsError(err as Object, 'Could not load the contacts.');
      if (this.phase === ListPhase.Ready && guardianSessionReady()) {
        this.refreshFailed = true;
      } else {
        this.contacts = [];
        this.phase = ListPhase.Failed;
      }
    }
  }

  private openEditor(contact: Contact | undefined): void {
    this.navStack.pushPathByName('contact-editor', new ContactEditorTarget(contact, nextSortOrder(this.contacts)));
  }

  @Builder
  avatar(contact: Contact) {
    // The backend stores no photos, so every contact gets an initials avatar.
    Text(contactInitials(contact.name))
      .width(48)
      .height(48)
      .borderRadius(24)
      .textAlign(TextAlign.Center)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.guardian_accent'))
      .backgroundColor($r('app.color.guardian_tint'))
  }

  @Builder
  contactRow(contact: Contact, showDivider: boolean) {
    Column() {
      Row({ space: 14 }) {
        Row({ space: 14 }) {
          this.avatar(contact)
          Column({ space: 3 }) {
            Text(contact.name)
              .fontSize(19)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(contact.phone)
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .accessibilityGroup(true)
        .accessibilityText(`${contact.name}, ${contact.phone}. Edit contact`)
        .attributeModifier(new CareFocusStyle())
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .onClick(() => this.openEditor(contact))

        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.phone_fill'))
              .fontSize(22)
              .fontColor([$r('app.color.guardian_accent')])
            Text('Call').fontSize(19).fontColor($r('app.color.guardian_accent'))
          }
        }
        .attributeModifier(new CareButtonStyle('secondary'))
        .accessibilityText(`Call ${contact.name}`)
        .onClick(() => {
          callContact(this.getUIContext(), contact);
        })
      }
      .width('100%')
      .constraintSize({ minHeight: 76 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 78 })
      }
    }
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
  }

  @Builder
  centered(icon: Resource, title: string, message: string) {
    Column({ space: 12 }) {
      IconBadge({
        icon: icon,
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
    }
    .width('100%')
    .padding({ top: 48, bottom: 16, left: 16, right: 16 })
  }

  @Builder
  addButton() {
    Button() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.person_badge_plus'))
          .fontSize(22)
          .fontColor([Color.White])
        Text('Add contact')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(56)
    .attributeModifier(new CareButtonStyle())
    .onClick(() => this.openEditor(undefined))
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.phase === ListPhase.Loading) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('app.color.guardian_accent'))
            Text('Loading contacts…')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding({ top: 64, bottom: 32 })
        } else if (this.phase === ListPhase.Failed) {
          this.centered($r('sys.symbol.wifi_slash'), 'Contacts not loaded', this.errorMessage)
          if (guardianSessionReady()) {
            Button('Try again')
              .width('100%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.guardian_accent'))
              .attributeModifier(new CareButtonStyle('secondary'))
              .onClick(() => {
                this.phase = ListPhase.Loading;
                this.reload();
              })
          }
        } else {
          if (this.refreshFailed) {
            NoticeBanner({ text: `Showing the last loaded list. ${this.errorMessage}` })
          }
          if (this.contacts.length === 0) {
            this.centered($r('sys.symbol.person_2_fill'), 'No trusted contacts yet',
              'Add the people your senior should be able to call with one tap.')
          } else {
            Column({ space: 8 }) {
              sectionTitle(this.contacts.length === 1 ? '1 trusted contact' :
                `${this.contacts.length} trusted contacts`)
              Column() {
                ForEach(this.contacts, (contact: Contact, index: number) => {
                  this.contactRow(contact, index < this.contacts.length - 1)
                }, (contact: Contact, index: number) =>
                  `${contact.id}-${contact.version}-${index === this.contacts.length - 1}`)
              }
              .width('100%')
              .borderRadius(20)
              .clip(true)
              .backgroundColor($r('app.color.surface'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          this.addButton()
        }

        Text('Contacts are saved on the care service and appear on the senior\'s phone in this order.')
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

// Add a trusted contact, or edit, call or delete an existing one.
@Component
export struct ContactEditorPage {
  @Consume('navStack') navStack: NavPathStack;
  target: ContactEditorTarget = new ContactEditorTarget(undefined, 0);
  @State private name: string = '';
  @State private phone: string = '';
  @State private showErrors: boolean = false;
  @State private busy: boolean = false;
  @State private formError: string = '';
  // The stored contact this edit is based on; replaced by the newer copy after a version conflict.
  private original: Contact | undefined = undefined;

  aboutToAppear(): void {
    this.original = this.target.contact;
    if (this.original !== undefined) {
      this.name = this.original.name;
      this.phone = this.original.phone;
    }
    if (!guardianSessionReady()) {
      this.formError = NOT_GUARDIAN_MESSAGE;
    }
  }

  private isNew(): boolean {
    return this.target.contact === undefined;
  }

  private fieldError(isName: boolean): string {
    return isName ? contactNameError(this.name) : contactPhoneError(this.phone);
  }

  private async chooseFromPhone(): Promise<void> {
    let picked: PickedContact | undefined = undefined;
    try {
      picked = await pickPhoneContact();
    } catch (err) {
      console.error(`Contact picker failed: ${(err as BusinessError).code}`);
      showToast(this.getUIContext(), 'Could not open the phone contacts.');
      return;
    }
    if (picked === undefined) {
      return;
    }
    if (picked.name.trim().length > 0) {
      this.name = picked.name.trim().substring(0, CONTACT_NAME_MAX_LENGTH);
    }
    if (picked.phone.trim().length === 0) {
      showToast(this.getUIContext(), 'That contact has no phone number. Enter one below.');
    } else {
      this.phone = normalizePhone(picked.phone).substring(0, CONTACT_PHONE_MAX_LENGTH);
    }
    this.showErrors = true;
  }

  private async save(): Promise<void> {
    if (contactNameError(this.name) !== '' || contactPhoneError(this.phone) !== '') {
      this.showErrors = true;
      return;
    }
    this.busy = true;
    this.formError = '';
    const name = this.name.trim();
    const phone = this.phone.trim();
    try {
      if (this.original === undefined) {
        await guardianContacts.create(name, phone, this.target.sortOrder);
      } else {
        await guardianContacts.update(this.original, name, phone);
      }
    } catch (err) {
      this.busy = false;
      this.handleSaveError(err as Object);
      return;
    }
    this.busy = false;
    showToast(this.getUIContext(), this.isNew() ? 'Contact added' : 'Contact saved');
    this.navStack.pop();
  }

  private handleSaveError(err: Object): void {
    if (isVersionConflict(err)) {
      const current = conflictingContact((err as ApiError).details);
      if (current !== undefined) {
        // Someone else saved first: show their copy and base the next save on it.
        this.original = current;
        this.name = current.name;
        this.phone = current.phone;
        this.formError = 'This contact was changed on another device. The latest details are shown; ' +
          'make your changes again and save.';
        return;
      }
      this.formError = 'This contact was changed on another device. Go back and open it again.';
      return;
    }
    this.formError = describeGuardianContactsError(err, 'Could not save the contact.');
  }

  private confirmDelete(): void {
    const contact = this.original;
    if (contact === undefined) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: 'Delete contact?',
      message: `${contact.name} will be removed from your senior's trusted contacts.`,
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
          this.remove(contact);
        }
      }
    });
  }

  private async remove(contact: Contact): Promise<void> {
    this.busy = true;
    this.formError = '';
    try {
      await guardianContacts.remove(contact);
    } catch (err) {
      // Already gone on the care service is the same outcome as deleting it here.
      if (!isNotFound(err as Object)) {
        this.busy = false;
        this.formError = describeGuardianContactsError(err as Object, 'Could not delete the contact.');
        return;
      }
    }
    this.busy = false;
    showToast(this.getUIContext(), 'Contact deleted');
    this.navStack.pop();
  }

  @Builder
  field(isName: boolean) {
    Column({ space: 6 }) {
      Text(isName ? 'Name' : 'Phone number')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
      TextInput({
        text: isName ? this.name : this.phone,
        placeholder: isName ? 'e.g. Anna Kowalska' : 'e.g. +48 600 100 200'
      })
        .width('100%')
        .height(56)
        .fontSize(20)
        .type(isName ? InputType.Normal : InputType.PhoneNumber)
        .maxLength(isName ? CONTACT_NAME_MAX_LENGTH : CONTACT_PHONE_MAX_LENGTH)
        .enterKeyType(isName ? EnterKeyType.Next : EnterKeyType.Done)
        .backgroundColor($r('app.color.page_background'))
        .border({
          width: this.showErrors && this.fieldError(isName) !== '' ? 2 : 0,
          color: $r('app.color.sos')
        })
        .accessibilityText(isName ? 'Contact name' : 'Contact phone number')
        .attributeModifier(new CareInputStyle(isName ? 'Contact name' : 'Contact phone number',
          this.showErrors ? this.fieldError(isName) : ''))
        .enabled(!this.busy)
        .onChange((value: string) => {
          if (isName) {
            this.name = value;
          } else {
            this.phone = value;
          }
        })
      if (this.showErrors && this.fieldError(isName) !== '') {
        Text(this.fieldError(isName))
          .fontSize(15)
          .fontColor($r('app.color.sos'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buttonLabel(icon: Resource, label: string, color: ResourceColor) {
    Row({ space: 8 }) {
      SymbolGlyph(icon)
        .fontSize(20)
        .fontColor([color])
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Row({ space: 16 }) {
            IconBadge({
              icon: this.isNew() ? $r('sys.symbol.person_badge_plus') : $r('sys.symbol.square_and_pencil'),
              accent: $r('app.color.guardian_accent'),
              tint: $r('app.color.guardian_tint'),
              badgeSize: 56
            })
            Text(this.isNew() ? 'Your senior will be able to call this person with one tap.' :
              'Changes appear on your senior\'s phone the next time it loads contacts.')
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')

          if (contactPickerAvailable()) {
            Button() {
              this.buttonLabel($r('sys.symbol.contacts_book'), 'Choose from phone contacts',
                $r('app.color.guardian_accent'))
            }
            .width('100%')
            .height(56)
            .attributeModifier(new CareButtonStyle('secondary'))
            .enabled(!this.busy)
            .onClick(() => {
              this.chooseFromPhone();
            })
          }

          Column({ space: 8 }) {
            sectionTitle('Contact details')
            Column({ space: 16 }) {
              this.field(true)
              this.field(false)
            }
            .width('100%')
            .padding(16)
            .borderRadius(20)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.formError !== '') {
            NoticeBanner({
              icon: $r('sys.symbol.exclamationmark_circle_fill'),
              text: this.formError
            })
          }

          Button() {
            Row({ space: 8 }) {
              if (this.busy) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color(Color.White)
              }
              Text(this.busy ? 'Saving…' : this.isNew() ? 'Add contact' : 'Save changes')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(56)
          .attributeModifier(new CareButtonStyle())
          .enabled(!this.busy && guardianSessionReady())
          .onClick(() => {
            this.save();
          })

          if (!this.isNew()) {
            Button() {
              this.buttonLabel($r('sys.symbol.phone_fill'), 'Call', $r('app.color.text_primary'))
            }
            .width('100%')
            .height(56)
            .attributeModifier(new CareButtonStyle('secondary'))
            .accessibilityText(`Call ${this.name}`)
            .onClick(() => {
              if (this.original !== undefined) {
                callContact(this.getUIContext(), this.original);
              }
            })

            Button() {
              this.buttonLabel($r('sys.symbol.trash'), 'Delete contact', $r('app.color.sos'))
            }
            .width('100%')
            .height(56)
            .attributeModifier(new CareButtonStyle('danger-secondary'))
            .enabled(!this.busy && guardianSessionReady())
            .onClick(() => this.confirmDelete())
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title(this.isNew() ? 'Add contact' : 'Edit contact')
    .backgroundColor($r('app.color.page_background'))
  }
}

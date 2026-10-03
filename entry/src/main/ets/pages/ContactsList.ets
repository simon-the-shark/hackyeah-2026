import { common } from '@kit.AbilityKit';
import { CareFocusStyle } from '../components/DesignSystem';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { Contact } from '../models/Contact';
import { DialResult, openDialer } from '../platform/PhoneDialer';
import { describeBackendError, NOT_CONFIGURED_MESSAGE } from '../services/BackendErrors';
import { contactInitials, dialableNumber } from '../services/ContactList';
import { contactsService, ContactsService } from '../services/ContactsService';

enum LoadPhase {
  Loading,
  Ready,
  Failed,
  NotConfigured
}

class AvatarColors {
  readonly foreground: Resource;
  readonly background: Resource;

  constructor(foreground: Resource, background: Resource) {
    this.foreground = foreground;
    this.background = background;
  }
}

const AVATAR_COLORS: AvatarColors[] = [
  new AvatarColors($r('app.color.senior_accent'), $r('app.color.senior_tint')),
  new AvatarColors($r('app.color.guardian_accent'), $r('app.color.guardian_tint')),
  new AvatarColors($r('app.color.success'), $r('app.color.success_tint'))
];

// Same contact, same color on every launch.
function avatarColors(contact: Contact): AvatarColors {
  let hash = 0;
  for (let i = 0; i < contact.id.length; i++) {
    hash = (hash * 31 + contact.id.charCodeAt(i)) % 1000003;
  }
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

@Component
struct ContactCard {
  @Require contact: Contact;
  onCall: () => void = () => {};

  build() {
    Row({ space: 16 }) {
      // The backend stores no photos yet, so every contact gets an initials avatar.
      Text(contactInitials(this.contact.name))
        .width(64)
        .height(64)
        .borderRadius(32)
        .textAlign(TextAlign.Center)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(avatarColors(this.contact).foreground)
        .backgroundColor(avatarColors(this.contact).background)

      Column({ space: 4 }) {
        Text(this.contact.name)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.contact.phone)
          .fontSize(17)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.phone_fill'))
          .fontSize(24)
          .fontColor([Color.White])
        Text('Call').fontSize(17).fontWeight(FontWeight.Medium).fontColor(Color.White)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.action_primary'))
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
    .accessibilityGroup(true)
    .accessibilityText(`Call ${this.contact.name}, ${this.contact.phone}`)
    .attributeModifier(new CareFocusStyle())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .stateStyles({
      normal: {
        .backgroundColor($r('app.color.surface'))
      },
      pressed: {
        .backgroundColor($r('app.color.divider'))
      }
    })
    .onClick(() => this.onCall())
  }
}

// Senior's trusted contacts from the backend; read-only, the guardian manages the list.
@Component
export struct ContactsList {
  @State phase: LoadPhase = LoadPhase.Loading;
  @State errorMessage: string = '';
  @State refreshFailed: boolean = false;
  @State refreshing: boolean = false;
  @State contacts: Contact[] = [];
  // Set while showing the copy saved on this phone because the backend was unreachable.
  @State cachedAt: number | undefined = undefined;

  aboutToAppear(): void {
    this.load();
  }

  private service(): ContactsService | undefined {
    return contactsService(this.getUIContext().getHostContext() as common.Context);
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
    try {
      const result = await service.load();
      this.contacts = result.contacts;
      this.cachedAt = result.cachedAt;
      this.refreshFailed = false;
      this.phase = LoadPhase.Ready;
    } catch (err) {
      this.errorMessage = describeBackendError(err as Object, 'Something went wrong while loading your contacts.');
      if (this.phase === LoadPhase.Ready) {
        this.refreshFailed = true;
      } else {
        this.phase = LoadPhase.Failed;
      }
    } finally {
      this.refreshing = false;
    }
  }

  private async callContact(contact: Contact): Promise<void> {
    const result = await openDialer(dialableNumber(contact.phone));
    if (result === DialResult.Opened) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: result === DialResult.Unavailable ? 'Calling is not available' : 'Could not open the phone app',
      message: `${result === DialResult.Unavailable ? 'This device cannot make phone calls.' :
        'Please try again.'} You can call ${contact.name} on ${contact.phone} from another phone.`,
      confirm: { value: 'OK', action: () => {} }
    });
  }

  private savedAtLabel(): string {
    const savedAt = new Date(this.cachedAt ?? 0);
    return savedAt.toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
  }

  @Builder
  notice(text: string) {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.wifi_slash'))
        .fontSize(22)
        .fontColor([$r('app.color.text_secondary')])
      Text(text)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(16)
    .backgroundColor($r('app.color.divider'))
  }

  @Builder
  contactList() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column({ space: 16 }) {
          Text('Tap a person to open the phone app. Confirm the call there.')
            .fontSize(17)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')

          if (this.cachedAt !== undefined) {
            this.notice(`You are offline. These contacts were saved on this phone on ${this.savedAtLabel()}.`)
          } else if (this.refreshFailed) {
            this.notice(`Showing the last loaded list. ${this.errorMessage}`)
          }

          if (this.contacts.length === 0) {
            Text('You have no contacts yet. Your guardian can add them in the Carely app.')
              .fontSize(18)
              .fontColor($r('app.color.text_secondary'))
          }

          ForEach(this.contacts, (contact: Contact) => {
            ContactCard({ contact: contact, onCall: () => this.callContact(contact) })
          }, (contact: Contact) => `${contact.id}|${contact.name}|${contact.phone}`)
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
    .onRefreshing(() => {
      this.load();
    })
  }

  build() {
    Column() {
      if (this.phase === LoadPhase.Ready) {
        this.contactList()
      } else if (this.phase === LoadPhase.Loading) {
        LoadingMessage({ message: 'Loading your contacts…' })
      } else if (this.phase === LoadPhase.Failed) {
        StatusMessage({
          icon: $r('sys.symbol.wifi_slash'),
          title: 'Contacts not loaded',
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
    }
    .width('100%')
    .height('100%')
  }
}

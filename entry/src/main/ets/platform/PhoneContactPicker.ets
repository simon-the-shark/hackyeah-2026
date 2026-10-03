import { contact } from '@kit.ContactsKit';

// System capability of the contact picker (and of the dial screen used by PhoneDialer).
const PICKER_CAPABILITY = 'SystemCapability.Applications.Contacts';

// Name and first phone number of the person chosen in the system contact picker.
export class PickedContact {
  readonly name: string;
  readonly phone: string;

  constructor(name: string, phone: string) {
    this.name = name;
    this.phone = phone;
  }
}

export function contactPickerAvailable(): boolean {
  return canIUse(PICKER_CAPABILITY);
}

// Opens the system contact picker for one person. The picker is system UI, so the app needs no
// READ_CONTACTS permission and only receives the person the user chooses.
// Resolves to undefined when the user cancels; rejects with a BusinessError when the picker cannot open.
export async function pickPhoneContact(): Promise<PickedContact | undefined> {
  const options: contact.ContactSelectionOptions = { isMultiSelect: false };
  const selected: contact.Contact[] = await contact.selectContacts(options);
  if (selected.length === 0) {
    return undefined;
  }
  const person = selected[0];
  const numbers = person.phoneNumbers ?? [];
  const firstNumber = numbers.length > 0 ? numbers[0].phoneNumber : '';
  return new PickedContact(person.name?.fullName ?? '', firstNumber ?? '');
}

import { Contact } from '../models/Contact';

// Limits enforced by the backend (`contactBody.name` and `schemas.phone` in backend/src).
export const CONTACT_NAME_MAX_LENGTH: number = 80;
// Optional "+" plus up to 20 digits, spaces, brackets or dashes.
export const CONTACT_PHONE_MAX_LENGTH: number = 21;

// Same rule as the backend's `phone` schema.
const PHONE_PATTERN: RegExp = new RegExp('^\\+?[0-9 ()-]{3,20}$');

// Inline error for the name field, or '' when the backend will accept it.
export function contactNameError(name: string): string {
  const trimmed = name.trim();
  if (trimmed.length === 0) {
    return 'Enter a name.';
  }
  if (trimmed.length > CONTACT_NAME_MAX_LENGTH) {
    return `Use at most ${CONTACT_NAME_MAX_LENGTH} characters.`;
  }
  return '';
}

// Inline error for the phone field, or '' when the backend will accept it.
export function contactPhoneError(phone: string): string {
  const trimmed = phone.trim();
  if (trimmed.length === 0) {
    return 'Enter a phone number.';
  }
  if (!PHONE_PATTERN.test(trimmed)) {
    return 'Use 3 to 20 digits. You may start with + and use spaces, brackets or dashes.';
  }
  return '';
}

// Brings a number from the phone's address book into the backend's format, e.g.
// "+48 600.100.200" becomes "+48 600100200". The result is still validated before saving.
export function normalizePhone(raw: string): string {
  const trimmed = raw.trim();
  const allowed = trimmed.replace(new RegExp('\\s', 'g'), ' ').replace(new RegExp('[^0-9 ()-]', 'g'), '')
    .replace(new RegExp(' +', 'g'), ' ').trim();
  return trimmed.startsWith('+') ? `+${allowed}` : allowed;
}

// New contacts go to the end of the guardian's order.
export function nextSortOrder(contacts: Contact[]): number {
  let highest = -1;
  contacts.forEach((contact: Contact) => {
    highest = Math.max(highest, contact.sortOrder);
  });
  return highest + 1;
}

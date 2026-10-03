import { Contact } from '../models/Contact';

// Guardian order first, then name, so the list is stable even when sort orders tie.
export function sortContacts(contacts: Contact[]): Contact[] {
  return contacts.slice().sort((a: Contact, b: Contact) =>
    a.sortOrder !== b.sortOrder ? a.sortOrder - b.sortOrder : a.name.localeCompare(b.name));
}

// Up to two letters from the first words of the name, ignoring bracketed notes such as "(son)".
export function contactInitials(name: string): string {
  const words = name.replace(new RegExp('\\(.*?\\)', 'g'), ' ').trim().split(new RegExp('\\s+'))
    .filter((word: string) => word.length > 0);
  if (words.length === 0) {
    return '?';
  }
  const letters = words.length === 1 ? words[0].substring(0, 1) :
    `${words[0].substring(0, 1)}${words[1].substring(0, 1)}`;
  return letters.toUpperCase();
}

// Digits and a leading "+" only, which is what the dialer expects.
export function dialableNumber(phone: string): string {
  const trimmed = phone.trim();
  const digits = trimmed.replace(new RegExp('[^0-9]', 'g'), '');
  return trimmed.startsWith('+') ? `+${digits}` : digits;
}

interface CachedContactEntry {
  id?: string;
  name?: string;
  phone?: string;
  sortOrder?: number;
}

class CachedContactJson {
  id: string;
  name: string;
  phone: string;
  sortOrder: number;

  constructor(contact: Contact) {
    this.id = contact.id;
    this.name = contact.name;
    this.phone = contact.phone;
    this.sortOrder = contact.sortOrder;
  }
}

export function encodeContacts(contacts: Contact[]): string[] {
  return contacts.map((contact: Contact) => JSON.stringify(new CachedContactJson(contact)));
}

// Malformed entries are dropped instead of hiding the whole list.
export function decodeContacts(entries: string[]): Contact[] {
  const contacts: Contact[] = [];
  entries.forEach((entry: string) => {
    try {
      const value = JSON.parse(entry) as CachedContactEntry;
      if (typeof value.id === 'string' && typeof value.name === 'string' && typeof value.phone === 'string') {
        contacts.push(new Contact(value.id, value.name, value.phone,
          typeof value.sortOrder === 'number' ? value.sortOrder : 0));
      }
    } catch (err) {
      // Not JSON; skip it.
    }
  });
  return contacts;
}

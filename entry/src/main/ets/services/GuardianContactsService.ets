import { Contact } from '../models/Contact';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { ContactsApi } from '../providers/backend/ContactsApi';
import { apiSession } from './CareApi';
import { sortContacts } from './ContactList';

export const NOT_GUARDIAN_MESSAGE = 'This phone is not paired as a guardian. Sign out and set it up again as a guardian.';

// True when this device holds a paired guardian session for a senior.
export function guardianSessionReady(): boolean {
  return apiSession.configured() && apiSession.role === 'guardian';
}

// Guardian management of the senior's trusted contacts. Authenticates with the paired guardian session
// (`apiSession` from pairing) and reuses the typed contacts client the senior Contacts tab uses.
export class GuardianContactsService {
  async list(): Promise<Contact[]> {
    return sortContacts(await this.api().contacts(apiSession.seniorId));
  }

  async create(name: string, phone: string, sortOrder: number): Promise<Contact> {
    return this.api().create(apiSession.seniorId, name, phone, sortOrder);
  }

  async update(original: Contact, name: string, phone: string): Promise<Contact> {
    return this.api().update(apiSession.seniorId, original, name, phone);
  }

  async remove(contact: Contact): Promise<void> {
    await this.api().remove(apiSession.seniorId, contact.id);
  }

  // Built per call so pairing again or signing out takes effect immediately.
  private api(): ContactsApi {
    if (!guardianSessionReady()) {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', NOT_GUARDIAN_MESSAGE);
    }
    return new ContactsApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
  }
}

export const guardianContacts: GuardianContactsService = new GuardianContactsService();

export function isVersionConflict(err: Object): boolean {
  return err instanceof ApiError && err.status === 409 && err.code === 'version_conflict';
}

export function isNotFound(err: Object): boolean {
  return err instanceof ApiError && err.status === 404;
}

// Guardian-facing explanation of a failed contacts call. `fallback` describes what could not be done.
export function describeGuardianContactsError(err: Object, fallback: string): string {
  if (!(err instanceof ApiError)) {
    return fallback;
  }
  if (err.kind === ApiErrorKind.Network) {
    return 'Cannot reach the Carely server. Check the internet connection and try again.';
  }
  if (err.kind === ApiErrorKind.InvalidResponse) {
    return `${fallback} The server sent a response this app cannot read.`;
  }
  if (err.status === 401) {
    return 'This phone\'s pairing is no longer valid. Sign out and pair it again.';
  }
  if (err.status === 403) {
    return err.message === NOT_GUARDIAN_MESSAGE ? NOT_GUARDIAN_MESSAGE :
      'This phone is not allowed to manage this senior\'s contacts.';
  }
  if (err.status === 404) {
    return 'This contact no longer exists. It may have been deleted on another device.';
  }
  if (err.status === 400) {
    return 'The server did not accept these details. Check the name and phone number.';
  }
  return fallback;
}

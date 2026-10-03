import { common } from '@kit.AbilityKit';
import { Contact } from '../models/Contact';
import { ContactsCacheStore } from '../platform/ContactsCacheStore';
import { ApiError, ApiErrorKind } from '../providers/backend/BackendClient';
import { ContactsApi } from '../providers/backend/ContactsApi';
import { sortContacts } from './ContactList';
import { SeniorAccount, seniorAccount } from './SeniorAccount';

export class ContactListResult {
  readonly contacts: Contact[];
  // Set when the backend was unreachable and the list comes from this phone; the time it was last loaded.
  readonly cachedAt: number | undefined;

  constructor(contacts: Contact[], cachedAt: number | undefined) {
    this.contacts = contacts;
    this.cachedAt = cachedAt;
  }
}

// Trusted contacts from the backend. The last list is kept on the phone, because calling someone
// must keep working when the network does not.
export class ContactsService {
  private readonly account: SeniorAccount;
  private readonly api: ContactsApi;
  private readonly cache: ContactsCacheStore;

  constructor(account: SeniorAccount, cache: ContactsCacheStore) {
    this.account = account;
    this.api = new ContactsApi(account.client);
    this.cache = cache;
  }

  async load(): Promise<ContactListResult> {
    try {
      const seniorId = await this.account.currentSeniorId();
      const contacts = sortContacts(await this.api.contacts(seniorId));
      await this.cache.save(contacts, Date.now());
      return new ContactListResult(contacts, undefined);
    } catch (err) {
      const cached = err instanceof ApiError && err.kind === ApiErrorKind.Network ? this.cache.load() : undefined;
      if (cached === undefined) {
        throw err as Error;
      }
      return new ContactListResult(sortContacts(cached.contacts), cached.savedAt);
    }
  }
}

let sharedService: ContactsService | undefined = undefined;

// Undefined until this phone is paired with a Carely care plan.
export function contactsService(context: common.Context): ContactsService | undefined {
  if (sharedService === undefined) {
    const account = seniorAccount();
    if (account !== undefined) {
      sharedService = new ContactsService(account, new ContactsCacheStore(context));
    }
  }
  return sharedService;
}

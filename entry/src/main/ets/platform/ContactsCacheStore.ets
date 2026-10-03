import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Contact } from '../models/Contact';
import { decodeContacts, encodeContacts } from '../services/ContactList';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'ContactsCacheStore';
const STORE_NAME = 'contacts-cache';
const CONTACTS_KEY = 'contacts';
const SAVED_AT_KEY = 'savedAt';

export class CachedContacts {
  readonly contacts: Contact[];
  // Milliseconds since the epoch when the list was last loaded from the backend.
  readonly savedAt: number;

  constructor(contacts: Contact[], savedAt: number) {
    this.contacts = contacts;
    this.savedAt = savedAt;
  }
}

// Last contact list from the backend, so the senior can still call someone while offline.
export class ContactsCacheStore {
  private readonly context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  load(): CachedContacts | undefined {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: STORE_NAME });
      const savedAt = store.getSync(SAVED_AT_KEY, 0) as number;
      if (savedAt === 0) {
        return undefined;
      }
      const empty: string[] = [];
      return new CachedContacts(decodeContacts(store.getSync(CONTACTS_KEY, empty) as string[]), savedAt);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to load cached contacts: ${(err as BusinessError).message}`);
      return undefined;
    }
  }

  async save(contacts: Contact[], savedAt: number): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: STORE_NAME });
      store.putSync(CONTACTS_KEY, encodeContacts(contacts));
      store.putSync(SAVED_AT_KEY, savedAt);
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to cache contacts: ${(err as BusinessError).message}`);
    }
  }
}

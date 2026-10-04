import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Contact } from '../models/Contact';
import { decodeContacts, encodeContacts } from '../services/ContactList';
import { SafePreferences } from '../services/SafePreferences';

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
  private readonly store: SafePreferences = new SafePreferences(STORE_NAME);

  constructor(context: common.Context) {
    this.context = context;
  }

  async load(): Promise<CachedContacts | undefined> {
    const prefs = await this.store.open(this.context);
    if (prefs === undefined) {
      return undefined;
    }
    try {
      const savedAt = await prefs.get(SAVED_AT_KEY, 0) as number;
      if (savedAt === 0) {
        return undefined;
      }
      const empty: string[] = [];
      return new CachedContacts(decodeContacts(await prefs.get(CONTACTS_KEY, empty) as string[]), savedAt);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load cached contacts');
      return undefined;
    }
  }

  // Best effort: a missing cache only means the list is unavailable offline.
  async save(contacts: Contact[], savedAt: number): Promise<void> {
    const prefs = await this.store.open(this.context);
    if (prefs === undefined) {
      return;
    }
    try {
      await prefs.put(CONTACTS_KEY, encodeContacts(contacts));
      await prefs.put(SAVED_AT_KEY, savedAt);
      await prefs.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to cache contacts');
    }
  }

  async clear(): Promise<void> {
    await this.store.clear(this.context);
  }
}

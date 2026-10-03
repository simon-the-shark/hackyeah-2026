import { common } from '@kit.AbilityKit';
import { apiSession } from './CareApi';
import { SafePreferences } from './SafePreferences';

const STORE_NAME = 'carely_api_session';
const DEFAULT_BASE_URL = 'http://localhost:8787';

/**
 * Persists the paired device session so SOS and location sharing survive an app
 * restart. Storage failures fall back to an empty session, which shows setup
 * rather than a half-working senior experience.
 */
export class ApiSessionStore {
  private readonly store = new SafePreferences(STORE_NAME);

  async restore(context: common.Context): Promise<void> {
    apiSession.baseUrl = await this.store.getString(context, 'baseUrl', DEFAULT_BASE_URL);
    apiSession.token = await this.store.getString(context, 'token', '');
    apiSession.seniorId = await this.store.getString(context, 'seniorId', '');
    apiSession.role = await this.store.getString(context, 'role', '');
  }

  async save(context: common.Context): Promise<void> {
    await this.store.putStrings(context, {
      'baseUrl': apiSession.baseUrl,
      'token': apiSession.token,
      'seniorId': apiSession.seniorId,
      'role': apiSession.role
    });
  }

  /**
   * Clears the in-memory session before touching storage, so signing out always
   * takes effect even when persistence fails. Leaving a token in memory after an
   * apparent sign-out would keep sending events on the user's behalf.
   */
  async clear(context: common.Context): Promise<void> {
    apiSession.clear();
    await this.store.clear(context);
  }
}

export const apiSessionStore: ApiSessionStore = new ApiSessionStore();
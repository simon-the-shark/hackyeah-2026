import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { apiSession } from './CareApi';

const STORE_NAME = 'carely_api_session';

export class ApiSessionStore {
  restore(context: common.Context): void {
    const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    apiSession.baseUrl = prefs.getSync('baseUrl', 'http://localhost:8787') as string;
    apiSession.token = prefs.getSync('token', '') as string;
    apiSession.seniorId = prefs.getSync('seniorId', '') as string;
    apiSession.role = prefs.getSync('role', '') as string;
  }

  async save(context: common.Context): Promise<void> {
    const prefs = await preferences.getPreferences(context, STORE_NAME);
    await prefs.put('baseUrl', apiSession.baseUrl);
    await prefs.put('token', apiSession.token);
    await prefs.put('seniorId', apiSession.seniorId);
    await prefs.put('role', apiSession.role);
    await prefs.flush();
  }

  async clear(context: common.Context): Promise<void> {
    apiSession.clear();
    const prefs = await preferences.getPreferences(context, STORE_NAME);
    await prefs.clear();
    await prefs.flush();
  }
}

export const apiSessionStore: ApiSessionStore = new ApiSessionStore();

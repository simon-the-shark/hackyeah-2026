import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { watchSession } from './WatchApi';

const STORE_NAME = 'carely_watch_session';

/**
 * Keeps the watch's pairing across restarts. Like the phone app's SafePreferences,
 * it never throws: a storage failure leaves the watch unpaired instead of crashing.
 */
export class WatchSessionStore {
  private cached: preferences.Preferences | undefined = undefined;

  private async open(context: common.Context): Promise<preferences.Preferences | undefined> {
    if (this.cached !== undefined) {
      return this.cached;
    }
    try {
      this.cached = await preferences.getPreferences(context, STORE_NAME);
    } catch (error) {
      console.error(`[WatchSessionStore] open failed: ${JSON.stringify(error)}`);
    }
    return this.cached;
  }

  private async read(prefs: preferences.Preferences, key: string, fallback: string): Promise<string> {
    try {
      const value = await prefs.get(key, fallback);
      return typeof value === 'string' ? value : fallback;
    } catch (error) {
      return fallback;
    }
  }

  async restore(context: common.Context): Promise<void> {
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return;
    }
    watchSession.baseUrl = await this.read(prefs, 'baseUrl', watchSession.baseUrl);
    watchSession.token = await this.read(prefs, 'token', '');
    watchSession.seniorId = await this.read(prefs, 'seniorId', '');
    watchSession.deviceId = await this.read(prefs, 'deviceId', '');
  }

  async save(context: common.Context): Promise<void> {
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return;
    }
    try {
      await prefs.put('baseUrl', watchSession.baseUrl);
      await prefs.put('token', watchSession.token);
      await prefs.put('seniorId', watchSession.seniorId);
      await prefs.put('deviceId', watchSession.deviceId);
      await prefs.flush();
    } catch (error) {
      console.error('[WatchSessionStore] save failed');
    }
  }

  /** Clears the in-memory session first, so unpairing always takes effect even if storage fails. */
  async clear(context: common.Context): Promise<void> {
    watchSession.clear();
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return;
    }
    try {
      await prefs.clear();
      await prefs.flush();
    } catch (error) {
      console.error('[WatchSessionStore] clear failed');
    }
  }
}

export const watchSessionStore: WatchSessionStore = new WatchSessionStore();

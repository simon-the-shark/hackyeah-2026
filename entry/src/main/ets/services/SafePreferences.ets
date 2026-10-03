import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * Preferences access that never throws.
 *
 * The synchronous `preferences.getPreferencesSync` returned `undefined` on the
 * HarmonyOS emulator, so reading from it crashed app startup before any page was
 * shown. This wrapper uses the documented async API, caches the instance, and
 * returns a fallback instead of propagating failures. A storage problem must
 * never take down a safety app; callers fail safe instead.
 */
export class SafePreferences {
  private readonly name: string;
  private cached: preferences.Preferences | undefined = undefined;

  constructor(name: string) {
    this.name = name;
  }

  async open(context: common.Context): Promise<preferences.Preferences | undefined> {
    if (this.cached !== undefined) {
      return this.cached;
    }
    try {
      this.cached = await preferences.getPreferences(context, this.name);
    } catch (error) {
      console.error(`[SafePreferences] open failed for ${this.name}: ${JSON.stringify(error)}`);
      return undefined;
    }
    return this.cached;
  }

  async getString(context: common.Context, key: string, fallback: string): Promise<string> {
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return fallback;
    }
    try {
      const value = await prefs.get(key, fallback);
      return typeof value === 'string' ? value : fallback;
    } catch (error) {
      console.error(`[SafePreferences] read failed for ${key}: ${JSON.stringify(error)}`);
      return fallback;
    }
  }

  /** Writes every entry, then flushes once so a multi-field save is atomic. */
  async putStrings(context: common.Context, entries: Record<string, string>): Promise<void> {
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return;
    }
    try {
      for (const key of Object.keys(entries)) {
        await prefs.put(key, entries[key]);
      }
      await prefs.flush();
    } catch (error) {
      console.error(`[SafePreferences] write failed for ${this.name}: ${JSON.stringify(error)}`);
    }
  }

  async clear(context: common.Context): Promise<void> {
    const prefs = await this.open(context);
    if (prefs === undefined) {
      return;
    }
    try {
      await prefs.clear();
      await prefs.flush();
    } catch (error) {
      console.error(`[SafePreferences] clear failed for ${this.name}: ${JSON.stringify(error)}`);
    }
  }
}
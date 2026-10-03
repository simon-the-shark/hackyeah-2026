import { common } from '@kit.AbilityKit';
import { SafePreferences } from '../services/SafePreferences';

const STORE_NAME = 'wellbeing-checkins';
const SHARED_KEY = 'shared';

// Check-ins the senior shared (sent or still waiting for a connection), kept only on this phone.
export class CheckInStore {
  private readonly context: common.Context;
  private readonly store: SafePreferences = new SafePreferences(STORE_NAME);

  constructor(context: common.Context) {
    this.context = context;
  }

  async load(): Promise<string> {
    return this.store.getString(this.context, SHARED_KEY, '[]');
  }

  async save(encoded: string): Promise<void> {
    await this.store.putStrings(this.context, { 'shared': encoded });
  }
}

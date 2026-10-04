import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DoseRecord } from '../models/Medication';
import { decodePendingDoses, encodePendingDoses } from '../services/MedicationSchedule';
import { SafePreferences } from '../services/SafePreferences';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'DoseOutboxStore';
const STORE_NAME = 'dose-outbox';
const PENDING_KEY = 'pending';

// Dose answers recorded while the backend was unreachable, kept on the device until they are delivered.
export class DoseOutboxStore {
  private readonly context: common.Context;
  private readonly store: SafePreferences = new SafePreferences(STORE_NAME);

  constructor(context: common.Context) {
    this.context = context;
  }

  async load(): Promise<DoseRecord[]> {
    const prefs = await this.store.open(this.context);
    if (prefs === undefined) {
      return [];
    }
    try {
      const empty: string[] = [];
      return decodePendingDoses(await prefs.get(PENDING_KEY, empty) as string[]);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load pending doses');
      return [];
    }
  }

  // Throws when the answers could not be stored, so the senior is never told an answer is saved when it is not.
  async save(records: DoseRecord[]): Promise<void> {
    const prefs = await this.store.open(this.context);
    if (prefs === undefined) {
      throw new Error('This phone could not save your answer.');
    }
    try {
      await prefs.put(PENDING_KEY, encodePendingDoses(records));
      await prefs.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to save pending doses');
      throw new Error('This phone could not save your answer.');
    }
  }

  async clear(): Promise<void> {
    await this.store.clear(this.context);
  }
}

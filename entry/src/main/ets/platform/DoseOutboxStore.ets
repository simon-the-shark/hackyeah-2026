import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DoseRecord } from '../models/Medication';
import { decodePendingDoses, encodePendingDoses } from '../services/MedicationSchedule';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'DoseOutboxStore';
const STORE_NAME = 'dose-outbox';
const PENDING_KEY = 'pending';

// Dose answers recorded while the backend was unreachable, kept on the device until they are delivered.
export class DoseOutboxStore {
  private readonly context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  load(): DoseRecord[] {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: STORE_NAME });
      const empty: string[] = [];
      return decodePendingDoses(store.getSync(PENDING_KEY, empty) as string[]);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to load pending doses: ${(err as BusinessError).message}`);
      return [];
    }
  }

  async save(records: DoseRecord[]): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: STORE_NAME });
      store.putSync(PENDING_KEY, encodePendingDoses(records));
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to save pending doses: ${(err as BusinessError).message}`);
    }
  }
}

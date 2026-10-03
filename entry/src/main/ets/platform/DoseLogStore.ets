import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { decodeTakenDoses, encodeTakenDoses } from '../services/MedicationSchedule';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'DoseLogStore';
const STORE_NAME = 'dose-log';
const TAKEN_KEY = 'taken';

// Keeps taken-dose times on the device until dose records are sent to the backend.
export function loadTakenDoses(context: common.Context, day: string): Map<string, number> {
  try {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    const empty: string[] = [];
    return decodeTakenDoses(store.getSync(TAKEN_KEY, empty) as string[], day);
  } catch (err) {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to load dose log: ${(err as BusinessError).message}`);
    return new Map<string, number>();
  }
}

export function saveTakenDoses(context: common.Context, taken: Map<string, number>): void {
  try {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(TAKEN_KEY, encodeTakenDoses(taken));
    store.flush().catch((err: BusinessError) => {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to persist dose log: ${err.message}`);
    });
  } catch (err) {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to save dose log: ${(err as BusinessError).message}`);
  }
}

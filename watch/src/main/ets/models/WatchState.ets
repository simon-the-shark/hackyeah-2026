/**
 * AppStorage keys shared by the monitor (which owns sensors and network) and the
 * watch screens (which only display). Components bind with @StorageProp.
 */
export const K_PAIRED = 'watchPaired';
/** Latest heart rate shown on the watch; 0 while there is none. */
export const K_HR_BPM = 'hrBpm';
export const K_HR_AT = 'hrAt';
/** One of the MonitorState values below. */
export const K_HR_STATE = 'hrState';
/** True when readings come from a virtual or emulated sensor. */
export const K_HR_SIMULATED = 'hrSimulated';
/** True while an out-of-range alert was sent and the reading is not yet back in range. */
export const K_HR_ALERTING = 'hrAlerting';
export const K_HR_SHARED_AT = 'hrSharedAt';
export const K_LOC_STATE = 'locState';
export const K_LOC_SHARED_AT = 'locSharedAt';
export const K_BATTERY = 'battery';
/** Last problem reaching the care service, shown on the status screen; empty when fine. */
export const K_SYNC_ERROR = 'syncError';

export class MonitorState {
  static readonly OFF: string = 'off';
  static readonly STARTING: string = 'starting';
  static readonly ACTIVE: string = 'active';
  static readonly DENIED: string = 'denied';
  static readonly MISSING: string = 'missing';
  static readonly FAILED: string = 'failed';
}

export function initWatchState(paired: boolean): void {
  AppStorage.setOrCreate<boolean>(K_PAIRED, paired);
  AppStorage.setOrCreate<number>(K_HR_BPM, 0);
  AppStorage.setOrCreate<number>(K_HR_AT, 0);
  AppStorage.setOrCreate<string>(K_HR_STATE, MonitorState.OFF);
  AppStorage.setOrCreate<boolean>(K_HR_SIMULATED, false);
  AppStorage.setOrCreate<boolean>(K_HR_ALERTING, false);
  AppStorage.setOrCreate<number>(K_HR_SHARED_AT, 0);
  AppStorage.setOrCreate<string>(K_LOC_STATE, MonitorState.OFF);
  AppStorage.setOrCreate<number>(K_LOC_SHARED_AT, 0);
  AppStorage.setOrCreate<number>(K_BATTERY, -1);
  AppStorage.setOrCreate<string>(K_SYNC_ERROR, '');
}

export function formatClock(timestamp: number): string {
  if (timestamp <= 0) {
    return '--:--';
  }
  const date = new Date(timestamp);
  return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
}

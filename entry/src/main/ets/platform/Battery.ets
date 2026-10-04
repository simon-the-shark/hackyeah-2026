import { batteryInfo } from '@kit.BasicServicesKit';

/** Battery charge in percent, or -1 when it cannot be read. */
export function batteryPercent(): number {
  try {
    const value = batteryInfo.batterySOC;
    return value >= 0 && value <= 100 ? Math.round(value) : -1;
  } catch (error) {
    return -1;
  }
}

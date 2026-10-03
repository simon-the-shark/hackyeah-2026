import { batteryInfo, deviceInfo } from '@kit.BasicServicesKit';

/**
 * True on a DevEco Studio emulator, whose sensors and GPS are driven from the
 * emulator's panels. The phone emulator reports `const.product.model=emulator`
 * (checked with hdc); the wearable image is assumed to do the same.
 */
export function runningOnEmulator(): boolean {
  return deviceInfo.productModel.toLowerCase().includes('emulator');
}

/** Battery charge in percent, or -1 when it cannot be read. */
export function batteryPercent(): number {
  try {
    const value = batteryInfo.batterySOC;
    return value >= 0 && value <= 100 ? Math.round(value) : -1;
  } catch (error) {
    return -1;
  }
}

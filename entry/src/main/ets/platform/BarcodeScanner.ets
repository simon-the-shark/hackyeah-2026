import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'BarcodeScanner';
const SCAN_CAPABILITY = 'SystemCapability.Multimedia.Scan.ScanBarcode';
const USER_CANCELLED = 1000500002;

export enum ScanStatus {
  Scanned,
  Cancelled,
  Unavailable
}

export class ScanOutcome {
  readonly status: ScanStatus;
  readonly value: string;

  constructor(status: ScanStatus, value: string = '') {
    this.status = status;
    this.value = value;
  }
}

export function isBarcodeScanSupported(): boolean {
  return canIUse(SCAN_CAPABILITY);
}

// Opens the system Scan Kit camera UI, which handles camera access itself.
export async function scanProductBarcode(context: common.Context): Promise<ScanOutcome> {
  if (!isBarcodeScanSupported()) {
    return new ScanOutcome(ScanStatus.Unavailable);
  }
  const options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: false,
    enableAlbum: false
  };
  try {
    const result = await scanBarcode.startScanForResult(context, options);
    return new ScanOutcome(ScanStatus.Scanned, result.originalValue);
  } catch (err) {
    const error = err as BusinessError;
    if (error.code === USER_CANCELLED) {
      return new ScanOutcome(ScanStatus.Cancelled);
    }
    hilog.error(LOG_DOMAIN, LOG_TAG, `Scan failed. Code: ${error.code}, message: ${error.message}`);
    return new ScanOutcome(ScanStatus.Unavailable);
  }
}

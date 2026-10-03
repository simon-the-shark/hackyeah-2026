import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { call } from '@kit.TelephonyKit';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'PhoneDialer';
const DIAL_CAPABILITY = 'SystemCapability.Applications.Contacts';

export enum DialResult {
  Opened,
  Unavailable,
  Failed
}

// Opens the system dial screen with the number filled in; the senior confirms the call there.
// Needs no permission, unlike placing a call directly.
export async function openDialer(phoneNumber: string): Promise<DialResult> {
  if (!canIUse(DIAL_CAPABILITY)) {
    return DialResult.Unavailable;
  }
  try {
    await call.makeCall(phoneNumber);
    return DialResult.Opened;
  } catch (err) {
    const error = err as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot open the dialer. Code: ${error.code}, message: ${error.message}`);
    return DialResult.Failed;
  }
}

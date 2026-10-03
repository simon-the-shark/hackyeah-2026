import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'Microphone';
const MICROPHONE: Permissions = 'ohos.permission.MICROPHONE';

export enum MicrophoneAccess {
  Granted,
  Denied,
  Failed
}

/** Asks for the microphone (user_grant). After an earlier refusal the system answers without a dialog. */
export async function requestMicrophone(context: common.UIAbilityContext): Promise<MicrophoneAccess> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [MICROPHONE]);
    return result.authResults[0] === 0 ? MicrophoneAccess.Granted : MicrophoneAccess.Denied;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'Microphone request failed: %{public}d', (error as BusinessError).code);
    return MicrophoneAccess.Failed;
  }
}

/** Opens the system dialog that lets the user turn the microphone back on for Carely. */
export async function openMicrophoneSettings(context: common.UIAbilityContext): Promise<boolean> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionOnSetting(context, [MICROPHONE]);
    return result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'Microphone settings failed: %{public}d', (error as BusinessError).code);
    return false;
  }
}

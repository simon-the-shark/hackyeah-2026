import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export const LOCATION_PERMISSIONS: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
export const HEALTH_PERMISSIONS: Permissions[] = ['ohos.permission.READ_HEALTH_DATA'];

/** Asks for the permissions; true when the first (the essential one) was granted. */
export async function requestPermissions(context: common.UIAbilityContext, permissions: Permissions[]): Promise<boolean> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions);
    return result.authResults.length > 0 && result.authResults[0] === 0;
  } catch (error) {
    console.error(`[Permissions] request failed: ${(error as BusinessError).code}`);
    return false;
  }
}

/** Error code of `requestGlobalSwitch` when the switch is already on. */
const SWITCH_ALREADY_ON = 12100013;

/** Asks the system to turn on the device-wide location switch (permissions alone are not enough). */
export async function requestLocationSwitch(context: common.UIAbilityContext): Promise<boolean> {
  try {
    return await abilityAccessCtrl.createAtManager().requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION);
  } catch (error) {
    const code = (error as BusinessError).code;
    if (code === SWITCH_ALREADY_ON) {
      return true;
    }
    console.error(`[Permissions] location switch request failed: ${code}`);
    return false;
  }
}

/** After a denial the system no longer asks, so the user is taken to the settings dialog instead. */
export async function requestPermissionsInSettings(context: common.UIAbilityContext,
  permissions: Permissions[]): Promise<boolean> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionOnSetting(context, permissions);
    return result.length > 0 && result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (error) {
    console.error(`[Permissions] settings request failed: ${(error as BusinessError).code}`);
    return false;
  }
}

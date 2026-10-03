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

import { common } from '@kit.AbilityKit';
import { PAIRING_EXPIRED_KEY } from '../providers/backend/BackendClient';
import { apiSessionStore } from '../services/ApiSessionStore';
import { apiSession } from '../services/CareApi';

export { PAIRING_EXPIRED_MESSAGE } from '../services/BackendErrors';

/** Clears pairing, then returns to setup. Signing out must always take effect. */
export async function signOut(ui: UIContext, navStack: NavPathStack): Promise<void> {
  await apiSessionStore.clear(ui.getHostContext() as common.UIAbilityContext);
  AppStorage.set('paired', false);
  navStack.clear();
}

function signOutMessage(): string {
  if (AppStorage.get<boolean>(PAIRING_EXPIRED_KEY) === true) {
    return 'This phone\'s pairing no longer works. After signing out you can set it up again.';
  }
  if (apiSession.role === 'senior') {
    return 'Your guardian will stop receiving your SOS, location and medicine answers. ' +
      'This account cannot be signed back into; setting up again creates a new account that must be paired again.';
  }
  return 'You will stop receiving alerts. To pair again you will need a new code from the senior\'s phone.';
}

/** Sign-out is hard to undo (a senior account cannot be recovered), so it always asks first. */
export function confirmSignOut(ui: UIContext, navStack: NavPathStack): void {
  ui.showAlertDialog({
    title: 'Sign out of Carely?',
    message: signOutMessage(),
    autoCancel: true,
    primaryButton: {
      value: 'Cancel',
      action: () => {
      }
    },
    secondaryButton: {
      value: 'Sign out',
      fontColor: $r('app.color.sos'),
      action: () => {
        signOut(ui, navStack);
      }
    }
  });
}

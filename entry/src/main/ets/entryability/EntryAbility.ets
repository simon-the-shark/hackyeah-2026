import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { apiSession } from '../services/CareApi';
import { apiSessionStore } from '../services/ApiSessionStore';
import { locationSharing } from '../services/LocationSharing';
import { guardianAlertWatcher } from '../services/GuardianAlertWatcher';
import { OPEN_ALERT_ID_KEY, OPEN_ALERT_NAME_KEY, OPEN_ALERT_NAME_PARAM, OPEN_ALERT_PARAM } from '../platform/Notifications';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.routeAlertNotification(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.routeAlertNotification(want);
  }

  /** A tapped alert notification carries the alert id; AlertDeepLink opens it. */
  private routeAlertNotification(want: Want): void {
    const alertId = want.parameters?.[OPEN_ALERT_PARAM];
    if (typeof alertId === 'string' && alertId !== '') {
      const seniorName = want.parameters?.[OPEN_ALERT_NAME_PARAM];
      AppStorage.setOrCreate<string>(OPEN_ALERT_NAME_KEY, typeof seniorName === 'string' ? seniorName : '');
      AppStorage.setOrCreate<string>(OPEN_ALERT_ID_KEY, alertId);
    }
  }

  onDestroy(): void {
    locationSharing.destroy();
    guardianAlertWatcher.stop();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onWindowStageCreate');
    this.restoreSessionAndLoad(windowStage);
  }

  /**
   * Restores the saved pairing before the first page renders, so a returning
   * senior does not see the setup screen. A storage failure must still leave a
   * usable app, so the session is treated as empty instead of blocking startup.
   */
  private async restoreSessionAndLoad(windowStage: window.WindowStage): Promise<void> {
    try {
      await apiSessionStore.restore(this.context);
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Session restore failed. Cause: %{public}s', JSON.stringify(error));
    }
    AppStorage.setOrCreate('paired', apiSession.configured());
    locationSharing.restore(this.context);
    guardianAlertWatcher.pollNow();

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }


  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    locationSharing.resume(this.context);
    // Guardian alerts are polled only while Carely is in the foreground; there is no remote push.
    guardianAlertWatcher.start(this.context);
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    locationSharing.pause();
    guardianAlertWatcher.stop();
  }
}

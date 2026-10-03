import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { initWatchState, K_PAIRED } from '../models/WatchState';
import { watchSession } from '../services/WatchApi';
import { watchMonitor } from '../services/WatchMonitor';
import { watchSessionStore } from '../services/WatchSessionStore';

const DOMAIN = 0x0000;

export default class WatchAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    initWatchState(false);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.restoreSessionAndLoad(windowStage);
  }

  /** Restores pairing before the first screen, so a paired watch opens straight on SOS. */
  private async restoreSessionAndLoad(windowStage: window.WindowStage): Promise<void> {
    await watchSessionStore.restore(this.context);
    AppStorage.set<boolean>(K_PAIRED, watchSession.configured());
    windowStage.loadContent('pages/WatchIndex', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'carely-watch', 'Failed to load the content: %{public}s', JSON.stringify(err));
      }
    });
  }

  onForeground(): void {
    watchMonitor.resume();
  }

  /** Sensors and location must not run in the background. */
  onBackground(): void {
    watchMonitor.pause();
  }
}

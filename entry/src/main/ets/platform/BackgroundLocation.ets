import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';

/** Public continuous-task API (start/stop API 9; cancellation callback API 15). */
export class BackgroundLocation {
  private listening: boolean = false;
  private active: boolean = false;
  private readonly cancelled: (info: backgroundTaskManager.ContinuousTaskCancelInfo) => void;

  constructor(onCancelled: () => void) {
    this.cancelled = (_info: backgroundTaskManager.ContinuousTaskCancelInfo): void => {
      this.active = false;
      onCancelled();
    };
  }

  async start(context: common.UIAbilityContext): Promise<void> {
    try {
      if (!this.listening) {
        backgroundTaskManager.on('continuousTaskCancel', this.cancelled);
        this.listening = true;
      }
      const agent = await wantAgent.getWantAgent({
        wants: [{ bundleName: context.abilityInfo.bundleName, abilityName: context.abilityInfo.name }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 7301,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      });
      await backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.LOCATION, agent);
      this.active = true;
    } catch (error) {
      throw new Error(`Background location task was refused (error ${(error as BusinessError).code}).`);
    }
  }

  async stop(context: common.UIAbilityContext): Promise<void> {
    try {
      // Remove our listener first: an intentional stop must not look like system cancellation.
      if (this.listening) {
        backgroundTaskManager.off('continuousTaskCancel', this.cancelled);
        this.listening = false;
      }
      if (this.active) {
        await backgroundTaskManager.stopBackgroundRunning(context);
        this.active = false;
      }
    } catch (error) {
      throw new Error(`Background location task could not stop (error ${(error as BusinessError).code}).`);
    }
  }
}

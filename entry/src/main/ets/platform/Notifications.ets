import { notificationManager } from '@kit.NotificationKit';
import { common, Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'CarelyNotifications';
const LABEL = 'carely-alert';

/** Want parameter carrying the backend alert id when a notification is tapped. */
export const OPEN_ALERT_PARAM = 'carelyAlertId';
/** Want parameter carrying the senior's display name, so the detail title can name them. */
export const OPEN_ALERT_NAME_PARAM = 'carelySeniorName';
/** AppStorage keys EntryAbility sets from a tapped notification; read by the AlertDeepLink component. */
export const OPEN_ALERT_ID_KEY = 'carelyOpenAlertId';
export const OPEN_ALERT_NAME_KEY = 'carelyOpenAlertName';

export class LocalAlertNotification {
  /** Stable key, e.g. the backend alert id; the same key replaces the earlier notification. */
  key: string;
  title: string;
  text: string;
  /** SOS uses the social-communication slot so it can be managed separately from other alerts. */
  urgent: boolean;
  /** Backend alert id opened on tap; empty for simulations, which only open the app. */
  openAlertId: string = '';
  seniorName: string = '';

  constructor(key: string, title: string, text: string, urgent: boolean) {
    this.key = key;
    this.title = title;
    this.text = text;
    this.urgent = urgent;
  }
}

/** Maps a string key to a positive 31-bit notification id, so one alert always maps to one notification. */
export function notificationIdFor(key: string): number {
  let hash = 0;
  for (let index = 0; index < key.length; index++) {
    hash = ((hash << 5) - hash + key.charCodeAt(index)) | 0;
  }
  return (hash & 0x7fffffff) || 1;
}

/**
 * Local notifications through Notification Kit. These are posted by this app on
 * this device only; they are not remote Push Kit messages. Publishing needs no
 * permission, only the user's notification consent for the app.
 */
export class Notifications {
  private askedThisSession: boolean = false;

  async isEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'isNotificationEnabled failed: %{public}d', (error as BusinessError).code);
      return false;
    }
  }

  /**
   * Shows the system consent dialog once per app session when notifications are
   * off. A refusal is not an error for the caller: in-app alerts keep working.
   */
  async ensureEnabled(context: common.UIAbilityContext, force: boolean = false): Promise<boolean> {
    if (await this.isEnabled()) {
      return true;
    }
    if (this.askedThisSession && !force) {
      return false;
    }
    this.askedThisSession = true;
    try {
      await notificationManager.requestEnableNotification(context);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'requestEnableNotification failed: %{public}d', (error as BusinessError).code);
    }
    return this.isEnabled();
  }

  async publish(context: common.UIAbilityContext, notification: LocalAlertNotification): Promise<boolean> {
    const id = notificationIdFor(notification.key);
    const request: notificationManager.NotificationRequest = {
      id: id,
      label: LABEL,
      notificationSlotType: notification.urgent
        ? notificationManager.SlotType.SOCIAL_COMMUNICATION
        : notificationManager.SlotType.SERVICE_INFORMATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: notification.title,
          text: notification.text
        }
      },
      tapDismissed: true
    };
    const agent = await this.openAppAgent(context, notification, id);
    if (agent !== undefined) {
      request.wantAgent = agent;
    }
    try {
      await notificationManager.publish(request);
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'publish failed: %{public}d', (error as BusinessError).code);
      return false;
    }
  }

  async cancel(key: string): Promise<void> {
    try {
      await notificationManager.cancel(notificationIdFor(key), LABEL);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'cancel failed: %{public}d', (error as BusinessError).code);
    }
  }

  async cancelAll(): Promise<void> {
    try {
      await notificationManager.cancelAll();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'cancelAll failed: %{public}d', (error as BusinessError).code);
    }
  }

  /** Tapping opens EntryAbility; the alert id travels in Want parameters when there is one. */
  private async openAppAgent(context: common.UIAbilityContext, notification: LocalAlertNotification,
    requestCode: number): Promise<WantAgent | undefined> {
    const parameters: Record<string, Object> = {};
    if (notification.openAlertId !== '') {
      parameters[OPEN_ALERT_PARAM] = notification.openAlertId;
      parameters[OPEN_ALERT_NAME_PARAM] = notification.seniorName;
    }
    const want: Want = {
      bundleName: context.abilityInfo.bundleName,
      abilityName: context.abilityInfo.name,
      parameters: parameters
    };
    try {
      return await wantAgent.getWantAgent({
        wants: [want],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: requestCode,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      });
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'getWantAgent failed: %{public}d', (error as BusinessError).code);
      return undefined;
    }
  }
}

export const notifications: Notifications = new Notifications();

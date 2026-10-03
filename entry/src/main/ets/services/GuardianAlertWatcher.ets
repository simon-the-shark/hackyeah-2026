import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AlertType, CareAlert, remoteAlertCopy } from '../models/Safety';
import { LocalAlertNotification, notifications } from '../platform/Notifications';
import { apiSession, careApi } from './CareApi';
import { SafePreferences } from './SafePreferences';

const DOMAIN = 0x0000;
const TAG = 'GuardianAlertWatcher';
const STORE_NAME = 'carely_alert_watcher';
const POLL_INTERVAL_MS = 20000;
const INBOX_LIMIT = 50;
/** On the first poll after pairing, only an SOS younger than this still notifies. */
const FIRST_RUN_SOS_WINDOW_MS = 15 * 60 * 1000;
const MAX_REMEMBERED_KEYS = 300;

/** AppStorage keys read by the in-app SOS banner. An empty id means no open SOS. */
export const SOS_ALERT_ID_KEY = 'guardianSosAlertId';
export const SOS_SENIOR_NAME_KEY = 'guardianSosSeniorName';
export const SOS_CREATED_AT_KEY = 'guardianSosCreatedAt';

/** One entry of `GET /v1/alerts` (guardian inbox). Null fields arrive as JSON null. */
export interface GuardianInboxAlert {
  id: string;
  kind: string;
  createdAt: string;
  seniorName?: string | null;
  cancelledAt?: string | null;
  acknowledgedAt?: string | null;
}

interface GuardianInbox {
  items: GuardianInboxAlert[];
}

function present(value: string | null | undefined): boolean {
  return value !== undefined && value !== null && value !== '';
}

export function seniorNameOf(item: GuardianInboxAlert): string {
  const name = item.seniorName;
  return name !== undefined && name !== null && name !== '' ? name : 'your senior';
}

/** Builds the detail-page model for an SOS known only by id, name and time. */
export function sosCareAlert(alertId: string, seniorName: string, createdAt: number): CareAlert {
  const name = seniorName !== '' ? seniorName : 'your senior';
  const alert = new CareAlert(alertId, AlertType.Sos, `SOS from ${name}`, `${name} requested help.`, 'Care service');
  alert.createdAt = createdAt;
  alert.remote = true;
  return alert;
}

/**
 * Foreground alert watcher for the guardian phone.
 *
 * While the ability is in the foreground and the device is paired as a
 * guardian, it polls `GET /v1/alerts?unacknowledged=true` every 20 s, posts a
 * local notification for each alert it has not notified before, and publishes
 * the newest open SOS to AppStorage for the in-app banner. This is polling plus
 * local Notification Kit notifications, not remote Push Kit: nothing arrives
 * while the app is in the background or closed.
 *
 * Notified alert ids are persisted, so a restart does not repeat old
 * notifications. On the first poll after pairing (no stored baseline) existing
 * alerts are recorded silently, except an open SOS younger than 15 minutes,
 * which still notifies because it may need action now.
 */
export class GuardianAlertWatcher {
  private readonly store = new SafePreferences(STORE_NAME);
  private context: common.UIAbilityContext | undefined = undefined;
  private timerId: number = -1;
  private polling: boolean = false;
  private loaded: boolean = false;
  private baselineSet: boolean = false;
  /** Alert ids already notified, plus `<id>:cancelled` once a cancellation was notified. */
  private notifiedKeys: string[] = [];
  /** Notifications posted by this process, so they can be withdrawn once acknowledged. */
  private readonly shownKeys: Set<string> = new Set<string>();

  start(context: common.UIAbilityContext): void {
    this.context = context;
    if (this.timerId === -1) {
      this.timerId = setInterval(() => {
        this.pollNow();
      }, POLL_INTERVAL_MS);
    }
    this.pollNow();
  }

  stop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** Called on sign-out: forgets the baseline, clears the banner and withdraws this app's notifications. */
  async reset(context: common.Context): Promise<void> {
    this.notifiedKeys = [];
    this.baselineSet = false;
    this.loaded = true;
    this.shownKeys.clear();
    this.publishBanner(undefined);
    await this.store.clear(context);
    await notifications.cancelAll();
  }

  /** Called after the guardian acknowledges an alert in the app. */
  async onAcknowledged(alertId: string): Promise<void> {
    if (AppStorage.get<string>(SOS_ALERT_ID_KEY) === alertId) {
      this.publishBanner(undefined);
    }
    if (this.shownKeys.has(alertId)) {
      this.shownKeys.delete(alertId);
      await notifications.cancel(alertId);
    }
    this.pollNow();
  }

  async pollNow(): Promise<void> {
    const context = this.context;
    if (context === undefined || this.polling) {
      return;
    }
    if (!apiSession.configured() || apiSession.role !== 'guardian') {
      this.publishBanner(undefined);
      return;
    }
    this.polling = true;
    try {
      await this.load(context);
      const inbox = await careApi.request(`/alerts?unacknowledged=true&limit=${INBOX_LIMIT}`,
        http.RequestMethod.GET) as GuardianInbox;
      const items = Array.isArray(inbox.items) ? inbox.items : [];
      await this.process(context, items);
    } catch (error) {
      // Network or server failure: keep the last known banner and try again on the next tick.
      hilog.warn(DOMAIN, TAG, 'Alert poll failed');
    } finally {
      this.polling = false;
    }
  }

  private async process(context: common.UIAbilityContext, items: GuardianInboxAlert[]): Promise<void> {
    const firstRun = !this.baselineSet;
    let changed = firstRun;
    for (const item of items) {
      if (!this.notifiedKeys.includes(item.id)) {
        this.remember(item.id);
        changed = true;
        const recentSos = item.kind === 'sos' && Date.now() - Date.parse(item.createdAt) < FIRST_RUN_SOS_WINDOW_MS;
        if (present(item.cancelledAt) || (firstRun && !recentSos)) {
          // Recorded silently; a later cancellation of an SOS we never announced is not announced either.
          if (item.kind === 'sos') {
            this.remember(`${item.id}:cancelled`);
          }
          continue;
        }
        await this.notifyAlert(context, item);
      } else if (item.kind === 'sos' && present(item.cancelledAt) && !this.notifiedKeys.includes(`${item.id}:cancelled`)) {
        this.remember(`${item.id}:cancelled`);
        changed = true;
        await this.notifyCancelled(context, item);
      }
    }

    // Alerts acknowledged elsewhere drop out of the inbox; withdraw their notifications.
    if (items.length < INBOX_LIMIT) {
      const openIds = items.map((item: GuardianInboxAlert) => item.id);
      for (const key of Array.from(this.shownKeys)) {
        if (!openIds.includes(key)) {
          this.shownKeys.delete(key);
          await notifications.cancel(key);
        }
      }
    }

    this.publishBanner(items.find((item: GuardianInboxAlert) => item.kind === 'sos' && !present(item.cancelledAt)));
    this.baselineSet = true;
    if (changed) {
      await this.save(context);
    }
  }

  private async notifyAlert(context: common.UIAbilityContext, item: GuardianInboxAlert): Promise<void> {
    const name = seniorNameOf(item);
    let notification: LocalAlertNotification;
    if (item.kind === 'sos') {
      notification = new LocalAlertNotification(item.id, `SOS from ${name}`,
        `${name} asked for help. Open Carely to respond.`, true);
    } else {
      const copy = remoteAlertCopy(item.kind);
      notification = new LocalAlertNotification(item.id, `${copy.title} · ${name}`, copy.detail, false);
    }
    notification.openAlertId = item.id;
    notification.seniorName = name;
    if (await notifications.publish(context, notification)) {
      this.shownKeys.add(item.id);
    }
  }

  private async notifyCancelled(context: common.UIAbilityContext, item: GuardianInboxAlert): Promise<void> {
    const name = seniorNameOf(item);
    // Same key as the SOS notification, so the cancellation replaces it instead of stacking.
    const notification = new LocalAlertNotification(item.id, `SOS cancelled · ${name}`,
      `${name} cancelled the SOS. Open Carely to mark it as seen.`, false);
    notification.openAlertId = item.id;
    notification.seniorName = name;
    if (await notifications.publish(context, notification)) {
      this.shownKeys.add(item.id);
    }
  }

  private publishBanner(item: GuardianInboxAlert | undefined): void {
    AppStorage.setOrCreate<string>(SOS_ALERT_ID_KEY, item === undefined ? '' : item.id);
    AppStorage.setOrCreate<string>(SOS_SENIOR_NAME_KEY, item === undefined ? '' : seniorNameOf(item));
    AppStorage.setOrCreate<number>(SOS_CREATED_AT_KEY, item === undefined ? 0 : Date.parse(item.createdAt));
  }

  private remember(key: string): void {
    this.notifiedKeys.push(key);
    if (this.notifiedKeys.length > MAX_REMEMBERED_KEYS) {
      this.notifiedKeys.splice(0, this.notifiedKeys.length - MAX_REMEMBERED_KEYS);
    }
  }

  private async load(context: common.Context): Promise<void> {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    this.baselineSet = await this.store.getString(context, 'baseline', '') === '1';
    const raw = await this.store.getString(context, 'notified', '[]');
    try {
      const parsed = JSON.parse(raw) as string[];
      this.notifiedKeys = Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      this.notifiedKeys = [];
    }
  }

  private async save(context: common.Context): Promise<void> {
    await this.store.putStrings(context, {
      'baseline': this.baselineSet ? '1' : '',
      'notified': JSON.stringify(this.notifiedKeys)
    });
  }
}

export const guardianAlertWatcher: GuardianAlertWatcher = new GuardianAlertWatcher();

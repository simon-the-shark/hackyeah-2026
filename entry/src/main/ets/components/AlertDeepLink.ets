import { http } from '@kit.NetworkKit';
import { GUARDIAN_PROFILE } from '../models/Features';
import { CareAlert, remoteAlertCopy } from '../models/Safety';
import { apiSession, careApi } from '../services/CareApi';
import { GuardianInboxAlert, sosCareAlert } from '../services/GuardianAlertWatcher';
import { OPEN_ALERT_NAME_KEY } from '../platform/Notifications';

/**
 * Invisible helper placed once in the root page. When a local alert
 * notification is tapped, it loads that alert and opens its detail page on top
 * of the guardian home. If the alert cannot be loaded it opens the inbox.
 */
@Component
export struct AlertDeepLink {
  @Consume('navStack') navStack: NavPathStack;
  @StorageLink('carelyOpenAlertId') @Watch('onOpenRequest') private openAlertId: string = '';

  aboutToAppear(): void {
    this.onOpenRequest();
  }

  private onOpenRequest(): void {
    const alertId = this.openAlertId;
    if (alertId === '') {
      return;
    }
    this.openAlertId = '';
    const seniorName = AppStorage.get<string>(OPEN_ALERT_NAME_KEY) ?? '';
    AppStorage.setOrCreate<string>(OPEN_ALERT_NAME_KEY, '');
    if (!apiSession.configured() || apiSession.role !== 'guardian') {
      return;
    }
    this.open(alertId, seniorName);
  }

  private async open(alertId: string, seniorName: string): Promise<void> {
    if (!this.navStack.getAllPathName().includes(GUARDIAN_PROFILE.route)) {
      this.navStack.pushPathByName(GUARDIAN_PROFILE.route, null);
    }
    try {
      const item = await careApi.request(`/alerts/${encodeURIComponent(alertId)}`,
        http.RequestMethod.GET) as GuardianInboxAlert;
      this.navStack.pushPathByName('alert-detail', this.toCareAlert(item, seniorName));
    } catch (error) {
      this.navStack.pushPathByName('alerts', null);
    }
  }

  private toCareAlert(item: GuardianInboxAlert, seniorName: string): CareAlert {
    const createdAt = Date.parse(item.createdAt);
    let alert: CareAlert;
    if (item.kind === 'sos') {
      alert = sosCareAlert(item.id, seniorName, createdAt);
    } else {
      const copy = remoteAlertCopy(item.kind);
      alert = new CareAlert(item.id, copy.type, copy.title, copy.detail, 'Care service');
      alert.createdAt = createdAt;
      alert.remote = true;
    }
    alert.acknowledged = item.acknowledgedAt !== undefined && item.acknowledgedAt !== null;
    return alert;
  }

  build() {
    Column()
      .width(0)
      .height(0)
      .visibility(Visibility.None)
  }
}

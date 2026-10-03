import { formatClockTime } from '../models/Safety';
import { formatAge } from '../models/WatchVitals';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { RemoteDevice, WatchVitalsApi } from '../providers/backend/WatchVitalsApi';
import { apiSession } from '../services/CareApi';
import { CareButtonStyle } from './DesignSystem';
import { sectionTitle } from './Common';

/**
 * Senior Settings: shows a short-lived code to type on the watch, and the
 * watches already paired, each of which can be removed (e.g. a lost watch).
 */
@Component
export struct WatchPairingCard {
  @State private code: string = '';
  @State private expiresAt: number = 0;
  @State private message: string = 'Pair a watch to share SOS, its location and heart rate with your guardian.';
  @State private watches: RemoteDevice[] = [];
  @State private confirmRemoveId: string = '';

  aboutToAppear(): void {
    this.loadWatches();
  }

  private api(): WatchVitalsApi {
    return new WatchVitalsApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
  }

  private describe(error: Object, fallback: string): string {
    if (error instanceof ApiError && error.kind === ApiErrorKind.Network) {
      return 'Cannot reach the Carely server. Check the internet connection.';
    }
    return fallback;
  }

  private async loadWatches(): Promise<void> {
    try {
      this.watches = await this.api().watches();
    } catch (error) {
      this.watches = [];
    }
  }

  /** `rotate` replaces a shown code, so the old one stops working on any watch. */
  private async showCode(rotate: boolean): Promise<void> {
    this.message = rotate ? 'Getting a new code…' : 'Getting a code…';
    try {
      const result = await this.api().watchCode(rotate);
      this.code = result.pairingCode;
      const expires = Date.parse(result.pairingExpiresAt);
      this.expiresAt = isFinite(expires) ? expires : 0;
      this.message = this.expiresAt > 0
        ? `Open Carely on the watch and enter this code before ${formatClockTime(this.expiresAt)}.`
        : 'Open Carely on the watch and enter this code.';
    } catch (error) {
      this.code = '';
      this.message = this.describe(error as Object, 'Could not get a watch code. Try again.');
    }
  }

  private async remove(watch: RemoteDevice): Promise<void> {
    if (this.confirmRemoveId !== watch.id) {
      this.confirmRemoveId = watch.id;
      return;
    }
    this.confirmRemoveId = '';
    try {
      await this.api().removeDevice(watch.id);
      this.message = 'Watch removed. It can no longer send anything.';
    } catch (error) {
      this.message = this.describe(error as Object, 'Could not remove the watch. Try again.');
    }
    await this.loadWatches();
  }

  private lastSeen(watch: RemoteDevice): string {
    const lastSeenAt = watch.lastSeenAt;
    const seen = lastSeenAt !== null && lastSeenAt !== undefined ? Date.parse(lastSeenAt) : NaN;
    return isFinite(seen) ? `Last seen ${formatAge(Math.max(0, Date.now() - seen))}` : 'Not seen yet';
  }

  build() {
    Column({ space: 12 }) {
      sectionTitle('Smartwatch')
      Column({ space: 10 }) {
        if (this.code !== '') {
          Text(this.code)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(4)
            .fontColor($r('app.color.senior_accent'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .accessibilityText(`Watch code ${this.code.split('').join(' ')}`)
        }
        Text(this.message)
          .fontSize(19)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
        Button(this.code === '' ? 'Pair a watch' : 'New code')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(56)
          .fontSize(19)
          .fontColor($r('app.color.senior_accent'))
          .attributeModifier(new CareButtonStyle('secondary'))
          .onClick(() => {
            this.showCode(this.code !== '');
            this.loadWatches();
          })

        ForEach(this.watches, (watch: RemoteDevice) => {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.watch_fill'))
              .fontSize(22)
              .fontColor([$r('app.color.senior_accent')])
            Column({ space: 2 }) {
              Text('Paired watch')
                .fontSize(19)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text(this.lastSeen(watch))
                .fontSize(17)
                .fontColor($r('app.color.text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Button(this.confirmRemoveId === watch.id ? 'Tap to confirm' : 'Remove')
              .type(ButtonType.Capsule)
              .height(48)
              .fontSize(17)
              .fontColor($r('app.color.sos'))
              .backgroundColor($r('app.color.sos_tint'))
              .border({ width: 2, color: $r('app.color.sos') })
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .accessibilityText(this.confirmRemoveId === watch.id ? 'Confirm removal of paired watch' : 'Remove paired watch')
              .onClick(() => this.remove(watch))
          }
          .width('100%')
        }, (watch: RemoteDevice) => watch.id)
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

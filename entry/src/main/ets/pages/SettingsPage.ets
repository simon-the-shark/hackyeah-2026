import { sectionTitle } from '../components/Common';
import { WatchPairingCard } from '../components/WatchPairingCard';
import { pasteboard } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { apiSession, careApi } from '../services/CareApi';
import { formatClockTime } from '../models/Safety';
import { confirmSignOut } from '../components/SignOut';
import { CareButtonStyle } from '../components/DesignSystem';

@Component
export struct SettingsPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private pairingCode: string = '';
  @State private pairingMessage: string = '';
  @State private loadingPairingCode: boolean = false;

  aboutToAppear(): void {
    if (apiSession.role === 'senior') {
      this.loadPairingCode(false);
    }
  }

  /** `rotate` expires the current code on the server, so a code shared by mistake stops working. */
  private async loadPairingCode(rotate: boolean): Promise<void> {
    if (this.loadingPairingCode) return;
    this.loadingPairingCode = true;
    this.pairingMessage = rotate ? 'Creating a new pairing code…' : 'Loading pairing code…';
    try {
      const path = rotate ? '/pairing/codes?rotate=true' : '/pairing/codes';
      const result = await careApi.request(path, http.RequestMethod.POST) as Record<string, string>;
      this.pairingCode = result['pairingCode'];
      const expires = Date.parse(result['pairingExpiresAt']);
      const until = isFinite(expires) ? ` It works until ${formatClockTime(expires)}.` : '';
      this.pairingMessage = rotate ? `New code ready. The old code no longer works.${until}` :
        `Share this code with your guardian.${until}`;
    } catch (error) {
      this.pairingCode = '';
      this.pairingMessage = rotate ? 'Could not create a new code. Try again.' :
        'Could not load a pairing code.';
    } finally {
      this.loadingPairingCode = false;
    }
  }

  private copyPairingCode(): void {
    if (this.pairingCode === '') {
      return;
    }
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.pairingCode);
    pasteboard.getSystemPasteboard().setData(pasteData).then(() => {
      this.pairingMessage = 'Pairing code copied. Share it with your guardian.';
    }).catch(() => {
      this.pairingMessage = 'Could not copy the pairing code. Please share it manually.';
    });
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 24 }) {
          if (apiSession.role === 'senior') {
            Column({ space: 12 }) {
              sectionTitle('Pairing')
              Column({ space: 8 }) {
                Text('Guardian pairing code')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text(this.pairingCode === '' ? '------' : this.pairingCode)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.senior_accent'))
                  .letterSpacing(4)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .accessibilityText(this.pairingCode === '' ? 'No pairing code yet' :
                    `Pairing code ${this.pairingCode.split('').join(' ')}`)
                Text(this.pairingMessage)
                  .fontSize(19)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Row({ space: 12 }) {
                  Button('Copy code')
                    .layoutWeight(1)
                    .fontColor(Color.White)
                    .attributeModifier(new CareButtonStyle())
                    .enabled(this.pairingCode !== '' && !this.loadingPairingCode)
                    .onClick(() => this.copyPairingCode())
                  Button(this.loadingPairingCode ? 'Loading…' : 'New code')
                    .layoutWeight(1)
                    .fontColor($r('app.color.senior_accent'))
                    .attributeModifier(new CareButtonStyle('secondary'))
                    .enabled(!this.loadingPairingCode)
                    .onClick(() => this.loadPairingCode(this.pairingCode !== ''))
                }
                .width('100%')
              }
              .width('100%')
              .padding(16)
              .borderRadius(20)
              .backgroundColor($r('app.color.surface'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            WatchPairingCard()
          }

          Button('Sign out')
            .width('100%')
            .height(56)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.sos'))
            .attributeModifier(new CareButtonStyle('danger-secondary'))
            .onClick(() => {
              confirmSignOut(this.getUIContext(), this.navStack);
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title('Settings')
    .backgroundColor($r('app.color.page_background'))
  }
}

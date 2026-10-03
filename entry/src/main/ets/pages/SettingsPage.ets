import { ActionRow, IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { WatchPairingCard } from '../components/WatchPairingCard';
import { safetyStore } from '../models/Safety';
import { pasteboard } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import common from '@ohos.app.ability.common';
import { apiSession, careApi } from '../services/CareApi';
import { apiSessionStore } from '../services/ApiSessionStore';

@Component
export struct SettingsPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private developerMode: boolean = safetyStore.developerMode;
  @State private pairingCode: string = '';
  @State private pairingMessage: string = '';

  aboutToAppear(): void {
    if (apiSession.role === 'senior') {
      this.loadPairingCode();
    }
  }

  private async loadPairingCode(): Promise<void> {
    this.pairingMessage = 'Loading pairing code...';
    try {
      const result = await careApi.request('/pairing/codes', http.RequestMethod.POST) as Record<string, string>;
      this.pairingCode = result['pairingCode'];
      this.pairingMessage = 'Share this code with your guardian.';
    } catch (error) {
      this.pairingCode = '';
      this.pairingMessage = 'Could not load a pairing code.';
    }
  }

  private setDeveloperMode(enabled: boolean): void {
    this.developerMode = enabled;
    safetyStore.developerMode = enabled;
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

  /** Clears pairing, then returns to setup. Signing out must always take effect. */
  private async signOut(): Promise<void> {
    await apiSessionStore.clear(this.getUIContext().getHostContext() as common.UIAbilityContext);
    AppStorage.set('paired', false);
    this.navStack.clear();
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
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Text(this.pairingMessage)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Row({ space: 12 }) {
                  Button('Copy code')
                    .layoutWeight(1)
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.senior_accent'))
                    .enabled(this.pairingCode !== '')
                    .onClick(() => this.copyPairingCode())
                  Button('Refresh code')
                    .layoutWeight(1)
                    .fontColor($r('app.color.senior_accent'))
                    .backgroundColor($r('app.color.senior_tint'))
                    .onClick(() => this.loadPairingCode())
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
            .backgroundColor($r('app.color.sos_tint'))
            .onClick(() => {
              this.signOut();
            })
          Column({ space: 8 }) {
            sectionTitle('Advanced')
            Row({ space: 16 }) {
              IconBadge({
                icon: $r('sys.symbol.gearshape_fill'),
                accent: $r('app.color.text_secondary'),
                tint: $r('app.color.page_background'),
                badgeSize: 44
              })
              Column({ space: 2 }) {
                Text('Developer Mode')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text('Test tools and simulations')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.developerMode })
                .selectedColor($r('app.color.senior_accent'))
                .onChange((enabled: boolean) => this.setDeveloperMode(enabled))
            }
            .width('100%')
            .constraintSize({ minHeight: 72 })
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(20)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.developerMode) {
            Column({ space: 8 }) {
              sectionTitle('Developer tools')
              Column() {
                ActionRow({
                  icon: $r('sys.symbol.map'),
                  title: 'Safe area trace replay',
                  summary: 'Simulate being inside or outside home',
                  accent: $r('app.color.warning'),
                  tint: $r('app.color.warning_tint'),
                  showDivider: true,
                  onTap: () => this.navStack.pushPathByName('developer-tools', null)
                })
                ActionRow({
                  icon: $r('sys.symbol.watch_fill'),
                  title: 'Watch safety simulation',
                  summary: 'Phone-hosted watch with an SOS button',
                  accent: $r('app.color.warning'),
                  tint: $r('app.color.warning_tint'),
                  onTap: () => this.navStack.pushPathByName('watch-safety', null)
                })
              }
              .width('100%')
              .borderRadius(20)
              .clip(true)
              .backgroundColor($r('app.color.surface'))

              NoticeBanner({ text: 'Simulations do not use real location or a real watch. Developer Mode resets when the app is closed.' })
                .margin({ top: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
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

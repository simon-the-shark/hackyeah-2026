import { ActionRow, IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { safetyStore } from '../models/Safety';

@Component
export struct SettingsPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private developerMode: boolean = safetyStore.developerMode;

  private setDeveloperMode(enabled: boolean): void {
    this.developerMode = enabled;
    safetyStore.developerMode = enabled;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 24 }) {
          Button('Connect to care service')
            .width('100%')
            .onClick(() => this.navStack.pushPathByName('connection', null))
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

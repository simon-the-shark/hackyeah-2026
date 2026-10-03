import { Feature, FeatureSection, RoleProfile, SENIOR_PROFILE } from '../models/Features';
import common from '@ohos.app.ability.common';
import { apiSessionStore } from '../services/ApiSessionStore';
import { FeaturePlaceholder } from './FeaturePage';
import { AlertsList } from './AlertsPage';
import { MedicationToday } from './MedicationToday';

@Component
export struct RoleHome {
  @Consume('navStack') navStack: NavPathStack;
  profile: RoleProfile = SENIOR_PROFILE;
  @State selectedTab: number = 0;
  /** Bumped whenever a tab or this page becomes visible, so tab content can reload. */
  @State tabRefresh: number = 0;

  /** Clears pairing, then returns to setup. Signing out must always take effect. */
  private async signOut(): Promise<void> {
    await apiSessionStore.clear(this.getUIContext().getHostContext() as common.UIAbilityContext);
    AppStorage.set('paired', false);
    this.navStack.clear();
  }

  private open(feature: Feature): void {
    if (feature.id === 'sign-out') {
      this.signOut();
    } else if (feature.id === 'sos') {
      this.navStack.pushPathByName('sos', null);
    } else if (feature.id === 'safe-area') {
      this.navStack.pushPathByName('safety', null);
    } else if (feature.id === 'alerts') {
      this.navStack.pushPathByName('alerts', null);
    } else if (feature.id === 'safe-area-setup') {
      this.navStack.pushPathByName('safe-area-setup', null);
    } else if (feature.id === 'settings') {
      this.navStack.pushPathByName('settings', null);
    } else {
      this.navStack.pushPathByName('feature', feature);
    }
  }

  @Builder
  hero() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph(this.profile.hero.icon)
          .fontSize(32)
          .fontColor([Color.White])
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#33FFFFFF')

      Text(this.profile.hero.title)
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Row({ space: 8 }) {
        Text(this.profile.hero.summary)
          .fontSize(17)
          .fontColor(Color.White)
          .opacity(0.92)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(28)
    .backgroundColor(this.profile.heroColor)
    .shadow({ radius: 24, color: $r('app.color.card_shadow'), offsetY: 8 })
    .accessibilityGroup(true)
    .onClick(() => this.open(this.profile.hero))
  }

  @Builder
  featureRow(feature: Feature, showDivider: boolean) {
    Column() {
      Row({ space: 16 }) {
        Row() {
          SymbolGlyph(feature.icon)
            .fontSize(24)
            .fontColor([feature.accent])
        }
        .width(48)
        .height(48)
        .borderRadius(14)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(feature.tint)

        Column({ space: 2 }) {
          Text(feature.title)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(feature.summary)
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 76 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 80 })
      }
    }
    .accessibilityGroup(true)
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
    .onClick(() => this.open(feature))
  }

  @Builder
  section(section: FeatureSection) {
    Column({ space: 8 }) {
      Text(section.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .padding({ left: 4 })

      Column() {
        ForEach(section.features, (feature: Feature, index: number) => {
          this.featureRow(feature, index < section.features.length - 1)
        }, (feature: Feature) => feature.id)
      }
      .width('100%')
      .borderRadius(20)
      .clip(true)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  homeContent() {
    Scroll() {
      Column({ space: 24 }) {
        Text(this.profile.headline)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        this.hero()

        ForEach(this.profile.sections, (section: FeatureSection) => {
          this.section(section)
        }, (section: FeatureSection) => section.title)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  /** Content of a bottom-bar tab; features without a screen yet show a placeholder. */
  @Builder
  tabContent(feature: Feature) {
    if (feature.id === 'alerts') {
      AlertsList({ refreshKey: this.tabRefresh })
    } else if (feature.id === 'medication') {
      MedicationToday()
    } else {
      FeaturePlaceholder({ feature: feature })
    }
  }

  @Builder
  tabItem(icon: Resource, label: string, index: number) {
    Column({ space: 4 }) {
      SymbolGlyph(icon)
        .fontSize(26)
        .fontColor([this.selectedTab === index ? this.profile.accent : $r('app.color.text_secondary')])
      Text(label)
        .fontSize(14)
        .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedTab === index ? this.profile.accent : $r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .accessibilityGroup(true)
  }

  build() {
    NavDestination() {
      if (this.profile.tabs.length > 0) {
        Tabs({ barPosition: BarPosition.End, index: this.selectedTab }) {
          TabContent() {
            this.homeContent()
          }
          .tabBar(this.tabItem($r('sys.symbol.house_fill'), 'Home', 0))

          ForEach(this.profile.tabs, (feature: Feature, index: number) => {
            TabContent() {
              this.tabContent(feature)
            }
            .tabBar(this.tabItem(feature.icon, feature.title, index + 1))
          }, (feature: Feature) => feature.id)
        }
        .scrollable(false)
        .barHeight(76)
        .barBackgroundColor($r('app.color.surface'))
        .divider({ strokeWidth: 1, color: $r('app.color.divider') })
        .onChange((index: number) => {
          this.selectedTab = index;
          this.tabRefresh++;
        })
      } else {
        this.homeContent()
      }
    }
    .title(this.selectedTab === 0 ? this.profile.label : this.profile.tabs[this.selectedTab - 1].title)
    .backgroundColor($r('app.color.page_background'))
    .onShown(() => this.tabRefresh++)
  }
}

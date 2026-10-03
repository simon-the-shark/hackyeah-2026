import { Feature, GUARDIAN_PROFILE, ROLE_PROFILES, RoleProfile, SENIOR_PROFILE } from '../models/Features';
import { FeaturePage } from './FeaturePage';
import { RoleHome } from './RoleHome';

@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack();

  @Builder
  routes(name: string, param: Object) {
    if (name === SENIOR_PROFILE.route) {
      RoleHome({ profile: SENIOR_PROFILE })
    } else if (name === GUARDIAN_PROFILE.route) {
      RoleHome({ profile: GUARDIAN_PROFILE })
    } else if (name === 'feature') {
      FeaturePage({ feature: param as Feature })
    }
  }

  @Builder
  roleCard(profile: RoleProfile) {
    Row({ space: 16 }) {
      Row() {
        SymbolGlyph(profile.icon)
          .fontSize(30)
          .fontColor([profile.accent])
      }
      .width(60)
      .height(60)
      .borderRadius(18)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(profile.tint)

      Column({ space: 4 }) {
        Text(profile.label)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(profile.description)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor($r('app.color.surface'))
    .shadow({ radius: 16, color: $r('app.color.card_shadow'), offsetY: 4 })
    .accessibilityGroup(true)
    .onClick(() => {
      this.navStack.pushPathByName(profile.route, null);
    })
  }

  build() {
    Navigation(this.navStack) {
      Column({ space: 32 }) {
        Column({ space: 8 }) {
          Row() {
            SymbolGlyph($r('sys.symbol.heart_fill'))
              .fontSize(36)
              .fontColor([$r('app.color.senior_accent')])
          }
          .width(72)
          .height(72)
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.senior_tint'))
          .margin({ bottom: 8 })

          Text('Carely')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('Who will use this device?')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 16 }) {
          ForEach(ROLE_PROFILES, (profile: RoleProfile) => {
            this.roleCard(profile)
          }, (profile: RoleProfile) => profile.route)
        }
        .width('100%')

        Blank()

        Text('Early preview. Features are not available yet.')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 48, bottom: 24 })
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.routes)
    .backgroundColor($r('app.color.page_background'))
  }
}

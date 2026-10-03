import { Feature, SENIOR_PROFILE } from '../models/Features';

@Component
export struct FeaturePlaceholder {
  feature: Feature = SENIOR_PROFILE.hero;

  build() {
    Column({ space: 16 }) {
      Row() {
        SymbolGlyph(this.feature.icon)
          .fontSize(48)
          .fontColor([this.feature.accent])
      }
      .width(96)
      .height(96)
      .borderRadius(32)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.feature.tint)

      Text(this.feature.summary)
        .fontSize(19)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      Text('Coming soon · This feature is not available yet')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.feature.accent)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(this.feature.tint)
    }
    .width('100%')
    .height('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct FeaturePage {
  feature: Feature = SENIOR_PROFILE.hero;

  build() {
    NavDestination() {
      Scroll() {
      FeaturePlaceholder({ feature: this.feature })
      }.width('100%').height('100%')
    }
    .title(this.feature.title)
    .backgroundColor($r('app.color.page_background'))
  }
}

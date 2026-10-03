// Full-screen loading, error and empty states for senior screens that load from the backend.
import { CareButtonStyle } from './DesignSystem';
@Component
export struct StatusMessage {
  @Require icon: Resource;
  @Require title: string;
  @Require message: string;
  // Shown as a "Try again" button when set.
  onRetry?: () => void;

  build() {
    Column({ space: 12 }) {
      SymbolGlyph(this.icon)
        .fontSize(48)
        .fontColor([$r('app.color.senior_accent')])
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
      Text(this.message)
        .fontSize(19)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      if (this.onRetry !== undefined) {
        Button('Try again')
          .height(56)
          .padding({ left: 32, right: 32 })
          .fontSize(18)
          .attributeModifier(new CareButtonStyle())
          .margin({ top: 8 })
          .onClick(() => this.onRetry?.())
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct LoadingMessage {
  @Require message: string;

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.senior_accent'))
      Text(this.message)
        .fontSize(18)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

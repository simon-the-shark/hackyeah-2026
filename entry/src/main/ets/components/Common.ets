import { CareFocusStyle } from './DesignSystem';

@Component
export struct IconBadge {
  @Prop icon: Resource = $r('sys.symbol.info_circle');
  @Prop accent: ResourceColor = $r('app.color.senior_accent');
  @Prop tint: ResourceColor = $r('app.color.senior_tint');
  badgeSize: number = 48;

  build() {
    Row() {
      SymbolGlyph(this.icon)
        .fontSize(this.badgeSize / 2)
        .fontColor([this.accent])
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
    .borderRadius(this.badgeSize * 0.3)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.tint)
    .accessibilityLevel('no')
  }
}

@Builder
export function sectionTitle(title: string) {
  Text(title)
    .fontSize(19)
    .fontWeight(FontWeight.Medium)
    .fontColor($r('app.color.text_secondary'))
    .padding({ left: 4 })
}

@Component
export struct NoticeBanner {
  @Prop icon: Resource = $r('sys.symbol.info_circle');
  @Prop text: string = '';
  @Prop accent: ResourceColor = $r('app.color.warning');
  @Prop tint: ResourceColor = $r('app.color.warning_tint');

  build() {
    Row({ space: 12 }) {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([this.accent])
        .accessibilityLevel('no')
      Text(this.text)
        .fontSize(19)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .borderRadius(14)
    .backgroundColor(this.tint)
    .accessibilityGroup(true)
  }
}

@Component
export struct ActionRow {
  icon: Resource = $r('sys.symbol.chevron_right');
  title: string = '';
  summary: string = '';
  accent: ResourceColor = $r('app.color.senior_accent');
  tint: ResourceColor = $r('app.color.senior_tint');
  showDivider: boolean = false;
  showChevron: boolean = true;
  onTap: () => void = () => {
  };

  build() {
    Column() {
      Row({ space: 16 }) {
        IconBadge({ icon: this.icon, accent: this.accent, tint: this.tint, badgeSize: 44 })

        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (this.summary !== '') {
            Text(this.summary)
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.showChevron) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(18)
            .fontColor([$r('app.color.text_secondary')])
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 76 })
      }
    }
    .accessibilityGroup(true)
    .attributeModifier(new CareFocusStyle())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(this.title + (this.summary === '' ? '' : `. ${this.summary}`))
    .stateStyles({
      normal: {
        .backgroundColor(Color.Transparent)
      },
      pressed: {
        .backgroundColor($r('app.color.pressed'))
      }
    })
    .onClick(() => this.onTap())
  }
}

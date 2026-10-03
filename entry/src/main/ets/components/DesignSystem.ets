// Shared public ArkUI modifiers (API 12+). Keep action fills separate from
// foreground accents: dark-mode accent text must not become a white-on-pastel button.
export class CareButtonStyle implements AttributeModifier<ButtonAttribute> {
  private variant: string;

  constructor(variant: string = 'primary') {
    this.variant = variant;
  }

  applyNormalAttribute(button: ButtonAttribute): void {
    const filled = this.variant === 'primary' || this.variant === 'danger';
    const danger = this.variant === 'danger' || this.variant === 'danger-secondary';
    button.type(ButtonType.Capsule)
      .constraintSize({ minHeight: 56, minWidth: 56 })
      .fontSize(19)
      .fontWeight(FontWeight.Medium)
      .borderRadius(28)
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .fontColor(filled ? Color.White : danger ? $r('app.color.sos') : $r('app.color.senior_accent'))
      .backgroundColor(filled ? danger ? $r('app.color.action_danger') : $r('app.color.action_primary') :
        $r('app.color.surface'))
      .border({ width: 2, radius: 28, color: filled ? Color.Transparent : danger ? $r('app.color.sos') :
        $r('app.color.senior_accent') });
  }

  applyFocusedAttribute(button: ButtonAttribute): void {
    const filled = this.variant === 'primary' || this.variant === 'danger';
    button.border({ width: 3, radius: 28, color: filled ? Color.White : $r('app.color.focus_ring') });
  }

  applyPressedAttribute(button: ButtonAttribute): void {
    button.opacity(0.85);
  }

  applyDisabledAttribute(button: ButtonAttribute): void {
    // Retain the semantic fill, including custom child labels, but distinguish
    // unavailability. The screen also explains pending/unavailable operations.
    button.opacity(0.5);
  }
}

export class CareInputStyle implements AttributeModifier<TextInputAttribute> {
  private label: string;
  private error: string;

  constructor(label: string, error: string = '') {
    this.label = label;
    this.error = error;
  }

  applyNormalAttribute(input: TextInputAttribute): void {
    input.constraintSize({ minHeight: 56 })
      .fontSize(19)
      .fontColor($r('app.color.text_primary'))
      .placeholderColor($r('app.color.text_secondary'))
      .backgroundColor($r('app.color.surface'))
      .borderRadius(14)
      .border({ width: this.error === '' ? 1 : 2, radius: 14,
        color: this.error === '' ? $r('app.color.control_border') : $r('app.color.sos') })
      .accessibilityText(this.label)
      .accessibilityDescription(this.error);
  }

  applyFocusedAttribute(input: TextInputAttribute): void {
    input.border({ width: 3, radius: 14, color: this.error === '' ? $r('app.color.focus_ring') : $r('app.color.sos') });
  }
}

export class CareTextAreaStyle implements AttributeModifier<TextAreaAttribute> {
  applyNormalAttribute(input: TextAreaAttribute): void {
    input.fontSize(19)
      .fontColor($r('app.color.text_primary'))
      .placeholderColor($r('app.color.text_secondary'))
      .backgroundColor($r('app.color.surface'))
      .borderRadius(14)
      .border({ width: 1, radius: 14, color: $r('app.color.control_border') });
  }

  applyFocusedAttribute(input: TextAreaAttribute): void {
    input.border({ width: 3, radius: 14, color: $r('app.color.focus_ring') });
  }
}

export class CareFocusStyle implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(control: CommonAttribute): void {
    control.focusable(true).border({ width: 3, color: Color.Transparent });
  }

  applyFocusedAttribute(control: CommonAttribute): void {
    control.border({ width: 3, color: $r('app.color.focus_ring') });
  }
}

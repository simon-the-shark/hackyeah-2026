import { common } from '@kit.AbilityKit';
import { CareFocusStyle } from './DesignSystem';
import { formatAlertTime } from '../models/Safety';
import { notifications } from '../platform/Notifications';
import { guardianAlertWatcher, sosCareAlert } from '../services/GuardianAlertWatcher';

/**
 * Prominent banner for an open (unacknowledged, not cancelled) SOS, fed by the
 * foreground alert watcher. Renders nothing when there is no open SOS.
 * The AppStorage keys match `SOS_*_KEY` in GuardianAlertWatcher.
 */
@Component
export struct SosBanner {
  @Consume('navStack') navStack: NavPathStack;
  @StorageProp('guardianSosAlertId') private alertId: string = '';
  @StorageProp('guardianSosSeniorName') private seniorName: string = '';
  @StorageProp('guardianSosCreatedAt') private createdAt: number = 0;
  /** Bumped every 30 s so the relative time stays current. */
  @State private tick: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.tick++;
    }, 30000);
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // Ask for notification consent where the guardian can see why, then check for alerts right away.
    notifications.ensureEnabled(context);
    guardianAlertWatcher.pollNow();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private timeLabel(): string {
    return this.tick >= 0 ? formatAlertTime(this.createdAt) : '';
  }

  build() {
    if (this.alertId !== '') {
      Row({ space: 14 }) {
        Row() {
          SymbolGlyph($r('sys.symbol.exclamationmark_shield_fill'))
            .fontSize(28)
            .fontColor([$r('app.color.action_danger')])
        }
        .width(52)
        .height(52)
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)

        Column({ space: 2 }) {
          Text(`SOS from ${this.seniorName}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.timeLabel())
            .fontSize(17)
            .fontColor(Color.White)
            .opacity(0.92)
          Text('Tap to open and respond')
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width('100%')
      .padding(18)
      .borderRadius(24)
      .backgroundColor($r('app.color.action_danger'))
      .shadow({ radius: 24, color: $r('app.color.card_shadow'), offsetY: 8 })
      .accessibilityGroup(true)
      .attributeModifier(new CareFocusStyle())
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityText(`SOS from ${this.seniorName}, ${this.timeLabel()}. Open alert.`)
      .onClick(() => {
        this.navStack.pushPathByName('alert-detail', sosCareAlert(this.alertId, this.seniorName, this.createdAt));
      })
    }
  }
}

import { common } from '@kit.AbilityKit';
import { formatClock, K_PAIRED, MonitorState } from '../models/WatchState';
import { LOCATION_PERMISSIONS, requestLocationSwitch, requestPermissionsInSettings } from '../platform/Permissions';
import { watchMonitor } from '../services/WatchMonitor';
import { watchSessionStore } from '../services/WatchSessionStore';

/** What the watch shares and whether the care service is reachable; also where the watch is unpaired. */
@Component
export struct StatusView {
  @StorageProp('locState') locState: string = MonitorState.OFF;
  @StorageProp('locSharedAt') locSharedAt: number = 0;
  @StorageProp('battery') battery: number = -1;
  @StorageProp('syncError') syncError: string = '';
  @State private confirmUnpair: boolean = false;

  private locationText(): string {
    if (this.locState === MonitorState.DENIED) {
      return 'Location: not allowed';
    }
    if (this.locState === MonitorState.SWITCH_OFF) {
      return 'Location is off on this watch';
    }
    if (this.locState === MonitorState.FAILED) {
      return 'Location: unavailable';
    }
    if (this.locSharedAt > 0) {
      return `Location shared ${formatClock(this.locSharedAt)}`;
    }
    return this.locState === MonitorState.ACTIVE ? 'Location: finding…' : 'Location: off';
  }

  private async allowLocation(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const fixed = this.locState === MonitorState.SWITCH_OFF
      ? await requestLocationSwitch(context)
      : await requestPermissionsInSettings(context, LOCATION_PERMISSIONS);
    if (fixed) {
      watchMonitor.pause();
      await watchMonitor.resume();
    }
  }

  private async unpair(): Promise<void> {
    if (!this.confirmUnpair) {
      this.confirmUnpair = true;
      return;
    }
    watchMonitor.stop();
    await watchSessionStore.clear(this.getUIContext().getHostContext() as common.UIAbilityContext);
    AppStorage.set<boolean>(K_PAIRED, false);
  }

  build() {
    Column({ space: 6 }) {
      SymbolGlyph($r('sys.symbol.location_up_fill'))
        .fontSize(18)
        .fontColor([$r('app.color.watch_accent')])
      Text(this.locationText())
        .fontSize(16)
        .fontColor($r('app.color.watch_text'))
        .textAlign(TextAlign.Center)
        .width(170)
      if (this.locState === MonitorState.DENIED || this.locState === MonitorState.SWITCH_OFF) {
        Button(this.locState === MonitorState.SWITCH_OFF ? 'Turn on' : 'Allow')
          .height(40)
          .fontSize(15)
          .fontColor(Color.Black)
          .backgroundColor($r('app.color.watch_accent'))
          .onClick(() => this.allowLocation())
      }
      Text(this.battery >= 0 ? `Battery ${this.battery}%` : 'Battery: unknown')
        .fontSize(15)
        .fontColor($r('app.color.watch_text_secondary'))
      if (this.syncError !== '') {
        Text(this.syncError)
          .fontSize(14)
          .fontColor($r('app.color.watch_warning'))
          .textAlign(TextAlign.Center)
          .width(170)
      }
      Text('Shared only while Carely is open.')
        .fontSize(13)
        .fontColor($r('app.color.watch_text_secondary'))
        .textAlign(TextAlign.Center)
        .width(170)
      Button(this.confirmUnpair ? 'Tap again to remove watch' : 'Remove watch')
        .height(40)
        .fontSize(14)
        .fontColor($r('app.color.watch_text'))
        .backgroundColor($r('app.color.watch_surface'))
        .borderRadius(20)
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityText(this.confirmUnpair ? 'Confirm remove paired watch' : 'Remove paired watch')
        .margin({ top: 4 })
        .onClick(() => this.unpair())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

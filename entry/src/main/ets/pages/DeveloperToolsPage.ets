import { ActionRow, NoticeBanner, sectionTitle } from '../components/Common';
import { common } from '@kit.AbilityKit';
import { GeofenceStatus, safetyStore } from '../models/Safety';
import { runCompanionDiagnostics } from '../services/CompanionDiagnostics';

@Component
export struct DeveloperToolsPage {
  @State private result: string = '';
  @State private alertCreated: boolean = false;
  @State private diagnostics: string[] = [];
  @State private diagnosing: boolean = false;

  private async diagnose(): Promise<void> {
    if (this.diagnosing) {
      return;
    }
    this.diagnosing = true;
    this.diagnostics = [];
    try {
      await runCompanionDiagnostics(this.getUIContext().getHostContext() as common.UIAbilityContext,
        (line: string) => this.diagnostics.push(line));
    } finally {
      this.diagnosing = false;
    }
  }

  private replay(status: GeofenceStatus): void {
    this.alertCreated = safetyStore.recordDemoLocation(status) !== undefined;
    this.result = this.alertCreated
      ? `${safetyStore.lastLocationMessage}. A safe-area alert was created; open Alerts in the Guardian view to see it.`
      : `${safetyStore.lastLocationMessage}.`;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          NoticeBanner({ text: 'Developer tool. These samples replace the device location for the Safe Area screen.' })

          Column({ space: 8 }) {
            sectionTitle('Replay a location sample')
            Column() {
              ActionRow({
                icon: $r('sys.symbol.house_fill'),
                title: 'Inside home',
                summary: 'Senior is within the safe area',
                showDivider: true,
                showChevron: false,
                onTap: () => this.replay(GeofenceStatus.Inside)
              })
              ActionRow({
                icon: $r('sys.symbol.figure_walk'),
                title: 'Outside safe area',
                summary: 'Creates an alert on the first exit',
                accent: $r('app.color.sos'),
                tint: $r('app.color.sos_tint'),
                showDivider: true,
                showChevron: false,
                onTap: () => this.replay(GeofenceStatus.Outside)
              })
              ActionRow({
                icon: $r('sys.symbol.questionmark_circle_fill'),
                title: 'Location unavailable',
                summary: 'No usable location fix',
                accent: $r('app.color.text_secondary'),
                tint: $r('app.color.page_background'),
                showChevron: false,
                onTap: () => this.replay(GeofenceStatus.Unknown)
              })
            }
            .width('100%')
            .borderRadius(20)
            .clip(true)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            sectionTitle('On-device AI and speech')
            Column() {
              ActionRow({
                icon: $r('sys.symbol.checkmark_shield_fill'),
                title: this.diagnosing ? 'Running…' : 'Run diagnostics',
                summary: 'Loads the bundled model, re-checks its answers and speech support',
                showChevron: false,
                onTap: () => this.diagnose()
              })
            }
            .width('100%')
            .borderRadius(20)
            .clip(true)
            .backgroundColor($r('app.color.surface'))
            if (this.diagnostics.length > 0) {
              Text(this.diagnostics.join('\n'))
                .fontSize(13)
                .fontFamily('monospace')
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding(12)
                .borderRadius(14)
                .backgroundColor($r('app.color.surface'))
                .copyOption(CopyOptions.LocalDevice)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.result !== '') {
            NoticeBanner({
              icon: this.alertCreated ? $r('sys.symbol.exclamationmark_circle_fill') : $r('sys.symbol.checkmark_circle_fill'),
              text: this.result,
              accent: this.alertCreated ? $r('app.color.sos') : $r('app.color.senior_accent'),
              tint: this.alertCreated ? $r('app.color.sos_tint') : $r('app.color.senior_tint')
            })
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
    .title('Developer Tools')
    .backgroundColor($r('app.color.page_background'))
  }
}

import { common } from '@kit.AbilityKit';
import { K_PAIRED } from '../models/WatchState';
import { watchApi, WatchApiError, watchSession } from '../services/WatchApi';
import { watchSessionStore } from '../services/WatchSessionStore';

const CODE_LENGTH = 6;
const KEYS: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'del', '0', 'ok'];

/** Big keypad for the 6-digit code shown on the senior's phone (Settings, Smartwatch, Pair a watch). */
@Component
export struct PairingView {
  @State private code: string = '';
  @State private message: string = 'Enter the code from your phone';
  @State private busy: boolean = false;

  private async pair(): Promise<void> {
    if (this.code.length !== CODE_LENGTH || this.busy) {
      return;
    }
    this.busy = true;
    this.message = 'Pairing…';
    try {
      const result = await watchApi.claim(watchSession.baseUrl, this.code);
      watchSession.token = result.token;
      watchSession.seniorId = result.seniorId;
      watchSession.deviceId = result.deviceId;
      await watchSessionStore.save(this.getUIContext().getHostContext() as common.UIAbilityContext);
      AppStorage.set<boolean>(K_PAIRED, true);
    } catch (error) {
      const status = error instanceof WatchApiError ? error.status : 0;
      this.message = status === 410 ? 'Wrong or expired code. Get a new one on the phone.'
        : status === 429 ? 'Too many tries. Wait 15 minutes.'
          : status === 0 ? 'Cannot reach Carely. Check the connection.'
            : 'Pairing failed. Try again.';
      this.code = '';
    } finally {
      this.busy = false;
    }
  }

  private press(key: string): void {
    if (this.busy) {
      return;
    }
    if (key === 'del') {
      this.code = this.code.slice(0, -1);
    } else if (key === 'ok') {
      this.pair();
    } else if (this.code.length < CODE_LENGTH) {
      this.code += key;
    }
  }

  private keyLabel(key: string): string {
    return key === 'del' ? '⌫' : key === 'ok' ? 'OK' : key;
  }

  private keyAccessibility(key: string): string {
    return key === 'del' ? 'Delete digit' : key === 'ok' ? 'Pair watch' : key;
  }

  @Builder
  keyButton(key: string) {
    Button(this.keyLabel(key))
      .width(46)
      .height(34)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .fontColor(key === 'ok' ? Color.Black : $r('app.color.watch_text'))
      .backgroundColor(key === 'ok' ? $r('app.color.watch_accent') : $r('app.color.watch_surface'))
      .enabled(key !== 'ok' || this.code.length === CODE_LENGTH)
      .opacity(key === 'ok' && this.code.length !== CODE_LENGTH ? 0.4 : 1)
      .accessibilityText(this.keyAccessibility(key))
      .onClick(() => this.press(key))
  }

  build() {
    Scroll() {
      Column({ space: 6 }) {
        Text('Pair with Carely')
          .fontSize(13)
          .fontColor($r('app.color.watch_text_secondary'))
        Text(this.code.padEnd(CODE_LENGTH, '•'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(4)
          .fontColor($r('app.color.watch_text'))
          .accessibilityText(`${this.code.length} of ${CODE_LENGTH} digits entered`)
        Grid() {
          ForEach(KEYS, (key: string) => {
            GridItem() {
              this.keyButton(key)
            }
          }, (key: string) => key)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(6)
        .rowsGap(5)
        .width(150)
        .height(151)
        Text(this.message)
          .fontSize(12)
          .fontColor($r('app.color.watch_text_secondary'))
          .textAlign(TextAlign.Center)
          .width(150)
      }
      .width('100%')
      .padding({ top: 22, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }
}

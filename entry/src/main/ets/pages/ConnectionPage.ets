import { http } from '@kit.NetworkKit';
import { apiSession, BootstrapRequest, careApi } from '../services/CareApi';

@Component
export struct ConnectionPage {
  @Consume('navStack') navStack: NavPathStack;
  onConnected: (role: string) => void = (role: string) => {};
  @State private name: string = '';
  @State private code: string = '';
  @State private guardian: boolean = false;
  @State private message: string = '';
  @State private connected: boolean = false;
  @State private pairingCode: string = '';

  private async connect(): Promise<void> {
    try {
      const body = new BootstrapRequest(this.name);
      if (this.guardian) body.code = this.code;
      const path = this.guardian ? '/pairing/claim' : '/seniors';
      const result = await careApi.publicRequest(apiSession.baseUrl, path, http.RequestMethod.POST, body) as Record<string, string>;
      apiSession.token = result['token'];
      apiSession.seniorId = result['seniorId'];
      apiSession.role = this.guardian ? 'guardian' : 'senior';
      this.pairingCode = this.guardian ? '' : result['pairingCode'];
      this.message = this.guardian ? 'You are paired with your senior.' : 'Share this code with your guardian.';
      this.connected = true;
    } catch (error) {
      this.message = `Could not connect: ${JSON.stringify(error)}`;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        if (this.connected) {
          Text(this.guardian ? 'You are connected' : 'Pair your guardian')
            .fontSize(28).fontWeight(FontWeight.Bold)
          Text(this.message).fontSize(16).fontColor($r('app.color.text_secondary'))
          if (!this.guardian) {
            Text(this.pairingCode).fontSize(42).fontWeight(FontWeight.Bold).width('100%').textAlign(TextAlign.Center)
            Text('Give this six-digit code to your guardian.').fontSize(16).width('100%').textAlign(TextAlign.Center)
          }
          Button('Continue').width('100%').onClick(() => this.onConnected(apiSession.role))
        } else {
          Text(this.guardian ? 'Pair with your senior' : 'Set up this phone').fontSize(28).fontWeight(FontWeight.Bold)
          Text(this.guardian ? 'Enter the pairing code from your senior.' : 'Create your senior account and get a pairing code.')
            .fontSize(16).fontColor($r('app.color.text_secondary'))
          TextInput({ text: this.name, placeholder: 'Your name' }).width('100%').onChange((v: string) => this.name = v)
          Row({ space: 12 }) {
            Button('I am a senior')
              .layoutWeight(1)
              .fontColor(!this.guardian ? Color.White : $r('app.color.text_primary'))
              .backgroundColor(!this.guardian ? $r('app.color.senior_accent') : $r('app.color.surface'))
              .onClick(() => this.guardian = false)
            Button('I am a guardian')
              .layoutWeight(1)
              .fontColor(this.guardian ? Color.White : $r('app.color.text_primary'))
              .backgroundColor(this.guardian ? $r('app.color.guardian_accent') : $r('app.color.surface'))
              .onClick(() => this.guardian = true)
          }
          .width('100%')
          if (this.guardian) {
            TextInput({ text: this.code, placeholder: '6-digit pairing code' }).width('100%').onChange((v: string) => this.code = v)
          }
          Button('Connect').width('100%').onClick(() => this.connect())
          Text(this.message).fontSize(14).width('100%')
        }
      }.width('100%').height('100%').alignItems(HorizontalAlign.Start).padding(20)
    }.title('Connection').backgroundColor($r('app.color.page_background'))
  }
}

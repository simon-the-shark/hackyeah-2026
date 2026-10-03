import { http } from '@kit.NetworkKit';
import common from '@ohos.app.ability.common';
import { apiSession, BootstrapRequest, careApi } from '../services/CareApi';
import { apiSessionStore } from '../services/ApiSessionStore';
import { CareButtonStyle, CareInputStyle } from '../components/DesignSystem';
import { NoticeBanner } from '../components/Common';

@Component
export struct ConnectionPage {
  @Consume('navStack') navStack: NavPathStack;
  onConnected: (role: string) => void = (role: string) => {};
  @State private name: string = '';
  @State private code: string = '';
  @State private guardian: boolean = false;
  @State private message: string = '';
  @State private busy: boolean = false;
  @State private nameError: string = '';
  @State private codeError: string = '';

  private async connect(): Promise<void> {
    if (this.busy) return;
    this.nameError = this.name.trim() === '' ? 'Enter your name to continue.' : '';
    this.codeError = this.guardian && !/^[0-9]{6}$/.test(this.code.trim()) ? 'Enter the six-digit code from your senior.' : '';
    if (this.nameError !== '' || this.codeError !== '') return;
    this.busy = true;
    this.message = 'Connecting to the care service…';
    try {
      const body = new BootstrapRequest(this.name.trim());
      if (this.guardian) body.code = this.code.trim();
      const path = this.guardian ? '/pairing/claim' : '/seniors';
      const result = await careApi.publicRequest(apiSession.baseUrl, path, http.RequestMethod.POST, body) as Record<string, string>;
      apiSession.token = result['token'];
      apiSession.seniorId = result['seniorId'];
      apiSession.role = this.guardian ? 'guardian' : 'senior';
      apiSession.displayName = this.name.trim();
      await apiSessionStore.save(this.getUIContext().getHostContext() as common.UIAbilityContext);
      this.onConnected(apiSession.role);
    } catch (error) {
      this.message = this.guardian ? 'Could not pair this phone. Check the code and your internet connection, then try again.' :
        'Could not set up this phone. Check your internet connection, then try again.';
    } finally {
      this.busy = false;
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Text(this.guardian ? 'Enter the pairing code from your senior.' : 'Set up your account. Share your guardian code from Home → Settings → Pairing.')
            .fontSize(19).fontColor($r('app.color.text_secondary'))
          Text('Your name').fontSize(19).fontColor($r('app.color.text_primary'))
          TextInput({ text: this.name, placeholder: 'Enter your name' })
            .width('100%')
            .attributeModifier(new CareInputStyle('Your name', this.nameError))
            .enabled(!this.busy)
            .onChange((v: string) => this.name = v)
          if (this.nameError !== '') {
            Text(this.nameError).fontSize(17).fontColor($r('app.color.sos'))
          }
          Text('Choose a role')
            .fontSize(19)
            .fontColor($r('app.color.text_primary'))
          Text('Select one option')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
          Column({ space: 12 }) {
            Button() {
              Row({ space: 10 }) {
                if (!this.guardian) {
                  SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                    .fontSize(20)
                    .fontColor([$r('app.color.senior_accent')])
                }
                Text('I am a senior')
                  .fontSize(19)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.senior_accent'))
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
              .type(ButtonType.Capsule)
              .width('100%')
              .attributeModifier(new CareButtonStyle('secondary'))
              .accessibilitySelected(!this.guardian)
              .accessibilityText('I am a senior')
              .accessibilityDescription(!this.guardian ? 'Selected role' : 'Select senior role')
              .enabled(!this.busy)
              .onClick(() => this.guardian = false)
            Button() {
              Row({ space: 10 }) {
                if (this.guardian) {
                  SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                    .fontSize(20)
                    .fontColor([$r('app.color.senior_accent')])
                }
                Text('I am a guardian')
                  .fontSize(19)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.senior_accent'))
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
              .type(ButtonType.Capsule)
              .width('100%')
              .attributeModifier(new CareButtonStyle('secondary'))
              .accessibilitySelected(this.guardian)
              .accessibilityText('I am a guardian')
              .accessibilityDescription(this.guardian ? 'Selected role' : 'Select guardian role')
              .enabled(!this.busy)
              .onClick(() => this.guardian = true)
          }
          .width('100%')
          if (this.guardian) {
            Text('Pairing code').fontSize(19).fontColor($r('app.color.text_primary'))
            TextInput({ text: this.code, placeholder: '6 digits' })
              .width('100%')
              .attributeModifier(new CareInputStyle('Six-digit pairing code', this.codeError))
              .type(InputType.Number)
              .maxLength(6)
              .enabled(!this.busy)
              .onChange((v: string) => this.code = v)
            if (this.codeError !== '') {
              Text(this.codeError).fontSize(17).fontColor($r('app.color.sos'))
            }
          }
          Button(this.busy ? 'Connecting…' : this.guardian ? 'Pair with senior' : 'Set up senior phone')
            .width('100%')
            .attributeModifier(new CareButtonStyle())
            .enabled(!this.busy)
            .onClick(() => this.connect())
          if (this.message !== '') {
            NoticeBanner({ text: this.message })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
    }.title(this.guardian ? 'Pair with your senior' : 'Set up this phone').backgroundColor($r('app.color.page_background'))
  }
}

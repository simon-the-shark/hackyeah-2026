import { common } from '@kit.AbilityKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { CareButtonStyle } from '../components/DesignSystem';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { WellbeingReportView } from '../components/WellbeingReportView';
import {
  AssistantInfo,
  Attention,
  attentionLabel,
  ChatMessage,
  ChatRole,
  guardianNamesText,
  WellbeingReport
} from '../models/Wellbeing';
import { MicrophoneAccess, openMicrophoneSettings, requestMicrophone } from '../platform/Microphone';
import { FinishReason } from '../providers/backend/WellbeingApi';
import { describeBackendError, NOT_CONFIGURED_MESSAGE } from '../services/BackendErrors';
import { apiSession } from '../services/CareApi';
import { LiveState, LiveVoiceSession } from '../services/LiveVoiceSession';
import { describeCheckInError, wellbeingCheckIn } from '../services/WellbeingService';

enum Phase {
  Loading,
  Failed,
  NotConfigured,
  Starting,
  Talk,
  Done
}

/** Why the conversation stopped, in words. */
function describeLiveEnd(code: string): string {
  if (code === 'assistant_unavailable') {
    return 'Talking with Carely is not available right now. Please try again in a few minutes.';
  }
  if (code === 'rate_limited') {
    return 'Too many conversations in a short time. Please wait a little and try again.';
  }
  if (code === 'time_limit') {
    return 'The conversation reached its time limit. Tap Continue talking to go on.';
  }
  if (code === 'session_full') {
    return 'This check-in is already long. Please press Finish to send the summary.';
  }
  if (code === 'session_closed') {
    return 'This check-in has already ended. You can start a new one.';
  }
  return 'The connection stopped. Check the internet connection, then tap Continue talking.';
}

/**
 * The senior's Wellbeing tab: a short spoken check-in with Carely. The senior just talks; the
 * backend relays the conversation to the voice model, notices when they have finished speaking, and
 * writes a summary for the guardian when Carely says goodbye. This screen shows the transcript,
 * exactly what was shared, and lets the senior remove it. SOS never depends on this screen.
 */
@Component
export struct WellbeingCheckIn {
  @Consume('navStack') navStack: NavPathStack;
  /** Bumped when the tab or page becomes visible again. */
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  /** False while another tab is shown: the conversation pauses. */
  @Prop @Watch('onVisibility') visible: boolean = true;
  @State private phase: Phase = Phase.Loading;
  @State private loadError: string = '';
  @State private notice: string = '';
  @State private assistant: AssistantInfo = new AssistantInfo();
  @State private guardians: string = 'your guardian';
  @State private sessionId: string = '';
  @State private messages: ChatMessage[] = [];
  @State private finishing: boolean = false;
  @State private micDenied: boolean = false;
  @State private safetyConcern: boolean = false;
  /** The conversation is running: the microphone streams and Carely answers aloud. */
  @State private live: boolean = false;
  @State private liveState: LiveState = LiveState.Connecting;
  @State private report: WellbeingReport | undefined = undefined;
  @State private removed: boolean = false;
  @State private removing: boolean = false;
  private liveSession: LiveVoiceSession | undefined = undefined;
  private loadingState: boolean = false;
  private liveStarting: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    if (this.visible) {
      this.load();
    }
  }

  aboutToDisappear(): void {
    this.stopLive();
  }

  private onRefresh(): void {
    if (!this.visible) {
      return;
    }
    if (this.phase === Phase.Loading || this.phase === Phase.Failed || this.phase === Phase.NotConfigured) {
      this.load();
    } else {
      this.refreshDetails();
    }
  }

  private onVisibility(): void {
    if (!this.visible) {
      this.stopLive();
    } else if (this.phase === Phase.Loading) {
      this.load();
    } else if (this.phase === Phase.Talk && !this.live) {
      this.startLive();
    }
  }

  private context(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  /** Guardian names and assistant availability can change while a check-in is open. */
  private async refreshDetails(): Promise<void> {
    try {
      const state = await wellbeingCheckIn.state();
      this.assistant = state.assistant;
      this.guardians = guardianNamesText(state.guardianNames);
    } catch (error) {
      // Keep what is shown; the next refresh tries again.
    }
  }

  private async load(): Promise<void> {
    if (this.loadingState || !this.visible) {
      return;
    }
    if (!apiSession.configured()) {
      this.phase = Phase.NotConfigured;
      return;
    }
    this.loadingState = true;
    this.phase = Phase.Loading;
    try {
      const state = await wellbeingCheckIn.state();
      this.assistant = state.assistant;
      this.guardians = guardianNamesText(state.guardianNames);
      if (state.session !== undefined) {
        // Resume an open check-in immediately when the Wellbeing tab is opened.
        this.sessionId = state.session.id;
        this.messages = state.messages;
        this.safetyConcern = state.messages.some((message: ChatMessage) => message.safetyConcern);
        this.phase = Phase.Talk;
        this.scrollToEnd();
        this.startLive();
      } else if (this.assistant.live) {
        // Skip the former explainer screen and enter a new check-in directly.
        await this.start();
      } else {
        this.loadError = 'Talking with Carely is not available right now. Please try again in a few minutes.';
        this.phase = Phase.Failed;
      }
    } catch (error) {
      this.loadError = describeBackendError(error as Object, 'Something went wrong while opening the check-in.');
      this.phase = Phase.Failed;
    } finally {
      this.loadingState = false;
    }
  }

  private async start(): Promise<void> {
    this.phase = Phase.Starting;
    this.notice = '';
    try {
      const started = await wellbeingCheckIn.start(true);
      this.sessionId = started.session.id;
      this.messages = started.messages;
      this.safetyConcern = false;
      this.report = undefined;
      this.removed = false;
      this.phase = Phase.Talk;
      if (this.visible) {
        this.startLive();
      }
    } catch (error) {
      this.loadError = describeCheckInError(error as Object, 'The check-in could not start. Please try again.');
      this.phase = Phase.Failed;
    }
  }

  private async startLive(): Promise<void> {
    if (this.live || this.liveStarting || !this.visible || this.sessionId === '' || this.finishing) {
      return;
    }
    this.notice = '';
    this.liveStarting = true;
    const access = await requestMicrophone(this.context());
    this.liveStarting = false;
    if (access !== MicrophoneAccess.Granted) {
      this.micDenied = access === MicrophoneAccess.Denied;
      this.notice = 'Carely needs the microphone to hear you.';
      return;
    }
    if (!this.visible) {
      return;
    }
    this.micDenied = false;
    const session = new LiveVoiceSession({
      onState: (state: LiveState) => {
        this.liveState = state;
        this.scrollToEnd();
      },
      onMessage: (message: ChatMessage) => {
        if (!this.messages.some((known: ChatMessage) => known.id === message.id)) {
          this.messages = this.messages.concat([message]);
          this.scrollToEnd();
        }
      },
      onSafetyConcern: () => {
        this.safetyConcern = true;
      },
      onFinished: (report: WellbeingReport | undefined) => {
        this.liveSession = undefined;
        this.live = false;
        this.completeWithReport(report);
      },
      onEnded: (code: string) => {
        this.liveSession = undefined;
        this.live = false;
        this.notice = describeLiveEnd(code);
        if (code === 'session_closed') {
          this.load();
        }
      }
    });
    this.liveSession = session;
    this.liveState = LiveState.Connecting;
    this.live = true;
    try {
      await session.start(wellbeingCheckIn.currentSeniorId(), this.sessionId);
    } catch (error) {
      this.liveSession = undefined;
      this.live = false;
      this.notice = 'The microphone or speaker does not work on this phone right now.';
    }
  }

  /** Pauses the conversation; the check-in stays open and Continue talking resumes it. */
  private stopLive(): void {
    const session = this.liveSession;
    this.liveSession = undefined;
    this.live = false;
    if (session !== undefined) {
      session.stop();
    }
  }

  private scrollToEnd(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }

  private confirmFinish(): void {
    this.getUIContext().showAlertDialog({
      title: 'Finish the check-in?',
      message: `Carely will send a short summary to ${this.guardians}.`,
      autoCancel: true,
      primaryButton: {
        value: 'Keep talking',
        action: () => {
        }
      },
      secondaryButton: {
        value: 'Finish and send',
        action: () => {
          this.finish();
        }
      }
    });
  }

  private async finish(): Promise<void> {
    if (this.finishing) {
      return;
    }
    this.stopLive();
    this.finishing = true;
    this.notice = '';
    try {
      await this.completeWithReport(await wellbeingCheckIn.finish(this.sessionId, FinishReason.Senior));
    } catch (error) {
      this.notice = describeCheckInError(error as Object,
        'The summary could not be sent. Please press Finish again in a moment.');
    } finally {
      this.finishing = false;
    }
  }

  /** Shows what was shared, whether the senior pressed Finish or Carely ended the conversation. */
  private async completeWithReport(report: WellbeingReport | undefined): Promise<void> {
    this.sessionId = '';
    this.messages = [];
    if (report === undefined) {
      this.loadError = 'Nothing was sent because there were no answers yet. Try again when you are ready.';
      this.phase = Phase.Failed;
      return;
    }
    this.report = report;
    this.removed = false;
    await this.refreshDetails();
    this.phase = Phase.Done;
  }

  private confirmRemove(): void {
    this.getUIContext().showAlertDialog({
      title: 'Remove this summary?',
      message: `${this.guardians} will no longer be able to read it.`,
      autoCancel: true,
      primaryButton: {
        value: 'Keep it',
        action: () => {
        }
      },
      secondaryButton: {
        value: 'Remove',
        fontColor: $r('app.color.sos'),
        action: () => {
          this.remove();
        }
      }
    });
  }

  private async remove(): Promise<void> {
    const report = this.report;
    if (report === undefined || this.removing) {
      return;
    }
    this.removing = true;
    this.notice = '';
    try {
      await wellbeingCheckIn.withdraw(this.context(), report.id);
      this.removed = true;
    } catch (error) {
      this.notice = describeCheckInError(error as Object, 'The summary could not be removed. Please try again.');
    } finally {
      this.removing = false;
    }
  }

  @Builder
  bubble(message: ChatMessage) {
    Row() {
      Text(message.text)
        .fontSize(20)
        .lineHeight(28)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .constraintSize({ maxWidth: '86%' })
        .borderRadius(20)
        .backgroundColor(message.role === ChatRole.Senior ? $r('app.color.senior_tint') : $r('app.color.surface'))
        .accessibilityText(`${message.role === ChatRole.Senior ? 'You' : 'Carely'}: ${message.text}`)
    }
    .width('100%')
    .justifyContent(message.role === ChatRole.Senior ? FlexAlign.End : FlexAlign.Start)
  }

  @Builder
  sosBanner() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.exclamationmark_shield_fill'))
        .fontSize(26)
        .fontColor([$r('app.color.sos')])
      Text('If you need help now, press SOS.')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Button('SOS')
        .height(56)
        .attributeModifier(new CareButtonStyle('danger'))
        .accessibilityText('Open SOS to ask for help')
        .onClick(() => this.navStack.pushPathByName('sos', null))
    }
    .width('100%')
    .padding({ left: 14, right: 10, top: 8, bottom: 8 })
    .borderRadius(18)
    .backgroundColor($r('app.color.sos_tint'))
  }

  private liveTitle(): string {
    if (this.finishing || (this.live && this.liveState === LiveState.Finishing)) {
      return `Sending the summary to ${this.guardians}…`;
    }
    if (!this.live) {
      return 'Paused';
    }
    if (this.liveState === LiveState.Connecting) {
      return 'Connecting…';
    }
    if (this.liveState === LiveState.SeniorSpeaking) {
      return 'Listening…';
    }
    if (this.liveState === LiveState.Thinking) {
      return 'Carely is thinking…';
    }
    if (this.liveState === LiveState.CarelySpeaking) {
      return 'Carely is speaking';
    }
    return 'I am listening';
  }

  private liveHint(): string {
    if (this.finishing) {
      return '';
    }
    if (!this.live) {
      return 'Tap Continue talking when you are ready.';
    }
    if (this.liveState === LiveState.Listening) {
      return 'Just speak. There is no need to press anything.';
    }
    if (this.liveState === LiveState.SeniorSpeaking) {
      return 'Take your time.';
    }
    if (this.liveState === LiveState.CarelySpeaking) {
      return 'You can answer when she has finished.';
    }
    return '';
  }

  private liveAccent(): Resource {
    if (!this.live) {
      return $r('app.color.text_secondary');
    }
    if (this.liveState === LiveState.SeniorSpeaking || this.liveState === LiveState.Listening) {
      return $r('app.color.senior_accent');
    }
    return this.liveState === LiveState.CarelySpeaking ? $r('app.color.success') : $r('app.color.text_secondary');
  }

  private busy(): boolean {
    return this.finishing || (this.live && (this.liveState === LiveState.Connecting ||
      this.liveState === LiveState.Thinking || this.liveState === LiveState.Finishing));
  }

  private listeningScale(): number {
    return this.live && this.liveState === LiveState.SeniorSpeaking ? 1.12 : 1;
  }

  /** What is happening now, in large words, with the few controls the senior may need. */
  @Builder
  livePanel() {
    Column({ space: 12 }) {
      if (this.notice !== '') {
        NoticeBanner({ text: this.notice })
        if (this.micDenied) {
          Button('Allow the microphone')
            .width('100%')
            .attributeModifier(new CareButtonStyle('secondary'))
            .onClick(async () => {
              if (await openMicrophoneSettings(this.context())) {
                this.micDenied = false;
                this.startLive();
              }
            })
        }
      }

      Row({ space: 16 }) {
        Row() {
          if (this.busy()) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(Color.White)
          } else {
            SymbolGlyph(this.live && this.liveState === LiveState.CarelySpeaking ?
            $r('sys.symbol.speaker_wave_2_fill') : $r('sys.symbol.mic_fill'))
              .fontSize(36)
              .fontColor([Color.White])
          }
        }
        .width(72)
        .height(72)
        .borderRadius(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.liveAccent())
        .scale({ x: this.listeningScale(), y: this.listeningScale() })
        .animation({ duration: 250, curve: Curve.EaseOut })

        Column({ space: 4 }) {
          Text(this.liveTitle())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          if (this.liveHint() !== '') {
            Text(this.liveHint())
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .accessibilityGroup(true)
      .accessibilityText(`${this.liveTitle()}. ${this.liveHint()}`)

      if (!this.live && !this.finishing) {
        Button() {
          Row({ space: 10 }) {
            SymbolGlyph($r('sys.symbol.mic_fill'))
              .fontSize(24)
              .fontColor([Color.White])
            Text('Continue talking')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(64)
        .attributeModifier(new CareButtonStyle())
        .enabled(this.assistant.live)
        .onClick(() => this.startLive())
      } else if (this.live && this.liveState === LiveState.CarelySpeaking) {
        Button('Let me talk')
          .width('100%')
          .attributeModifier(new CareButtonStyle('secondary'))
          .accessibilityText('Stop Carely and answer now')
          .onClick(() => this.liveSession?.interrupt())
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  talk() {
    Column() {
      Row({ space: 12 }) {
        Text('Talking with Carely')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Button('Finish')
          .attributeModifier(new CareButtonStyle('secondary'))
          .enabled(!this.finishing && !(this.live && this.liveState === LiveState.Finishing))
          .accessibilityText(`Finish the check-in and send a summary to ${this.guardians}`)
          .onClick(() => this.confirmFinish())
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 4, bottom: 8 })

      if (this.safetyConcern) {
        Column() {
          this.sosBanner()
        }
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      Scroll(this.scroller) {
        Column({ space: 12 }) {
          ForEach(this.messages, (message: ChatMessage) => {
            this.bubble(message)
          }, (message: ChatMessage) => message.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Column() {
        this.livePanel()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  done() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          IconBadge({
            icon: this.removed ? $r('sys.symbol.trash') : $r('sys.symbol.checkmark_circle_fill'),
            accent: this.removed ? $r('app.color.text_secondary') : $r('app.color.success'),
            tint: $r('app.color.surface'),
            badgeSize: 56
          })
          Text(this.removed ? 'Summary removed' : `Summary sent to ${this.guardians}`)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(this.removed ? `${this.guardians} can no longer read it.` :
            'Thank you for checking in. Below is exactly what was shared.')
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .opacity(0.85)
        }
        .width('100%')
        .padding(20)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(24)
        .backgroundColor(this.removed ? $r('app.color.surface') : $r('app.color.success_tint'))
        .accessibilityGroup(true)

        if (this.report !== undefined && !this.removed) {
          Column({ space: 14 }) {
            Text(`What ${this.guardians} will read`)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
            if (this.report.attention !== Attention.None) {
              Text(`Carely marked it: ${attentionLabel(this.report.attention)}.`)
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            WellbeingReportView({ report: this.report })
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
          .borderRadius(20)
          .backgroundColor($r('app.color.surface'))
        }

        if (this.notice !== '') {
          NoticeBanner({ text: this.notice })
        }

        Button('Start a new check-in')
          .width('100%')
          .height(60)
          .attributeModifier(new CareButtonStyle())
          .onClick(() => {
            this.notice = '';
            this.phase = Phase.Loading;
            this.load();
          })
        if (!this.removed) {
          Button(this.removing ? 'Removing…' : 'Remove this summary')
            .width('100%')
            .attributeModifier(new CareButtonStyle('danger-secondary'))
            .enabled(!this.removing)
            .onClick(() => this.confirmRemove())
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      if (this.phase === Phase.Loading) {
        LoadingMessage({ message: 'Opening your check-in…' })
      } else if (this.phase === Phase.Failed) {
        StatusMessage({
          icon: $r('sys.symbol.wifi_slash'),
          title: 'Check-in not available',
          message: this.loadError,
          onRetry: () => this.load()
        })
      } else if (this.phase === Phase.NotConfigured) {
        StatusMessage({
          icon: $r('sys.symbol.exclamationmark_triangle_fill'),
          title: 'Not connected yet',
          message: NOT_CONFIGURED_MESSAGE
        })
      } else if (this.phase === Phase.Talk) {
        this.talk()
      } else if (this.phase === Phase.Done) {
        this.done()
      } else {
        LoadingMessage({ message: 'Starting your check-in…' })
      }
    }
    .width('100%')
    .height('100%')
  }
}

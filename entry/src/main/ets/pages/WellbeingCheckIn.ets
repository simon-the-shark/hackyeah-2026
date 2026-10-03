import { common } from '@kit.AbilityKit';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { IconBadge, NoticeBanner } from '../components/Common';
import { CareButtonStyle, CareTextAreaStyle } from '../components/DesignSystem';
import { LoadingMessage, StatusMessage } from '../components/StatusMessage';
import { WellbeingReportView } from '../components/WellbeingReportView';
import {
  AssistantInfo,
  Attention,
  attentionLabel,
  ChatMessage,
  ChatRole,
  Exchange,
  guardianNamesText,
  WellbeingReport
} from '../models/Wellbeing';
import { formatClockTime } from '../models/Safety';
import {
  MicrophoneAccess,
  openMicrophoneSettings,
  requestMicrophone,
  VOICE_FORMAT,
  VoiceRecorder
} from '../platform/VoiceRecorder';
import { VoicePlayer } from '../platform/VoicePlayer';
import { ApiError } from '../providers/backend/BackendClient';
import { FinishReason } from '../providers/backend/WellbeingApi';
import { describeBackendError, NOT_CONFIGURED_MESSAGE } from '../services/BackendErrors';
import { apiSession } from '../services/CareApi';
import { describeCheckInError, SharedSummary, wellbeingCheckIn } from '../services/WellbeingService';

enum Phase {
  Loading,
  Failed,
  NotConfigured,
  Intro,
  Starting,
  Chat,
  Done
}

enum Mic {
  Idle,
  Recording,
  Sending
}

/** A spoken answer longer than this stops by itself, so a forgotten recording cannot run on. */
const MAX_RECORDING_SECONDS = 60;
const PENDING_ID = 'pending';

function sharedDateLabel(timestamp: number): string {
  const date = new Date(timestamp);
  const today = new Date();
  if (date.toDateString() === today.toDateString()) {
    return `Today at ${formatClockTime(timestamp)}`;
  }
  return `${date.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' })} at ` +
    formatClockTime(timestamp);
}

function elapsedLabel(seconds: number): string {
  return `${Math.floor(seconds / 60)}:${(seconds % 60).toString().padStart(2, '0')}`;
}

/**
 * The senior's Wellbeing tab: a short daily check-in chat with the assistant, by voice or text.
 * When it ends, the backend writes a summary for the guardian; this screen shows exactly what was
 * shared and lets the senior remove it. SOS never depends on this screen or the assistant.
 */
@Component
export struct WellbeingCheckIn {
  @Consume('navStack') navStack: NavPathStack;
  /** Bumped when the tab or page becomes visible again. */
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  /** False while another tab is shown: recording and reading aloud stop. */
  @Prop @Watch('onVisibility') visible: boolean = true;
  @State @Watch('applyKeyboardMode') private phase: Phase = Phase.Loading;
  @State private loadError: string = '';
  @State private notice: string = '';
  @State private assistant: AssistantInfo = new AssistantInfo();
  @State private guardians: string = 'your guardian';
  @State private sessionId: string = '';
  @State private simulated: boolean = false;
  @State private messages: ChatMessage[] = [];
  @State private draft: string = '';
  @State private thinking: boolean = false;
  @State private finishing: boolean = false;
  @State private mic: Mic = Mic.Idle;
  @State private micDenied: boolean = false;
  @State private recordSeconds: number = 0;
  @State private safetyConcern: boolean = false;
  /** Read each new reply aloud; switched on once the senior speaks. */
  @State private readAloud: boolean = false;
  /** Id of the reply being read aloud, or fetched for reading. */
  @State private speakingId: string = '';
  @State private report: WellbeingReport | undefined = undefined;
  @State private removed: boolean = false;
  @State private removing: boolean = false;
  @State private lastShared: SharedSummary | undefined = undefined;
  private recorder: VoiceRecorder = new VoiceRecorder();
  private player: VoicePlayer = new VoicePlayer();
  private scroller: Scroller = new Scroller();
  private recordTimer: number = -1;
  /** The window's keyboard mode before the chat switched it to RESIZE; undefined while not switched. */
  private savedKeyboardMode: KeyboardAvoidMode | undefined = undefined;

  aboutToAppear(): void {
    this.load();
  }

  aboutToDisappear(): void {
    this.stopVoice();
    this.restoreKeyboardMode();
  }

  private onRefresh(): void {
    if (this.phase === Phase.Intro || this.phase === Phase.Failed || this.phase === Phase.NotConfigured) {
      this.load();
    } else {
      this.refreshDetails();
    }
  }

  private onVisibility(): void {
    if (!this.visible) {
      this.stopVoice();
    }
    this.applyKeyboardMode();
  }

  /**
   * While the chat is on screen the keyboard shrinks the page (RESIZE) instead of pushing it up,
   * so the newest messages and the input stay visible under the title. Other screens keep their mode.
   */
  private applyKeyboardMode(): void {
    const ui = this.getUIContext();
    const chatShown = this.visible && this.phase === Phase.Chat;
    if (chatShown && this.savedKeyboardMode === undefined) {
      this.savedKeyboardMode = ui.getKeyboardAvoidMode();
      ui.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    } else if (!chatShown) {
      this.restoreKeyboardMode();
    }
  }

  private restoreKeyboardMode(): void {
    if (this.savedKeyboardMode !== undefined) {
      this.getUIContext().setKeyboardAvoidMode(this.savedKeyboardMode);
      this.savedKeyboardMode = undefined;
    }
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

  private context(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private stopVoice(): void {
    this.stopTimer();
    if (this.mic === Mic.Recording) {
      this.mic = Mic.Idle;
    }
    this.recorder.cancel();
    this.player.stop();
  }

  private async load(): Promise<void> {
    if (!apiSession.configured()) {
      this.phase = Phase.NotConfigured;
      return;
    }
    if (this.phase !== Phase.Intro) {
      this.phase = Phase.Loading;
    }
    try {
      const state = await wellbeingCheckIn.state();
      this.assistant = state.assistant;
      this.guardians = guardianNamesText(state.guardianNames);
      this.lastShared = await wellbeingCheckIn.lastShared(this.context());
      if (state.session !== undefined) {
        this.sessionId = state.session.id;
        this.simulated = state.session.simulated;
        this.messages = state.messages;
        this.safetyConcern = state.messages.some((message: ChatMessage) => message.safetyConcern);
        this.phase = Phase.Chat;
        this.scrollToEnd();
      } else {
        this.phase = Phase.Intro;
      }
    } catch (error) {
      this.loadError = describeBackendError(error as Object, 'Something went wrong while opening the check-in.');
      this.phase = Phase.Failed;
    }
  }

  private async start(): Promise<void> {
    this.phase = Phase.Starting;
    this.notice = '';
    try {
      const started = await wellbeingCheckIn.start();
      this.sessionId = started.session.id;
      this.simulated = started.session.simulated;
      this.messages = started.messages;
      this.safetyConcern = false;
      this.report = undefined;
      this.removed = false;
      this.phase = Phase.Chat;
      this.scrollToEnd();
    } catch (error) {
      this.notice = describeCheckInError(error as Object, 'The check-in could not start. Please try again.');
      this.phase = Phase.Intro;
    }
  }

  private scrollToEnd(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }

  private pendingMessage(text: string, voice: boolean): ChatMessage {
    const message = new ChatMessage();
    message.id = PENDING_ID;
    message.role = ChatRole.Senior;
    message.text = text;
    message.voice = voice;
    return message;
  }

  private withoutPending(): ChatMessage[] {
    return this.messages.filter((message: ChatMessage) => message.id !== PENDING_ID);
  }

  private async sendText(): Promise<void> {
    const text = this.draft.trim();
    if (text === '' || this.thinking || this.finishing) {
      return;
    }
    this.draft = '';
    this.notice = '';
    this.thinking = true;
    this.messages = this.withoutPending().concat([this.pendingMessage(text, false)]);
    this.scrollToEnd();
    try {
      this.applyExchange(await wellbeingCheckIn.sendText(this.sessionId, text));
    } catch (error) {
      this.messages = this.withoutPending();
      this.draft = text;
      this.handleSendError(error as Object);
    } finally {
      this.thinking = false;
    }
  }

  private async toggleMic(): Promise<void> {
    if (this.mic === Mic.Recording) {
      await this.stopAndSendVoice();
      return;
    }
    if (this.mic !== Mic.Idle || this.thinking || this.finishing) {
      return;
    }
    this.notice = '';
    await this.player.stop();
    const access = await requestMicrophone(this.context());
    if (access !== MicrophoneAccess.Granted) {
      this.micDenied = access === MicrophoneAccess.Denied;
      this.notice = 'Carely needs the microphone to hear you. You can type your answer instead.';
      return;
    }
    this.micDenied = false;
    try {
      await this.recorder.start(this.context());
    } catch (error) {
      this.notice = 'Recording does not work on this phone right now. Please type your answer instead.';
      return;
    }
    this.mic = Mic.Recording;
    this.recordSeconds = 0;
    this.recordTimer = setInterval(() => {
      this.recordSeconds++;
      if (this.recordSeconds >= MAX_RECORDING_SECONDS) {
        this.stopAndSendVoice();
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.recordTimer >= 0) {
      clearInterval(this.recordTimer);
      this.recordTimer = -1;
    }
  }

  private async cancelRecording(): Promise<void> {
    this.stopTimer();
    this.mic = Mic.Idle;
    await this.recorder.cancel();
  }

  private async stopAndSendVoice(): Promise<void> {
    if (this.mic !== Mic.Recording) {
      return;
    }
    this.stopTimer();
    this.mic = Mic.Sending;
    const audio = await this.recorder.stop();
    if (audio === undefined) {
      this.mic = Mic.Idle;
      this.notice = 'Nothing was recorded. Please try again, or type your answer.';
      return;
    }
    this.thinking = true;
    this.messages = this.withoutPending().concat([this.pendingMessage('Sending what you said…', true)]);
    this.scrollToEnd();
    try {
      this.readAloud = this.assistant.voice;
      this.applyExchange(await wellbeingCheckIn.sendVoice(this.sessionId, audio, VOICE_FORMAT));
    } catch (error) {
      this.messages = this.withoutPending();
      this.handleSendError(error as Object);
    } finally {
      this.thinking = false;
      this.mic = Mic.Idle;
    }
  }

  private applyExchange(exchange: Exchange): void {
    this.messages = this.withoutPending().concat([exchange.message, exchange.reply]);
    this.safetyConcern = this.safetyConcern || exchange.safetyConcern;
    this.scrollToEnd();
    if (this.readAloud) {
      this.speak(exchange.reply);
    }
    if (exchange.suggestFinish) {
      // The assistant has said goodbye: the summary goes out now, as the senior was told at the start.
      this.finish(FinishReason.Assistant);
    }
  }

  private handleSendError(error: Object): void {
    if (error instanceof ApiError && error.code === 'session_closed') {
      this.phase = Phase.Intro;
      this.load();
    }
    this.notice = describeCheckInError(error, 'Your message was not sent. Please try again.');
  }

  private async speak(message: ChatMessage): Promise<void> {
    if (this.speakingId === message.id) {
      // Also cancels a reply whose audio is still being fetched.
      this.speakingId = '';
      await this.player.stop();
      return;
    }
    await this.player.stop();
    this.speakingId = message.id;
    try {
      const audio = await wellbeingCheckIn.speech(message.text);
      if (this.speakingId !== message.id) {
        return;
      }
      await this.player.play(this.context(), audio, () => {
        if (this.speakingId === message.id) {
          this.speakingId = '';
        }
      });
    } catch (error) {
      if (this.speakingId === message.id) {
        this.speakingId = '';
      }
      this.notice = 'Reading aloud is not available right now. The reply is shown as text.';
    }
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
          this.finish(FinishReason.Senior);
        }
      }
    });
  }

  private async finish(reason: FinishReason): Promise<void> {
    if (this.finishing) {
      return;
    }
    await this.cancelRecording();
    this.finishing = true;
    this.notice = '';
    try {
      const report = await wellbeingCheckIn.finish(this.sessionId, reason);
      this.sessionId = '';
      this.messages = [];
      if (report === undefined) {
        this.notice = 'Nothing was sent, because there were no answers yet.';
        this.phase = Phase.Intro;
        return;
      }
      this.report = report;
      this.removed = false;
      await this.refreshDetails();
      await wellbeingCheckIn.rememberShared(this.context(), report, this.guardians);
      this.lastShared = await wellbeingCheckIn.lastShared(this.context());
      this.phase = Phase.Done;
    } catch (error) {
      this.notice = describeCheckInError(error as Object,
        'The summary could not be sent. Please press Finish again in a moment.');
    } finally {
      this.finishing = false;
    }
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
      this.lastShared = undefined;
    } catch (error) {
      this.notice = describeCheckInError(error as Object, 'The summary could not be removed. Please try again.');
    } finally {
      this.removing = false;
    }
  }

  @Builder
  infoRow(icon: Resource, accent: Resource, tint: Resource, text: string) {
    Row({ space: 14 }) {
      IconBadge({ icon: icon, accent: accent, tint: tint, badgeSize: 44 })
      Text(text)
        .fontSize(18)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .accessibilityGroup(true)
  }

  @Builder
  intro() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          IconBadge({
            icon: $r('sys.symbol.heart_fill'),
            accent: $r('app.color.senior_accent'),
            tint: $r('app.color.surface'),
            badgeSize: 56
          })
          Text('How are you feeling today?')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(this.assistant.voice ? 'Have a short chat with Carely about your day. You can speak or type.' :
            'Have a short chat with Carely about your day by typing your answers.')
            .fontSize(19)
            .fontColor($r('app.color.text_primary'))
            .opacity(0.85)
        }
        .width('100%')
        .padding(20)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(24)
        .backgroundColor($r('app.color.senior_tint'))

        Column({ space: 16 }) {
          this.infoRow($r('sys.symbol.doc_text_fill'), $r('app.color.senior_accent'), $r('app.color.senior_tint'),
            `When you finish, a short summary goes to ${this.guardians}.`)
          this.infoRow($r('sys.symbol.lock_fill'), $r('app.color.senior_accent'), $r('app.color.senior_tint'),
            `${this.guardians} reads the summary, not the whole conversation.`)
          this.infoRow($r('sys.symbol.message_fill'), $r('app.color.senior_accent'), $r('app.color.senior_tint'),
            this.assistant.simulated ? 'Demo mode: the replies are scripted, not written by AI.' :
              'The replies come from an AI assistant (OpenAI). It cannot give medical advice.')
          this.infoRow($r('sys.symbol.exclamationmark_shield_fill'), $r('app.color.sos'), $r('app.color.sos_tint'),
            'If you need help now, use the red SOS button on the Home screen.')
        }
        .width('100%')
        .padding(16)
        .borderRadius(20)
        .backgroundColor($r('app.color.surface'))

        if (this.lastShared !== undefined) {
          Column({ space: 6 }) {
            Text('Last check-in')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
            Text(`${sharedDateLabel(this.lastShared.createdAt)} · sent to ${this.lastShared.guardians}`)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            if (this.lastShared.summary !== '') {
              Text(this.lastShared.summary)
                .fontSize(17)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(4)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
          .borderRadius(20)
          .backgroundColor($r('app.color.surface'))
          .accessibilityGroup(true)
        }

        if (!this.assistant.available) {
          NoticeBanner({ text: 'The assistant is not available right now. Please try again later.' })
        }
        if (this.notice !== '') {
          NoticeBanner({ text: this.notice })
        }

        Button() {
          Row({ space: 10 }) {
            if (this.phase === Phase.Starting) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
            } else {
              SymbolGlyph($r('sys.symbol.message_fill'))
                .fontSize(22)
                .fontColor([Color.White])
            }
            Text(this.phase === Phase.Starting ? 'Starting…' : 'Start check-in')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(64)
        .attributeModifier(new CareButtonStyle())
        .enabled(this.assistant.available && this.phase !== Phase.Starting)
        .onClick(() => this.start())
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

  @Builder
  bubble(message: ChatMessage) {
    Row() {
      Column({ space: 8 }) {
        Text(message.text)
          .fontSize(20)
          .lineHeight(28)
          .fontColor(message.id === PENDING_ID ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
        if (message.role === ChatRole.Assistant && this.assistant.voice && message.id !== PENDING_ID) {
          Row({ space: 6 }) {
            SymbolGlyph(this.speakingId === message.id ? $r('sys.symbol.stop_circle_fill') :
            $r('sys.symbol.speaker_wave_2_fill'))
              .fontSize(20)
              .fontColor([$r('app.color.senior_accent')])
            Text(this.speakingId === message.id ? 'Stop reading' : 'Read aloud')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.senior_accent'))
          }
          .constraintSize({ minHeight: 44 })
          .padding({ right: 8 })
          .accessibilityGroup(true)
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText(this.speakingId === message.id ? 'Stop reading aloud' : 'Read this reply aloud')
          .onClick(() => this.speak(message))
        }
        if (message.role === ChatRole.Senior && message.voice && message.id !== PENDING_ID) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.mic_fill'))
              .fontSize(14)
              .fontColor([$r('app.color.text_secondary')])
            Text('Spoken')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
        }
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: '86%' })
      .borderRadius(20)
      .backgroundColor(message.role === ChatRole.Senior ? $r('app.color.senior_tint') : $r('app.color.surface'))
      .accessibilityGroup(message.role === ChatRole.Senior)
      .accessibilityText(`${message.role === ChatRole.Senior ? 'You' : 'Carely'}: ${message.text}`)
    }
    .width('100%')
    .justifyContent(message.role === ChatRole.Senior ? FlexAlign.End : FlexAlign.Start)
  }

  @Builder
  thinkingBubble() {
    Row() {
      Row({ space: 10 }) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color($r('app.color.senior_accent'))
        Text('Carely is thinking…')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
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

  @Builder
  composer() {
    Column({ space: 10 }) {
      if (this.notice !== '') {
        NoticeBanner({ text: this.notice })
        if (this.micDenied) {
          Button('Allow the microphone')
            .width('100%')
            .attributeModifier(new CareButtonStyle('secondary'))
            .onClick(async () => {
              if (await openMicrophoneSettings(this.context())) {
                this.micDenied = false;
                this.notice = '';
              }
            })
        }
      }

      if (this.finishing) {
        Row({ space: 12 }) {
          LoadingProgress()
            .width(28)
            .height(28)
            .color($r('app.color.senior_accent'))
          Text(`Sending the summary to ${this.guardians}…`)
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor($r('app.color.surface'))
      } else if (this.mic === Mic.Recording) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.mic_fill'))
            .fontSize(24)
            .fontColor([$r('app.color.sos')])
          Text(`Listening… ${elapsedLabel(this.recordSeconds)}`)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Button('Cancel')
            .attributeModifier(new CareButtonStyle('secondary'))
            .onClick(() => this.cancelRecording())
        }
        .width('100%')
        .accessibilityGroup(false)
        Button() {
          Row({ space: 10 }) {
            SymbolGlyph($r('sys.symbol.stop_circle_fill'))
              .fontSize(26)
              .fontColor([Color.White])
            Text('Done, send it')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(64)
        .attributeModifier(new CareButtonStyle())
        .accessibilityText('Stop recording and send what you said')
        .onClick(() => this.stopAndSendVoice())
      } else {
        if (this.assistant.voice) {
          Button() {
            Row({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.mic_fill'))
                .fontSize(24)
                .fontColor([Color.White])
              Text(this.mic === Mic.Sending ? 'Sending…' : 'Speak')
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(64)
          .attributeModifier(new CareButtonStyle())
          .enabled(!this.thinking && this.mic === Mic.Idle)
          .accessibilityText('Speak your answer. Tap again when you are done.')
          .onClick(() => this.toggleMic())
        }
        Row({ space: 10 }) {
          TextArea({ text: $$this.draft, placeholder: this.assistant.voice ? 'Or type here' : 'Type your answer' })
            .layoutWeight(1)
            .constraintSize({ minHeight: 56, maxHeight: 132 })
            .attributeModifier(new CareTextAreaStyle())
            .enterKeyType(EnterKeyType.Send)
            .maxLength(1000)
            .accessibilityText('Your answer')
            .onSubmit(() => this.sendText())
          Button() {
            SymbolGlyph($r('sys.symbol.paperplane_fill'))
              .fontSize(24)
              .fontColor([Color.White])
          }
          .width(56)
          .height(56)
          .attributeModifier(new CareButtonStyle())
          .padding(0)
          .enabled(this.draft.trim() !== '' && !this.thinking && this.mic === Mic.Idle)
          .accessibilityText('Send')
          .onClick(() => this.sendText())
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 12 })
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  chat() {
    Column() {
      Row({ space: 12 }) {
        Text(this.simulated ? 'Demo assistant · scripted replies' : 'Chatting with Carely')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Button('Finish')
          .attributeModifier(new CareButtonStyle('secondary'))
          .enabled(!this.finishing && !this.thinking && this.mic !== Mic.Sending)
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
          }, (message: ChatMessage) => `${message.id}:${message.text.length}`)
          if (this.thinking) {
            this.thinkingBubble()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      this.composer()
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
            this.phase = Phase.Intro;
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
      } else if (this.phase === Phase.Chat) {
        this.chat()
      } else if (this.phase === Phase.Done) {
        this.done()
      } else {
        this.intro()
      }
    }
    .width('100%')
    .height('100%')
  }
}

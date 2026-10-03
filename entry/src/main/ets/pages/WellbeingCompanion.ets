import { common } from '@kit.AbilityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { NoticeBanner, sectionTitle } from '../components/Common';
import {
  AiConcernCheck,
  AnswerOption,
  CheckInAnswer,
  CheckInQuestion,
  DeliveryState,
  QuestionKind,
  SharedCheckIn,
  StructuredCheckIn
} from '../models/Wellbeing';
import { Contact } from '../models/Contact';
import { openDialer } from '../platform/PhoneDialer';
import { ListenOutcome, ListenStatus, speechInput } from '../platform/SpeechInput';
import { speechOutput } from '../platform/SpeechOutput';
import { describeBackendError, NOT_CONFIGURED_MESSAGE } from '../services/BackendErrors';
import {
  answerFor,
  buildStructured,
  CONCERN_LABELS,
  concernFlags,
  factLines,
  freeTextAnswer,
  freeTextOf,
  matchSpokenAnswer,
  nextQuestion,
  scriptedReply,
  templateSummary
} from '../services/CheckInScript';
import { concernCheck, ConcernCheckState } from '../services/ConcernCheck';
import { contactsService } from '../services/ContactsService';
import { wellbeingService, WellbeingService } from '../services/WellbeingService';

enum Phase {
  Intro,
  Asking,
  Preview,
  Shared
}

class ChatMessage {
  readonly id: number;
  readonly fromCompanion: boolean;
  readonly text: string;
  // Said because the on-device model flagged the senior's words (the wording itself is fixed).
  readonly fromAiCheck: boolean;

  constructor(id: number, fromCompanion: boolean, text: string, fromAiCheck: boolean = false) {
    this.id = id;
    this.fromCompanion = fromCompanion;
    this.text = text;
    this.fromAiCheck = fromAiCheck;
  }
}

function sharedTime(entry: SharedCheckIn): string {
  const date = new Date(entry.sharedAt);
  const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
  return `${date.toLocaleDateString()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

const AI_FLAG_REPLY = 'Thank you for telling me. That sounds like it could be hard. At the end I will show you a quick ' +
  'way to call someone.';

// Senior Wellbeing tab: a short spoken or tapped check-in, an on-device AI check of anything the senior writes,
// a preview of exactly what will be shared, and the list of shared check-ins with a way to withdraw them.
@Component
export struct WellbeingCompanion {
  @Consume('navStack') navStack: NavPathStack;
  @State private phase: Phase = Phase.Intro;
  @State private messages: ChatMessage[] = [];
  @State private question: CheckInQuestion | undefined = undefined;
  @State private modelState: ConcernCheckState = concernCheck.state;
  @State private checking: boolean = false;
  @State private speakOn: boolean = true;
  @State private speechAvailable: boolean = false;
  // English speech recognition works on this device (the emulator's recognizer only offers Chinese).
  @State private voiceInputAvailable: boolean = false;
  @State private listening: boolean = false;
  @State private heard: string = '';
  @State private draft: string = '';
  @State private includeNotes: boolean = true;
  @State private aiCheck: AiConcernCheck | undefined = undefined;
  @State private concerns: string[] = [];
  @State private history: SharedCheckIn[] = [];
  @State private lastShared: SharedCheckIn | undefined = undefined;
  @State private errorMessage: string = '';
  @State private sharing: boolean = false;
  // Bumped when answers change, so the preview recomputes facts.
  @State private answersVersion: number = 0;
  private answers: Map<string, CheckInAnswer> = new Map<string, CheckInAnswer>();
  private nextMessageId: number = 0;
  private scroller: Scroller = new Scroller();
  private service: WellbeingService | undefined = undefined;

  aboutToAppear(): void {
    const context = this.context();
    this.service = wellbeingService(context);
    concernCheck.load(context).then((state: ConcernCheckState) => this.modelState = state);
    speechOutput.isAvailable().then((available: boolean) => {
      this.speechAvailable = available;
      this.speakOn = available;
    });
    speechInput.isAvailable().then((available: boolean) => this.voiceInputAvailable = available);
    this.refreshHistory(true);
  }

  aboutToDisappear(): void {
    speechOutput.stop();
    speechInput.cancel();
  }

  private context(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private async refreshHistory(deliver: boolean): Promise<void> {
    if (this.service === undefined) {
      return;
    }
    try {
      if (deliver) {
        await this.service.deliverPending();
      }
    } finally {
      this.history = await this.service.history();
    }
  }

  private say(text: string, fromAiCheck: boolean = false): void {
    this.messages.push(new ChatMessage(this.nextMessageId++, true, text, fromAiCheck));
    this.scrollToEnd();
    if (this.speakOn) {
      speechOutput.speak(text);
    }
  }

  private scrollToEnd(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }

  private start(): void {
    this.answers = new Map<string, CheckInAnswer>();
    this.answersVersion++;
    this.messages = [];
    this.aiCheck = undefined;
    this.errorMessage = '';
    this.includeNotes = true;
    this.phase = Phase.Asking;
    this.say('Hello! Let\'s do your daily check-in. It only takes a minute.');
    this.askNext();
  }

  private askNext(): void {
    const question = nextQuestion(this.answers);
    this.question = question;
    this.draft = '';
    this.heard = '';
    if (question === undefined) {
      this.finish();
      return;
    }
    // Leave time for the acknowledgement to be read before the next question.
    setTimeout(() => {
      this.say(question.prompt);
    }, this.speakOn ? 1500 : 0);
  }

  private async answer(question: CheckInQuestion, answer: CheckInAnswer): Promise<void> {
    if (this.checking) {
      return;
    }
    speechInput.cancel();
    this.answers.set(question.id, answer);
    this.answersVersion++;
    this.messages.push(new ChatMessage(this.nextMessageId++, false, answer.label));
    this.question = undefined;
    this.scrollToEnd();
    const wasFlagged = this.aiCheck?.flagged ?? false;
    if (question.kind === QuestionKind.FreeText && answer.value.length > 0 &&
      this.modelState === ConcernCheckState.Ready) {
      this.checking = true;
      // Re-read everything written so far, so the result covers the whole check-in.
      this.aiCheck = await concernCheck.check(freeTextOf(this.answers)) ?? this.aiCheck;
      this.checking = false;
    }
    if (!wasFlagged && (this.aiCheck?.flagged ?? false)) {
      this.say(AI_FLAG_REPLY, true);
    } else {
      this.say(scriptedReply(question, answer));
    }
    this.askNext();
  }

  private chooseOption(option: AnswerOption): void {
    if (this.question !== undefined) {
      this.answer(this.question, answerFor(this.question, option));
    }
  }

  private sendText(skip: boolean): void {
    if (this.question !== undefined) {
      this.answer(this.question, freeTextAnswer(this.question, skip ? '' : this.draft));
    }
  }

  private async listen(): Promise<void> {
    const question = this.question;
    if (question === undefined || this.listening) {
      return;
    }
    speechOutput.stop();
    this.listening = true;
    this.heard = '';
    const outcome: ListenOutcome = await speechInput.listenOnce(this.context(), (text: string) => {
      this.heard = text;
    });
    this.listening = false;
    if (outcome.status === ListenStatus.PermissionDenied) {
      this.heard = 'Microphone access was not allowed. You can tap or type your answer.';
      return;
    }
    if (outcome.status !== ListenStatus.Heard) {
      this.heard = outcome.status === ListenStatus.Unavailable ?
        'Voice answers are not available on this phone. Please tap or type.' :
        'I did not catch that. Please try again or tap an answer.';
      return;
    }
    if (this.question !== question) {
      return;
    }
    if (question.kind === QuestionKind.FreeText) {
      this.draft = outcome.text;
      this.heard = '';
      return;
    }
    const option = matchSpokenAnswer(question, outcome.text);
    if (option !== undefined) {
      this.heard = '';
      this.answer(question, answerFor(question, option));
    } else {
      this.heard = `I heard "${outcome.text}". Please tap the answer that fits best.`;
    }
  }

  private hasNotes(): boolean {
    return freeTextOf(this.answers).length > 0;
  }

  private facts(): StructuredCheckIn {
    return buildStructured(this.answers, this.includeNotes, new Date(), this.aiCheck);
  }

  private finish(): void {
    this.concerns = concernFlags(this.answers, this.aiCheck?.flagged ?? false);
    this.phase = Phase.Preview;
    this.say('Thank you! Here is what your family will see. Nothing is shared until you choose to.');
  }

  private async share(): Promise<void> {
    if (this.service === undefined) {
      this.errorMessage = NOT_CONFIGURED_MESSAGE;
      return;
    }
    if (this.sharing) {
      return;
    }
    this.sharing = true;
    this.errorMessage = '';
    try {
      const facts = this.facts();
      this.lastShared = await this.service.share(facts, templateSummary(facts), new Date());
      this.phase = Phase.Shared;
      await this.refreshHistory(false);
    } catch (err) {
      this.errorMessage = describeBackendError(err as Object, 'The check-in could not be shared.');
    } finally {
      this.sharing = false;
    }
  }

  private discard(): void {
    this.phase = Phase.Intro;
    this.messages = [];
    speechOutput.stop();
  }

  private async withdraw(entry: SharedCheckIn): Promise<void> {
    if (this.service === undefined) {
      return;
    }
    try {
      await this.service.withdraw(entry.localId);
      this.errorMessage = '';
    } catch (err) {
      this.errorMessage = describeBackendError(err as Object, 'The check-in could not be withdrawn.');
    }
    await this.refreshHistory(false);
  }

  private async callFirstContact(): Promise<void> {
    const service = contactsService(this.context());
    if (service === undefined) {
      return;
    }
    try {
      const contacts: Contact[] = (await service.load()).contacts;
      if (contacts.length > 0) {
        await openDialer(contacts[0].phone);
      } else {
        this.errorMessage = 'No contacts are set up yet. Ask your guardian to add one.';
      }
    } catch (err) {
      this.errorMessage = describeBackendError(err as Object, 'Contacts could not be loaded.');
    }
  }

  @Builder
  modelBadge() {
    Row({ space: 6 }) {
      SymbolGlyph(this.modelState === ConcernCheckState.Ready ? $r('sys.symbol.checkmark_shield_fill') :
        $r('sys.symbol.info_circle'))
        .fontSize(16)
        .fontColor([this.modelState === ConcernCheckState.Ready ? $r('app.color.success') :
          $r('app.color.text_secondary')])
      Text(this.modelState === ConcernCheckState.Loading ? 'Preparing the on-device AI…' :
        this.modelState === ConcernCheckState.Ready ? 'On-device AI reads what you write. Nothing leaves your phone until you share.' :
          'Guided check-in. On-device AI is not available on this phone.')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
    .accessibilityGroup(true)
  }

  @Builder
  bubble(message: ChatMessage) {
    Row() {
      Column({ space: 4 }) {
        Text(message.text)
          .fontSize(20)
          .fontColor(message.fromCompanion ? $r('app.color.text_primary') : Color.White)
        if (message.fromAiCheck) {
          Text('Noticed by on-device AI')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .borderRadius(20)
      .backgroundColor(message.fromCompanion ? $r('app.color.surface') : $r('app.color.senior_accent'))
      .constraintSize({ maxWidth: '85%' })
    }
    .width('100%')
    .justifyContent(message.fromCompanion ? FlexAlign.Start : FlexAlign.End)
  }

  @Builder
  answerPanel() {
    Column({ space: 12 }) {
      if (this.heard.length > 0) {
        Text(this.heard)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
      if (this.question !== undefined && this.question.kind === QuestionKind.Choice) {
        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(10), cross: LengthMetrics.vp(10) } }) {
          ForEach(this.question.options, (option: AnswerOption) => {
            Button(option.label)
              .height(60)
              .padding({ left: 20, right: 20 })
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.senior_accent'))
              .backgroundColor($r('app.color.senior_tint'))
              .onClick(() => this.chooseOption(option))
          }, (option: AnswerOption) => `${this.question?.id ?? ''}|${option.value}`)
          // The question id is part of the key: several questions share values such as "yes"/"no", and reusing
          // their buttons kept the previous question's labels and tap handlers.
        }
        .width('100%')
      }
      if (this.question !== undefined && this.question.kind === QuestionKind.FreeText) {
        TextArea({ text: $$this.draft, placeholder: this.voiceInputAvailable ? 'Type here, or tap Speak' : 'Type here' })
          .fontSize(20)
          .height(96)
          .width('100%')
        Row({ space: 10 }) {
          Button('Skip')
            .height(56)
            .layoutWeight(1)
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.page_background'))
            .onClick(() => this.sendText(true))
          Button('Send')
            .height(56)
            .layoutWeight(1)
            .fontSize(18)
            .enabled(this.draft.trim().length > 0)
            .backgroundColor($r('app.color.senior_accent'))
            .onClick(() => this.sendText(false))
        }
        .width('100%')
      }
      if (this.question !== undefined && this.voiceInputAvailable) {
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.mic_fill'))
              .fontSize(22)
              .fontColor([Color.White])
            Text(this.listening ? 'Listening… tap to stop' : 'Speak your answer')
              .fontSize(18)
              .fontColor(Color.White)
          }
        }
        .height(56)
        .width('100%')
        .backgroundColor(this.listening ? $r('app.color.sos') : $r('app.color.guardian_accent'))
        .accessibilityText(this.listening ? 'Listening, tap to stop' : 'Speak your answer')
        .onClick(() => this.listening ? speechInput.cancel() : this.listen())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  concernCard() {
    Column({ space: 12 }) {
      Text('Would you like to talk to someone?')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.concerns.map((flag: string) => CONCERN_LABELS[flag] ?? flag).join('\n'))
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
      Row({ space: 10 }) {
        Button('Call family')
          .height(56)
          .layoutWeight(1)
          .fontSize(18)
          .backgroundColor($r('app.color.senior_accent'))
          .onClick(() => this.callFirstContact())
        Button('SOS')
          .height(56)
          .layoutWeight(1)
          .fontSize(18)
          .backgroundColor($r('app.color.sos'))
          .onClick(() => this.navStack.pushPathByName('sos', null))
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.warning_tint'))
  }

  @Builder
  aiCheckLine() {
    if (this.aiCheck !== undefined) {
      NoticeBanner({
        icon: $r('sys.symbol.checkmark_shield_fill'),
        text: (this.aiCheck.flagged ? 'On-device AI noticed a possible health worry in what you wrote.' :
          'On-device AI found no health worry in what you wrote.') +
          (this.includeNotes ? ' Your guardian will see this result.' : ' This result is not shared.'),
        accent: $r('app.color.guardian_accent'),
        tint: $r('app.color.guardian_tint')
      })
    }
  }

  @Builder
  preview() {
    Column({ space: 16 }) {
      if (this.concerns.length > 0) {
        this.concernCard()
      }
      sectionTitle('Your answers (shared with your guardian)')
      Column({ space: 8 }) {
        ForEach(factLines(this.facts()), (line: string) => {
          Text(line)
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
        }, (line: string) => `${this.answersVersion}|${line}`)
        if (this.includeNotes && this.hasNotes()) {
          Text(`What you wrote: ${freeTextOf(this.answers)}`)
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
        }
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))

      if (this.hasNotes()) {
        Row({ space: 12 }) {
          Checkbox({ name: 'includeNotes' })
            .select(this.includeNotes)
            .width(28)
            .height(28)
            .onChange((value: boolean) => this.includeNotes = value)
          Text('Include what I wrote')
            .fontSize(18)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
      }
      this.aiCheckLine()

      sectionTitle('Note for your guardian (built from your answers)')
      Text(templateSummary(this.facts()))
        .fontSize(18)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding(16)
        .borderRadius(20)
        .backgroundColor($r('app.color.surface'))

      if (this.errorMessage.length > 0) {
        NoticeBanner({ text: this.errorMessage, accent: $r('app.color.sos'), tint: $r('app.color.sos_tint') })
      }
      Row({ space: 10 }) {
        Button('Don\'t share')
          .height(60)
          .layoutWeight(1)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.page_background'))
          .onClick(() => this.discard())
        Button(this.sharing ? 'Sharing…' : 'Share with guardian')
          .height(60)
          .layoutWeight(1)
          .fontSize(18)
          .enabled(!this.sharing)
          .backgroundColor($r('app.color.senior_accent'))
          .onClick(() => this.share())
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  historyList() {
    if (this.history.length > 0) {
      Column({ space: 8 }) {
        sectionTitle('Shared check-ins')
        ForEach(this.history, (entry: SharedCheckIn) => {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(sharedTime(entry))
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text(entry.delivery === DeliveryState.Sent ? 'Sent to your guardian' :
                'Waiting for a connection; it will be sent automatically')
                .fontSize(14)
                .fontColor(entry.delivery === DeliveryState.Sent ? $r('app.color.success') : $r('app.color.warning'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button('Withdraw')
              .height(48)
              .fontSize(16)
              .fontColor($r('app.color.sos'))
              .backgroundColor($r('app.color.sos_tint'))
              .accessibilityText(`Withdraw the check-in from ${sharedTime(entry)}`)
              .onClick(() => this.withdraw(entry))
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.surface'))
        }, (entry: SharedCheckIn) => `${entry.localId}|${entry.reportId}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  intro() {
    Scroll() {
      Column({ space: 20 }) {
        Text('Daily check-in')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('A few short questions about how you feel. You decide what your family sees.')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
        this.modelBadge()
        Button('Start check-in')
          .width('100%')
          .height(64)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.senior_accent'))
          .onClick(() => this.start())
        if (this.speechAvailable) {
          Row({ space: 12 }) {
            Toggle({ type: ToggleType.Switch, isOn: this.speakOn })
              .onChange((isOn: boolean) => this.speakOn = isOn)
            Text('Read questions aloud')
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
          }
        }
        if (this.service === undefined) {
          NoticeBanner({ text: NOT_CONFIGURED_MESSAGE })
        }
        if (this.errorMessage.length > 0) {
          NoticeBanner({ text: this.errorMessage, accent: $r('app.color.sos'), tint: $r('app.color.sos_tint') })
        }
        this.historyList()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 16, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  @Builder
  conversation() {
    Column() {
      Row({ space: 12 }) {
        this.modelBadge()
        if (this.speechAvailable) {
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph(this.speakOn ? $r('sys.symbol.speaker_wave_2_fill') : $r('sys.symbol.speaker_slash_fill'))
              .fontSize(22)
              .fontColor([$r('app.color.senior_accent')])
          }
          .width(48)
          .height(48)
          .backgroundColor($r('app.color.senior_tint'))
          .accessibilityText(this.speakOn ? 'Stop reading aloud' : 'Read aloud')
          .onClick(() => {
            this.speakOn = !this.speakOn;
            if (!this.speakOn) {
              speechOutput.stop();
            }
          })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Scroll(this.scroller) {
        Column({ space: 12 }) {
          ForEach(this.messages, (message: ChatMessage) => {
            this.bubble(message)
          }, (message: ChatMessage) => `${message.id}`)
          if (this.checking) {
            Row({ space: 8 }) {
              LoadingProgress()
                .width(28)
                .height(28)
                .color($r('app.color.senior_accent'))
              Text('Reading what you wrote, on this phone…')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
            }
          }
          if (this.phase === Phase.Preview) {
            this.preview()
          }
          if (this.phase === Phase.Shared && this.lastShared !== undefined) {
            NoticeBanner({
              icon: $r('sys.symbol.checkmark_circle_fill'),
              text: this.lastShared.delivery === DeliveryState.Sent ? 'Shared with your guardian.' :
                'Saved on this phone. It will be sent when the connection is back.',
              accent: $r('app.color.success'),
              tint: $r('app.color.success_tint')
            })
            Button('Done')
              .width('100%')
              .height(60)
              .fontSize(20)
              .backgroundColor($r('app.color.senior_accent'))
              .onClick(() => this.discard())
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      if (this.phase === Phase.Asking && this.question !== undefined && !this.checking) {
        this.answerPanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.phase === Phase.Intro) {
      this.intro()
    } else {
      this.conversation()
    }
  }
}

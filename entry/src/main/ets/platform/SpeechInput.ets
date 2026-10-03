import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// One-shot speech-to-text for check-in answers with Core Speech Kit (offline engine, microphone recording
// mode). Touch input always remains available; this only adds a way to answer by voice.

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'SpeechInput';
const ASR_CAPABILITY = 'SystemCapability.AI.SpeechRecognizer';
const MICROPHONE = 'ohos.permission.MICROPHONE';
const LANGUAGE = 'en-US';
const OFFLINE = 1;
const LISTEN_TIMEOUT_MS = 20000;

export enum ListenStatus {
  Heard,
  // Nothing recognizable was said before the timeout.
  Silent,
  PermissionDenied,
  Unavailable
}

export class ListenOutcome {
  readonly status: ListenStatus;
  readonly text: string;

  constructor(status: ListenStatus, text: string = '') {
    this.status = status;
    this.text = text;
  }
}

export function isSpeechInputSupported(): boolean {
  return canIUse(ASR_CAPABILITY);
}

class SpeechInput {
  private engine: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private failed: boolean = false;
  private sessionCount: number = 0;
  private activeSession: string = '';
  lastError: string = '';

  async requestMicrophone(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [MICROPHONE]);
      return result.authResults[0] === 0;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Microphone permission request failed: ${(err as BusinessError).code}`);
      return false;
    }
  }

  // Records until the speaker stops (voice activity detection) and returns the final text.
  async listenOnce(context: common.UIAbilityContext, onPartial?: (text: string) => void): Promise<ListenOutcome> {
    if (!isSpeechInputSupported()) {
      return new ListenOutcome(ListenStatus.Unavailable);
    }
    if (!(await this.requestMicrophone(context))) {
      return new ListenOutcome(ListenStatus.PermissionDenied);
    }
    const engine = await this.ensureEngine();
    if (engine === undefined) {
      return new ListenOutcome(ListenStatus.Unavailable);
    }
    this.cancel();
    this.sessionCount++;
    const sessionId = `carely-asr-${Date.now()}-${this.sessionCount}`;
    this.activeSession = sessionId;
    return new Promise<ListenOutcome>((resolve: (outcome: ListenOutcome) => void) => {
      let text = '';
      let settled = false;
      const finish = (outcome: ListenOutcome) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          if (this.activeSession === sessionId) {
            this.activeSession = '';
          }
          resolve(outcome);
        }
      };
      const timer = setTimeout(() => {
        this.cancel();
        finish(text.length > 0 ? new ListenOutcome(ListenStatus.Heard, text) : new ListenOutcome(ListenStatus.Silent));
      }, LISTEN_TIMEOUT_MS);
      engine.setListener({
        onStart: () => {},
        onEvent: () => {},
        onResult: (id: string, result: speechRecognizer.SpeechRecognitionResult) => {
          if (id !== sessionId) {
            return;
          }
          text = result.result;
          onPartial?.(text);
          if (result.isLast) {
            finish(text.trim().length > 0 ? new ListenOutcome(ListenStatus.Heard, text.trim()) :
              new ListenOutcome(ListenStatus.Silent));
          }
        },
        onComplete: (id: string) => {
          if (id === sessionId) {
            finish(text.trim().length > 0 ? new ListenOutcome(ListenStatus.Heard, text.trim()) :
              new ListenOutcome(ListenStatus.Silent));
          }
        },
        onError: (id: string, code: number, message: string) => {
          if (id === sessionId) {
            this.lastError = `${code} ${message}`;
            hilog.error(LOG_DOMAIN, LOG_TAG, `recognition error: ${this.lastError}`);
            finish(new ListenOutcome(ListenStatus.Silent));
          }
        }
      });
      try {
        engine.startListening({
          sessionId: sessionId,
          audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 },
          extraParams: { 'recognitionMode': 0, 'vadBegin': 3000, 'vadEnd': 1500, 'maxAudioDuration': 20000 }
        });
      } catch (err) {
        const error = err as BusinessError;
        this.lastError = `${error.code} ${error.message}`;
        hilog.error(LOG_DOMAIN, LOG_TAG, `startListening failed: ${this.lastError}`);
        finish(new ListenOutcome(ListenStatus.Unavailable));
      }
    });
  }

  cancel(): void {
    if (this.engine !== undefined && this.activeSession.length > 0) {
      try {
        this.engine.cancel(this.activeSession);
      } catch (err) {
        hilog.warn(LOG_DOMAIN, LOG_TAG, `cancel failed: ${(err as BusinessError).message}`);
      }
      this.activeSession = '';
    }
  }

  // Languages the offline recognizer reports, for the diagnostics screen.
  async languages(): Promise<string[]> {
    const engine = await this.ensureEngine();
    if (engine === undefined) {
      return [];
    }
    try {
      return await engine.listLanguages({ sessionId: `carely-lang-${Date.now()}` });
    } catch (err) {
      return [];
    }
  }

  private async ensureEngine(): Promise<speechRecognizer.SpeechRecognitionEngine | undefined> {
    if (this.engine !== undefined || this.failed || !isSpeechInputSupported()) {
      return this.engine;
    }
    try {
      this.engine = await speechRecognizer.createEngine({
        language: LANGUAGE,
        online: OFFLINE,
        extraParams: { 'recognizerMode': 'short' }
      });
    } catch (err) {
      const error = err as BusinessError;
      this.lastError = `${error.code} ${error.message}`;
      this.failed = true;
      hilog.warn(LOG_DOMAIN, LOG_TAG, `No ${LANGUAGE} speech recognizer: ${this.lastError}`);
    }
    return this.engine;
  }
}

export const speechInput: SpeechInput = new SpeechInput();

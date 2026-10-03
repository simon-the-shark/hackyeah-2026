import { BusinessError } from '@kit.BasicServicesKit';
import { textToSpeech } from '@kit.CoreSpeechKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// Reads companion questions aloud with Core Speech Kit text-to-speech (offline engine). Speech is a
// convenience: every question is also on screen, and failures only switch the speaker off.

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'SpeechOutput';
const TTS_CAPABILITY = 'SystemCapability.AI.TextToSpeech';
const LANGUAGE = 'en-US';
const OFFLINE = 1;

export function isSpeechOutputSupported(): boolean {
  return canIUse(TTS_CAPABILITY);
}

class SpeechOutput {
  private engine: textToSpeech.TextToSpeechEngine | undefined = undefined;
  private creating: Promise<textToSpeech.TextToSpeechEngine | undefined> | undefined = undefined;
  private failed: boolean = false;
  private requestCount: number = 0;
  lastError: string = '';

  // Speaks `text`, interrupting anything still being read. Returns false when speech is unavailable.
  async speak(text: string): Promise<boolean> {
    const engine = await this.ensureEngine();
    if (engine === undefined || text.trim().length === 0) {
      return false;
    }
    try {
      if (engine.isBusy()) {
        engine.stop();
      }
      this.requestCount++;
      engine.speak(text, { requestId: `carely-${Date.now()}-${this.requestCount}` });
      return true;
    } catch (err) {
      const error = err as BusinessError;
      this.lastError = `${error.code} ${error.message}`;
      hilog.error(LOG_DOMAIN, LOG_TAG, `speak failed: ${this.lastError}`);
      return false;
    }
  }

  stop(): void {
    try {
      if (this.engine !== undefined && this.engine.isBusy()) {
        this.engine.stop();
      }
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, `stop failed: ${(err as BusinessError).message}`);
    }
  }

  // Whether an English voice could be created on this device (creates the engine on first call).
  async isAvailable(): Promise<boolean> {
    return (await this.ensureEngine()) !== undefined;
  }

  private async ensureEngine(): Promise<textToSpeech.TextToSpeechEngine | undefined> {
    if (this.engine !== undefined || this.failed || !isSpeechOutputSupported()) {
      return this.engine;
    }
    if (this.creating === undefined) {
      this.creating = this.createEngine().then((engine: textToSpeech.TextToSpeechEngine | undefined) => {
        this.engine = engine;
        this.failed = engine === undefined;
        this.creating = undefined;
        return engine;
      });
    }
    return this.creating;
  }

  private async createEngine(): Promise<textToSpeech.TextToSpeechEngine | undefined> {
    try {
      const engine = await textToSpeech.createEngine({ language: LANGUAGE, person: 0, online: OFFLINE });
      engine.setListener({
        onStart: () => {},
        onComplete: () => {},
        onStop: () => {},
        onError: (_requestId: string, code: number, message: string) => {
          this.lastError = `${code} ${message}`;
          hilog.error(LOG_DOMAIN, LOG_TAG, `speech error: ${this.lastError}`);
        }
      });
      return engine;
    } catch (err) {
      const error = err as BusinessError;
      this.lastError = `${error.code} ${error.message}`;
      hilog.warn(LOG_DOMAIN, LOG_TAG, `No ${LANGUAGE} text-to-speech engine: ${this.lastError}`);
      return undefined;
    }
  }
}

export const speechOutput: SpeechOutput = new SpeechOutput();

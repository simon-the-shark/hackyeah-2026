import { common } from '@kit.AbilityKit';
import { AiConcernCheck } from '../models/Wellbeing';
import { ConcernModel, ModelScore } from '../platform/ConcernModel';
import { concernPrompt } from './CheckInScript';

const MODEL_LABEL = 'Qwen2.5-0.5B-Instruct (on-device, MindSpore Lite)';
// Score (logit yes - logit no) above which a message is flagged. On the emulator, int8 weights plus float16
// kernels raised harmless messages' scores by ~0.4-0.7 (up to +0.09) while worries stayed >= 1.50, so 0 would
// flag harmless text. Chosen on the 12 synthetic check messages; revisit with more data.
export const CONCERN_THRESHOLD = 0.5;

export enum ConcernCheckState {
  Loading,
  // The bundled model is loaded and runs on this phone.
  Ready,
  // No model on this device or in this build; only the fixed keyword rules apply.
  Unavailable
}

// Asks the on-device model whether the senior's free text mentions a health worry. The answer only adds a
// flag next to the fixed keyword rules; failures simply mean no AI flag.
export class ConcernCheck {
  private model: ConcernModel | undefined = undefined;
  private loading: Promise<ConcernCheckState> | undefined = undefined;
  state: ConcernCheckState = ConcernCheckState.Loading;

  async load(context: common.Context): Promise<ConcernCheckState> {
    if (this.loading === undefined) {
      this.loading = ConcernModel.load(context).then((model: ConcernModel | undefined) => {
        this.model = model;
        this.state = model !== undefined ? ConcernCheckState.Ready : ConcernCheckState.Unavailable;
        return this.state;
      });
    }
    return this.loading;
  }

  loadedModel(): ConcernModel | undefined {
    return this.model;
  }

  async check(text: string): Promise<AiConcernCheck | undefined> {
    if (this.model === undefined || text.trim().length === 0) {
      return undefined;
    }
    const result: ModelScore | undefined = await this.model.score(concernPrompt(text));
    return result === undefined ? undefined : new AiConcernCheck(MODEL_LABEL, result.score > CONCERN_THRESHOLD, result.score);
  }
}

export const concernCheck: ConcernCheck = new ConcernCheck();

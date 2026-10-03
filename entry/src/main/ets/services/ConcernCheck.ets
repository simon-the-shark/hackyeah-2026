import { common } from '@kit.AbilityKit';
import { AiConcernCheck } from '../models/Wellbeing';
import { ConcernModel, ModelScore } from '../platform/ConcernModel';
import { concernPrompt } from './CheckInScript';

const MODEL_LABEL = 'Qwen2.5-0.5B-Instruct (on-device, MindSpore Lite)';

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
    return result === undefined ? undefined : new AiConcernCheck(MODEL_LABEL, result.score > 0, result.score);
  }
}

export const concernCheck: ConcernCheck = new ConcernCheck();

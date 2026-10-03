import { common } from '@kit.AbilityKit';
import {
  isModelBundled,
  isOnDeviceModelSupported,
  ModelCheck,
  ModelScore,
  rawText,
  TokenizerVector
} from '../platform/ConcernModel';
import { isSpeechInputSupported, speechInput } from '../platform/SpeechInput';
import { isSpeechOutputSupported, speechOutput } from '../platform/SpeechOutput';
import { concernPrompt } from './CheckInScript';
import { concernCheck, ConcernCheckState } from './ConcernCheck';

// Records what the wellbeing companion's platform capabilities actually do on this device, so the demo and
// AI_WORKFLOW.md report measured behaviour rather than assumptions.

// A quantized model may move scores a little; a different yes/no decision is a failure.
const SCORE_TOLERANCE = 0.5;

function sameIds(a: number[], b: number[]): boolean {
  return a.length === b.length && a.every((id: number, i: number) => id === b[i]);
}

export async function runCompanionDiagnostics(context: common.UIAbilityContext,
  report: (line: string) => void): Promise<void> {
  report(`MindSpore Lite (SystemCapability.AI.MindSporeLite): ${isOnDeviceModelSupported() ? 'yes' : 'no'}`);
  report(`Model bundled in this build: ${isModelBundled(context) ? 'yes' : 'no (run scripts/build-companion-model.sh)'}`);
  const loadStarted = Date.now();
  const state = await concernCheck.load(context);
  const model = concernCheck.loadedModel();
  if (state !== ConcernCheckState.Ready || model === undefined) {
    report('On-device model: unavailable');
  } else {
    report(`On-device model: ${model.meta.model}, ready (${Date.now() - loadStarted} ms including first load)`);
    const vectorsText = rawText(context, 'tokenizer_vectors.json');
    const vectors = vectorsText !== undefined ? JSON.parse(vectorsText) as TokenizerVector[] : [];
    const passed = vectors.filter((vector: TokenizerVector) => sameIds(model.tokenizer.encode(vector.text), vector.ids));
    report(`Tokenizer matches reference: ${passed.length}/${vectors.length}`);
    let agree = 0;
    let totalMs = 0;
    for (const check of model.meta.checks as ModelCheck[]) {
      const result: ModelScore | undefined = await model.score(concernPrompt(check.message));
      if (result === undefined) {
        report(`  failed: ${check.message}`);
        continue;
      }
      totalMs += result.elapsedMs;
      const ok = (result.score > 0) === check.concern && Math.abs(result.score - check.score) < SCORE_TOLERANCE;
      agree += ok ? 1 : 0;
      report(`  ${ok ? 'ok ' : 'BAD'} ${result.score.toFixed(2)} (ref ${check.score.toFixed(2)}, ` +
        `${result.elapsedMs} ms) ${check.message}`);
    }
    const count = model.meta.checks.length;
    report(`Concern checks agreeing with the reference: ${agree}/${count}, ` +
      `average ${count > 0 ? Math.round(totalMs / count) : 0} ms`);
  }
  report(`Text-to-speech capability: ${isSpeechOutputSupported() ? 'yes' : 'no'}; English voice: ` +
    `${(await speechOutput.isAvailable()) ? 'yes' : `no ${speechOutput.lastError}`}`);
  const languages = isSpeechInputSupported() ? await speechInput.languages() : [];
  report(`Speech recognition capability: ${isSpeechInputSupported() ? 'yes' : 'no'}; languages: ` +
    `${languages.length > 0 ? languages.join(', ') : `none reported ${speechInput.lastError}`}`);
}

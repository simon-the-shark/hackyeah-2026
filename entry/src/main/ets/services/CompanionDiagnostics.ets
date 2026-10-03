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
import { CONCERN_THRESHOLD, concernCheck, ConcernCheckState } from './ConcernCheck';

// Records what the wellbeing companion's platform capabilities actually do on this device, so the demo and
// AI_WORKFLOW.md report measured behaviour rather than assumptions.


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
    report(`  load: ${model.loadReport}`);
    const vectorsText = rawText(context, 'tokenizer_vectors.json');
    const vectors = vectorsText !== undefined ? JSON.parse(vectorsText) as TokenizerVector[] : [];
    let passed = 0;
    for (const vector of vectors) {
      passed += sameIds(await model.tokenize(vector.text), vector.ids) ? 1 : 0;
    }
    report(`Tokenizer matches reference: ${passed}/${vectors.length}`);
    let agree = 0;
    let totalMs = 0;
    let maxDrift = 0;
    for (const check of model.meta.checks as ModelCheck[]) {
      const result: ModelScore | undefined = await model.score(concernPrompt(check.message));
      if (result === undefined) {
        report(`  failed: ${check.message}`);
        continue;
      }
      totalMs += result.elapsedMs;
      maxDrift = Math.max(maxDrift, Math.abs(result.score - check.score));
      // The decision the app makes, compared with the message's label.
      const ok = (result.score > CONCERN_THRESHOLD) === check.concern;
      agree += ok ? 1 : 0;
      report(`  ${ok ? 'ok ' : 'BAD'} ${result.score.toFixed(2)} (computer ${check.score.toFixed(2)}, ` +
        `${result.elapsedMs} ms) ${check.message}`);
    }
    const count = model.meta.checks.length;
    report(`Correct decisions at threshold ${CONCERN_THRESHOLD}: ${agree}/${count}; largest score change vs ` +
      `computer ${maxDrift.toFixed(2)}; average ${count > 0 ? Math.round(totalMs / count) : 0} ms`);
  }
  report(`Text-to-speech capability: ${isSpeechOutputSupported() ? 'yes' : 'no'}; English voice: ` +
    `${(await speechOutput.isAvailable()) ? 'yes' : `no ${speechOutput.lastError}`}`);
  if (speechOutput.voices.length > 0) {
    report(`  voices listed: ${speechOutput.voices.join(', ')}`);
  }
  const languages = isSpeechInputSupported() ? await speechInput.languages() : [];
  report(`Speech recognition capability: ${isSpeechInputSupported() ? 'yes' : 'no'}; languages: ` +
    `${languages.length > 0 ? languages.join(', ') : `none reported ${speechInput.lastError}`}`);
  if (speechInput.probedLanguages.length > 0) {
    report(`  languages the recognizer lists: ${speechInput.probedLanguages.join(', ')}`);
  }
}

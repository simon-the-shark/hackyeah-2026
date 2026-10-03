import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BpeTokenizer, TokenizerConfig } from '../services/companion/BpeTokenizer';

// The bundled on-device model (Qwen2.5-0.5B-Instruct reduced to a yes/no scorer and converted to MindSpore
// Lite by scripts/build-companion-model.sh). One call reads a whole prompt and returns the logits of "yes"
// and "no"; nothing is generated and nothing leaves the device.

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'ConcernModel';
const MINDSPORE_CAPABILITY = 'SystemCapability.AI.MindSporeLite';
const DIR = 'companion';
const MODEL_FILE = 'concern_classifier.ms';
const COPY_CHUNK = 4 * 1024 * 1024;

export interface ModelCheck {
  message: string;
  concern: boolean;
  // Score from the original model on a computer, for comparison on the device.
  score: number;
}

export interface ModelMeta {
  model: string;
  maxTokens: number;
  padId: number;
  checks: ModelCheck[];
}

export interface TokenizerVector {
  text: string;
  ids: number[];
}

export class ModelScore {
  // logit("yes") - logit("no"); above 0 means the model answered yes.
  readonly score: number;
  readonly elapsedMs: number;

  constructor(score: number, elapsedMs: number) {
    this.score = score;
    this.elapsedMs = elapsedMs;
  }
}

export function isOnDeviceModelSupported(): boolean {
  return canIUse(MINDSPORE_CAPABILITY);
}

// Undefined when the raw file is missing or unreadable.
export function rawText(context: common.Context, name: string): string | undefined {
  try {
    const bytes = context.resourceManager.getRawFileContentSync(`${DIR}/${name}`);
    return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(bytes, { stream: false });
  } catch (err) {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot read ${name}: ${(err as BusinessError).code}`);
    return undefined;
  }
}

// Whether the model files were packed into this build (they are produced by a separate script).
export function isModelBundled(context: common.Context): boolean {
  try {
    return context.resourceManager.getRawFileListSync(DIR).indexOf(MODEL_FILE) >= 0;
  } catch (err) {
    return false;
  }
}

// MindSpore Lite loads from a file path, but the model is a raw file inside the HAP, so it is copied to the
// app's private files once (and again when an update changes its size). Undefined when copying fails.
function ensureModelFile(context: common.Context): string | undefined {
  const target = `${context.filesDir}/${MODEL_FILE}`;
  const rawPath = `${DIR}/${MODEL_FILE}`;
  let out: fs.File | undefined = undefined;
  try {
    const raw = context.resourceManager.getRawFdSync(rawPath);
    if (fs.accessSync(target) && fs.statSync(target).size === raw.length) {
      return target;
    }
    out = fs.openSync(target, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
    const buffer = new ArrayBuffer(COPY_CHUNK);
    let copied = 0;
    while (copied < raw.length) {
      const read = fs.readSync(raw.fd, buffer, { offset: raw.offset + copied,
        length: Math.min(COPY_CHUNK, raw.length - copied) });
      if (read <= 0) {
        throw new Error('Unexpected end of the bundled model file.');
      }
      fs.writeSync(out.fd, buffer, { length: read });
      copied += read;
    }
    return target;
  } catch (err) {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot copy the model: ${(err as BusinessError).message}`);
    return undefined;
  } finally {
    try {
      if (out !== undefined) {
        fs.closeSync(out);
      }
      context.resourceManager.closeRawFdSync(rawPath);
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Cannot close model files');
    }
  }
}

export class ConcernModel {
  readonly tokenizer: BpeTokenizer;
  readonly meta: ModelMeta;
  private readonly model: mindSporeLite.Model;
  private queue: Promise<void> = Promise.resolve();

  private constructor(model: mindSporeLite.Model, meta: ModelMeta, tokenizer: BpeTokenizer) {
    this.model = model;
    this.meta = meta;
    this.tokenizer = tokenizer;
  }

  // Undefined when MindSpore Lite is missing, the model was not bundled, or loading fails.
  static async load(context: common.Context): Promise<ConcernModel | undefined> {
    if (!isOnDeviceModelSupported()) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'MindSpore Lite is not available on this device');
      return undefined;
    }
    if (!isModelBundled(context)) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'The model was not bundled; run scripts/build-companion-model.sh');
      return undefined;
    }
    const metaText = rawText(context, 'model_meta.json');
    const configText = rawText(context, 'tokenizer_config.json');
    const vocabText = rawText(context, 'vocab.json');
    const mergesText = rawText(context, 'merges.txt');
    const path = ensureModelFile(context);
    if (metaText === undefined || configText === undefined || vocabText === undefined || mergesText === undefined ||
      path === undefined) {
      return undefined;
    }
    try {
      const meta = JSON.parse(metaText) as ModelMeta;
      const config = JSON.parse(configText) as TokenizerConfig;
      const tokenizer = new BpeTokenizer(JSON.parse(vocabText) as Record<string, number>, mergesText.split('\n'),
        config);
      const started = Date.now();
      const msContext: mindSporeLite.Context = { target: ['cpu'], cpu: { threadNum: 4 } };
      const model = await mindSporeLite.loadModelFromFile(path, msContext);
      hilog.info(LOG_DOMAIN, LOG_TAG, `Model loaded in ${Date.now() - started} ms`);
      return new ConcernModel(model, meta, tokenizer);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot load the model: ${error.code} ${error.message}`);
      return undefined;
    }
  }

  // Undefined when the prompt does not fit or inference fails. Calls run one at a time.
  async score(prompt: string): Promise<ModelScore | undefined> {
    const ids = this.tokenizer.encode(prompt);
    if (ids.length === 0 || ids.length > this.meta.maxTokens) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, `Prompt does not fit: ${ids.length} tokens`);
      return undefined;
    }
    const run = this.queue.then(() => this.predict(ids));
    this.queue = run.then(() => {}, () => {});
    return run;
  }

  private async predict(ids: number[]): Promise<ModelScore | undefined> {
    const started = Date.now();
    try {
      const inputs = this.model.getInputs();
      const tokens = inputs.find((tensor: mindSporeLite.MSTensor) => tensor.name === 'tokens');
      const length = inputs.find((tensor: mindSporeLite.MSTensor) => tensor.name === 'length');
      if (tokens === undefined || length === undefined) {
        throw new Error('The model has unexpected inputs.');
      }
      const padded = new Int32Array(this.meta.maxTokens).fill(this.meta.padId);
      padded.set(ids);
      tokens.setData(padded.buffer);
      length.setData(new Int32Array([ids.length]).buffer);
      const outputs = await this.model.predict(inputs);
      const scores = new Float32Array(outputs[0].getData());
      return new ModelScore(scores[0] - scores[1], Date.now() - started);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Inference failed: ${error.code} ${error.message}`);
      return undefined;
    }
  }
}

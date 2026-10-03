import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MessageEvents, util, worker } from '@kit.ArkTS';
import { WorkerReply, WorkerRequest } from './ConcernWorkerProtocol';

// The bundled on-device model (Qwen2.5-0.5B-Instruct reduced to a yes/no scorer and converted to MindSpore
// Lite by scripts/build-companion-model.sh). One call reads a whole prompt and returns the logits of "yes"
// and "no"; nothing is generated and nothing leaves the device. All model work runs in
// workers/ConcernWorker.ets: building the model blocks for many seconds and must not run on the UI thread.

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'ConcernModel';
const MINDSPORE_CAPABILITY = 'SystemCapability.AI.MindSporeLite';
const DIR = 'companion';
const MODEL_FILE = 'concern_classifier.ms';
const WORKER_SCRIPT = 'entry/ets/workers/ConcernWorker.ets';
// Generous: the first launch copies 512 MB and expands the int8 weights on a phone-class CPU.
const LOAD_TIMEOUT_MS = 5 * 60 * 1000;
const SCORE_TIMEOUT_MS = 60 * 1000;

export interface ModelCheck {
  message: string;
  concern: boolean;
  // Score from the original model on a computer, for comparison on the device.
  score: number;
}

export interface ModelMeta {
  model: string;
  // Content hash of the bundled .ms; names the cached copy in the app's files.
  modelHash?: string;
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

type ReplyHandler = (reply: WorkerReply) => void;

export class ConcernModel {
  readonly meta: ModelMeta;
  readonly loadReport: string;
  private readonly thread: worker.ThreadWorker;
  private readonly pending: Map<number, ReplyHandler>;
  private nextId: number = 1;

  private constructor(thread: worker.ThreadWorker, pending: Map<number, ReplyHandler>, meta: ModelMeta,
    loadReport: string) {
    this.thread = thread;
    this.pending = pending;
    this.meta = meta;
    this.loadReport = loadReport;
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
    const request = new WorkerRequest();
    request.kind = 'load';
    request.config = rawText(context, 'tokenizer_config.json') ?? '';
    request.vocab = rawText(context, 'vocab.json') ?? '';
    request.merges = rawText(context, 'merges.txt') ?? '';
    if (metaText === undefined || request.config === '' || request.vocab === '' || request.merges === '') {
      return undefined;
    }
    const meta = JSON.parse(metaText) as ModelMeta;
    request.maxTokens = meta.maxTokens;
    request.padId = meta.padId;
    request.modelPath = `${context.filesDir}/concern_classifier-${meta.modelHash ?? 'unversioned'}.ms`;
    request.filesDir = context.filesDir;
    const rawPath = `${DIR}/${MODEL_FILE}`;
    let thread: worker.ThreadWorker | undefined = undefined;
    try {
      const raw = context.resourceManager.getRawFdSync(rawPath);
      request.rawFd = raw.fd;
      request.rawOffset = raw.offset;
      request.rawLength = raw.length;
      thread = new worker.ThreadWorker(WORKER_SCRIPT);
      const pending = new Map<number, ReplyHandler>();
      const loaded = new Promise<WorkerReply>((resolve: (reply: WorkerReply) => void) => {
        const timer = setTimeout(() => resolve(WorkerReply.loaded(false, 'Loading timed out.', LOAD_TIMEOUT_MS)),
          LOAD_TIMEOUT_MS);
        (thread as worker.ThreadWorker).onmessage = (event: MessageEvents) => {
          const reply = event.data as WorkerReply;
          if (reply.kind === 'loaded') {
            clearTimeout(timer);
            resolve(reply);
            return;
          }
          const handler = pending.get(reply.id);
          if (handler !== undefined) {
            pending.delete(reply.id);
            handler(reply);
          }
        };
      });
      thread.postMessage(request);
      const result = await loaded;
      if (!result.ok) {
        hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot load the model: ${result.message}`);
        thread.terminate();
        return undefined;
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, `Model loaded in ${result.elapsedMs} ms (${result.message})`);
      return new ConcernModel(thread, pending, meta, `${result.elapsedMs} ms: ${result.message}`);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Cannot start the model worker: ${(err as BusinessError).message}`);
      thread?.terminate();
      return undefined;
    } finally {
      try {
        context.resourceManager.closeRawFdSync(rawPath);
      } catch (err) {
        hilog.warn(LOG_DOMAIN, LOG_TAG, 'Cannot close the bundled model file');
      }
    }
  }

  // Undefined when the prompt does not fit, inference fails or times out.
  async score(prompt: string): Promise<ModelScore | undefined> {
    const reply = await this.ask(WorkerRequest.score(this.nextId++, prompt), SCORE_TIMEOUT_MS);
    if (reply === undefined || !reply.ok) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Inference failed: ${reply?.message ?? 'timed out'}`);
      return undefined;
    }
    return new ModelScore(reply.score, reply.elapsedMs);
  }

  // Token ids for `text`, for the diagnostics comparison with reference encodings.
  async tokenize(text: string): Promise<number[]> {
    const reply = await this.ask(WorkerRequest.tokenize(this.nextId++, text), SCORE_TIMEOUT_MS);
    return reply?.ids ?? [];
  }

  private ask(request: WorkerRequest, timeoutMs: number): Promise<WorkerReply | undefined> {
    return new Promise<WorkerReply | undefined>((resolve: (reply: WorkerReply | undefined) => void) => {
      const timer = setTimeout(() => {
        this.pending.delete(request.id);
        resolve(undefined);
      }, timeoutMs);
      this.pending.set(request.id, (reply: WorkerReply) => {
        clearTimeout(timer);
        resolve(reply);
      });
      this.thread.postMessage(request);
    });
  }
}

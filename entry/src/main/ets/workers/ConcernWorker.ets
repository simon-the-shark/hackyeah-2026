import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { fileIo as fs } from '@kit.CoreFileKit';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { BpeTokenizer, TokenizerConfig } from '../services/companion/BpeTokenizer';
import { WorkerReply, WorkerRequest } from '../platform/ConcernWorkerProtocol';

// Runs the on-device concern model off the UI thread. MindSpore Lite builds the model synchronously (including
// expanding the int8 weights), which blocked the UI thread for more than 6 s on the emulator and got the app
// killed (THREAD_BLOCK_6S). Copying the 512 MB model and parsing the tokenizer happen here for the same reason.

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
const COPY_CHUNK = 4 * 1024 * 1024;

let model: mindSporeLite.Model | undefined = undefined;
let tokenizer: BpeTokenizer | undefined = undefined;
let maxTokens = 0;
let padId = 0;

function reply(message: WorkerReply): void {
  workerPort.postMessage(message);
}

// Copies the model out of the HAP (raw file descriptor + offset) into the app's files once. The file name
// carries the model's content hash, so an updated model is copied again and older copies are removed.
function ensureModelFile(request: WorkerRequest): void {
  if (fs.accessSync(request.modelPath) && fs.statSync(request.modelPath).size === request.rawLength) {
    return;
  }
  fs.listFileSync(request.filesDir).forEach((name: string) => {
    if (name.startsWith('concern_classifier') && name.endsWith('.ms')) {
      fs.unlinkSync(`${request.filesDir}/${name}`);
    }
  });
  const out = fs.openSync(request.modelPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
  try {
    const buffer = new ArrayBuffer(COPY_CHUNK);
    let copied = 0;
    while (copied < request.rawLength) {
      const read = fs.readSync(request.rawFd, buffer, { offset: request.rawOffset + copied,
        length: Math.min(COPY_CHUNK, request.rawLength - copied) });
      if (read <= 0) {
        throw new Error('Unexpected end of the bundled model file.');
      }
      fs.writeSync(out.fd, buffer, { length: read });
      copied += read;
    }
  } finally {
    fs.closeSync(out);
  }
}

async function load(request: WorkerRequest): Promise<void> {
  const started = Date.now();
  try {
    tokenizer = new BpeTokenizer(JSON.parse(request.vocab) as Record<string, number>, request.merges.split('\n'),
      JSON.parse(request.config) as TokenizerConfig);
    maxTokens = request.maxTokens;
    padId = request.padId;
    ensureModelFile(request);
    const copiedMs = Date.now() - started;
    // float16 kernels keep the expanded weights at about 1 GB instead of 2 GB; with float32 the emulator's
    // low-memory killer (4 GB RAM) stopped the app while the model was being built.
    const context: mindSporeLite.Context = { target: ['cpu'], cpu: { threadNum: 4, precisionMode: 'preferred_fp16' } };
    model = await mindSporeLite.loadModelFromFile(request.modelPath, context);
    reply(WorkerReply.loaded(true, `copy+tokenizer ${copiedMs} ms, model build ${Date.now() - started - copiedMs} ms`,
      Date.now() - started));
  } catch (err) {
    model = undefined;
    reply(WorkerReply.loaded(false, `${(err as Error).message}`, Date.now() - started));
  }
}

async function score(request: WorkerRequest): Promise<void> {
  const started = Date.now();
  if (model === undefined || tokenizer === undefined) {
    reply(WorkerReply.failed(request.id, 'The model is not loaded.'));
    return;
  }
  try {
    const ids = tokenizer.encode(request.prompt);
    if (ids.length === 0 || ids.length > maxTokens) {
      reply(WorkerReply.failed(request.id, `The prompt does not fit (${ids.length} tokens).`));
      return;
    }
    const inputs = model.getInputs();
    const tokens = inputs.find((tensor: mindSporeLite.MSTensor) => tensor.name === 'tokens');
    const length = inputs.find((tensor: mindSporeLite.MSTensor) => tensor.name === 'length');
    if (tokens === undefined || length === undefined) {
      reply(WorkerReply.failed(request.id, 'The model has unexpected inputs.'));
      return;
    }
    const padded = new Int32Array(maxTokens).fill(padId);
    padded.set(ids);
    tokens.setData(padded.buffer);
    length.setData(new Int32Array([ids.length]).buffer);
    const outputs = await model.predict(inputs);
    const scores = new Float32Array(outputs[0].getData());
    reply(WorkerReply.scored(request.id, scores[0] - scores[1], Date.now() - started));
  } catch (err) {
    reply(WorkerReply.failed(request.id, `${(err as Error).message}`));
  }
}

workerPort.onmessage = (event: MessageEvents) => {
  const request = event.data as WorkerRequest;
  if (request.kind === 'load') {
    load(request);
  } else if (request.kind === 'score') {
    score(request);
  } else if (request.kind === 'tokenize') {
    reply(WorkerReply.tokens(request.id, tokenizer !== undefined ? tokenizer.encode(request.prompt) : []));
  }
};

workerPort.onerror = (event: ErrorEvent) => {
  reply(WorkerReply.loaded(false, `Worker error: ${event.message}`, 0));
};

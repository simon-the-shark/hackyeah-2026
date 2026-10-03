// Messages between the UI thread (ConcernModel) and the model worker (workers/ConcernWorker.ets).

export class WorkerRequest {
  kind: string = '';
  id: number = 0;
  prompt: string = '';
  // load only
  modelPath: string = '';
  // Older cached model copies in this directory are deleted after a new one is in place.
  filesDir: string = '';
  rawFd: number = -1;
  rawOffset: number = 0;
  rawLength: number = 0;
  vocab: string = '';
  merges: string = '';
  config: string = '';
  maxTokens: number = 0;
  padId: number = 0;

  static score(id: number, prompt: string): WorkerRequest {
    const request = new WorkerRequest();
    request.kind = 'score';
    request.id = id;
    request.prompt = prompt;
    return request;
  }

  static tokenize(id: number, text: string): WorkerRequest {
    const request = new WorkerRequest();
    request.kind = 'tokenize';
    request.id = id;
    request.prompt = text;
    return request;
  }
}

export class WorkerReply {
  kind: string = '';
  id: number = 0;
  ok: boolean = false;
  message: string = '';
  score: number = 0;
  elapsedMs: number = 0;
  ids: number[] = [];

  static loaded(ok: boolean, message: string, elapsedMs: number): WorkerReply {
    const reply = new WorkerReply();
    reply.kind = 'loaded';
    reply.ok = ok;
    reply.message = message;
    reply.elapsedMs = elapsedMs;
    return reply;
  }

  static scored(id: number, score: number, elapsedMs: number): WorkerReply {
    const reply = new WorkerReply();
    reply.kind = 'scored';
    reply.id = id;
    reply.ok = true;
    reply.score = score;
    reply.elapsedMs = elapsedMs;
    return reply;
  }

  static failed(id: number, message: string): WorkerReply {
    const reply = new WorkerReply();
    reply.kind = 'scored';
    reply.id = id;
    reply.message = message;
    return reply;
  }

  static tokens(id: number, ids: number[]): WorkerReply {
    const reply = new WorkerReply();
    reply.kind = 'tokens';
    reply.id = id;
    reply.ok = true;
    reply.ids = ids;
    return reply;
  }
}

import type { ZodType } from "zod";
import {
  CHAT_SCHEMA,
  chatInstructions,
  greetingRequest,
  SUMMARY_SCHEMA,
  summaryInstructions,
  transcript,
} from "./prompts.js";
import {
  AssistantError,
  chatReply,
  wellbeingSummary,
  type Assistant,
  type AudioFormat,
  type ChatContext,
  type ChatTurn,
} from "./provider.js";

const API = "https://api.openai.com/v1";
const CHAT_TIMEOUT_MS = 30_000;
const SUMMARY_TIMEOUT_MS = 45_000;
const AUDIO_TIMEOUT_MS = 30_000;

const AUDIO_MIME: Record<AudioFormat, string> = {
  m4a: "audio/mp4",
  mp3: "audio/mpeg",
  wav: "audio/wav",
  webm: "audio/webm",
  ogg: "audio/ogg",
};

export type OpenAiOptions = {
  apiKey: string;
  chatModel: string;
  transcribeModel: string;
};

type InputMessage = { role: "user" | "assistant" | "developer"; content: string };

type ResponsesBody = {
  status?: string;
  output?: { type?: string; content?: { type?: string; text?: string }[] }[];
};

/**
 * OpenAI through its REST API (Responses for chat and summaries with strict JSON schemas, audio
 * transcriptions). `store: false`, so OpenAI keeps no retrievable copy of the responses.
 * Errors never include the conversation, only the status and OpenAI's error code.
 */
export class OpenAiAssistant implements Assistant {
  readonly name: string;
  readonly simulated = false;
  readonly voice = true;

  constructor(
    private readonly opts: OpenAiOptions,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {
    this.name = `openai/${opts.chatModel}`;
  }

  async reply(ctx: ChatContext, history: ChatTurn[]) {
    const input: InputMessage[] =
      history.length === 0
        ? [{ role: "developer", content: greetingRequest(ctx) }]
        : history.map((t) => ({ role: t.role === "senior" ? "user" : "assistant", content: t.text }));
    return this.structured(chatInstructions(ctx), input, "checkin_reply", CHAT_SCHEMA, chatReply, "low", CHAT_TIMEOUT_MS);
  }

  async summarize(ctx: ChatContext, history: ChatTurn[]) {
    const input: InputMessage[] = [{ role: "user", content: transcript(ctx, history) }];
    return this.structured(
      summaryInstructions(ctx),
      input,
      "checkin_summary",
      SUMMARY_SCHEMA,
      wellbeingSummary,
      "medium",
      SUMMARY_TIMEOUT_MS,
    );
  }

  async transcribe(audio: Uint8Array, format: AudioFormat) {
    const form = new FormData();
    form.append("file", new File([new Uint8Array(audio)], `speech.${format}`, { type: AUDIO_MIME[format] }));
    form.append("model", this.opts.transcribeModel);
    form.append("response_format", "json");
    const res = await this.request("/audio/transcriptions", form, AUDIO_TIMEOUT_MS);
    const body = (await this.json(res)) as { text?: unknown };
    if (typeof body.text !== "string") throw new AssistantError("Transcription returned no text");
    return body.text.trim();
  }

  private async structured<T>(
    instructions: string,
    input: InputMessage[],
    name: string,
    schema: object,
    validator: ZodType<T>,
    effort: "low" | "medium",
    timeoutMs: number,
  ): Promise<T> {
    const res = await this.request(
      "/responses",
      JSON.stringify({
        model: this.opts.chatModel,
        instructions,
        input,
        store: false,
        reasoning: { effort },
        text: { format: { type: "json_schema", name, schema, strict: true } },
      }),
      timeoutMs,
    );
    const body = (await this.json(res)) as ResponsesBody;
    if (body.status !== "completed") throw new AssistantError(`Response not completed (${body.status ?? "unknown"})`);
    const parts = (body.output ?? []).filter((o) => o.type === "message").flatMap((o) => o.content ?? []);
    // A refusal carries no output_text, so it ends up here too.
    const text = parts.find((p) => p.type === "output_text")?.text;
    if (typeof text !== "string") throw new AssistantError("Response had no output text");
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch (err) {
      throw new AssistantError("Response was not valid JSON", { cause: err });
    }
    const result = validator.safeParse(parsed);
    if (!result.success) throw new AssistantError("Response did not match the schema");
    return result.data;
  }

  private async request(path: string, body: string | FormData, timeoutMs: number) {
    let res: Response;
    try {
      res = await this.fetchImpl(`${API}${path}`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.opts.apiKey}`,
          ...(typeof body === "string" ? { "Content-Type": "application/json" } : {}),
        },
        body,
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch (err) {
      throw new AssistantError(`OpenAI ${path} request failed`, { cause: err });
    }
    if (!res.ok) {
      let code = "";
      try {
        const error = ((await res.json()) as { error?: { code?: unknown; type?: unknown } }).error;
        code = String(error?.code ?? error?.type ?? "");
      } catch {
        // Not OpenAI's JSON error shape.
      }
      console.warn(`[assistant] OpenAI ${path} -> ${res.status} ${code}`);
      throw new AssistantError(`OpenAI ${path} answered ${res.status}`);
    }
    return res;
  }

  private async json(res: Response): Promise<unknown> {
    try {
      return await res.json();
    } catch (err) {
      throw new AssistantError("OpenAI sent an unreadable response", { cause: err });
    }
  }
}

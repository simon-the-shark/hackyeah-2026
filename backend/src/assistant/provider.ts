import { z } from "zod";

export type ChatTurn = { role: "assistant" | "senior"; text: string };

/** What the assistant knows about the people involved; never health data from other features. */
export type ChatContext = {
  seniorName: string;
  guardianNames: string[];
  /** BCP 47 hint from the senior's phone (e.g. "pl", "en-Latn-US"); the language the senior uses wins. */
  language: string | null;
  /** The senior's local weekday and time, e.g. "Saturday 09:12", when their time zone is known. */
  localTime: string | null;
};

export const chatReply = z.object({
  reply: z.string().trim().min(1).max(2000),
  suggestFinish: z.boolean(),
  safetyConcern: z.boolean(),
});
export type ChatReply = z.infer<typeof chatReply>;

export const MOODS = ["good", "okay", "low", "unclear"] as const;
export const SLEEP = ["good", "okay", "poor", "unclear"] as const;
export const PAIN = ["none", "mild", "strong", "unclear"] as const;
export const ATTENTION = ["none", "soon", "urgent"] as const;
export type Attention = (typeof ATTENTION)[number];

/** Validated summary of a finished check-in; concerns are trimmed to what a guardian can read at a glance. */
export const wellbeingSummary = z.object({
  mood: z.enum(MOODS),
  energy: z.enum(MOODS),
  sleep: z.enum(SLEEP),
  pain: z.enum(PAIN),
  concerns: z
    .array(z.string().trim())
    .transform((items) => items.filter((s) => s.length > 0).slice(0, 5).map((s) => s.slice(0, 200))),
  attention: z.enum(ATTENTION),
  attentionReason: z
    .string()
    .trim()
    .nullable()
    .transform((s) => (s ? s.slice(0, 300) : null)),
  summary: z.string().trim().min(1).max(2000),
  language: z
    .string()
    .trim()
    .nullable()
    .transform((s) => (s ? s.slice(0, 35) : null)),
});
export type WellbeingSummary = z.infer<typeof wellbeingSummary>;

export const AUDIO_FORMATS = ["m4a", "mp3", "wav", "webm", "ogg"] as const;
export type AudioFormat = (typeof AUDIO_FORMATS)[number];

/** Any failure of the assistant service (unavailable, timeout, refusal, invalid output). Routes answer 503. */
export class AssistantError extends Error {
  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = "AssistantError";
  }
}

/**
 * The wellbeing check-in assistant. Implementations must throw AssistantError for every failure,
 * so the caller can keep its state unchanged and report the assistant as unavailable.
 */
export interface Assistant {
  /** Provider and model, stored on each session, e.g. `openai/gpt-6-luna` or `simulated`. */
  readonly name: string;
  /** Scripted replies; everything it produces is labelled a simulation. */
  readonly simulated: boolean;
  /** Whether `transcribe` works. */
  readonly voice: boolean;
  /** Next assistant message; an empty history asks for the opening greeting and first question. */
  reply(ctx: ChatContext, history: ChatTurn[]): Promise<ChatReply>;
  summarize(ctx: ChatContext, history: ChatTurn[]): Promise<WellbeingSummary>;
  transcribe(audio: Uint8Array, format: AudioFormat): Promise<string>;
}

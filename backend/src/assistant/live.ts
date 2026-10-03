import type { ChatContext, ChatTurn } from "./provider.js";

/**
 * What the live voice upstream reports, already translated from the provider's protocol.
 * `audio` is base64 PCM16 mono at 24 kHz.
 */
export type LiveEvent =
  | { type: "ready" }
  | { type: "speech_started" }
  | { type: "speech_stopped"; itemId: string | null }
  | { type: "user_transcript"; itemId: string | null; transcript: string }
  | { type: "user_transcript_failed"; itemId: string | null }
  | { type: "audio"; audio: string }
  | { type: "audio_done" }
  | { type: "assistant_transcript"; transcript: string }
  | { type: "tool_call"; callId: string; name: string }
  | { type: "response_done"; status: string }
  /** `fatal`: the live session cannot continue (e.g. it could not be configured). */
  | { type: "error"; message: string; fatal: boolean }
  /** The upstream connection closed. */
  | { type: "closed" };

/** One live voice conversation with the model. Every method is safe to call after it closed. */
export interface LiveUpstream {
  appendAudio(base64: string): void;
  /** Ask the model to speak now (the greeting, or after a tool result). */
  requestResponse(): void;
  cancelResponse(): void;
  /** Answer a tool call; `continueResponse` lets the model keep talking afterwards. */
  sendToolResult(callId: string, output: string, continueResponse: boolean): void;
  close(): void;
}

/** Speech-to-speech model for the hands-free check-in. The backend proxies it; the app never talks to the provider. */
export interface LiveVoice {
  /** Provider and model, e.g. `openai/gpt-realtime-2.1`. */
  readonly name: string;
  /**
   * Opens a conversation configured for the check-in and seeded with `history`. Emits `ready` once the
   * session is configured; events arrive through `onEvent` until `closed`.
   */
  connect(opts: { ctx: ChatContext; history: ChatTurn[]; onEvent: (event: LiveEvent) => void }): LiveUpstream;
}

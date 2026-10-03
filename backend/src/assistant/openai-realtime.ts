import WebSocket from "ws";
import type { LiveEvent, LiveUpstream, LiveVoice } from "./live.js";
import { VOICE_TOOLS, voiceInstructions } from "./prompts.js";
import type { ChatContext, ChatTurn } from "./provider.js";

const URL_BASE = "wss://api.openai.com/v1/realtime";
/** Configuring the session must not take longer than this. */
const READY_TIMEOUT_MS = 15_000;
/** Harmless errors, e.g. cancelling when nothing is being said. */
const IGNORED_ERROR_CODES = new Set(["response_cancel_not_active"]);

export type OpenAiRealtimeOptions = {
  apiKey: string;
  model: string;
  voice: string;
  transcribeModel: string;
};

type ServerEvent = {
  type?: string;
  item_id?: string;
  transcript?: string;
  delta?: string;
  audio?: string;
  call_id?: string;
  name?: string;
  response?: { status?: string; status_details?: { error?: { code?: string; type?: string } } };
  error?: { type?: string; code?: string; message?: string };
};

/**
 * OpenAI Realtime over a server-to-server WebSocket (`ws`, because the request needs the
 * Authorization header). Audio is PCM16 mono at 24 kHz both ways; semantic VAD with low eagerness
 * waits for the senior to finish a thought. Nothing here logs audio or conversation text.
 */
export class OpenAiRealtime implements LiveVoice {
  readonly name: string;

  constructor(
    private readonly opts: OpenAiRealtimeOptions,
    private readonly open: (url: string, headers: Record<string, string>) => WebSocket = (url, headers) =>
      new WebSocket(url, { headers }),
  ) {
    this.name = `openai/${opts.model}`;
  }

  connect({ ctx, history, onEvent }: { ctx: ChatContext; history: ChatTurn[]; onEvent: (event: LiveEvent) => void }): LiveUpstream {
    const ws = this.open(`${URL_BASE}?model=${encodeURIComponent(this.opts.model)}`, {
      Authorization: `Bearer ${this.opts.apiKey}`,
    });
    let ready = false;
    let closed = false;
    const emit = (event: LiveEvent) => {
      if (!closed || event.type === "closed") onEvent(event);
    };
    const send = (event: object) => {
      if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(event));
    };
    const readyTimer = setTimeout(() => {
      if (!ready) {
        emit({ type: "error", message: "Realtime session was not configured in time", fatal: true });
        ws.terminate();
      }
    }, READY_TIMEOUT_MS);

    ws.on("open", () => {
      send({
        type: "session.update",
        session: {
          type: "realtime",
          instructions: voiceInstructions(ctx),
          output_modalities: ["audio"],
          tools: VOICE_TOOLS,
          tool_choice: "auto",
          audio: {
            input: {
              format: { type: "audio/pcm", rate: 24000 },
              noise_reduction: { type: "near_field" },
              transcription: { model: this.opts.transcribeModel },
              turn_detection: { type: "semantic_vad", eagerness: "low", create_response: true, interrupt_response: true },
            },
            output: { format: { type: "audio/pcm", rate: 24000 }, voice: this.opts.voice },
          },
        },
      });
      // Earlier turns of this check-in (typed or spoken), so the model continues the same conversation.
      for (const turn of history) {
        send({
          type: "conversation.item.create",
          item:
            turn.role === "senior"
              ? { type: "message", role: "user", content: [{ type: "input_text", text: turn.text }] }
              : { type: "message", role: "assistant", content: [{ type: "output_text", text: turn.text }] },
        });
      }
    });

    ws.on("message", (data) => {
      let event: ServerEvent;
      try {
        event = JSON.parse(data.toString()) as ServerEvent;
      } catch {
        return;
      }
      switch (event.type) {
        case "session.updated":
          if (!ready) {
            ready = true;
            clearTimeout(readyTimer);
            emit({ type: "ready" });
          }
          break;
        case "input_audio_buffer.speech_started":
          emit({ type: "speech_started" });
          break;
        case "input_audio_buffer.speech_stopped":
          emit({ type: "speech_stopped", itemId: event.item_id ?? null });
          break;
        case "conversation.item.input_audio_transcription.completed":
          emit({ type: "user_transcript", itemId: event.item_id ?? null, transcript: event.transcript ?? "" });
          break;
        case "conversation.item.input_audio_transcription.failed":
          console.warn("[live] OpenAI transcription failed", event.error?.code ?? event.error?.type ?? "");
          emit({ type: "user_transcript_failed", itemId: event.item_id ?? null });
          break;
        case "response.output_audio.delta": {
          const audio = event.delta ?? event.audio;
          if (typeof audio === "string" && audio !== "") emit({ type: "audio", audio });
          break;
        }
        case "response.output_audio.done":
          emit({ type: "audio_done" });
          break;
        case "response.output_audio_transcript.done":
          if (typeof event.transcript === "string" && event.transcript.trim() !== "") {
            emit({ type: "assistant_transcript", transcript: event.transcript.trim() });
          }
          break;
        case "response.function_call_arguments.done":
          if (event.call_id && event.name) emit({ type: "tool_call", callId: event.call_id, name: event.name });
          break;
        case "response.done": {
          const status = event.response?.status ?? "unknown";
          if (status === "failed") {
            const error = event.response?.status_details?.error;
            console.warn("[live] OpenAI response failed", error?.code ?? error?.type ?? "");
          }
          emit({ type: "response_done", status });
          break;
        }
        case "error": {
          const code = event.error?.code ?? event.error?.type ?? "unknown";
          if (IGNORED_ERROR_CODES.has(code)) break;
          console.warn(`[live] OpenAI error ${code}`);
          // Before the session is configured nothing can work; later errors usually concern one event.
          emit({ type: "error", message: `OpenAI error ${code}`, fatal: !ready });
          break;
        }
        default:
          break;
      }
    });

    ws.on("error", (err) => {
      console.warn("[live] OpenAI socket error", err.message);
      emit({ type: "error", message: "OpenAI connection failed", fatal: true });
    });
    ws.on("unexpected-response", (_req, res) => {
      console.warn(`[live] OpenAI refused the connection: HTTP ${res.statusCode}`);
      emit({ type: "error", message: `OpenAI refused the connection (${res.statusCode})`, fatal: true });
      ws.terminate();
    });
    ws.on("close", () => {
      clearTimeout(readyTimer);
      if (closed) return;
      closed = true;
      onEvent({ type: "closed" });
    });

    return {
      appendAudio: (audio) => send({ type: "input_audio_buffer.append", audio }),
      requestResponse: () => send({ type: "response.create" }),
      cancelResponse: () => send({ type: "response.cancel" }),
      sendToolResult: (callId, output, continueResponse) => {
        send({ type: "conversation.item.create", item: { type: "function_call_output", call_id: callId, output } });
        if (continueResponse) send({ type: "response.create" });
      },
      close: () => {
        clearTimeout(readyTimer);
        if (ws.readyState === WebSocket.CONNECTING) ws.terminate();
        else if (ws.readyState === WebSocket.OPEN) ws.close(1000);
      },
    };
  }
}

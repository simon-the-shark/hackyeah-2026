import type { AddressInfo } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import WebSocket, { WebSocketServer } from "ws";
import type { LiveEvent } from "../src/assistant/live.js";
import { OpenAiRealtime } from "../src/assistant/openai-realtime.js";
import type { ChatContext } from "../src/assistant/provider.js";

const ctx: ChatContext = { seniorName: "Halina", guardianNames: ["Marek"], language: "pl", localTime: null };
const opts = { apiKey: "test-key", model: "gpt-realtime-2.1", voice: "marin", transcribeModel: "gpt-transcribe" };

/** Local stand-in for the OpenAI Realtime socket: records what the backend sends. */
let fake: WebSocketServer;
let port = 0;
const upstream: { url?: string; auth?: string; received: Record<string, unknown>[]; socket?: WebSocket } = { received: [] };

beforeAll(async () => {
  fake = new WebSocketServer({ port: 0 });
  await new Promise((resolve) => fake.once("listening", resolve));
  port = (fake.address() as AddressInfo).port;
  fake.on("connection", (socket, req) => {
    upstream.url = req.url;
    upstream.auth = req.headers.authorization;
    upstream.socket = socket;
    socket.on("message", (data) => upstream.received.push(JSON.parse(data.toString()) as Record<string, unknown>));
  });
});
afterAll(() => new Promise((resolve) => fake.close(resolve)));

const until = async (check: () => boolean) => {
  for (let i = 0; i < 200 && !check(); i++) await new Promise((r) => setTimeout(r, 10));
  if (!check()) throw new Error("condition not met");
};

function connect() {
  upstream.received = [];
  upstream.socket = undefined;
  const events: LiveEvent[] = [];
  const realtime = new OpenAiRealtime(opts, (url, headers) =>
    new WebSocket(url.replace("wss://api.openai.com", `ws://127.0.0.1:${port}`), { headers }),
  );
  const live = realtime.connect({
    ctx,
    history: [
      { role: "assistant", text: "Dzień dobry Halino!" },
      { role: "senior", text: "Dobrze" },
    ],
    onEvent: (event) => events.push(event),
  });
  const serverSends = (event: object) => upstream.socket!.send(JSON.stringify(event));
  return { realtime, live, events, serverSends };
}

describe("OpenAI Realtime", () => {
  it("configures a spoken check-in with tools, semantic VAD and the earlier turns", async () => {
    const { realtime, live, events, serverSends } = connect();
    expect(realtime.name).toBe("openai/gpt-realtime-2.1");
    await until(() => upstream.received.length >= 3);
    expect(upstream.url).toBe("/v1/realtime?model=gpt-realtime-2.1");
    expect(upstream.auth).toBe("Bearer test-key");
    const [update, first, second] = upstream.received as {
      type: string;
      session?: Record<string, never>;
      item?: Record<string, unknown>;
    }[];
    expect(update!.type).toBe("session.update");
    const session = update!.session as unknown as {
      type: string;
      instructions: string;
      tools: { name: string }[];
      audio: { input: Record<string, unknown>; output: Record<string, unknown> };
    };
    expect(session.type).toBe("realtime");
    expect(session.instructions).toContain("Halina");
    expect(session.instructions).toContain("end_check_in");
    expect(session.tools.map((tool) => tool.name)).toEqual(["report_safety_concern", "end_check_in"]);
    expect(session.audio.input).toMatchObject({
      format: { type: "audio/pcm", rate: 24000 },
      transcription: { model: "gpt-transcribe" },
      turn_detection: { type: "semantic_vad", eagerness: "low" },
    });
    expect(session.audio.output).toMatchObject({ format: { type: "audio/pcm", rate: 24000 }, voice: "marin" });
    expect(first!.item).toEqual({ type: "message", role: "assistant", content: [{ type: "output_text", text: "Dzień dobry Halino!" }] });
    expect(second!.item).toEqual({ type: "message", role: "user", content: [{ type: "input_text", text: "Dobrze" }] });

    serverSends({ type: "session.updated", session: {} });
    serverSends({ type: "input_audio_buffer.speech_started" });
    serverSends({ type: "input_audio_buffer.speech_stopped", item_id: "item_1" });
    serverSends({ type: "conversation.item.input_audio_transcription.completed", item_id: "item_1", transcript: "Źle spałam" });
    serverSends({ type: "response.output_audio.delta", delta: "AAAA" });
    serverSends({ type: "response.output_audio.done" });
    serverSends({ type: "response.output_audio_transcript.done", transcript: " Przykro mi. " });
    serverSends({ type: "response.function_call_arguments.done", call_id: "c1", name: "end_check_in", arguments: "{}" });
    serverSends({ type: "error", error: { type: "invalid_request_error", code: "response_cancel_not_active" } });
    serverSends({ type: "error", error: { type: "invalid_request_error", code: "other" } });
    serverSends({ type: "response.done", response: { status: "completed" } });
    await until(() => events.some((e) => e.type === "response_done"));
    expect(events).toEqual([
      { type: "ready" },
      { type: "speech_started" },
      { type: "speech_stopped", itemId: "item_1" },
      { type: "user_transcript", itemId: "item_1", transcript: "Źle spałam" },
      { type: "audio", audio: "AAAA" },
      { type: "audio_done" },
      { type: "assistant_transcript", transcript: "Przykro mi." },
      { type: "tool_call", callId: "c1", name: "end_check_in" },
      { type: "error", message: "OpenAI error other", fatal: false },
      { type: "response_done", status: "completed" },
    ]);

    upstream.received = [];
    live.appendAudio("UENN");
    live.sendToolResult("c1", '{"ok":true}', true);
    live.cancelResponse();
    await until(() => upstream.received.length >= 4);
    expect(upstream.received).toEqual([
      { type: "input_audio_buffer.append", audio: "UENN" },
      { type: "conversation.item.create", item: { type: "function_call_output", call_id: "c1", output: '{"ok":true}' } },
      { type: "response.create" },
      { type: "response.cancel" },
    ]);
    live.close();
    await until(() => events.at(-1)?.type === "closed");
  });

  it("treats an error before the session is configured as fatal", async () => {
    const { events, serverSends, live } = connect();
    await until(() => upstream.socket !== undefined);
    serverSends({ type: "error", error: { type: "invalid_request_error", code: "unknown_model" } });
    await until(() => events.length > 0);
    expect(events[0]).toEqual({ type: "error", message: "OpenAI error unknown_model", fatal: true });
    live.close();
  });
});

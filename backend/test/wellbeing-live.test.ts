import { serve, type ServerType } from "@hono/node-server";
import { eq } from "drizzle-orm";
import type { AddressInfo } from "node:net";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import WebSocket, { WebSocketServer } from "ws";
import type { LiveEvent, LiveUpstream, LiveVoice } from "../src/assistant/live.js";
import type { ChatContext, ChatTurn } from "../src/assistant/provider.js";
import { alerts, wellbeingMessages, wellbeingSessions } from "../src/db/schema.js";
import { setup } from "./helpers.js";

class FakeUpstream implements LiveUpstream {
  audio: string[] = [];
  responses = 0;
  cancels = 0;
  toolResults: { callId: string; output: string; continueResponse: boolean }[] = [];
  closed = false;

  constructor(
    readonly emit: (event: LiveEvent) => void,
    readonly ctx: ChatContext,
    readonly history: ChatTurn[],
  ) {}

  appendAudio(audio: string) {
    this.audio.push(audio);
  }
  requestResponse() {
    this.responses++;
  }
  cancelResponse() {
    this.cancels++;
  }
  sendToolResult(callId: string, output: string, continueResponse: boolean) {
    this.toolResults.push({ callId, output, continueResponse });
  }
  close() {
    this.closed = true;
  }
}

class FakeLiveVoice implements LiveVoice {
  readonly name = "fake/realtime";
  connections: FakeUpstream[] = [];
  connect({ ctx, history, onEvent }: { ctx: ChatContext; history: ChatTurn[]; onEvent: (event: LiveEvent) => void }) {
    const upstream = new FakeUpstream(onEvent, ctx, history);
    this.connections.push(upstream);
    setTimeout(() => onEvent({ type: "ready" }), 5);
    return upstream;
  }
}

const live = new FakeLiveVoice();
const t = setup({ liveVoice: live, liveTiming: { holdMs: 150, maxMs: 60_000 } });
const noLive = setup();
let server: ServerType;
let port = 0;

beforeAll(async () => {
  server = serve({ fetch: t.app.fetch, port: 0, websocket: { server: new WebSocketServer({ noServer: true }) } });
  if (!server.listening) await new Promise((resolve) => server.once("listening", resolve));
  port = (server.address() as AddressInfo).port;
});
afterAll(async () => {
  await new Promise((resolve) => server.close(resolve));
  await Promise.all([t.close(), noLive.close()]);
});
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  live.connections = [];
  Object.assign(t.assistant, { failing: false, replies: [], calls: [] });
});

type Ctx = { seniorId: string; seniorToken: string; guardianToken: string };
type Frame = { type: string; [key: string]: unknown };

const livePath = (ctx: Ctx, sessionId: string) => `/v1/seniors/${ctx.seniorId}/wellbeing/sessions/${sessionId}/live`;

async function startSession(ctx: Ctx, body: object = { voice: true }) {
  const res = await t.call("POST", `/v1/seniors/${ctx.seniorId}/wellbeing/sessions`, ctx.seniorToken, body);
  return res.body.session.id as string;
}

/** Opens the live socket and collects every frame. */
async function connect(ctx: Ctx, sessionId: string, token = ctx.seniorToken) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}${livePath(ctx, sessionId)}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const frames: Frame[] = [];
  const closed = new Promise<number>((resolve) => ws.on("close", (code) => resolve(code)));
  ws.on("message", (data) => frames.push(JSON.parse(data.toString()) as Frame));
  await new Promise((resolve, reject) => {
    ws.once("open", resolve);
    ws.once("error", reject);
  });
  const waitFor = async (type: string, nth = 1) => {
    for (let i = 0; i < 200; i++) {
      const matches = frames.filter((f) => f.type === type);
      if (matches.length >= nth) return matches[nth - 1]!;
      await new Promise((r) => setTimeout(r, 10));
    }
    throw new Error(`no "${type}" frame; got ${frames.map((f) => f.type).join(", ")}`);
  };
  const upstream = async () => {
    await waitFor("ready");
    return live.connections[live.connections.length - 1]!;
  };
  return { ws, frames, closed, waitFor, upstream, send: (frame: object) => ws.send(JSON.stringify(frame)) };
}

/** HTTP status of a rejected upgrade on the real server. */
function upgradeStatus(path: string, token?: string) {
  return new Promise<number>((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}${path}`, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
    ws.on("unexpected-response", (_req, res) => {
      resolve(res.statusCode ?? 0);
      ws.terminate();
    });
    ws.on("open", () => reject(new Error("upgrade was accepted")));
    ws.on("error", () => undefined);
  });
}

const tick = (ms = 30) => new Promise((r) => setTimeout(r, ms));

async function messagesOf(sessionId: string) {
  return t.db.select().from(wellbeingMessages).where(eq(wellbeingMessages.sessionId, sessionId)).orderBy(wellbeingMessages.seq);
}

describe("live voice availability", () => {
  it("reports live voice and starts a voice check-in without a typed greeting", async () => {
    const ctx = await t.pair();
    const res = await t.call("POST", `/v1/seniors/${ctx.seniorId}/wellbeing/sessions`, ctx.seniorToken, { voice: true });
    expect(res.status).toBe(201);
    expect(res.body.messages).toEqual([]);
    expect(t.assistant.calls).toHaveLength(0);
    const state = await t.call("GET", `/v1/seniors/${ctx.seniorId}/wellbeing/session`, ctx.seniorToken);
    expect(state.body.assistant).toMatchObject({ available: true, live: true });
  });

  it("greets in text as before when live voice is not configured", async () => {
    const ctx = await noLive.pair();
    const res = await noLive.call("POST", `/v1/seniors/${ctx.seniorId}/wellbeing/sessions`, ctx.seniorToken, { voice: true });
    expect(res.status).toBe(201);
    expect(res.body.messages).toHaveLength(1);
    const state = await noLive.call("GET", `/v1/seniors/${ctx.seniorId}/wellbeing/session`, ctx.seniorToken);
    expect(state.body.assistant.live).toBe(false);
  });
});

describe("live voice upgrade", () => {
  it("rejects unauthenticated, guardian, unknown, finished and unsupported requests", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx, {});
    expect(await upgradeStatus(livePath(ctx, sessionId))).toBe(401);
    expect(await upgradeStatus(livePath(ctx, sessionId), ctx.guardianToken)).toBe(403);
    expect(await upgradeStatus(livePath(ctx, "00000000-0000-4000-8000-000000000000"), ctx.seniorToken)).toBe(404);

    const upgrade = { Authorization: `Bearer ${ctx.seniorToken}`, Upgrade: "websocket" };
    expect((await t.app.request(livePath(ctx, sessionId), { headers: { Authorization: upgrade.Authorization } })).status).toBe(400);

    await t.db.update(wellbeingSessions).set({ status: "finished" }).where(eq(wellbeingSessions.id, sessionId));
    expect(await upgradeStatus(livePath(ctx, sessionId), ctx.seniorToken)).toBe(409);

    const other = await noLive.pair();
    const otherSession = (await noLive.call("POST", `/v1/seniors/${other.seniorId}/wellbeing/sessions`, other.seniorToken, {})).body
      .session.id as string;
    const res = await noLive.app.request(livePath(other, otherSession), {
      headers: { Authorization: `Bearer ${other.seniorToken}`, Upgrade: "websocket" },
    });
    expect(res.status).toBe(503);
    expect((await res.json()).error.code).toBe("assistant_unavailable");
  });
});

describe("live voice relay", () => {
  it("asks for the greeting on an empty check-in and relays audio both ways", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    expect(up.responses).toBe(1);
    expect(up.ctx).toMatchObject({ seniorName: "Halina", guardianNames: ["Marek"] });
    expect(up.history).toEqual([]);

    const pcm = Buffer.from([1, 2, 3, 4]).toString("base64");
    conn.send({ type: "audio", audio: pcm });
    conn.send({ type: "audio", audio: "not base64!" });
    conn.send({ type: "audio", audio: "A".repeat(300_000) });
    conn.send({ type: "interrupt" });
    await tick();
    expect(up.audio).toEqual([pcm]);
    expect(up.cancels).toBe(1);

    up.emit({ type: "audio", audio: "AAAA" });
    up.emit({ type: "audio_done" });
    up.emit({ type: "response_done", status: "completed" });
    up.emit({ type: "speech_started" });
    up.emit({ type: "speech_stopped", itemId: "item_1" });
    await conn.waitFor("speech_stopped");
    expect(conn.frames.map((f) => f.type)).toEqual(["ready", "audio", "audio_done", "speech_started", "speech_stopped"]);
    conn.ws.close();
    await conn.closed;
    await tick();
    expect(up.closed).toBe(true);
    const [session] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, sessionId));
    expect(session!.status).toBe("open");
  });

  it("continues a typed check-in with its history and stores both transcripts in order", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx, {});
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    expect(up.responses).toBe(0);
    expect(up.history).toEqual([{ role: "assistant", text: "Hello Halina! How are you today?" }]);

    // The reply is ready before the senior's words are transcribed: it waits for them.
    up.emit({ type: "speech_stopped", itemId: "item_1" });
    up.emit({ type: "assistant_transcript", transcript: "I am glad. How did you sleep?" });
    await tick();
    up.emit({ type: "user_transcript", itemId: "item_1", transcript: " I feel fine " });
    const first = await conn.waitFor("message", 1);
    const second = await conn.waitFor("message", 2);
    expect(first.message).toMatchObject({ role: "senior", text: "I feel fine", inputMode: "voice" });
    expect(second.message).toMatchObject({ role: "assistant", text: "I am glad. How did you sleep?", inputMode: null });

    // A transcript that never comes does not hold the reply for long.
    up.emit({ type: "speech_stopped", itemId: "item_2" });
    up.emit({ type: "assistant_transcript", transcript: "Take your time." });
    const third = await conn.waitFor("message", 3);
    expect(third.message).toMatchObject({ role: "assistant", text: "Take your time." });
    up.emit({ type: "user_transcript_failed", itemId: "item_2" });
    up.emit({ type: "user_transcript", itemId: "item_3", transcript: "   " });
    await tick(60);

    const stored = await messagesOf(sessionId);
    expect(stored.map((m) => [m.role, m.text])).toEqual([
      ["assistant", "Hello Halina! How are you today?"],
      ["senior", "I feel fine"],
      ["assistant", "I am glad. How did you sleep?"],
      ["assistant", "Take your time."],
    ]);
    const [session] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, sessionId));
    expect(session).toMatchObject({ seniorMessages: 1, voiceMessages: 1 });
    conn.ws.close();
  });

  it("raises one wellbeing alert on a safety concern and marks the next reply", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    up.emit({ type: "tool_call", callId: "call_1", name: "report_safety_concern" });
    await conn.waitFor("safety_concern");
    expect(up.toolResults).toEqual([{ callId: "call_1", output: '{"ok":true}', continueResponse: true }]);
    up.emit({ type: "assistant_transcript", transcript: "Please press the red SOS button now." });
    const reply = await conn.waitFor("message");
    expect(reply.message).toMatchObject({ role: "assistant", safetyConcern: true });

    await tick(60);
    const raised = (await t.db.select().from(alerts).where(eq(alerts.seniorId, ctx.seniorId))).filter((a) => a.kind === "wellbeing");
    expect(raised).toHaveLength(1);
    expect(raised[0]!.details).toMatchObject({ sessionId, attention: "urgent", during: "conversation" });
    expect(t.push.calls.map((c) => c.message.title)).toContain("Halina's wellbeing check-in needs attention");
    expect(JSON.stringify(t.push.calls)).not.toContain("SOS button");
    conn.ws.close();
  });

  it("finishes the check-in after the goodbye and closes normally", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    up.emit({ type: "speech_stopped", itemId: "item_1" });
    up.emit({ type: "user_transcript", itemId: "item_1", transcript: "I slept badly, bye" });
    await conn.waitFor("message");
    up.emit({ type: "assistant_transcript", transcript: "Thank you, a summary goes to Marek. Goodbye!" });
    up.emit({ type: "tool_call", callId: "call_end", name: "end_check_in" });
    expect(up.toolResults).toEqual([{ callId: "call_end", output: '{"ok":true}', continueResponse: false }]);
    up.emit({ type: "audio", audio: "AAAA" });
    up.emit({ type: "response_done", status: "completed" });

    const finished = await conn.waitFor("finished");
    expect(await conn.closed).toBe(1000);
    expect(finished.session).toMatchObject({ id: sessionId, status: "finished", finishReason: "assistant" });
    expect(finished.report).toMatchObject({ source: "ai", summary: t.assistant.summary.summary });
    // Audio is relayed at once while transcripts are stored first, so only the set and the last frame are fixed.
    expect(conn.frames.map((f) => f.type).sort()).toEqual([
      "audio",
      "audio_done",
      "finished",
      "message",
      "message",
      "ready",
      "speech_stopped",
    ]);
    expect(conn.frames.at(-1)!.type).toBe("finished");
    expect(await messagesOf(sessionId)).toHaveLength(0);
    expect(t.push.calls.map((c) => c.message.title)).toContain("Halina shared a wellbeing check-in");
    expect(up.closed).toBe(true);
  });

  it("keeps the check-in open when the summary fails", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    up.emit({ type: "speech_stopped", itemId: "item_1" });
    up.emit({ type: "user_transcript", itemId: "item_1", transcript: "Bye" });
    await conn.waitFor("message");
    t.assistant.failing = true;
    up.emit({ type: "tool_call", callId: "call_end", name: "end_check_in" });
    up.emit({ type: "response_done", status: "completed" });
    const error = await conn.waitFor("error");
    expect(error).toMatchObject({ code: "assistant_unavailable" });
    expect(await conn.closed).toBe(1000);
    const [session] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, sessionId));
    expect(session!.status).toBe("open");
  });

  it("reports an upstream failure and closes with 1011", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const conn = await connect(ctx, sessionId);
    const up = await conn.upstream();
    up.emit({ type: "error", message: "not fatal", fatal: false });
    await tick();
    expect(conn.frames.map((f) => f.type)).toEqual(["ready"]);
    up.emit({ type: "error", message: "boom", fatal: true });
    expect(await conn.waitFor("error")).toMatchObject({ code: "assistant_unavailable" });
    expect(await conn.closed).toBe(1011);
    expect(up.closed).toBe(true);
  });

  it("replaces an older connection to the same check-in", async () => {
    const ctx = await t.pair();
    const sessionId = await startSession(ctx);
    const first = await connect(ctx, sessionId);
    const firstUp = await first.upstream();
    const second = await connect(ctx, sessionId);
    await second.upstream();
    expect(await first.closed).toBe(1000);
    expect(firstUp.closed).toBe(true);
    second.ws.close();
  });

  it("ends voice mode when the hourly assistant budget runs out", async () => {
    const limited = setup({ liveVoice: live, rateLimits: { assistantPerHour: 2 } });
    const limitedServer = serve({
      fetch: limited.app.fetch,
      port: 0,
      websocket: { server: new WebSocketServer({ noServer: true }) },
    });
    try {
      if (!limitedServer.listening) await new Promise((resolve) => limitedServer.once("listening", resolve));
      const limitedPort = (limitedServer.address() as AddressInfo).port;
      const ctx = await limited.pair();
      const sessionId = (
        await limited.call("POST", `/v1/seniors/${ctx.seniorId}/wellbeing/sessions`, ctx.seniorToken, { voice: true })
      ).body.session.id as string;
      const ws = new WebSocket(`ws://127.0.0.1:${limitedPort}${livePath(ctx, sessionId)}`, {
        headers: { Authorization: `Bearer ${ctx.seniorToken}` },
      });
      const frames: Frame[] = [];
      ws.on("message", (data) => frames.push(JSON.parse(data.toString()) as Frame));
      const closed = new Promise<number>((resolve) => ws.on("close", (code) => resolve(code)));
      await new Promise((resolve) => ws.once("open", resolve));
      for (let i = 0; i < 100 && !frames.some((f) => f.type === "ready"); i++) await tick(10);
      const up = live.connections[live.connections.length - 1]!;
      up.emit({ type: "speech_stopped", itemId: "a" }); // second call: allowed
      up.emit({ type: "speech_stopped", itemId: "b" }); // third call: over the limit
      expect(await closed).toBe(1000);
      expect(frames.find((f) => f.type === "error")).toMatchObject({ code: "rate_limited" });
    } finally {
      await new Promise((resolve) => limitedServer.close(resolve));
      await limited.close();
    }
  });
});

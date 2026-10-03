import { count, eq } from "drizzle-orm";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { alerts, reports, wellbeingMessages, wellbeingSessions } from "../src/db/schema.js";
import { runWatchdogOnce } from "../src/services/watchdog.js";
import { FakeAssistant, setup } from "./helpers.js";

const t = setup();
const off = setup({ assistant: null });
const limited = setup({ rateLimits: { assistantPerHour: 2 } });
afterAll(() => Promise.all([t.close(), off.close(), limited.close()]));

const defaults = new FakeAssistant();
beforeEach(async () => {
  await t.reset();
  for (const s of [t, off, limited]) {
    s.push.calls = [];
    s.time.now = new Date("2026-10-03T12:00:00Z");
  }
  Object.assign(t.assistant, { failing: false, replies: [], calls: [], voice: true });
  t.assistant.summary = { ...defaults.summary };
  t.assistant.transcript = defaults.transcript;
});

type Ctx = { seniorId: string; seniorToken: string; guardianToken: string };
type Harness = typeof t;

const base = (ctx: Ctx) => `/v1/seniors/${ctx.seniorId}/wellbeing`;
const start = (ctx: Ctx, body: object = {}, h: Harness = t) =>
  h.call("POST", `${base(ctx)}/sessions`, ctx.seniorToken, body);
const say = (ctx: Ctx, sessionId: string, body: object, h: Harness = t) =>
  h.call("POST", `${base(ctx)}/sessions/${sessionId}/messages`, ctx.seniorToken, body);
const finish = (ctx: Ctx, sessionId: string, body?: object, h: Harness = t) =>
  h.call("POST", `${base(ctx)}/sessions/${sessionId}/finish`, ctx.seniorToken, body);
const audio = (text: string) => Buffer.from(text).toString("base64");

async function messagesOf(sessionId: string) {
  return t.db.select().from(wellbeingMessages).where(eq(wellbeingMessages.sessionId, sessionId));
}

async function wellbeingAlerts(seniorId: string) {
  return t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId)).then((rows) => rows.filter((a) => a.kind === "wellbeing"));
}

describe("starting a check-in", () => {
  it("greets the senior by name, then resumes the open check-in", async () => {
    const ctx = await t.pair();
    const res = await start(ctx, { language: "pl", timezone: "Europe/Warsaw" });
    expect(res.status).toBe(201);
    expect(res.body.session).toMatchObject({ status: "open", seniorMessages: 0, assistant: "fake/model", simulated: false });
    expect(res.body.messages).toEqual([
      expect.objectContaining({ role: "assistant", text: "Hello Halina! How are you today?", inputMode: null, safetyConcern: false }),
    ]);
    expect(t.assistant.calls[0]!.ctx).toEqual({
      seniorName: "Halina",
      guardianNames: ["Marek"],
      language: "pl",
      localTime: "Saturday 14:00",
    });

    const state = await t.call("GET", `${base(ctx)}/session`, ctx.seniorToken);
    expect(state.status).toBe(200);
    expect(state.body.session.id).toBe(res.body.session.id);
    expect(state.body.messages).toHaveLength(1);
    expect(state.body.assistant).toEqual({ available: true, simulated: false, voice: true, live: false });
    expect(state.body.guardians).toEqual([expect.objectContaining({ displayName: "Marek" })]);

    const again = await start(ctx);
    expect(again.status).toBe(200);
    expect(again.body.session.id).toBe(res.body.session.id);
    expect(again.body.messages).toHaveLength(1);
    expect(t.assistant.calls).toHaveLength(1);
  });

  it("answers 503 and stores nothing when the assistant fails or is not configured", async () => {
    const ctx = await t.pair();
    t.assistant.failing = true;
    const res = await start(ctx);
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe("assistant_unavailable");
    const [row] = await t.db.select({ n: count() }).from(wellbeingSessions);
    expect(row!.n).toBe(0);

    const other = await off.pair();
    const state = await off.call("GET", `${base(other)}/session`, other.seniorToken);
    expect(state.body).toMatchObject({ session: null, messages: [], assistant: { available: false, simulated: false, voice: false } });
    expect((await start(other, {}, off)).status).toBe(503);
  });

  it("is only for the senior themselves", async () => {
    const ctx = await t.pair();
    const stranger = await t.pair();
    expect((await t.call("GET", `${base(ctx)}/session`, ctx.guardianToken)).status).toBe(403);
    expect((await t.call("POST", `${base(ctx)}/sessions`, ctx.guardianToken, {})).status).toBe(403);
    expect((await t.call("POST", `${base(ctx)}/sessions`, stranger.seniorToken, {})).status).toBe(403);

    const session = (await start(ctx)).body.session;
    const foreign = await t.call("POST", `${base(stranger)}/sessions/${session.id}/messages`, stranger.seniorToken, { text: "hi" });
    expect(foreign.status).toBe(404);
    expect((await t.call("POST", `${base(ctx)}/sessions/${session.id}/finish`, ctx.guardianToken, {})).status).toBe(403);
  });
});

describe("messages", () => {
  it("stores a typed answer with the assistant's reply", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    const res = await say(ctx, session.id, { text: "  I feel fine  " });
    expect(res.status).toBe(201);
    expect(res.body.message).toMatchObject({ role: "senior", text: "I feel fine", inputMode: "text" });
    expect(res.body.reply).toMatchObject({ role: "assistant", text: "Thank you. How did you sleep?", inputMode: null });
    expect(res.body).toMatchObject({ suggestFinish: false, safetyConcern: false });
    expect(t.assistant.calls[1]!.history).toEqual([
      { role: "assistant", text: "Hello Halina! How are you today?" },
      { role: "senior", text: "I feel fine" },
    ]);

    const state = (await t.call("GET", `${base(ctx)}/session`, ctx.seniorToken)).body;
    expect(state.messages.map((m: { role: string }) => m.role)).toEqual(["assistant", "senior", "assistant"]);
    expect(state.session.seniorMessages).toBe(1);
  });

  it("stores nothing when the reply fails", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    t.assistant.failing = true;
    expect((await say(ctx, session.id, { text: "Hello" })).status).toBe(503);
    expect(await messagesOf(session.id)).toHaveLength(1);
  });

  it("transcribes a voice answer", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    const res = await say(ctx, session.id, { audio: audio("fake m4a"), audioFormat: "m4a" });
    expect(res.status).toBe(201);
    expect(res.body.message).toMatchObject({ text: "I slept badly", inputMode: "voice" });
    expect(t.assistant.calls.find((c) => c.method === "transcribe")?.format).toBe("m4a");
    const [row] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, session.id));
    expect(row).toMatchObject({ seniorMessages: 1, voiceMessages: 1 });

    t.assistant.transcript = "   ";
    const silent = await say(ctx, session.id, { audio: audio("silence"), audioFormat: "m4a" });
    expect(silent.status).toBe(422);
    expect(silent.body.error.code).toBe("no_speech");
  });

  it("rejects invalid bodies and voice when the assistant has none", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    for (const body of [
      {},
      { text: "" },
      { text: "a".repeat(1001) },
      { audio: "@@not base64@@", audioFormat: "m4a" },
      { audio: audio("x"), audioFormat: "flac" },
      { text: "hi", audio: audio("x"), audioFormat: "m4a" },
    ]) {
      expect((await say(ctx, session.id, body)).status).toBe(400);
    }
    t.assistant.voice = false;
    expect((await say(ctx, session.id, { audio: audio("x"), audioFormat: "m4a" })).status).toBe(503);
  });

  it("raises one wellbeing alert for a possible emergency, without what was said", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    const sos = { reply: "Please press the red SOS button now.", suggestFinish: false, safetyConcern: true };
    t.assistant.replies = [sos, sos];
    const res = await say(ctx, session.id, { text: "I fell and my chest hurts" });
    expect(res.body.safetyConcern).toBe(true);
    expect(res.body.reply.safetyConcern).toBe(true);
    await say(ctx, session.id, { text: "Still on the floor" });

    const raised = await wellbeingAlerts(ctx.seniorId);
    expect(raised).toHaveLength(1);
    expect(raised[0]!.details).toEqual({ sessionId: session.id, attention: "urgent", during: "conversation" });
    expect(t.push.calls).toHaveLength(1);
    expect(t.push.calls[0]!.message.title).toBe("Halina's wellbeing check-in needs attention");
    expect(t.push.calls[0]!.message.body).toBe("AI summary, not a medical assessment. Open the app for details.");
    expect(JSON.stringify(t.push.calls)).not.toMatch(/fell|chest|floor/i);
  });

  it("suggests finishing from the 30th answer and stops at 40", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    await t.db.update(wellbeingSessions).set({ seniorMessages: 29 }).where(eq(wellbeingSessions.id, session.id));
    expect((await say(ctx, session.id, { text: "More" })).body.suggestFinish).toBe(true);
    await t.db.update(wellbeingSessions).set({ seniorMessages: 40 }).where(eq(wellbeingSessions.id, session.id));
    const full = await say(ctx, session.id, { text: "More" });
    expect(full.status).toBe(409);
    expect(full.body.error.code).toBe("session_full");
  });
});

describe("finishing", () => {
  it("stores the report, deletes the conversation and tells the guardians, once", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "Good, thanks" });
    await say(ctx, session.id, { audio: audio("voice"), audioFormat: "m4a" });

    const res = await finish(ctx, session.id, { reason: "assistant" });
    expect(res.status).toBe(200);
    expect(res.body.session).toMatchObject({ status: "finished", finishReason: "assistant", reportId: res.body.report.id });
    expect(res.body.report).toMatchObject({
      source: "ai",
      period: "2026-10-03",
      summary: "Halina feels good but slept badly. Her knee hurts a little when walking.",
      structured: {
        kind: "wellbeing_chat",
        mood: "good",
        energy: "okay",
        sleep: "poor",
        pain: "mild",
        concerns: ["Knee hurts when walking"],
        attention: "none",
        attentionReason: null,
        language: "en",
        sessionId: session.id,
        finishReason: "assistant",
        seniorMessages: 2,
        voiceMessages: 1,
        assistant: "fake/model",
      },
    });
    expect(t.assistant.calls.find((c) => c.method === "summarize")?.history).toHaveLength(5);
    expect(await messagesOf(session.id)).toHaveLength(0);
    expect(t.push.calls).toHaveLength(1);
    expect(t.push.calls[0]!.message).toMatchObject({
      title: "Halina shared a wellbeing check-in",
      data: { reportId: res.body.report.id, seniorId: ctx.seniorId, kind: "wellbeing_report" },
    });
    expect(await wellbeingAlerts(ctx.seniorId)).toHaveLength(0);

    const repeat = await finish(ctx, session.id);
    expect(repeat.status).toBe(200);
    expect(repeat.body.report.id).toBe(res.body.report.id);
    expect(t.push.calls).toHaveLength(1);
    expect(t.assistant.calls.filter((c) => c.method === "summarize")).toHaveLength(1);

    expect((await say(ctx, session.id, { text: "One more" })).body.error.code).toBe("session_closed");
    expect((await t.call("GET", `${base(ctx)}/session`, ctx.seniorToken)).body.session).toBeNull();
    const list = await t.call("GET", `/v1/seniors/${ctx.seniorId}/reports`, ctx.guardianToken);
    expect(list.body.items.map((r: { id: string }) => r.id)).toEqual([res.body.report.id]);
  });

  it("drops a check-in the senior never answered", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    const res = await finish(ctx, session.id);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ session: null, report: null });
    expect(await t.db.select().from(wellbeingSessions)).toHaveLength(0);
    expect(t.push.calls).toHaveLength(0);
  });

  it("keeps the check-in open when the summary fails", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "Fine" });
    t.assistant.failing = true;
    expect((await finish(ctx, session.id)).status).toBe(503);
    const state = (await t.call("GET", `${base(ctx)}/session`, ctx.seniorToken)).body;
    expect(state.session.status).toBe("open");
    expect(state.messages).toHaveLength(3);
  });

  it("raises an alert with the report for an urgent summary", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "I fell" });
    t.assistant.summary = { ...defaults.summary, attention: "urgent", attentionReason: "She fell and cannot get up." };
    const report = (await finish(ctx, session.id)).body.report;

    const [alert] = await wellbeingAlerts(ctx.seniorId);
    expect(alert!.details).toEqual({
      sessionId: session.id,
      reportId: report.id,
      attention: "urgent",
      reason: "She fell and cannot get up.",
    });
    expect(t.push.calls.map((c) => c.message.title)).toEqual([
      "Halina's wellbeing check-in: please read soon",
      "Halina's wellbeing check-in needs attention",
    ]);
  });

  it("adds the report to an alert raised during the conversation", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    t.assistant.replies = [{ reply: "Press SOS.", suggestFinish: false, safetyConcern: true }];
    await say(ctx, session.id, { text: "Chest pain" });
    t.assistant.summary = { ...defaults.summary, attention: "urgent", attentionReason: "Chest pain." };
    const report = (await finish(ctx, session.id)).body.report;
    const raised = await wellbeingAlerts(ctx.seniorId);
    expect(raised).toHaveLength(1);
    expect(raised[0]!.details).toEqual({ sessionId: session.id, attention: "urgent", during: "conversation", reportId: report.id });
  });
});

describe("guardian reading", () => {
  it("reads one report by id; seniors and other guardians cannot", async () => {
    const ctx = await t.pair();
    const stranger = await t.pair();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "Fine" });
    const report = (await finish(ctx, session.id)).body.report;
    const path = `/v1/seniors/${ctx.seniorId}/reports/${report.id}`;
    const res = await t.call("GET", path, ctx.guardianToken);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ id: report.id, source: "ai" });
    expect((await t.call("GET", path, ctx.seniorToken)).status).toBe(403);
    expect((await t.call("GET", path, stranger.guardianToken)).status).toBe(403);
    expect((await t.call("GET", `/v1/seniors/${ctx.seniorId}/reports/${session.id}`, ctx.guardianToken)).status).toBe(404);

    // Withdrawn by the senior: gone for the guardian, and the session no longer points at it.
    expect((await t.call("DELETE", path, ctx.seniorToken)).status).toBe(204);
    expect((await t.call("GET", path, ctx.guardianToken)).status).toBe(404);
    expect((await finish(ctx, session.id)).body).toMatchObject({ session: { reportId: null }, report: null });
  });

  it("shows the latest report and its attention in the overview", async () => {
    const ctx = await t.pair();
    const before = await t.call("GET", `/v1/seniors/${ctx.seniorId}/overview`, ctx.guardianToken);
    expect(before.body.latestReport).toBeNull();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "My knee is worse" });
    t.assistant.summary = { ...defaults.summary, attention: "soon", attentionReason: "Worsening knee pain." };
    const report = (await finish(ctx, session.id)).body.report;
    const res = await t.call("GET", `/v1/seniors/${ctx.seniorId}/overview`, ctx.guardianToken);
    expect(res.body.latestReport).toEqual({ id: report.id, createdAt: report.createdAt, attention: "soon", source: "ai" });
    expect(res.body.latestReportAt).toBe(report.createdAt);
  });
});

describe("idle check-ins", () => {
  it("are finished by the watchdog, and dropped when never answered", async () => {
    const answered = await t.pair();
    const silent = await t.pair();
    const session = (await start(answered)).body.session;
    await say(answered, session.id, { text: "Fine" });
    const empty = (await start(silent)).body.session;

    t.time.now = new Date("2026-10-03T12:21:00Z");
    await runWatchdogOnce(t.deps);
    const [finished] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, session.id));
    expect(finished).toMatchObject({ status: "finished", finishReason: "idle" });
    const [report] = await t.db.select().from(reports).where(eq(reports.id, finished!.reportId!));
    expect(report!.structured).toMatchObject({ finishReason: "idle" });
    expect(await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, empty.id))).toHaveLength(0);
  });

  it("wait while the assistant fails and close with a report without summary after a day", async () => {
    const ctx = await t.pair();
    const session = (await start(ctx)).body.session;
    await say(ctx, session.id, { text: "Fine" });
    t.assistant.failing = true;

    t.time.now = new Date("2026-10-03T12:21:00Z");
    await runWatchdogOnce(t.deps);
    let [row] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, session.id));
    expect(row).toMatchObject({ status: "open", lastActivityAt: t.time.now });

    t.time.now = new Date("2026-10-04T12:01:00Z");
    await runWatchdogOnce(t.deps);
    [row] = await t.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, session.id));
    expect(row!.status).toBe("finished");
    const [report] = await t.db.select().from(reports).where(eq(reports.id, row!.reportId!));
    expect(report).toMatchObject({
      source: "structured",
      summary: null,
      structured: { summaryUnavailable: true, mood: "unclear", attention: "none", concerns: [] },
    });
    expect(await messagesOf(session.id)).toHaveLength(0);
  });
});

describe("rate limit", () => {
  it("caps assistant calls per senior and hour", async () => {
    const ctx = await limited.pair();
    const session = (await start(ctx, {}, limited)).body.session;
    expect((await say(ctx, session.id, { text: "One" }, limited)).status).toBe(201);
    const blocked = await say(ctx, session.id, { text: "Two" }, limited);
    expect(blocked.status).toBe(429);
    expect(blocked.body.error.code).toBe("rate_limited");
    limited.time.now = new Date("2026-10-03T13:00:01Z");
    expect((await say(ctx, session.id, { text: "Two" }, limited)).status).toBe(201);
  });
});

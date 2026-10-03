import { sql } from "drizzle-orm";
import { randomUUID } from "node:crypto";
import { createApp } from "../src/app.js";
import {
  AssistantError,
  type Assistant,
  type AudioFormat,
  type ChatContext,
  type ChatReply,
  type ChatTurn,
  type WellbeingSummary,
} from "../src/assistant/provider.js";
import { createDb } from "../src/db/client.js";
import type { PushMessage, PushProvider } from "../src/push/provider.js";
import type { Deps } from "../src/types.js";

export class FakePush implements PushProvider {
  readonly name = "fake";
  calls: { tokens: string[]; message: PushMessage }[] = [];
  result: "sent" | "failed" = "sent";
  async send(tokens: string[], message: PushMessage) {
    this.calls.push({ tokens, message });
    return this.result;
  }
}

/** Deterministic stand-in for the OpenAI assistant; queue replies, set the summary, or make it fail. */
export class FakeAssistant implements Assistant {
  name = "fake/model";
  simulated = false;
  voice = true;
  /** Every call throws AssistantError while set. */
  failing = false;
  /** Used in order; when empty, a generic question follows. */
  replies: ChatReply[] = [];
  summary: WellbeingSummary = {
    mood: "good",
    energy: "okay",
    sleep: "poor",
    pain: "mild",
    concerns: ["Knee hurts when walking"],
    attention: "none",
    attentionReason: null,
    summary: "Halina feels good but slept badly. Her knee hurts a little when walking.",
    language: "en",
  };
  transcript = "I slept badly";
  calls: { method: string; ctx?: ChatContext; history?: ChatTurn[]; format?: AudioFormat; text?: string }[] = [];

  private check() {
    if (this.failing) throw new AssistantError("fake failure");
  }

  async reply(ctx: ChatContext, history: ChatTurn[]) {
    this.calls.push({ method: "reply", ctx, history });
    this.check();
    return (
      this.replies.shift() ?? {
        reply: history.length === 0 ? `Hello ${ctx.seniorName}! How are you today?` : "Thank you. How did you sleep?",
        suggestFinish: false,
        safetyConcern: false,
      }
    );
  }

  async summarize(ctx: ChatContext, history: ChatTurn[]) {
    this.calls.push({ method: "summarize", ctx, history });
    this.check();
    return this.summary;
  }

  async transcribe(_audio: Uint8Array, format: AudioFormat) {
    this.calls.push({ method: "transcribe", format });
    this.check();
    return this.transcript;
  }

  async speak(text: string) {
    this.calls.push({ method: "speak", text });
    this.check();
    return new Uint8Array([0x49, 0x44, 0x33, 0x04]);
  }
}

type Overrides = Partial<Omit<Deps, "rateLimits">> & { rateLimits?: Partial<Deps["rateLimits"]> };

export function setup(overrides: Overrides = {}) {
  const { db, close } = createDb(process.env.DATABASE_URL!);
  const push = new FakePush();
  const assistant = new FakeAssistant();
  const time = { now: new Date("2026-10-03T12:00:00Z") };
  const deps: Deps = {
    db,
    push,
    clock: () => time.now,
    staleSeconds: 900,
    doseGraceMinutes: 60,
    sosRepushSeconds: 120,
    lowBatteryPercent: 15,
    assistant,
    wellbeingIdleMinutes: 20,
    ...overrides,
    // Tests share one "unknown" client IP, so limits are off unless a test sets them.
    rateLimits: {
      bootstrapPerMinute: 1_000_000,
      claimFailuresPer15Min: 1_000_000,
      assistantPerHour: 1_000_000,
      ...overrides.rateLimits,
    },
  };
  const app = createApp(deps);

  const call = async (method: string, path: string, token?: string, body?: unknown) => {
    const res = await app.request(path, {
      method,
      headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), "Content-Type": "application/json" },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const type = res.headers.get("content-type") ?? "";
    if (type && !type.includes("json")) {
      return { status: res.status, body: new Uint8Array(await res.arrayBuffer()), contentType: type };
    }
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : null, contentType: type };
  };

  const reset = () =>
    db.execute(sql`truncate users, medication_catalog restart identity cascade`);

  /** Senior + paired guardian, both with a registered push token. */
  async function pair() {
    const senior = (await call("POST", "/v1/seniors", undefined, { displayName: "Halina" })).body;
    const guardian = (
      await call("POST", "/v1/pairing/claim", undefined, { code: senior.pairingCode, displayName: "Marek" })
    ).body;
    await call("PUT", "/v1/devices/me/push-token", guardian.token, { pushToken: `push-${randomUUID()}` });
    return { seniorId: senior.seniorId as string, seniorToken: senior.token as string, guardianToken: guardian.token as string };
  }

  return { db, close, push, assistant, time, deps, app, call, reset, pair };
}

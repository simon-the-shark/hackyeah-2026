import { sql } from "drizzle-orm";
import { randomUUID } from "node:crypto";
import { createApp } from "../src/app.js";
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

export function setup(overrides: Partial<Deps> = {}) {
  const { db, close } = createDb(process.env.DATABASE_URL!);
  const push = new FakePush();
  const time = { now: new Date("2026-10-03T12:00:00Z") };
  const deps: Deps = {
    db,
    push,
    clock: () => time.now,
    staleSeconds: 900,
    doseGraceMinutes: 60,
    sosRepushSeconds: 120,
    // Tests share one "unknown" client IP, so limits are off unless a test sets them.
    rateLimits: { bootstrapPerMinute: 1_000_000, claimFailuresPer15Min: 1_000_000 },
    ...overrides,
  };
  const app = createApp(deps);

  const call = async (method: string, path: string, token?: string, body?: unknown) => {
    const res = await app.request(path, {
      method,
      headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), "Content-Type": "application/json" },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : null };
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

  return { db, close, push, time, deps, app, call, reset, pair };
}

import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { setup } from "./helpers.js";

const t = setup({ rateLimits: { bootstrapPerMinute: 3, claimFailuresPer15Min: 2 } });
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
});

describe("rate limits on unauthenticated endpoints", () => {
  it("limits senior bootstrap per minute", async () => {
    t.time.now = new Date("2026-10-03T12:00:00Z");
    for (let i = 0; i < 3; i++) {
      expect((await t.call("POST", "/v1/seniors", undefined, { displayName: "S" })).status).toBe(201);
    }
    const blocked = await t.call("POST", "/v1/seniors", undefined, { displayName: "S" });
    expect(blocked.status).toBe(429);
    expect(blocked.body.error.code).toBe("rate_limited");
    expect(blocked.body.error.details.retryAfterSeconds).toBeGreaterThan(0);
    t.time.now = new Date("2026-10-03T12:01:01Z");
    expect((await t.call("POST", "/v1/seniors", undefined, { displayName: "S" })).status).toBe(201);
  });

  it("locks out pairing-code guessing but not successful claims", async () => {
    t.time.now = new Date("2026-10-03T13:00:00Z");
    const senior = (await t.call("POST", "/v1/seniors", undefined, { displayName: "S" })).body;
    const guess = (code: string) => t.call("POST", "/v1/pairing/claim", undefined, { code, displayName: "G" });
    expect((await guess("000001")).status).toBe(410);
    expect((await guess("000002")).status).toBe(410);
    // Locked out now, even with the right code.
    expect((await guess(senior.pairingCode)).status).toBe(429);
    t.time.now = new Date("2026-10-03T13:15:01Z");
    const code = (await t.call("POST", "/v1/pairing/codes", senior.token)).body.pairingCode;
    expect((await guess(code)).status).toBe(201);
  });

  it("counts guardian and watch claim guesses against one budget", async () => {
    t.time.now = new Date("2026-10-03T14:00:00Z");
    const senior = (await t.call("POST", "/v1/seniors", undefined, { displayName: "S" })).body;
    const watchCode = (await t.call("POST", "/v1/pairing/watch-codes", senior.token)).body.pairingCode;
    expect((await t.call("POST", "/v1/pairing/claim", undefined, { code: "000001", displayName: "G" })).status).toBe(410);
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: "000002" })).status).toBe(410);
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: watchCode })).status).toBe(429);
  });
});

import { randomUUID } from "node:crypto";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { runWatchdogOnce } from "../src/services/watchdog.js";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.push.result = "sent";
  t.time.now = new Date("2026-10-03T12:00:00Z");
});

/** A paired senior with a watch, as the watch app would set it up. */
async function withWatch() {
  const pair = await t.pair();
  const code = (await t.call("POST", "/v1/pairing/watch-codes", pair.seniorToken)).body.pairingCode;
  const watch = (await t.call("POST", "/v1/pairing/watch-claim", undefined, { code })).body;
  return { ...pair, watchToken: watch.token as string };
}

const reading = { bpm: 134, direction: "high", lowBpm: 45, highBpm: 120, sustainedSeconds: 120 };
const outOfRange = (extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  type: "heart_rate_out_of_range",
  occurredAt: "2026-10-03T11:59:58Z",
  source: "device",
  heartRate: reading,
  ...extra,
});
const inRange = (extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  type: "heart_rate_in_range",
  occurredAt: "2026-10-03T11:59:59Z",
  source: "device",
  ...extra,
});

describe("heart-rate alerts", () => {
  it("raises an informational alert whose push carries no reading", async () => {
    const { seniorId, watchToken, guardianToken } = await withWatch();
    const res = await t.call("POST", `/v1/seniors/${seniorId}/events`, watchToken, outOfRange());
    expect(res.status).toBe(201);
    expect(res.body.alert.kind).toBe("heart_rate");

    const [push] = t.push.calls;
    expect(push!.message.title).toBe("Halina's watch: heart rate outside the set range");
    expect(push!.message.title).not.toMatch(/\d/);
    expect(push!.message.body).toMatch(/not a medical assessment/);

    const alert = (await t.call("GET", `/v1/alerts/${res.body.alert.id}`, guardianToken)).body;
    expect(alert.details).toEqual(reading);
  });

  it("validates the heart-rate payload and requires a source", async () => {
    const { seniorId, watchToken } = await withWatch();
    const path = `/v1/seniors/${seniorId}/events`;
    const bad = [
      outOfRange({ source: undefined }),
      outOfRange({ heartRate: undefined }),
      inRange({ source: undefined }),
      { id: randomUUID(), type: "sos", occurredAt: "2026-10-03T11:59:58Z", heartRate: reading },
      outOfRange({ heartRate: { ...reading, lowBpm: 120, highBpm: 120 } }),
      outOfRange({ heartRate: { ...reading, bpm: 300 } }),
    ];
    for (const body of bad) {
      expect((await t.call("POST", path, watchToken, body)).status).toBe(400);
    }
    expect(t.push.calls).toHaveLength(0);
  });

  it("labels a simulated reading in the push and the alert", async () => {
    const { seniorId, watchToken, guardianToken } = await withWatch();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, watchToken, outOfRange({ source: "simulated" }));
    expect(t.push.calls[0]!.message.title).toBe("[Simulation] Halina's watch: heart rate outside the set range");
    const [alert] = (await t.call("GET", "/v1/alerts", guardianToken)).body.items;
    expect(alert.event.source).toBe("simulated");
  });

  it("is idempotent on the event id", async () => {
    const { seniorId, watchToken } = await withWatch();
    const body = outOfRange();
    const first = await t.call("POST", `/v1/seniors/${seniorId}/events`, watchToken, body);
    const again = await t.call("POST", `/v1/seniors/${seniorId}/events`, watchToken, body);
    expect([first.status, again.status]).toEqual([201, 200]);
    expect(again.body.alert.id).toBe(first.body.alert.id);
    expect(t.push.calls).toHaveLength(1);
  });

  it("does not page guardians again while a recent heart-rate alert is open", async () => {
    const { seniorId, watchToken } = await withWatch();
    const path = `/v1/seniors/${seniorId}/events`;
    await t.call("POST", path, watchToken, outOfRange());
    t.time.now = new Date("2026-10-03T12:30:00Z");
    const second = await t.call("POST", path, watchToken, outOfRange());
    expect(second.status).toBe(201);
    expect(second.body.alert).toBeNull();
    expect(t.push.calls).toHaveLength(1);

    // After an hour the episode counts as new, even if nothing resolved the first alert.
    t.time.now = new Date("2026-10-03T13:01:00Z");
    expect((await t.call("POST", path, watchToken, outOfRange())).body.alert.kind).toBe("heart_rate");
  });

  it("resolves the open alert when the reading is back in range, and re-arms", async () => {
    const { seniorId, watchToken, guardianToken } = await withWatch();
    const path = `/v1/seniors/${seniorId}/events`;
    const alertId = (await t.call("POST", path, watchToken, outOfRange())).body.alert.id;
    const back = inRange({ source: "simulated" });
    await t.call("POST", path, watchToken, back);
    await t.call("POST", path, watchToken, inRange());

    expect(t.push.calls.map((c) => c.message.title)).toEqual([
      "Halina's watch: heart rate outside the set range",
      "[Simulation] Halina's watch: heart rate back in the set range",
    ]);
    const alert = (await t.call("GET", `/v1/alerts/${alertId}`, guardianToken)).body;
    expect(alert.resolvedByEventId).toBe(back.id);

    t.time.now = new Date("2026-10-03T12:10:00Z");
    expect((await t.call("POST", path, watchToken, outOfRange())).body.alert.kind).toBe("heart_rate");
  });

  it("is not urgent: it cannot be cancelled and gets no reminders or acknowledgement push", async () => {
    const { seniorId, seniorToken, watchToken, guardianToken } = await withWatch();
    await t.call("PUT", "/v1/devices/me/push-token", seniorToken, { pushToken: "senior-push" });
    const path = `/v1/seniors/${seniorId}/events`;
    const event = outOfRange();
    const alertId = (await t.call("POST", path, watchToken, event)).body.alert.id;
    const cancel = { id: randomUUID(), type: "cancel", occurredAt: "2026-10-03T12:00:01Z", cancelsEventId: event.id };
    expect((await t.call("POST", path, watchToken, cancel)).status).toBe(404);

    for (let i = 1; i <= 2; i++) {
      t.time.now = new Date(Date.parse("2026-10-03T12:00:00Z") + i * 121_000);
      await runWatchdogOnce(t.deps);
    }
    await t.call("POST", `/v1/alerts/${alertId}/ack`, guardianToken);
    expect(t.push.calls).toHaveLength(1);
  });
});

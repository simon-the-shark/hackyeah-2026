import { randomUUID } from "node:crypto";
import { eq } from "drizzle-orm";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { alerts } from "../src/db/schema.js";
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

const event = (type: string, extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  type,
  occurredAt: "2026-10-03T11:59:58Z",
  ...extra,
});

describe("event provenance", () => {
  it("labels simulated events in the alert and the push title", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("area_exit", { source: "trace_replay" }));
    expect(t.push.calls[0]!.message.title).toMatch(/^\[Simulation\] /);
    const list = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body;
    expect(list.items[0].event.source).toBe("trace_replay");
  });

  it("defaults to device and keeps the location's measuring device", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call(
      "POST",
      `/v1/seniors/${seniorId}/events`,
      seniorToken,
      event("sos", { location: { lat: 50.06, lng: 19.93, measuredBy: "phone" } }),
    );
    expect(t.push.calls[0]!.message.title).not.toMatch(/Simulation/);
    const alert = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items[0];
    expect(alert.event.source).toBe("device");
    expect(alert.event.location.measuredBy).toBe("phone");
  });

  it("rejects an unknown source", async () => {
    const { seniorId, seniorToken } = await t.pair();
    const res = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("sos", { source: "guess" }));
    expect(res.status).toBe(400);
  });
});

describe("per-device heartbeats", () => {
  async function withWatch() {
    const ctx = await t.pair();
    const watch = (await t.call("POST", "/v1/devices", ctx.seniorToken, { kind: "watch" })).body;
    return { ...ctx, watchToken: watch.token as string };
  }

  it("keeps phone and watch status apart", async () => {
    const { seniorId, seniorToken, guardianToken, watchToken } = await withWatch();
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside", battery: 80 });
    t.time.now = new Date("2026-10-03T12:01:00Z");
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, watchToken, { monitoringState: "unavailable", battery: 30 });
    const res = (await t.call("GET", `/v1/seniors/${seniorId}/status`, guardianToken)).body;
    expect(res.devices.map((d: { deviceKind: string }) => d.deviceKind)).toEqual(["watch", "phone"]);
    expect(res.status.deviceKind).toBe("watch");
    expect(res.devices[1].battery).toBe(80);
  });

  it("raises monitoring_lost only when every device is stale", async () => {
    const { seniorId, seniorToken, watchToken } = await withWatch();
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside" });
    t.time.now = new Date("2026-10-03T12:10:00Z");
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, watchToken, { monitoringState: "inside" });

    t.time.now = new Date("2026-10-03T12:20:00Z"); // phone stale, watch fresh
    expect(await runWatchdogOnce(t.deps)).toBe(0);
    t.time.now = new Date("2026-10-03T12:30:00Z"); // both stale
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    expect(await runWatchdogOnce(t.deps)).toBe(0);
    const [alert] = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect((alert!.details as { devices: unknown[] }).devices).toHaveLength(2);

    // One live device re-arms monitoring for the whole senior.
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, watchToken, { monitoringState: "inside" });
    t.time.now = new Date("2026-10-03T12:50:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
  });
});

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

describe("alert resolution", () => {
  it("resolves an area_exit on re-entry with one push, keeping the alert", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const events = `/v1/seniors/${seniorId}/events`;
    await t.call("POST", events, seniorToken, event("area_exit"));
    const enter = event("area_enter");
    await t.call("POST", events, seniorToken, enter);
    await t.call("POST", events, seniorToken, event("area_enter")); // nothing left to resolve
    expect(t.push.calls.map((c) => c.message.title)).toEqual(["Halina left the safe area", "Halina is back in the safe area"]);
    const [alert] = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items;
    expect(alert.resolvedAt).not.toBeNull();
    expect(alert.resolvedByEventId).toBe(enter.id);
    expect(alert.acknowledgedAt).toBeNull();
    expect((await t.call("GET", "/v1/alerts?unresolved=true", guardianToken)).body.items).toHaveLength(0);
  });

  it("resolves monitoring_lost on the next heartbeat", async () => {
    const { seniorId, seniorToken } = await t.pair();
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside" });
    t.time.now = new Date("2026-10-03T12:20:00Z");
    await runWatchdogOnce(t.deps);
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside" });
    const [alert] = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(alert!.resolvedAt).not.toBeNull();
    expect(t.push.calls.at(-1)!.message.title).toBe("Monitoring restored for Halina");
  });

  it("resolves trip alerts for that trip on arrival", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const trip = (
      await t.call("POST", `/v1/seniors/${seniorId}/trips`, guardianToken, {
        label: "Doctor",
        destLat: 50.07,
        destLng: 19.94,
        radiusM: 100,
        windowStart: "2026-10-03T12:00:00Z",
        windowEnd: "2026-10-03T13:00:00Z",
      })
    ).body;
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("trip_deviation", { tripId: trip.id }));
    t.time.now = new Date("2026-10-03T13:30:00Z");
    await runWatchdogOnce(t.deps);
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("trip_arrived", { tripId: trip.id }));
    const rows = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(rows.map((r) => [r.kind, r.resolvedAt !== null]).sort()).toEqual([
      ["trip_deviation", true],
      ["trip_not_completed", true],
    ]);
  });

  it("resolves a dose_missed alert when the dose is recorded late", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    t.time.now = new Date("2026-10-03T05:00:00Z");
    const med = (
      await t.call("POST", `/v1/seniors/${seniorId}/medications`, guardianToken, {
        name: "Demo",
        times: ["08:00"],
        timezone: "Europe/Warsaw",
      })
    ).body;
    t.time.now = new Date("2026-10-03T07:30:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    const dose = { occurrenceId: `${med.id}@2026-10-03T08:00`, medicationId: med.id, recordedAt: "2026-10-03T07:31:00Z" };
    await t.call("POST", `/v1/seniors/${seniorId}/doses`, seniorToken, { ...dose, status: "taken" });
    const [alert] = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(alert!.resolvedAt).not.toBeNull();
    expect(t.push.calls.at(-1)!.message.title).toBe("Halina took the missed dose of Demo");
  });
});

describe("delivery feedback", () => {
  it("tells the senior once when a guardian acknowledges their SOS", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call("PUT", "/v1/devices/me/push-token", seniorToken, { pushToken: "senior-push" });
    const alertId = (await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("sos"))).body.alert.id;
    await t.call("POST", `/v1/alerts/${alertId}/ack`, guardianToken);
    await t.call("POST", `/v1/alerts/${alertId}/ack`, guardianToken);
    const toSenior = t.push.calls.filter((c) => c.tokens.includes("senior-push"));
    expect(toSenior.map((c) => c.message.title)).toEqual(["Marek has seen your SOS"]);
  });

  it("reminds guardians of an unacknowledged SOS, capped, and stops on ack", async () => {
    const { seniorId, seniorToken } = await t.pair();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("sos"));
    for (let i = 1; i <= 5; i++) {
      t.time.now = new Date(Date.parse("2026-10-03T12:00:00Z") + i * 121_000);
      await runWatchdogOnce(t.deps);
    }
    expect(t.push.calls).toHaveLength(4); // first push + 3 reminders
    expect(t.push.calls[1]!.message.title).toBe("Reminder: SOS from Halina (not yet acknowledged)");

    const other = await t.pair();
    await t.call("POST", `/v1/seniors/${other.seniorId}/events`, other.seniorToken, event("sos"));
    const [a] = (await t.call("GET", "/v1/alerts", other.guardianToken)).body.items;
    await t.call("POST", `/v1/alerts/${a.id}/ack`, other.guardianToken);
    const before = t.push.calls.length;
    t.time.now = new Date(t.time.now.getTime() + 600_000);
    await runWatchdogOnce(t.deps);
    expect(t.push.calls).toHaveLength(before);
  });

  it("retries a failed non-SOS push once", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    t.push.result = "failed";
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("area_exit"));
    t.push.result = "sent";
    t.time.now = new Date("2026-10-03T12:00:30Z");
    await runWatchdogOnce(t.deps); // too early
    t.time.now = new Date("2026-10-03T12:02:00Z");
    await runWatchdogOnce(t.deps);
    t.time.now = new Date("2026-10-03T12:10:00Z");
    await runWatchdogOnce(t.deps);
    expect(t.push.calls).toHaveLength(2);
    const [alert] = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items;
    expect(alert.pushStatus).toBe("sent");
  });
});

describe("fall detection", () => {
  it("requires an explicit source and raises a fall alert", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const path = `/v1/seniors/${seniorId}/events`;
    expect((await t.call("POST", path, seniorToken, event("fall_detected"))).status).toBe(400);
    const res = await t.call("POST", path, seniorToken, event("fall_detected", { source: "simulated" }));
    expect(res.status).toBe(201);
    expect(res.body.alert.kind).toBe("fall");
    expect(t.push.calls[0]!.message.title).toBe("[Simulation] Possible fall detected for Halina");
    const [alert] = (await t.call("GET", "/v1/alerts", guardianToken)).body.items;
    expect(alert.event.source).toBe("simulated");
  });

  it("cancels a fall with the generic cancel event, but not a non-urgent alert", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const path = `/v1/seniors/${seniorId}/events`;
    const fall = event("fall_detected", { source: "device" });
    await t.call("POST", path, seniorToken, fall);
    const exit = event("area_exit");
    await t.call("POST", path, seniorToken, exit);
    expect((await t.call("POST", path, seniorToken, event("cancel", { cancelsEventId: exit.id }))).status).toBe(404);
    expect((await t.call("POST", path, seniorToken, event("cancel", { cancelsEventId: fall.id }))).status).toBe(201);
    const items = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items;
    const byKind = Object.fromEntries(items.map((a: { kind: string; cancelledAt: string | null }) => [a.kind, a.cancelledAt]));
    expect(byKind.fall).not.toBeNull();
    expect(byKind.area_exit).toBeNull();
  });
});

describe("trip routes", () => {
  const trip = {
    label: "Doctor",
    destLat: 50.07,
    destLng: 19.94,
    radiusM: 100,
    windowStart: "2026-10-03T12:00:00Z",
    windowEnd: "2026-10-03T13:00:00Z",
  };
  const route = [
    { lat: 50.06, lng: 19.93 },
    { lat: 50.065, lng: 19.935 },
    { lat: 50.07, lng: 19.94 },
  ];

  it("keeps the route when an update omits it, and clears it only on an explicit null", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const base = `/v1/seniors/${seniorId}/trips`;
    const created = await t.call("POST", base, guardianToken, { ...trip, route, corridorM: 150 });
    expect(created.status).toBe(201);
    expect((await t.call("GET", base, seniorToken)).body.items[0].route).toHaveLength(3);
    const path = `${base}/${created.body.id}`;
    // Editing only the window must not drop the route.
    const moved = await t.call("PUT", path, guardianToken, { ...trip, windowEnd: "2026-10-03T14:00:00Z", version: 1 });
    expect(moved.body.route).toHaveLength(3);
    expect(moved.body.corridorM).toBe(150);
    const cleared = await t.call("PUT", path, guardianToken, { ...trip, route: null, version: 2 });
    expect(cleared.body.route).toBeNull();
    expect(cleared.body.corridorM).toBeNull();
  });

  it("rejects a corridor on a trip with no stored route", async () => {
    const { seniorId, guardianToken } = await t.pair();
    const base = `/v1/seniors/${seniorId}/trips`;
    const created = (await t.call("POST", base, guardianToken, trip)).body;
    const res = await t.call("PUT", `${base}/${created.id}`, guardianToken, { ...trip, corridorM: 100, version: 1 });
    expect(res.status).toBe(400);
    expect((await t.call("PUT", `${base}/${created.id}`, guardianToken, { ...trip, version: 2 })).status).toBe(409);
  });

  it("rejects a corridor without a route and a one-point route", async () => {
    const { seniorId, guardianToken } = await t.pair();
    const base = `/v1/seniors/${seniorId}/trips`;
    expect((await t.call("POST", base, guardianToken, { ...trip, corridorM: 150 })).status).toBe(400);
    expect((await t.call("POST", base, guardianToken, { ...trip, route: [route[0]] })).status).toBe(400);
    expect((await t.call("POST", base, guardianToken, { ...trip, route: null, corridorM: 150 })).status).toBe(400);
  });
});

describe("low battery", () => {
  it("alerts once per discharge and resolves after recovery", async () => {
    const { seniorId, seniorToken } = await t.pair();
    const beat = (battery: number) =>
      t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside", battery });
    await beat(40);
    await beat(15);
    await beat(9);
    await beat(20); // above threshold, not yet recovered
    await beat(12);
    let rows = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(rows.map((r) => r.kind)).toEqual(["low_battery"]);
    expect(rows[0]!.details).toMatchObject({ deviceKind: "phone", battery: 15 });

    await beat(25); // recovered: resolved, and re-armed
    t.time.now = new Date("2026-10-03T12:30:00Z");
    await beat(10);
    rows = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(rows.map((r) => [r.kind, r.resolvedAt !== null])).toEqual([
      ["low_battery", true],
      ["low_battery", false],
    ]);
    expect(t.push.calls.map((c) => c.message.title)).toEqual([
      "Low battery on Halina's device",
      "Halina's device is charged again",
      "Low battery on Halina's device",
    ]);
  });
});

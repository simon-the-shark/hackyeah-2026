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

const sosBody = (id = randomUUID()) => ({ id, type: "sos", occurredAt: "2026-10-03T11:59:58Z" });

describe("pairing and access", () => {
  it("rejects missing and invalid tokens", async () => {
    expect((await t.call("GET", "/v1/me")).status).toBe(401);
    expect((await t.call("GET", "/v1/me", "nope")).status).toBe(401);
  });

  it("pairs a guardian and reports links in /me", async () => {
    const { seniorId, guardianToken } = await t.pair();
    const me = (await t.call("GET", "/v1/me", guardianToken)).body;
    expect(me.role).toBe("guardian");
    expect(me.linked.seniors.map((s: { id: string }) => s.id)).toEqual([seniorId]);
  });

  it("rejects a used or unknown pairing code with 410", async () => {
    const senior = (await t.call("POST", "/v1/seniors", undefined, { displayName: "Halina" })).body;
    const claim = { code: senior.pairingCode, displayName: "A" };
    expect((await t.call("POST", "/v1/pairing/claim", undefined, claim)).status).toBe(201);
    expect((await t.call("POST", "/v1/pairing/claim", undefined, claim)).status).toBe(410);
    expect((await t.call("POST", "/v1/pairing/claim", undefined, { code: "000000", displayName: "A" })).status).toBe(410);
  });

  it("rejects an expired pairing code with 410", async () => {
    const senior = (await t.call("POST", "/v1/seniors", undefined, { displayName: "Halina" })).body;
    t.time.now = new Date("2026-10-03T12:11:00Z");
    const res = await t.call("POST", "/v1/pairing/claim", undefined, { code: senior.pairingCode, displayName: "A" });
    expect(res.status).toBe(410);
    expect(res.body.error.code).toBe("pairing_expired");
  });

  it("forbids an unlinked guardian from reading another senior's data", async () => {
    const a = await t.pair();
    const b = await t.pair();
    const res = await t.call("GET", `/v1/seniors/${a.seniorId}/alerts`, b.guardianToken);
    expect(res.status).toBe(403);
  });

  it("returns uniform validation errors", async () => {
    const res = await t.call("POST", "/v1/seniors", undefined, { displayName: "" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation_error");
  });
});

describe("events and alerts", () => {
  it("is idempotent: same event id gives one alert and one push", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const body = sosBody();
    const first = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, body);
    const second = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, body);
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    expect(second.body.alert.id).toBe(first.body.alert.id);
    expect(t.push.calls).toHaveLength(1);
    const list = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body;
    expect(list.items).toHaveLength(1);
    expect(list.items[0].kind).toBe("sos");
  });

  it("stores the alert even when the push fails", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    t.push.result = "failed";
    const res = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, sosBody());
    expect(res.status).toBe(201);
    expect(res.body.alert.pushStatus).toBe("failed");
    const list = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body;
    expect(list.items).toHaveLength(1);
  });

  it("keeps the original alert on sos_cancel and marks it cancelled", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const sos = sosBody();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, sos);
    const cancel = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, {
      id: randomUUID(),
      type: "sos_cancel",
      cancelsEventId: sos.id,
      occurredAt: "2026-10-03T12:00:05Z",
    });
    expect(cancel.status).toBe(201);
    const list = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body;
    expect(list.items).toHaveLength(1);
    expect(list.items[0].cancelledAt).not.toBeNull();
  });

  it("only guardians can acknowledge, and acknowledgement is idempotent", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const alertId = (await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, sosBody())).body.alert.id;
    expect((await t.call("POST", `/v1/alerts/${alertId}/ack`, seniorToken)).status).toBe(403);
    const first = (await t.call("POST", `/v1/alerts/${alertId}/ack`, guardianToken)).body;
    t.time.now = new Date("2026-10-03T12:05:00Z");
    const second = (await t.call("POST", `/v1/alerts/${alertId}/ack`, guardianToken)).body;
    expect(first.acknowledgedAt).not.toBeNull();
    expect(second.acknowledgedAt).toBe(first.acknowledgedAt);
  });

  it("refreshes alerts incrementally with ?since", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, sosBody());
    t.time.now = new Date("2026-10-03T12:10:00Z");
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, {
      id: randomUUID(),
      type: "area_exit",
      occurredAt: "2026-10-03T12:09:59Z",
    });
    const res = await t.call("GET", `/v1/seniors/${seniorId}/alerts?since=2026-10-03T12:05:00Z`, guardianToken);
    expect(res.body.items.map((a: { kind: string }) => a.kind)).toEqual(["area_exit"]);
  });
});

describe("configuration versioning", () => {
  it("creates and updates the safe area, returning 409 on a stale version", async () => {
    const { seniorId, guardianToken, seniorToken } = await t.pair();
    const path = `/v1/seniors/${seniorId}/safe-area`;
    const created = await t.call("PUT", path, guardianToken, { lat: 50.06, lng: 19.93, radiusM: 150 });
    expect(created.status).toBe(201);
    expect(created.body.version).toBe(1);
    const updated = await t.call("PUT", path, guardianToken, { lat: 50.06, lng: 19.93, radiusM: 200, version: 1 });
    expect(updated.body.version).toBe(2);
    const stale = await t.call("PUT", path, guardianToken, { lat: 50.06, lng: 19.93, radiusM: 300, version: 1 });
    expect(stale.status).toBe(409);
    expect(stale.body.error.details.current.radiusM).toBe(200);
    expect((await t.call("GET", path, seniorToken)).body.radiusM).toBe(200);
    expect((await t.call("PUT", path, seniorToken, { lat: 1, lng: 1, radiusM: 100, version: 2 })).status).toBe(403);
  });

  it("rejects invalid coordinates and unusable radius", async () => {
    const { seniorId, guardianToken } = await t.pair();
    const path = `/v1/seniors/${seniorId}/safe-area`;
    expect((await t.call("PUT", path, guardianToken, { lat: 95, lng: 0, radiusM: 100 })).status).toBe(400);
    expect((await t.call("PUT", path, guardianToken, { lat: 50, lng: 19, radiusM: 1 })).status).toBe(400);
  });

  it("manages contacts with optimistic locking", async () => {
    const { seniorId, guardianToken, seniorToken } = await t.pair();
    const base = `/v1/seniors/${seniorId}/contacts`;
    const c = (await t.call("POST", base, guardianToken, { name: "Marek", phone: "+48 600 000 001" })).body;
    const ok = await t.call("PUT", `${base}/${c.id}`, guardianToken, { name: "Marek S.", phone: "+48 600 000 001", version: 1 });
    expect(ok.status).toBe(200);
    const stale = await t.call("PUT", `${base}/${c.id}`, guardianToken, { name: "X", phone: "123", version: 1 });
    expect(stale.status).toBe(409);
    expect((await t.call("GET", base, seniorToken)).body.items).toHaveLength(1);
  });
});

describe("medication and doses", () => {
  async function withMedication() {
    const ctx = await t.pair();
    const med = (
      await t.call("POST", `/v1/seniors/${ctx.seniorId}/medications`, ctx.guardianToken, {
        name: "Demo",
        times: ["08:00"],
        timezone: "Europe/Warsaw",
      })
    ).body;
    return { ...ctx, medId: med.id as string };
  }

  it("rejects an unknown time zone", async () => {
    const { seniorId, guardianToken } = await t.pair();
    const res = await t.call("POST", `/v1/seniors/${seniorId}/medications`, guardianToken, {
      name: "Demo",
      times: ["08:00"],
      timezone: "Mars/Base",
    });
    expect(res.status).toBe(400);
  });

  it("deduplicates dose occurrences, but lets a snooze become taken", async () => {
    const { seniorId, seniorToken, medId } = await withMedication();
    const path = `/v1/seniors/${seniorId}/doses`;
    const dose = (status: string) => ({
      occurrenceId: `${medId}@2026-10-03T08:00`,
      medicationId: medId,
      status,
      recordedAt: "2026-10-03T08:01:00Z",
    });
    expect((await t.call("POST", path, seniorToken, dose("snoozed"))).body.status).toBe("snoozed");
    expect((await t.call("POST", path, seniorToken, dose("taken"))).body.status).toBe("taken");
    const dup = await t.call("POST", path, seniorToken, dose("skipped"));
    expect(dup.status).toBe(200);
    expect(dup.body.status).toBe("taken");
    expect((await t.call("GET", path, seniorToken)).body.items).toHaveLength(1);
  });

  it("returns 404 for an unknown barcode", async () => {
    const { seniorToken } = await t.pair();
    expect((await t.call("GET", "/v1/catalog/0000", seniorToken)).status).toBe(404);
  });
});

describe("watchdog", () => {
  it("raises exactly one monitoring_lost alert per stale gap and re-arms after a heartbeat", async () => {
    const { seniorId, seniorToken } = await t.pair();
    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside" });
    expect(await runWatchdogOnce(t.deps)).toBe(0);

    t.time.now = new Date("2026-10-03T12:20:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    expect(await runWatchdogOnce(t.deps)).toBe(0);
    expect(t.push.calls).toHaveLength(1);

    await t.call("PUT", `/v1/seniors/${seniorId}/status`, seniorToken, { monitoringState: "inside" });
    t.time.now = new Date("2026-10-03T12:40:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    const rows = await t.db.select().from(alerts).where(eq(alerts.seniorId, seniorId));
    expect(rows.map((r) => r.kind)).toEqual(["monitoring_lost", "monitoring_lost"]);
  });

  it("raises trip_not_completed once when a window ends without arrival", async () => {
    const { seniorId, guardianToken } = await t.pair();
    await t.call("POST", `/v1/seniors/${seniorId}/trips`, guardianToken, {
      label: "Doctor",
      destLat: 50.07,
      destLng: 19.94,
      radiusM: 100,
      windowStart: "2026-10-03T12:00:00Z",
      windowEnd: "2026-10-03T13:00:00Z",
    });
    t.time.now = new Date("2026-10-03T13:30:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    expect(await runWatchdogOnce(t.deps)).toBe(0);
  });
});

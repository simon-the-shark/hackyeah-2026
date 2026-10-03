import { randomUUID } from "node:crypto";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { medicationCatalog } from "../src/db/schema.js";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.time.now = new Date("2026-10-03T05:00:00Z");
});

describe("guardian overview", () => {
  it("summarises status, alerts, doses, reports and config in one call", async () => {
    const ctx = await t.pair();
    const base = `/v1/seniors/${ctx.seniorId}`;
    await t.call("POST", `${base}/medications`, ctx.guardianToken, { name: "Demo", times: ["08:00", "20:00"], timezone: "Europe/Warsaw" });
    await t.call("PUT", `${base}/safe-area`, ctx.guardianToken, { lat: 50.06, lng: 19.93, radiusM: 150 });
    t.time.now = new Date("2026-10-03T07:30:00Z"); // 08:00 local dose missed
    await t.call("PUT", `${base}/status`, ctx.seniorToken, { monitoringState: "inside", battery: 70 });
    await t.call("POST", `${base}/events`, ctx.seniorToken, { id: randomUUID(), type: "area_exit", occurredAt: "2026-10-03T07:29:00Z" });
    await t.call("POST", `${base}/reports`, ctx.seniorToken, { structured: { mood: 4 }, source: "structured" });

    const res = await t.call("GET", `${base}/overview`, ctx.guardianToken);
    expect(res.status).toBe(200);
    const o = res.body;
    expect(o.senior.displayName).toBe("Halina");
    expect(o.status.monitoringState).toBe("inside");
    expect(o.devices).toHaveLength(1);
    expect(o.alerts).toEqual({ unacknowledged: 1, unresolved: 1 });
    expect(o.nextDoses.map((d: { localTime: string }) => d.localTime)).toEqual(["20:00", "08:00"]);
    expect(o.missedDosesLast24h).toBe(1);
    expect(o.latestReportAt).not.toBeNull();
    expect(o.safeAreaVersion).toBe(1);
    expect(o.plannedOrActiveTrips).toBe(0);
  });

  it("is forbidden for unlinked guardians", async () => {
    const a = await t.pair();
    const b = await t.pair();
    expect((await t.call("GET", `/v1/seniors/${a.seniorId}/overview`, b.guardianToken)).status).toBe(403);
  });
});

describe("emergency contacts", () => {
  it("stores the emergency flag", async () => {
    const ctx = await t.pair();
    const c = await t.call("POST", `/v1/seniors/${ctx.seniorId}/contacts`, ctx.guardianToken, {
      name: "Marek",
      phone: "+48 600 000 001",
      isEmergency: true,
    });
    expect(c.body.isEmergency).toBe(true);
  });
});

describe("config sync", () => {
  it("returns the whole config with an ETag and 304 when unchanged", async () => {
    const ctx = await t.pair();
    const base = `/v1/seniors/${ctx.seniorId}`;
    await t.call("POST", `${base}/medications`, ctx.guardianToken, { name: "Demo", times: ["08:00"], timezone: "Europe/Warsaw" });
    const first = await t.app.request(`${base}/config`, { headers: { Authorization: `Bearer ${ctx.seniorToken}` } });
    expect(first.status).toBe(200);
    const etag = first.headers.get("etag")!;
    const body = await first.json();
    expect(body.medications).toHaveLength(1);
    expect(etag).toBe(`"${body.configVersion}"`);

    const again = await t.app.request(`${base}/config`, {
      headers: { Authorization: `Bearer ${ctx.seniorToken}`, "If-None-Match": etag },
    });
    expect(again.status).toBe(304);

    await t.call("POST", `${base}/contacts`, ctx.guardianToken, { name: "Marek", phone: "+48 600 000 001" });
    const changed = await t.app.request(`${base}/config`, {
      headers: { Authorization: `Bearer ${ctx.seniorToken}`, "If-None-Match": etag },
    });
    expect(changed.status).toBe(200);
  });
});

describe("report sharing controls", () => {
  it("lets the senior list and withdraw their shared reports", async () => {
    const ctx = await t.pair();
    const base = `/v1/seniors/${ctx.seniorId}/reports`;
    const r1 = (await t.call("POST", base, ctx.seniorToken, { structured: { mood: 3 }, source: "structured" })).body;
    t.time.now = new Date("2026-10-03T06:00:00Z");
    await t.call("POST", base, ctx.seniorToken, { structured: { mood: 4 }, summary: "Good day", source: "simulated" });

    expect((await t.call("GET", "/v1/me/reports", ctx.seniorToken)).body.items).toHaveLength(2);
    expect((await t.call("GET", "/v1/me/reports", ctx.guardianToken)).status).toBe(403);
    expect((await t.call("GET", `${base}?before=2026-10-03T05:30:00Z`, ctx.guardianToken)).body.items).toHaveLength(1);

    expect((await t.call("DELETE", `${base}/${r1.id}`, ctx.guardianToken)).status).toBe(403);
    expect((await t.call("DELETE", `${base}/${r1.id}`, ctx.seniorToken)).status).toBe(204);
    expect((await t.call("DELETE", `${base}/${r1.id}`, ctx.seniorToken)).status).toBe(404);
    expect((await t.call("GET", base, ctx.guardianToken)).body.items).toHaveLength(1);
  });
});

describe("catalog search", () => {
  it("finds synthetic catalog entries by name and treats wildcards literally", async () => {
    const ctx = await t.pair();
    await t.db.insert(medicationCatalog).values([
      { barcode: "1", name: "Demo Blood Pressure 5 mg (synthetic)" },
      { barcode: "2", name: "Demo Vitamin D (synthetic)" },
    ]);
    const hits = (await t.call("GET", "/v1/catalog?q=blood", ctx.seniorToken)).body.items;
    expect(hits.map((h: { barcode: string }) => h.barcode)).toEqual(["1"]);
    expect((await t.call("GET", "/v1/catalog?q=%25%25", ctx.seniorToken)).body.items).toHaveLength(0);
    expect((await t.call("GET", "/v1/catalog?q=a", ctx.seniorToken)).status).toBe(400);
  });
});

import { eq } from "drizzle-orm";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { trips } from "../src/db/schema.js";
import { isoWeekday, materializeRoutines } from "../src/services/routines.js";
import { runWatchdogOnce } from "../src/services/watchdog.js";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  // Saturday 2026-10-03, 08:00 in Warsaw.
  t.time.now = new Date("2026-10-03T06:00:00Z");
});

// Weekends 10:00-11:00 Warsaw (08:00-09:00Z in October).
const routine = {
  label: "Saturday market",
  destLat: 50.06,
  destLng: 19.94,
  radiusM: 120,
  weekdays: [6, 7],
  startTime: "10:00",
  endTime: "11:00",
  timezone: "Europe/Warsaw",
};

describe("isoWeekday", () => {
  it("numbers Monday 1 to Sunday 7", () => {
    expect(isoWeekday("2026-10-03")).toBe(6);
    expect(isoWeekday("2026-10-04")).toBe(7);
    expect(isoWeekday("2026-10-05")).toBe(1);
  });
});

describe("routine suggestions", () => {
  it("a guardian accepts a device suggestion into a routine, exactly once", async () => {
    const ctx = await t.pair();
    const base = `/v1/seniors/${ctx.seniorId}/routine-suggestions`;
    expect((await t.call("POST", base, ctx.guardianToken, routine)).status).toBe(403);
    const s = (await t.call("POST", base, ctx.seniorToken, { ...routine, source: "simulated" })).body;
    expect(s.status).toBe("pending");
    expect((await t.call("GET", `${base}?status=pending`, ctx.guardianToken)).body.items).toHaveLength(1);

    expect((await t.call("POST", `${base}/${s.id}/accept`, ctx.seniorToken)).status).toBe(403);
    const accepted = await t.call("POST", `${base}/${s.id}/accept`, ctx.guardianToken);
    expect(accepted.status).toBe(201);
    expect(accepted.body.routine.suggestionId).toBe(s.id);
    const again = await t.call("POST", `${base}/${s.id}/reject`, ctx.guardianToken);
    expect(again.status).toBe(409);
    expect(again.body.error.details.current.status).toBe("accepted");
    expect((await t.call("GET", `/v1/seniors/${ctx.seniorId}/routines`, ctx.seniorToken)).body.items).toHaveLength(1);
  });

  it("rejects a window that ends before it starts", async () => {
    const ctx = await t.pair();
    const res = await t.call("POST", `/v1/seniors/${ctx.seniorId}/routine-suggestions`, ctx.seniorToken, {
      ...routine,
      startTime: "11:00",
      endTime: "10:00",
    });
    expect(res.status).toBe(400);
  });
});

describe("routine materialization", () => {
  async function withRoutine(extra: Record<string, unknown> = {}) {
    const ctx = await t.pair();
    const r = (await t.call("POST", `/v1/seniors/${ctx.seniorId}/routines`, ctx.guardianToken, { ...routine, ...extra })).body;
    return { ...ctx, routineId: r.id as string };
  }
  const tripsOf = (seniorId: string) => t.db.select().from(trips).where(eq(trips.seniorId, seniorId));

  it("creates exactly one trip per matching upcoming day", async () => {
    const { seniorId } = await withRoutine();
    expect(await materializeRoutines(t.deps)).toBe(2); // today and Sunday
    expect(await materializeRoutines(t.deps)).toBe(0);
    const rows = (await tripsOf(seniorId)).sort((a, b) => a.windowStart.getTime() - b.windowStart.getTime());
    expect(rows.map((r) => [r.localDate, r.windowStart.toISOString(), r.windowEnd.toISOString()])).toEqual([
      ["2026-10-03", "2026-10-03T08:00:00.000Z", "2026-10-03T09:00:00.000Z"],
      ["2026-10-04", "2026-10-04T08:00:00.000Z", "2026-10-04T09:00:00.000Z"],
    ]);
  });

  it("never creates a trip whose window has already started", async () => {
    t.time.now = new Date("2026-10-03T08:30:00Z");
    const { seniorId } = await withRoutine();
    await materializeRoutines(t.deps);
    expect((await tripsOf(seniorId)).map((r) => r.localDate)).toEqual(["2026-10-04"]);
  });

  it("feeds the normal trip lifecycle: a missed routine trip alerts once", async () => {
    const { seniorId } = await withRoutine({ weekdays: [6] });
    await runWatchdogOnce(t.deps);
    t.time.now = new Date("2026-10-03T09:30:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
    const [trip] = await tripsOf(seniorId);
    expect(trip!.status).toBe("missed");
  });

  it("rebuilds upcoming trips after an edit and drops them on delete", async () => {
    const { seniorId, guardianToken, routineId } = await withRoutine();
    await materializeRoutines(t.deps);
    const path = `/v1/seniors/${seniorId}/routines/${routineId}`;
    await t.call("PUT", path, guardianToken, { ...routine, startTime: "12:00", endTime: "13:00", version: 1 });
    expect(await tripsOf(seniorId)).toHaveLength(0);
    await materializeRoutines(t.deps);
    expect((await tripsOf(seniorId)).every((r) => r.windowStart.getUTCHours() === 10)).toBe(true);
    expect((await t.call("DELETE", path, guardianToken)).status).toBe(204);
    expect(await tripsOf(seniorId)).toHaveLength(0);
  });

  it("skips inactive routines", async () => {
    const { seniorId } = await withRoutine({ active: false });
    await materializeRoutines(t.deps);
    expect(await tripsOf(seniorId)).toHaveLength(0);
  });
});

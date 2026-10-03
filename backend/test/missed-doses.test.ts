import { randomUUID } from "node:crypto";
import { eq } from "drizzle-orm";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { alerts, medications } from "../src/db/schema.js";
import { checkMissedDoses, zonedTimeToUtc } from "../src/services/doses.js";
import { runWatchdogOnce } from "../src/services/watchdog.js";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.push.result = "sent";
});

const at = (iso: string) => {
  t.time.now = new Date(iso);
};

// 08:00 Europe/Warsaw on 2026-10-03 is 06:00Z (CEST, UTC+2). Grace is 60 min.
async function withMedication(createdAt = "2026-10-03T05:00:00Z") {
  at(createdAt);
  const ctx = await t.pair();
  const med = (
    await t.call("POST", `/v1/seniors/${ctx.seniorId}/medications`, ctx.guardianToken, {
      name: "Demo BP",
      times: ["08:00"],
      timezone: "Europe/Warsaw",
    })
  ).body;
  const occurrence = `${med.id}@2026-10-03T08:00`;
  const dose = (status: string, recordedAt: string) =>
    t.call("POST", `/v1/seniors/${ctx.seniorId}/doses`, ctx.seniorToken, {
      occurrenceId: occurrence,
      medicationId: med.id,
      status,
      recordedAt,
    });
  return { ...ctx, medId: med.id as string, occurrence, dose };
}

describe("zonedTimeToUtc", () => {
  it("converts local wall-clock time across a DST change", () => {
    expect(zonedTimeToUtc("2026-10-24", "08:00", "Europe/Warsaw").toISOString()).toBe("2026-10-24T06:00:00.000Z");
    expect(zonedTimeToUtc("2026-10-25", "08:00", "Europe/Warsaw").toISOString()).toBe("2026-10-25T07:00:00.000Z");
    expect(zonedTimeToUtc("2026-07-01", "20:30", "America/New_York").toISOString()).toBe("2026-07-02T00:30:00.000Z");
    expect(zonedTimeToUtc("2026-01-15", "09:00", "UTC").toISOString()).toBe("2026-01-15T09:00:00.000Z");
  });
});

describe("server-side missed doses", () => {
  it("raises one dose_missed alert with details after the grace period, and pushes once", async () => {
    const { seniorId, guardianToken, medId, occurrence } = await withMedication();
    at("2026-10-03T06:59:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(0);
    at("2026-10-03T07:00:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
    expect(await checkMissedDoses(t.deps)).toBe(0);
    expect(t.push.calls).toHaveLength(1);

    const [alert] = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items;
    expect(alert.kind).toBe("dose_missed");
    expect(alert.event).toBeNull();
    expect(alert.details).toMatchObject({
      medicationId: medId,
      medicationName: "Demo BP",
      occurrenceId: occurrence,
      scheduledFor: "2026-10-03T06:00:00.000Z",
      localTime: "08:00",
      timezone: "Europe/Warsaw",
    });
  });

  it("does not alert when the dose was taken or skipped", async () => {
    for (const status of ["taken", "skipped"]) {
      await t.reset();
      const { dose } = await withMedication();
      at("2026-10-03T06:10:00Z");
      expect((await dose(status, "2026-10-03T06:10:00Z")).status).toBe(201);
      at("2026-10-03T09:00:00Z");
      expect(await checkMissedDoses(t.deps)).toBe(0);
    }
  });

  it("restarts the grace period from the latest snooze", async () => {
    const { dose } = await withMedication();
    await dose("snoozed", "2026-10-03T06:50:00Z");
    at("2026-10-03T07:10:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(0);
    at("2026-10-03T07:50:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
  });

  it("ignores doses scheduled before the medication was created or edited", async () => {
    await withMedication("2026-10-03T06:30:00Z");
    at("2026-10-03T08:00:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(0);
  });

  it("treats a schedule edit as a fresh start", async () => {
    const { seniorId, guardianToken, medId } = await withMedication();
    at("2026-10-03T06:30:00Z");
    const edit = await t.call("PUT", `/v1/seniors/${seniorId}/medications/${medId}`, guardianToken, {
      name: "Demo BP",
      times: ["08:00", "20:00"],
      timezone: "Europe/Warsaw",
      version: 1,
    });
    expect(edit.status).toBe(200);
    at("2026-10-03T08:00:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(0);
  });

  it("keeps detecting missed doses after a name-only edit", async () => {
    const { seniorId, guardianToken, medId } = await withMedication();
    at("2026-10-03T06:30:00Z");
    const edit = await t.call("PUT", `/v1/seniors/${seniorId}/medications/${medId}`, guardianToken, {
      name: "Demo Blood Pressure",
      instructions: "With water",
      times: ["08:00"],
      timezone: "Europe/Warsaw",
      version: 1,
    });
    expect(edit.status).toBe(200);
    at("2026-10-03T07:00:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
    const [row] = await t.db.select().from(alerts);
    expect(row?.details).toMatchObject({ medicationName: "Demo Blood Pressure" });
  });

  it("only looks back 24 hours, so downtime does not flood old alerts", async () => {
    const { medId } = await withMedication();
    // Pretend the medication has existed since 1 October.
    await t.db.update(medications).set({ scheduleUpdatedAt: new Date("2026-10-01T00:00:00Z") }).where(eq(medications.id, medId));
    at("2026-10-04T12:00:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
    const [row] = await t.db.select().from(alerts);
    expect(row?.dedupKey).toBe(`dose_missed:${medId}@2026-10-04T08:00`);
  });

  it("runs as part of the watchdog pass", async () => {
    await withMedication();
    at("2026-10-03T07:30:00Z");
    expect(await runWatchdogOnce(t.deps)).toBe(1);
  });

  it("no longer turns a device-reported dose_missed event into an alert", async () => {
    const { seniorId, seniorToken } = await withMedication();
    const res = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, {
      id: randomUUID(),
      type: "dose_missed",
      occurredAt: "2026-10-03T07:00:00Z",
    });
    expect(res.status).toBe(201);
    expect(res.body.alert).toBeNull();
  });

  it("rejects occurrence ids that do not follow the canonical format", async () => {
    const { seniorId, seniorToken, medId } = await withMedication();
    const post = (occurrenceId: string) =>
      t.call("POST", `/v1/seniors/${seniorId}/doses`, seniorToken, {
        occurrenceId,
        medicationId: medId,
        status: "taken",
        recordedAt: "2026-10-03T06:05:00Z",
      });
    expect((await post(`${medId}@1`)).status).toBe(400);
    expect((await post(`${randomUUID()}@2026-10-03T08:00`)).status).toBe(400);
    expect((await post(`${medId}@2026-10-03T08:00`)).status).toBe(201);
  });
});

describe("dose schedule and per-medication rules", () => {
  async function med(ctx: Awaited<ReturnType<typeof t.pair>>, extra: Record<string, unknown> = {}) {
    return (
      await t.call("POST", `/v1/seniors/${ctx.seniorId}/medications`, ctx.guardianToken, {
        name: "Demo",
        times: ["08:00", "20:00"],
        timezone: "Europe/Warsaw",
        ...extra,
      })
    ).body;
  }
  const record = (ctx: { seniorId: string; seniorToken: string }, medId: string, time: string, status: string, recordedAt: string) =>
    t.call("POST", `/v1/seniors/${ctx.seniorId}/doses`, ctx.seniorToken, {
      occurrenceId: `${medId}@2026-10-03T${time}`,
      medicationId: medId,
      status,
      recordedAt,
    });

  it("lists occurrences with their status", async () => {
    at("2026-10-02T12:00:00Z");
    const ctx = await t.pair();
    const m = await med(ctx);
    const other = await med(ctx, { name: "Evening", times: ["21:00"] });
    at("2026-10-03T12:00:00Z");
    await record(ctx, m.id, "08:00", "taken", "2026-10-03T06:05:00Z");
    const res = await t.call(
      "GET",
      `/v1/seniors/${ctx.seniorId}/dose-schedule?from=2026-10-03T00:00:00Z&to=2026-10-04T00:00:00Z`,
      ctx.guardianToken,
    );
    expect(res.status).toBe(200);
    expect(res.body.items.map((i: { localTime: string; status: string; medicationId: string }) => [i.medicationId === other.id, i.localTime, i.status])).toEqual([
      [false, "08:00", "taken"],
      [false, "20:00", "pending"],
      [true, "21:00", "pending"],
    ]);
    at("2026-10-03T19:30:00Z");
    const later = (await t.call("GET", `/v1/seniors/${ctx.seniorId}/dose-schedule?from=2026-10-03T00:00:00Z&to=2026-10-04T00:00:00Z`, ctx.seniorToken)).body;
    expect(later.items[1].status).toBe("missed"); // 20:00 local = 18:00Z, grace 60 min
  });

  it("rejects a range over 7 days", async () => {
    const ctx = await t.pair();
    const res = await t.call("GET", `/v1/seniors/${ctx.seniorId}/dose-schedule?from=2026-10-01T00:00:00Z&to=2026-10-09T00:00:00Z`, ctx.guardianToken);
    expect(res.status).toBe(400);
  });

  it("uses a per-medication grace period", async () => {
    at("2026-10-03T05:00:00Z");
    const ctx = await t.pair();
    await med(ctx, { times: ["08:00"], missedGraceMinutes: 15 });
    at("2026-10-03T06:14:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(0);
    at("2026-10-03T06:15:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
  });

  it("stops snoozes past the cap from delaying a missed dose", async () => {
    at("2026-10-03T05:00:00Z");
    const ctx = await t.pair();
    const m = await med(ctx, { times: ["08:00"], maxSnoozes: 1 });
    at("2026-10-03T06:10:00Z");
    await record(ctx, m.id, "08:00", "snoozed", "2026-10-03T06:10:00Z"); // counted: grace until 07:10
    at("2026-10-03T07:00:00Z");
    const second = await record(ctx, m.id, "08:00", "snoozed", "2026-10-03T07:00:00Z"); // over the cap
    expect(second.body.snoozeCount).toBe(2);
    at("2026-10-03T07:10:00Z");
    expect(await checkMissedDoses(t.deps)).toBe(1);
  });
});

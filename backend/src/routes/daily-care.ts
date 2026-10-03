import { and, asc, desc, eq, gte, ilike, lt, lte, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { alerts, doseRecords, medicationCatalog, medications, reports } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { isoDate, seniorParam, uuid } from "../schemas.js";
import { resolveAlerts } from "../services/alerts.js";
import { doseSchedule, parseOccurrenceId } from "../services/doses.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const HOUR_MS = 60 * 60 * 1000;

const doseBody = z.object({
  occurrenceId: z.string().min(1).max(128),
  medicationId: uuid,
  status: z.enum(["taken", "skipped", "snoozed"]),
  scheduledFor: isoDate.optional(),
  recordedAt: isoDate,
});

const reportBody = z.object({
  period: z.string().max(64).optional(),
  structured: z.record(z.string(), z.unknown()),
  summary: z.string().max(5000).optional(),
  source: z.enum(["ai", "structured", "simulated"]),
});

export function dailyCareRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  app.post("/seniors/:seniorId/doses", validate("param", seniorParam), validate("json", doseBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");
    const [med] = await db
      .select({ id: medications.id, name: medications.name, maxSnoozes: medications.maxSnoozes })
      .from(medications)
      .where(and(eq(medications.id, body.medicationId), eq(medications.seniorId, seniorId)));
    if (!med) throw notFound("Medication");
    if (!parseOccurrenceId(body.occurrenceId, body.medicationId)) {
      throw new ApiError(400, "validation_error", "occurrenceId must be <medicationId>@<YYYY-MM-DD>T<HH:MM> in the medication's time zone");
    }

    const values = {
      occurrenceId: body.occurrenceId,
      medicationId: body.medicationId,
      medicationName: med.name,
      seniorId,
      status: body.status,
      scheduledFor: body.scheduledFor ?? null,
      recordedAt: body.recordedAt,
    };
    const snooze = body.status === "snoozed";
    // Past the medication's snooze cap a snooze is still recorded but no longer restarts the grace period.
    const recordedAt =
      snooze && med.maxSnoozes !== null
        ? sql`case when ${doseRecords.snoozeCount} >= ${med.maxSnoozes} then ${doseRecords.recordedAt} else ${values.recordedAt.toISOString()}::timestamptz end`
        : values.recordedAt;
    // Duplicate taps are no-ops. Only a snoozed occurrence can still change (to taken/skipped, or snoozed again).
    const [row] = await db
      .insert(doseRecords)
      .values({ ...values, snoozeCount: snooze ? 1 : 0 })
      .onConflictDoUpdate({
        target: doseRecords.occurrenceId,
        set: {
          status: values.status,
          recordedAt,
          snoozeCount: snooze ? sql`${doseRecords.snoozeCount} + 1` : doseRecords.snoozeCount,
        },
        setWhere: and(sql`${doseRecords.status} = 'snoozed'`, eq(doseRecords.seniorId, seniorId)),
      })
      .returning();
    if (row) {
      // A late answer ends an already-reported missed dose; a snooze does not.
      if (row.status !== "snoozed") {
        await resolveAlerts(deps, seniorId, eq(alerts.dedupKey, `dose_missed:${row.occurrenceId}`), {
          title: (n) => `${n} ${row.status === "taken" ? "took" : "skipped"} the missed dose of ${med.name}`,
        });
      }
      return c.json(row, 201);
    }
    const [existing] = await db.select().from(doseRecords).where(eq(doseRecords.occurrenceId, body.occurrenceId));
    if (!existing || existing.seniorId !== seniorId) throw new ApiError(409, "version_conflict", "Occurrence id already used");
    return c.json(existing, 200);
  });

  app.get(
    "/seniors/:seniorId/doses",
    validate("param", seniorParam),
    validate("query", z.object({ from: isoDate.optional(), to: isoDate.optional() })),
    async (c) => {
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, c.get("auth"), seniorId);
      const { from, to } = c.req.valid("query");
      const items = await db
        .select()
        .from(doseRecords)
        .where(
          and(
            eq(doseRecords.seniorId, seniorId),
            from ? gte(doseRecords.recordedAt, from) : undefined,
            to ? lte(doseRecords.recordedAt, to) : undefined,
          ),
        )
        .orderBy(desc(doseRecords.recordedAt))
        .limit(500);
      return c.json({ items });
    },
  );

  /** Expanded schedule with per-occurrence status: "next medication" for the senior, adherence for the guardian. */
  app.get(
    "/seniors/:seniorId/dose-schedule",
    validate("param", seniorParam),
    validate("query", z.object({ from: isoDate.optional(), to: isoDate.optional() })),
    async (c) => {
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, c.get("auth"), seniorId);
      const now = deps.clock();
      const q = c.req.valid("query");
      const from = q.from ?? new Date(now.getTime() - 12 * HOUR_MS);
      const to = q.to ?? new Date(now.getTime() + 24 * HOUR_MS);
      if (to <= from || to.getTime() - from.getTime() > 7 * 24 * HOUR_MS) {
        throw new ApiError(400, "validation_error", "to must be after from and at most 7 days later");
      }
      return c.json({ items: await doseSchedule(deps, seniorId, from, to), serverTime: now });
    },
  );

  // Only user-approved report content is ever sent here; raw check-ins stay on the device.
  app.post("/seniors/:seniorId/reports", validate("param", seniorParam), validate("json", reportBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");
    const [row] = await db
      .insert(reports)
      .values({
        seniorId,
        period: body.period ?? null,
        structured: body.structured,
        summary: body.summary ?? null,
        source: body.source,
        createdAt: deps.clock(),
      })
      .returning();
    return c.json(row, 201);
  });

  // Guardian-only: the senior submits reports but does not read them back.
  app.get(
    "/seniors/:seniorId/reports",
    validate("param", seniorParam),
    validate("query", z.object({ before: isoDate.optional(), limit: z.coerce.number().int().min(1).max(100).default(50) })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const { before, limit } = c.req.valid("query");
      const items = await db
        .select()
        .from(reports)
        .where(and(eq(reports.seniorId, seniorId), before ? lt(reports.createdAt, before) : undefined))
        .orderBy(desc(reports.createdAt))
        .limit(limit);
      return c.json({ items });
    },
  );

  app.get(
    "/seniors/:seniorId/reports/:reportId",
    validate("param", z.object({ seniorId: uuid, reportId: uuid })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId, reportId } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const [row] = await db
        .select()
        .from(reports)
        .where(and(eq(reports.id, reportId), eq(reports.seniorId, seniorId)));
      if (!row) throw notFound("Report");
      return c.json(row);
    },
  );

  /**
   * Sharing control: the senior withdraws a report they shared (its id comes from the POST response);
   * it disappears for guardians too. The senior's app keeps its own record of what it shared.
   */
  app.delete(
    "/seniors/:seniorId/reports/:id",
    validate("param", z.object({ seniorId: uuid, id: uuid })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "senior");
      const { seniorId, id } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const deleted = await db
        .delete(reports)
        .where(and(eq(reports.id, id), eq(reports.seniorId, seniorId)))
        .returning({ id: reports.id });
      if (deleted.length === 0) throw notFound("Report");
      return c.body(null, 204);
    },
  );

  /** Case-insensitive name search, to help manual entry after an unknown barcode. Synthetic demo data only. */
  app.get("/catalog", validate("query", z.object({ q: z.string().trim().min(2).max(64) })), async (c) => {
    const term = c.req.valid("query").q.replace(/[\\%_]/g, (ch) => `\\${ch}`);
    const items = await db
      .select()
      .from(medicationCatalog)
      .where(ilike(medicationCatalog.name, `%${term}%`))
      .orderBy(asc(medicationCatalog.name))
      .limit(10);
    return c.json({ items });
  });

  app.get("/catalog/:barcode", validate("param", z.object({ barcode: z.string().min(1).max(64) })), async (c) => {
    const [row] = await db
      .select()
      .from(medicationCatalog)
      .where(eq(medicationCatalog.barcode, c.req.valid("param").barcode));
    // A barcode names a candidate only; dose and prescription must be confirmed by a person.
    if (!row) throw notFound("Barcode");
    return c.json(row);
  });

  return app;
}

import { and, desc, eq, gte, lte, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { doseRecords, medicationCatalog, medications, reports } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { isoDate, seniorParam, uuid } from "../schemas.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

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
      .select({ id: medications.id })
      .from(medications)
      .where(and(eq(medications.id, body.medicationId), eq(medications.seniorId, seniorId)));
    if (!med) throw notFound("Medication");

    const values = {
      occurrenceId: body.occurrenceId,
      medicationId: body.medicationId,
      seniorId,
      status: body.status,
      scheduledFor: body.scheduledFor ?? null,
      recordedAt: body.recordedAt,
    };
    // Duplicate taps are no-ops. Only a snoozed occurrence can still change (to taken/skipped).
    const [row] = await db
      .insert(doseRecords)
      .values(values)
      .onConflictDoUpdate({
        target: doseRecords.occurrenceId,
        set: { status: values.status, recordedAt: values.recordedAt },
        setWhere: and(sql`${doseRecords.status} = 'snoozed'`, eq(doseRecords.seniorId, seniorId)),
      })
      .returning();
    if (row) return c.json(row, 201);
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

  app.get("/seniors/:seniorId/reports", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const items = await db
      .select()
      .from(reports)
      .where(eq(reports.seniorId, seniorId))
      .orderBy(desc(reports.createdAt))
      .limit(50);
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

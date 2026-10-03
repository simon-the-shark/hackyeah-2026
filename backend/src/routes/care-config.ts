import { createHash } from "node:crypto";
import { and, asc, eq, inArray, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { contacts, medications, safeAreas, trips } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { isoDate, lat, lng, phone, radiusM, seniorParam, timeOfDay, timezone, uuid } from "../schemas.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const conflict = (current: unknown) =>
  new ApiError(409, "version_conflict", "Entity was modified; refetch and retry", { current });

const rowParam = z.object({ seniorId: uuid, id: uuid });
const version = z.number().int().min(1);

const safeAreaBody = z.object({ lat, lng, radiusM, version: version.optional() });
const contactBody = z.object({
  name: z.string().min(1).max(80),
  phone,
  sortOrder: z.number().int().default(0),
  isEmergency: z.boolean().default(false),
});
const medicationBody = z.object({
  name: z.string().min(1).max(120),
  doseText: z.string().max(200).optional(),
  instructions: z.string().max(1000).optional(),
  barcode: z.string().max(64).optional(),
  modelAssetKey: z.string().max(64).optional(),
  times: z.array(timeOfDay).max(12),
  timezone,
  missedGraceMinutes: z.number().int().min(5).max(24 * 60).optional(),
  maxSnoozes: z.number().int().min(1).max(10).optional(),
});
const tripBody = z
  .object({
    label: z.string().min(1).max(120),
    destLat: lat,
    destLng: lng,
    radiusM,
    windowStart: isoDate,
    windowEnd: isoDate,
  })
  .refine((t) => t.windowEnd > t.windowStart, { message: "windowEnd must be after windowStart", path: ["windowEnd"] });

/** Guardian-managed configuration. Reads: linked senior or guardian. Writes: guardian. */
export function careConfigRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  // ---- whole configuration, for the senior device to sync and reschedule reminders ----
  app.get("/seniors/:seniorId/config", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const [[safeArea], contactRows, medicationRows, tripRows] = await Promise.all([
      db.select().from(safeAreas).where(eq(safeAreas.seniorId, seniorId)),
      db.select().from(contacts).where(eq(contacts.seniorId, seniorId)).orderBy(asc(contacts.sortOrder), asc(contacts.name)),
      db.select().from(medications).where(eq(medications.seniorId, seniorId)).orderBy(asc(medications.name), asc(medications.id)),
      db
        .select()
        .from(trips)
        .where(and(eq(trips.seniorId, seniorId), inArray(trips.status, ["planned", "active"])))
        .orderBy(asc(trips.windowStart), asc(trips.id)),
    ]);
    const config = { safeArea: safeArea ?? null, contacts: contactRows, medications: medicationRows, trips: tripRows };
    // Content hash: any create, edit or delete changes it, and an unchanged config can be skipped with 304.
    const configVersion = createHash("sha256").update(JSON.stringify(config)).digest("hex").slice(0, 16);
    const etag = `"${configVersion}"`;
    c.header("ETag", etag);
    if (c.req.header("if-none-match") === etag) return c.body(null, 304);
    return c.json({ ...config, configVersion });
  });

  // ---- safe area ----
  app.get("/seniors/:seniorId/safe-area", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const [row] = await db.select().from(safeAreas).where(eq(safeAreas.seniorId, seniorId));
    if (!row) throw notFound("Safe area");
    return c.json(row);
  });

  app.put("/seniors/:seniorId/safe-area", validate("param", seniorParam), validate("json", safeAreaBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");
    const [existing] = await db.select().from(safeAreas).where(eq(safeAreas.seniorId, seniorId));
    if (!existing) {
      if (body.version !== undefined) throw conflict(null);
      const [created] = await db
        .insert(safeAreas)
        .values({ seniorId, lat: body.lat, lng: body.lng, radiusM: body.radiusM, updatedAt: deps.clock() })
        .onConflictDoNothing()
        .returning();
      if (!created) {
        const [current] = await db.select().from(safeAreas).where(eq(safeAreas.seniorId, seniorId));
        throw conflict(current);
      }
      return c.json(created, 201);
    }
    const [updated] = await db
      .update(safeAreas)
      .set({
        lat: body.lat,
        lng: body.lng,
        radiusM: body.radiusM,
        version: sql`${safeAreas.version} + 1`,
        updatedAt: deps.clock(),
      })
      .where(and(eq(safeAreas.seniorId, seniorId), eq(safeAreas.version, body.version ?? -1)))
      .returning();
    if (!updated) throw conflict(existing);
    return c.json(updated);
  });

  // ---- contacts ----
  app.get("/seniors/:seniorId/contacts", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const rows = await db
      .select()
      .from(contacts)
      .where(eq(contacts.seniorId, seniorId))
      .orderBy(asc(contacts.sortOrder), asc(contacts.name));
    return c.json({ items: rows });
  });

  app.post("/seniors/:seniorId/contacts", validate("param", seniorParam), validate("json", contactBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const [row] = await db
      .insert(contacts)
      .values({ seniorId, ...c.req.valid("json") })
      .returning();
    return c.json(row, 201);
  });

  app.put(
    "/seniors/:seniorId/contacts/:id",
    validate("param", rowParam),
    validate("json", contactBody.extend({ version })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId, id } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const { version: v, ...fields } = c.req.valid("json");
      const [updated] = await db
        .update(contacts)
        .set({ ...fields, version: sql`${contacts.version} + 1` })
        .where(and(eq(contacts.id, id), eq(contacts.seniorId, seniorId), eq(contacts.version, v)))
        .returning();
      if (updated) return c.json(updated);
      const [current] = await db.select().from(contacts).where(and(eq(contacts.id, id), eq(contacts.seniorId, seniorId)));
      if (!current) throw notFound("Contact");
      throw conflict(current);
    },
  );

  app.delete("/seniors/:seniorId/contacts/:id", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const deleted = await db
      .delete(contacts)
      .where(and(eq(contacts.id, id), eq(contacts.seniorId, seniorId)))
      .returning({ id: contacts.id });
    if (deleted.length === 0) throw notFound("Contact");
    return c.body(null, 204);
  });

  // ---- medications ----
  app.get("/seniors/:seniorId/medications", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    return c.json({ items: await db.select().from(medications).where(eq(medications.seniorId, seniorId)) });
  });

  app.post(
    "/seniors/:seniorId/medications",
    validate("param", seniorParam),
    validate("json", medicationBody),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const [row] = await db
        .insert(medications)
        .values({ seniorId, ...c.req.valid("json"), scheduleUpdatedAt: deps.clock() })
        .returning();
      return c.json(row, 201);
    },
  );

  app.put(
    "/seniors/:seniorId/medications/:id",
    validate("param", rowParam),
    validate("json", medicationBody.extend({ version })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId, id } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const { version: v, ...fields } = c.req.valid("json");
      const [existing] = await db
        .select()
        .from(medications)
        .where(and(eq(medications.id, id), eq(medications.seniorId, seniorId)));
      if (!existing) throw notFound("Medication");
      // Only a schedule change restarts missed-dose detection; a name or note fix must not hide missed doses.
      // The version check below guarantees `existing` is the row being replaced.
      const scheduleChanged =
        existing.timezone !== fields.timezone || JSON.stringify(existing.times) !== JSON.stringify(fields.times);
      const [updated] = await db
        .update(medications)
        .set({
          name: fields.name,
          doseText: fields.doseText ?? null,
          instructions: fields.instructions ?? null,
          barcode: fields.barcode ?? null,
          modelAssetKey: fields.modelAssetKey ?? null,
          times: fields.times,
          timezone: fields.timezone,
          missedGraceMinutes: fields.missedGraceMinutes ?? null,
          maxSnoozes: fields.maxSnoozes ?? null,
          version: sql`${medications.version} + 1`,
          ...(scheduleChanged ? { scheduleUpdatedAt: deps.clock() } : {}),
        })
        .where(and(eq(medications.id, id), eq(medications.seniorId, seniorId), eq(medications.version, v)))
        .returning();
      if (updated) return c.json(updated);
      const [current] = await db
        .select()
        .from(medications)
        .where(and(eq(medications.id, id), eq(medications.seniorId, seniorId)));
      if (!current) throw notFound("Medication");
      throw conflict(current);
    },
  );

  app.delete("/seniors/:seniorId/medications/:id", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const deleted = await db
      .delete(medications)
      .where(and(eq(medications.id, id), eq(medications.seniorId, seniorId)))
      .returning({ id: medications.id });
    if (deleted.length === 0) throw notFound("Medication");
    return c.body(null, 204);
  });

  // ---- trips (P2) ----
  app.get("/seniors/:seniorId/trips", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    return c.json({
      items: await db.select().from(trips).where(eq(trips.seniorId, seniorId)).orderBy(asc(trips.windowStart)),
    });
  });

  app.post("/seniors/:seniorId/trips", validate("param", seniorParam), validate("json", tripBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const [row] = await db
      .insert(trips)
      .values({ seniorId, ...c.req.valid("json") })
      .returning();
    return c.json(row, 201);
  });

  app.put(
    "/seniors/:seniorId/trips/:id",
    validate("param", rowParam),
    validate("json", tripBody.and(z.object({ version }))),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId, id } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const { version: v, ...fields } = c.req.valid("json");
      const [updated] = await db
        .update(trips)
        .set({ ...fields, version: sql`${trips.version} + 1` })
        .where(and(eq(trips.id, id), eq(trips.seniorId, seniorId), eq(trips.version, v)))
        .returning();
      if (updated) return c.json(updated);
      const [current] = await db.select().from(trips).where(and(eq(trips.id, id), eq(trips.seniorId, seniorId)));
      if (!current) throw notFound("Trip");
      throw conflict(current);
    },
  );

  app.delete("/seniors/:seniorId/trips/:id", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const deleted = await db
      .delete(trips)
      .where(and(eq(trips.id, id), eq(trips.seniorId, seniorId)))
      .returning({ id: trips.id });
    if (deleted.length === 0) throw notFound("Trip");
    return c.body(null, 204);
  });

  return app;
}

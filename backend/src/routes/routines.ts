import { and, asc, desc, eq, isNotNull, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { routines, routineSuggestions } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { eventSource, lat, lng, radiusM, seniorParam, timeOfDay, timezone, uuid } from "../schemas.js";
import { dropUpcomingRoutineTrips } from "../services/routines.js";
import { corridorField, corridorNeedsRoute, routeField, needsStoredRoute, routeUpdate } from "./route-fields.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const rowParam = z.object({ seniorId: uuid, id: uuid });
const version = z.number().int().min(1);

const recurringTrip = z
  .object({
    label: z.string().min(1).max(120),
    destLat: lat,
    destLng: lng,
    radiusM,
    route: routeField,
    weekdays: z
      .array(z.number().int().min(1).max(7))
      .min(1)
      .max(7)
      .refine((d) => new Set(d).size === d.length, "Duplicate weekday"),
    startTime: timeOfDay,
    endTime: timeOfDay,
    timezone,
  })
  .refine((r) => r.endTime > r.startTime, { message: "endTime must be after startTime on the same day", path: ["endTime"] });

const suggestionBody = recurringTrip.and(z.object({ source: eventSource }));
const routineBody = recurringTrip
  .and(z.object({ corridorM: corridorField, active: z.boolean().default(true) }))
  .refine(corridorNeedsRoute.check, corridorNeedsRoute.message);

/**
 * Learned routines (P2 v2). The senior device suggests a routine computed on the device; a guardian
 * confirms it into a recurring trip. Raw location history never reaches the server.
 */
export function routineRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  app.post(
    "/seniors/:seniorId/routine-suggestions",
    validate("param", seniorParam),
    validate("json", suggestionBody),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "senior");
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const [row] = await db
        .insert(routineSuggestions)
        .values({ seniorId, ...c.req.valid("json"), createdAt: deps.clock() })
        .returning();
      return c.json(row, 201);
    },
  );

  app.get(
    "/seniors/:seniorId/routine-suggestions",
    validate("param", seniorParam),
    validate("query", z.object({ status: z.enum(["pending", "accepted", "rejected"]).optional() })),
    async (c) => {
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, c.get("auth"), seniorId);
      const { status } = c.req.valid("query");
      const items = await db
        .select()
        .from(routineSuggestions)
        .where(and(eq(routineSuggestions.seniorId, seniorId), status ? eq(routineSuggestions.status, status) : undefined))
        .orderBy(desc(routineSuggestions.createdAt))
        .limit(100);
      return c.json({ items });
    },
  );

  /** Decides a pending suggestion exactly once; a second decision gets 409 with the stored one. */
  async function decide(seniorId: string, id: string, guardianId: string, status: "accepted" | "rejected") {
    const [row] = await db
      .update(routineSuggestions)
      .set({ status, decidedAt: deps.clock(), decidedBy: guardianId })
      .where(
        and(
          eq(routineSuggestions.id, id),
          eq(routineSuggestions.seniorId, seniorId),
          eq(routineSuggestions.status, "pending"),
        ),
      )
      .returning();
    if (row) return row;
    const [current] = await db
      .select()
      .from(routineSuggestions)
      .where(and(eq(routineSuggestions.id, id), eq(routineSuggestions.seniorId, seniorId)));
    if (!current) throw notFound("Routine suggestion");
    throw new ApiError(409, "version_conflict", "Suggestion was already decided", { current });
  }

  app.post("/seniors/:seniorId/routine-suggestions/:id/accept", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const s = await decide(seniorId, id, auth.userId, "accepted");
    const [routine] = await db
      .insert(routines)
      .values({
        seniorId,
        label: s.label,
        destLat: s.destLat,
        destLng: s.destLng,
        radiusM: s.radiusM,
        route: s.route,
        weekdays: s.weekdays,
        startTime: s.startTime,
        endTime: s.endTime,
        timezone: s.timezone,
        suggestionId: s.id,
        createdAt: deps.clock(),
      })
      .returning();
    return c.json({ suggestion: s, routine }, 201);
  });

  app.post("/seniors/:seniorId/routine-suggestions/:id/reject", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    return c.json(await decide(seniorId, id, auth.userId, "rejected"));
  });

  // ---- routines: guardian-managed, versioned like the other configuration ----
  app.get("/seniors/:seniorId/routines", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const items = await db
      .select()
      .from(routines)
      .where(eq(routines.seniorId, seniorId))
      .orderBy(asc(routines.startTime), asc(routines.id));
    return c.json({ items });
  });

  app.post("/seniors/:seniorId/routines", validate("param", seniorParam), validate("json", routineBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");
    if (body.corridorM != null && body.route == null) {
      throw new ApiError(400, "validation_error", "corridorM needs a route");
    }
    const [row] = await db
      .insert(routines)
      .values({ seniorId, ...body, createdAt: deps.clock() })
      .returning();
    return c.json(row, 201);
  });

  app.put(
    "/seniors/:seniorId/routines/:id",
    validate("param", rowParam),
    validate("json", routineBody.and(z.object({ version }))),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { seniorId, id } = c.req.valid("param");
      await assertLinked(db, auth, seniorId);
      const { version: v, route, corridorM, ...fields } = c.req.valid("json");
      const [updated] = await db
        .update(routines)
        .set({ ...fields, ...routeUpdate({ route, corridorM }), version: sql`${routines.version} + 1` })
        .where(
          and(
            eq(routines.id, id),
            eq(routines.seniorId, seniorId),
            eq(routines.version, v),
            needsStoredRoute({ route, corridorM }) ? isNotNull(routines.route) : undefined,
          ),
        )
        .returning();
      if (updated) {
        // Upcoming generated trips are rebuilt from the new schedule on the next watchdog pass.
        await dropUpcomingRoutineTrips(db, id, deps.clock());
        return c.json(updated);
      }
      const [current] = await db.select().from(routines).where(and(eq(routines.id, id), eq(routines.seniorId, seniorId)));
      if (!current) throw notFound("Routine");
      if (current.version === v) throw new ApiError(400, "validation_error", "corridorM needs a route");
      throw new ApiError(409, "version_conflict", "Entity was modified; refetch and retry", { current });
    },
  );

  app.delete("/seniors/:seniorId/routines/:id", validate("param", rowParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { seniorId, id } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    // Past and running trips stay as history (their routine link becomes null); upcoming ones go.
    await dropUpcomingRoutineTrips(db, id, deps.clock());
    const deleted = await db
      .delete(routines)
      .where(and(eq(routines.id, id), eq(routines.seniorId, seniorId)))
      .returning({ id: routines.id });
    if (deleted.length === 0) throw notFound("Routine");
    return c.body(null, 204);
  });

  return app;
}

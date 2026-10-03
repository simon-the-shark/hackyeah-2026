import { and, desc, eq, gt, isNull } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { alerts, events, statusHeartbeats, trips } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { geoPoint, idParam, isoDate, seniorParam, uuid } from "../schemas.js";
import { ingestEvent } from "../services/alerts.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const eventBody = z
  .object({
    id: uuid,
    type: z.enum(["sos", "sos_cancel", "area_exit", "area_enter", "dose_missed", "trip_arrived", "trip_deviation"]),
    occurredAt: isoDate,
    cancelsEventId: uuid.optional(),
    tripId: uuid.optional(),
    location: geoPoint.optional(),
  })
  .superRefine((e, ctx) => {
    if (e.type === "sos_cancel" && !e.cancelsEventId) {
      ctx.addIssue({ code: "custom", path: ["cancelsEventId"], message: "Required for sos_cancel" });
    }
    if ((e.type === "trip_arrived" || e.type === "trip_deviation") && !e.tripId) {
      ctx.addIssue({ code: "custom", path: ["tripId"], message: "Required for trip events" });
    }
  });

const statusBody = z.object({
  monitoringState: z.enum(["inside", "outside", "unknown", "unavailable"]),
  location: geoPoint.optional(),
  battery: z.number().int().min(0).max(100).optional(),
});

const alertView = (row: {
  alert: typeof alerts.$inferSelect;
  event: typeof events.$inferSelect | null;
}) => ({
  id: row.alert.id,
  seniorId: row.alert.seniorId,
  kind: row.alert.kind,
  createdAt: row.alert.createdAt,
  cancelledAt: row.alert.cancelledAt,
  pushStatus: row.alert.pushStatus,
  acknowledgedAt: row.alert.acknowledgedAt,
  acknowledgedBy: row.alert.acknowledgedBy,
  event: row.event && {
    id: row.event.id,
    type: row.event.type,
    occurredAt: row.event.occurredAt,
    receivedAt: row.event.receivedAt,
    deviceId: row.event.deviceId,
    location: row.event.location,
  },
});

export function safetyRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  app.post("/seniors/:seniorId/events", validate("param", seniorParam), validate("json", eventBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");

    if (body.tripId) {
      const [trip] = await db
        .select({ id: trips.id })
        .from(trips)
        .where(and(eq(trips.id, body.tripId), eq(trips.seniorId, seniorId)));
      if (!trip) throw new ApiError(404, "not_found", "Trip not found");
    }

    const result = await ingestEvent(deps, auth, seniorId, body);
    if (result.created && body.type === "trip_arrived" && body.tripId) {
      await db
        .update(trips)
        .set({ status: "completed" })
        .where(and(eq(trips.id, body.tripId), eq(trips.seniorId, seniorId)));
    }
    return c.json(
      {
        event: result.event,
        alert: result.alert && { id: result.alert.id, kind: result.alert.kind, pushStatus: result.alert.pushStatus },
      },
      result.created ? 201 : 200,
    );
  });

  // Senior may read own alerts too, to show "accepted" vs "guardian acknowledged".
  app.get(
    "/seniors/:seniorId/alerts",
    validate("param", seniorParam),
    validate("query", z.object({ since: isoDate.optional(), limit: z.coerce.number().int().min(1).max(200).default(50) })),
    async (c) => {
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, c.get("auth"), seniorId);
      const { since, limit } = c.req.valid("query");
      const rows = await db
        .select({ alert: alerts, event: events })
        .from(alerts)
        .leftJoin(events, eq(events.id, alerts.eventId))
        .where(and(eq(alerts.seniorId, seniorId), since ? gt(alerts.createdAt, since) : undefined))
        .orderBy(desc(alerts.createdAt))
        .limit(limit);
      return c.json({ items: rows.map(alertView), serverTime: deps.clock() });
    },
  );

  async function loadAlert(id: string) {
    const [row] = await db
      .select({ alert: alerts, event: events })
      .from(alerts)
      .leftJoin(events, eq(events.id, alerts.eventId))
      .where(eq(alerts.id, id));
    if (!row) throw notFound("Alert");
    return row;
  }

  app.get("/alerts/:id", validate("param", idParam), async (c) => {
    const row = await loadAlert(c.req.valid("param").id);
    await assertLinked(db, c.get("auth"), row.alert.seniorId);
    return c.json(alertView(row));
  });

  app.post("/alerts/:id/ack", validate("param", idParam), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "guardian");
    const { id } = c.req.valid("param");
    const row = await loadAlert(id);
    await assertLinked(db, auth, row.alert.seniorId);
    // Idempotent: the first acknowledgement wins and later ones return it unchanged.
    await db
      .update(alerts)
      .set({ acknowledgedAt: deps.clock(), acknowledgedBy: auth.userId })
      .where(and(eq(alerts.id, id), isNull(alerts.acknowledgedAt)));
    return c.json(alertView(await loadAlert(id)));
  });

  app.put("/seniors/:seniorId/status", validate("param", seniorParam), validate("json", statusBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");
    const values = {
      deviceId: auth.deviceId,
      monitoringState: body.monitoringState,
      location: body.location ?? null,
      battery: body.battery ?? null,
      // Server receipt time, so a skewed device clock cannot hide a stale gap.
      reportedAt: deps.clock(),
      staleAlertedAt: null,
    };
    const [row] = await db
      .insert(statusHeartbeats)
      .values({ seniorId, ...values })
      .onConflictDoUpdate({ target: statusHeartbeats.seniorId, set: values })
      .returning();
    return c.json(row);
  });

  app.get("/seniors/:seniorId/status", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const [row] = await db.select().from(statusHeartbeats).where(eq(statusHeartbeats.seniorId, seniorId));
    return c.json({ status: row ?? null, serverTime: deps.clock() });
  });

  return app;
}

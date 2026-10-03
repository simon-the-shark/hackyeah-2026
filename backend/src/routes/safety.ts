import { and, desc, eq, gt, isNull } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { alerts, careLinks, devices, events, statusHeartbeats, trips, users } from "../db/schema.js";
import { ApiError, notFound } from "../errors.js";
import { eventSource, geoPoint, idParam, isoDate, seniorParam, uuid } from "../schemas.js";
import { ingestEvent, resolveAlerts } from "../services/alerts.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const eventBody = z
  .object({
    id: uuid,
    type: z.enum(["sos", "sos_cancel", "area_exit", "area_enter", "dose_missed", "trip_started", "trip_arrived", "trip_deviation"]),
    occurredAt: isoDate,
    cancelsEventId: uuid.optional(),
    tripId: uuid.optional(),
    location: geoPoint.optional(),
    source: eventSource,
  })
  .superRefine((e, ctx) => {
    if (e.type === "sos_cancel" && !e.cancelsEventId) {
      ctx.addIssue({ code: "custom", path: ["cancelsEventId"], message: "Required for sos_cancel" });
    }
    if ((e.type === "trip_started" || e.type === "trip_arrived" || e.type === "trip_deviation") && !e.tripId) {
      ctx.addIssue({ code: "custom", path: ["tripId"], message: "Required for trip events" });
    }
  });

const statusBody = z.object({
  monitoringState: z.enum(["inside", "outside", "unknown", "unavailable"]),
  location: geoPoint.optional(),
  battery: z.number().int().min(0).max(100).optional(),
  source: eventSource,
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
  resolvedAt: row.alert.resolvedAt,
  resolvedByEventId: row.alert.resolvedByEventId,
  pushStatus: row.alert.pushStatus,
  details: row.alert.details,
  acknowledgedAt: row.alert.acknowledgedAt,
  acknowledgedBy: row.alert.acknowledgedBy,
  event: row.event && {
    id: row.event.id,
    type: row.event.type,
    occurredAt: row.event.occurredAt,
    receivedAt: row.event.receivedAt,
    deviceId: row.event.deviceId,
    location: row.event.location,
    source: row.event.source,
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
    if (result.created && body.type === "trip_started" && body.tripId) {
      // Only a planned trip becomes active; a missed or completed trip is never revived.
      await db
        .update(trips)
        .set({ status: "active" })
        .where(and(eq(trips.id, body.tripId), eq(trips.seniorId, seniorId), eq(trips.status, "planned")));
    }
    // Intentionally unguarded, unlike trip_started: arriving late is still arriving, and a guardian who
    // already got a trip_not_completed alert should see the trip as completed. The alert is kept as history.
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

  // Guardian-wide inbox: lets the app resolve "which alert?" after a notification tap without push payload data.
  app.get(
    "/alerts",
    validate(
      "query",
      z.object({
        since: isoDate.optional(),
        unacknowledged: z.enum(["true", "false"]).default("false").transform((v) => v === "true"),
        unresolved: z.enum(["true", "false"]).default("false").transform((v) => v === "true"),
        limit: z.coerce.number().int().min(1).max(200).default(50),
      }),
    ),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "guardian");
      const { since, unacknowledged, unresolved, limit } = c.req.valid("query");
      const rows = await db
        .select({ alert: alerts, event: events, seniorName: users.displayName })
        .from(careLinks)
        .innerJoin(alerts, eq(alerts.seniorId, careLinks.seniorId))
        .innerJoin(users, eq(users.id, alerts.seniorId))
        .leftJoin(events, eq(events.id, alerts.eventId))
        .where(
          and(
            eq(careLinks.guardianId, auth.userId),
            since ? gt(alerts.createdAt, since) : undefined,
            unacknowledged ? isNull(alerts.acknowledgedAt) : undefined,
            unresolved ? and(isNull(alerts.resolvedAt), isNull(alerts.cancelledAt)) : undefined,
          ),
        )
        .orderBy(desc(alerts.createdAt))
        .limit(limit);
      return c.json({
        items: rows.map((r) => ({ ...alertView(r), seniorName: r.seniorName })),
        serverTime: deps.clock(),
      });
    },
  );

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
      seniorId,
      monitoringState: body.monitoringState,
      location: body.location ?? null,
      battery: body.battery ?? null,
      source: body.source,
      // Server receipt time, so a skewed device clock cannot hide a stale gap.
      reportedAt: deps.clock(),
    };
    const [row] = await db
      .insert(statusHeartbeats)
      .values({ deviceId: auth.deviceId, ...values })
      .onConflictDoUpdate({ target: statusHeartbeats.deviceId, set: values })
      .returning();
    // Any live device ends the senior's monitoring gap and re-arms monitoring_lost.
    await db.update(statusHeartbeats).set({ staleAlertedAt: null }).where(eq(statusHeartbeats.seniorId, seniorId));
    await resolveAlerts(deps, seniorId, eq(alerts.kind, "monitoring_lost"), {
      title: (n) => `Monitoring restored for ${n}`,
      source: body.source,
    });
    return c.json({ ...row!, staleAlertedAt: null });
  });

  app.get("/seniors/:seniorId/status", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const rows = await db
      .select({ hb: statusHeartbeats, kind: devices.kind })
      .from(statusHeartbeats)
      .innerJoin(devices, eq(devices.id, statusHeartbeats.deviceId))
      .where(eq(statusHeartbeats.seniorId, seniorId))
      .orderBy(desc(statusHeartbeats.reportedAt));
    const items = rows.map((r) => ({ ...r.hb, deviceKind: r.kind }));
    // `status` is the newest heartbeat from any device; `devices` keeps phone and watch apart.
    return c.json({ status: items[0] ?? null, devices: items, serverTime: deps.clock() });
  });

  return app;
}

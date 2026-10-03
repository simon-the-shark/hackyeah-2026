import { and, count, desc, eq, inArray, isNull } from "drizzle-orm";
import { Hono } from "hono";
import { assertLinked } from "../auth/middleware.js";
import { alerts, reports, safeAreas, trips, users } from "../db/schema.js";
import { seniorParam } from "../schemas.js";
import { doseSchedule } from "../services/doses.js";
import { seniorStatus } from "../services/status.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const DAY_MS = 24 * 60 * 60 * 1000;
const ATTENTION_LEVELS = ["none", "soon", "urgent"];

/** Wellbeing chat reports carry an attention level; other reports have none (null). */
function reportAttention(structured: Record<string, unknown>) {
  const value = structured.attention;
  return typeof value === "string" && ATTENTION_LEVELS.includes(value) ? value : null;
}

/** One call for the guardian overview screen. */
export function overviewRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  app.get("/seniors/:seniorId/overview", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, c.get("auth"), seniorId);
    const now = deps.clock();
    const open = and(eq(alerts.seniorId, seniorId), isNull(alerts.cancelledAt));
    const [[senior], status, [unacknowledged], [unresolved], doses, [report], [safeArea], [activeTrips]] =
      await Promise.all([
        db.select({ id: users.id, displayName: users.displayName }).from(users).where(eq(users.id, seniorId)),
        seniorStatus(db, seniorId),
        db.select({ n: count() }).from(alerts).where(and(open, isNull(alerts.acknowledgedAt))),
        db.select({ n: count() }).from(alerts).where(and(open, isNull(alerts.resolvedAt))),
        doseSchedule(deps, seniorId, new Date(now.getTime() - DAY_MS), new Date(now.getTime() + DAY_MS)),
        db
          .select({ id: reports.id, createdAt: reports.createdAt, structured: reports.structured, source: reports.source })
          .from(reports)
          .where(eq(reports.seniorId, seniorId))
          .orderBy(desc(reports.createdAt))
          .limit(1),
        db.select({ version: safeAreas.version }).from(safeAreas).where(eq(safeAreas.seniorId, seniorId)),
        db
          .select({ n: count() })
          .from(trips)
          .where(and(eq(trips.seniorId, seniorId), inArray(trips.status, ["planned", "active"]))),
      ]);
    return c.json({
      senior,
      ...status,
      alerts: { unacknowledged: unacknowledged?.n ?? 0, unresolved: unresolved?.n ?? 0 },
      // Still open: upcoming, or due and within the grace period (pending or snoozed).
      nextDoses: doses.filter((d) => d.status === "pending" || d.status === "snoozed").slice(0, 3),
      missedDosesLast24h: doses.filter((d) => d.status === "missed" && d.scheduledFor <= now).length,
      latestReportAt: report?.createdAt ?? null,
      latestReport: report
        ? { id: report.id, createdAt: report.createdAt, attention: reportAttention(report.structured), source: report.source }
        : null,
      safeAreaVersion: safeArea?.version ?? null,
      plannedOrActiveTrips: activeTrips?.n ?? 0,
      serverTime: now,
    });
  });

  return app;
}

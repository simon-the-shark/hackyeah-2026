import { and, eq, inArray, isNull, lt, ne, notInArray, sql } from "drizzle-orm";
import { alerts, events, statusHeartbeats, trips } from "../db/schema.js";
import type { Deps } from "../types.js";
import { isUrgent, notifyGuardians, raiseServerAlert, URGENT_KINDS } from "./alerts.js";
import { checkMissedDoses } from "./doses.js";
import { materializeRoutines } from "./routines.js";
import { pruneVitalSamples } from "./vitals.js";

/**
 * One pass: stale heartbeats -> monitoring_lost; routines -> upcoming trips; old heart-rate samples pruned;
 * elapsed trip windows -> trip_not_completed; overdue doses -> dose_missed; then push reminders and retries.
 */
export async function runWatchdogOnce(deps: Deps) {
  const now = deps.clock();
  const cutoff = new Date(now.getTime() - deps.staleSeconds * 1000);
  let raised = 0;

  // Monitoring is lost only when every device of a senior is stale. The UPDATE claims each gap
  // atomically (all of the senior's rows at once), so concurrent passes cannot double-alert.
  const stale = await deps.db
    .update(statusHeartbeats)
    .set({ staleAlertedAt: now })
    .where(
      and(
        isNull(statusHeartbeats.staleAlertedAt),
        inArray(
          statusHeartbeats.seniorId,
          deps.db
            .select({ seniorId: statusHeartbeats.seniorId })
            .from(statusHeartbeats)
            .groupBy(statusHeartbeats.seniorId)
            .having(sql`max(${statusHeartbeats.reportedAt}) < ${cutoff.toISOString()}`),
        ),
      ),
    )
    .returning();
  const gaps = new Map<string, (typeof stale)[number][]>();
  for (const hb of stale) gaps.set(hb.seniorId, [...(gaps.get(hb.seniorId) ?? []), hb]);
  for (const [seniorId, rows] of gaps) {
    const lastSeen = Math.max(...rows.map((r) => r.reportedAt.getTime()));
    const alert = await raiseServerAlert(deps, seniorId, "monitoring_lost", `monitoring_lost:${seniorId}:${lastSeen}`, {
      devices: rows.map((r) => ({ deviceId: r.deviceId, reportedAt: r.reportedAt.toISOString() })),
    });
    if (alert) raised++;
  }

  await materializeRoutines(deps);
  await pruneVitalSamples(deps);

  const missed = await deps.db
    .update(trips)
    .set({ status: "missed" })
    .where(and(inArray(trips.status, ["planned", "active"]), lt(trips.windowEnd, now), ne(trips.status, "missed")))
    .returning();
  for (const trip of missed) {
    const alert = await raiseServerAlert(deps, trip.seniorId, "trip_not_completed", `trip:${trip.id}`);
    if (alert) raised++;
  }

  raised += await checkMissedDoses(deps);
  await repushAlerts(deps);
  return raised;
}

/** Reminders after the first SOS or fall push; a guardian acknowledgement, cancel or resolution stops them. */
export const SOS_MAX_REMINDERS = 3;
/** A failed non-SOS push is retried once, this long after the failure. */
const FAILED_RETRY_MS = 60_000;

/**
 * Re-sends pushes that may not have reached anyone: unacknowledged SOS and fall alerts get up to
 * SOS_MAX_REMINDERS reminders, and other alerts whose only push failed get one retry. Each row is
 * claimed by bumping last_push_at first, so concurrent passes cannot double-send.
 */
async function repushAlerts(deps: Deps) {
  const now = deps.clock();
  const open = and(isNull(alerts.acknowledgedAt), isNull(alerts.cancelledAt), isNull(alerts.resolvedAt));
  const urgentDue = await deps.db
    .update(alerts)
    .set({ lastPushAt: now })
    .where(
      and(
        open,
        inArray(alerts.kind, [...URGENT_KINDS]),
        lt(alerts.pushAttempts, 1 + SOS_MAX_REMINDERS),
        lt(alerts.lastPushAt, new Date(now.getTime() - deps.sosRepushSeconds * 1000)),
      ),
    )
    .returning();
  const failedDue = await deps.db
    .update(alerts)
    .set({ lastPushAt: now })
    .where(
      and(
        open,
        notInArray(alerts.kind, [...URGENT_KINDS]),
        eq(alerts.pushStatus, "failed"),
        lt(alerts.pushAttempts, 2),
        lt(alerts.lastPushAt, new Date(now.getTime() - FAILED_RETRY_MS)),
      ),
    )
    .returning();

  for (const alert of [...urgentDue, ...failedDue]) {
    const [event] = alert.eventId
      ? await deps.db.select({ source: events.source }).from(events).where(eq(events.id, alert.eventId))
      : [];
    await notifyGuardians(deps, alert, { reminder: isUrgent(alert.kind), source: event?.source });
  }
}

export function startWatchdog(deps: Deps, intervalMs = 30_000) {
  const timer = setInterval(() => {
    runWatchdogOnce(deps).catch((err) => console.error("[watchdog] pass failed", err));
  }, intervalMs);
  timer.unref();
  return () => clearInterval(timer);
}

import { and, inArray, isNull, lt, ne, sql } from "drizzle-orm";
import { statusHeartbeats, trips } from "../db/schema.js";
import type { Deps } from "../types.js";
import { raiseServerAlert } from "./alerts.js";
import { checkMissedDoses } from "./doses.js";

/** One pass: stale heartbeats -> monitoring_lost; elapsed trip windows -> trip_not_completed; overdue doses -> dose_missed. */
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
  return raised;
}

export function startWatchdog(deps: Deps, intervalMs = 30_000) {
  const timer = setInterval(() => {
    runWatchdogOnce(deps).catch((err) => console.error("[watchdog] pass failed", err));
  }, intervalMs);
  timer.unref();
  return () => clearInterval(timer);
}

import { and, inArray, isNull, lt, ne } from "drizzle-orm";
import { statusHeartbeats, trips } from "../db/schema.js";
import type { Deps } from "../types.js";
import { raiseServerAlert } from "./alerts.js";
import { checkMissedDoses } from "./doses.js";

/** One pass: stale heartbeats -> monitoring_lost; elapsed trip windows -> trip_not_completed; overdue doses -> dose_missed. */
export async function runWatchdogOnce(deps: Deps) {
  const now = deps.clock();
  const cutoff = new Date(now.getTime() - deps.staleSeconds * 1000);
  let raised = 0;

  // The UPDATE claims each gap atomically, so concurrent passes cannot double-alert.
  const stale = await deps.db
    .update(statusHeartbeats)
    .set({ staleAlertedAt: now })
    .where(and(lt(statusHeartbeats.reportedAt, cutoff), isNull(statusHeartbeats.staleAlertedAt)))
    .returning();
  for (const hb of stale) {
    const alert = await raiseServerAlert(deps, hb.seniorId, "monitoring_lost", `monitoring_lost:${hb.seniorId}:${hb.reportedAt.getTime()}`);
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

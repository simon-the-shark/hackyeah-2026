import { lt } from "drizzle-orm";
import { vitalSamples } from "../db/schema.js";
import type { Deps } from "../types.js";

const HOUR_MS = 60 * 60 * 1000;

/** Heart-rate readings are kept for a week: enough for a guardian's trend view, no long-term health record. */
export const VITAL_RETENTION_MS = 7 * 24 * HOUR_MS;
/** A reading this far ahead of server time means a wrong watch clock, not a measurement. */
export const MAX_FUTURE_SKEW_MS = 5 * 60 * 1000;
export const DEFAULT_WINDOW_MS = 24 * HOUR_MS;

/** Deletes readings older than the retention period; run by the watchdog. */
export async function pruneVitalSamples(deps: Deps) {
  const cutoff = new Date(deps.clock().getTime() - VITAL_RETENTION_MS);
  await deps.db.delete(vitalSamples).where(lt(vitalSamples.measuredAt, cutoff));
}

import { and, eq, gt } from "drizzle-orm";
import type { Db } from "../db/client.js";
import { routines, trips } from "../db/schema.js";
import type { Deps } from "../types.js";
import { addDays, localDateIn, zonedTimeToUtc } from "./doses.js";

/** ISO weekday (1 = Monday ... 7 = Sunday) of a YYYY-MM-DD calendar date. */
export function isoWeekday(localDate: string) {
  const [y, m, d] = localDate.split("-").map(Number) as [number, number, number];
  return ((new Date(Date.UTC(y, m - 1, d)).getUTCDay() + 6) % 7) + 1;
}

/**
 * Creates the planned trips of every active routine for today and tomorrow (local dates), once per
 * routine and date. Only windows that have not started yet are created, so a routine added late in
 * the day never produces a trip that is already missed.
 */
export async function materializeRoutines(deps: Deps) {
  const now = deps.clock();
  const active = await deps.db.select().from(routines).where(eq(routines.active, true));
  let created = 0;
  for (const r of active) {
    const today = localDateIn(now, r.timezone);
    for (const localDate of [today, addDays(today, 1)]) {
      if (!r.weekdays.includes(isoWeekday(localDate))) continue;
      const windowStart = zonedTimeToUtc(localDate, r.startTime, r.timezone);
      if (windowStart <= now) continue;
      const rows = await deps.db
        .insert(trips)
        .values({
          seniorId: r.seniorId,
          label: r.label,
          destLat: r.destLat,
          destLng: r.destLng,
          radiusM: r.radiusM,
          route: r.route,
          corridorM: r.corridorM,
          windowStart,
          windowEnd: zonedTimeToUtc(localDate, r.endTime, r.timezone),
          routineId: r.id,
          localDate,
        })
        .onConflictDoNothing()
        .returning({ id: trips.id });
      created += rows.length;
    }
  }
  return created;
}

/** Drops a routine's trips that have not started, so an edit or deletion takes effect from the next window. */
export async function dropUpcomingRoutineTrips(db: Db, routineId: string, now: Date) {
  await db
    .delete(trips)
    .where(and(eq(trips.routineId, routineId), eq(trips.status, "planned"), gt(trips.windowStart, now)));
}

import { and, inArray, sql } from "drizzle-orm";
import { doseRecords, medications } from "../db/schema.js";
import type { Deps } from "../types.js";
import { raiseServerAlert } from "./alerts.js";

/** Only doses scheduled within this window are checked, so a restart never floods old alerts. */
const LOOKBACK_MS = 24 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Canonical dose occurrence id shared with the app: `<medicationId>@<YYYY-MM-DD>T<HH:MM>` in the medication's zone. */
export const occurrenceId = (medicationId: string, localDate: string, time: string) =>
  `${medicationId}@${localDate}T${time}`;

export function parseOccurrenceId(id: string, medicationId: string) {
  const m = /^(.+)@(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})$/.exec(id);
  if (!m || m[1] !== medicationId) return null;
  return { localDate: m[2]!, time: m[3]! };
}

const formatters = new Map<string, Intl.DateTimeFormat>();
function zoneParts(instant: Date, timeZone: string) {
  let f = formatters.get(timeZone);
  if (!f) {
    f = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hourCycle: "h23",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
    formatters.set(timeZone, f);
  }
  const p = Object.fromEntries(f.formatToParts(instant).map((x) => [x.type, x.value]));
  return { y: +p.year!, mo: +p.month!, d: +p.day!, h: +p.hour!, mi: +p.minute!, s: +p.second! };
}

/** Offset of the zone from UTC at the given instant, in ms. */
function zoneOffsetMs(instant: Date, timeZone: string) {
  const p = zoneParts(instant, timeZone);
  const asUtc = Date.UTC(p.y, p.mo - 1, p.d, p.h, p.mi, p.s);
  return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

/** UTC instant of a local wall-clock time in an IANA zone (DST-aware; times in a spring-forward gap shift forward). */
export function zonedTimeToUtc(localDate: string, time: string, timeZone: string): Date {
  const [y, mo, d] = localDate.split("-").map(Number) as [number, number, number];
  const [h, mi] = time.split(":").map(Number) as [number, number];
  const guess = Date.UTC(y, mo - 1, d, h, mi);
  const first = guess - zoneOffsetMs(new Date(guess), timeZone);
  const second = guess - zoneOffsetMs(new Date(first), timeZone);
  return new Date(second);
}

export function localDateIn(instant: Date, timeZone: string) {
  const p = zoneParts(instant, timeZone);
  return `${p.y}-${String(p.mo).padStart(2, "0")}-${String(p.d).padStart(2, "0")}`;
}

function addDays(localDate: string, days: number) {
  const [y, mo, d] = localDate.split("-").map(Number) as [number, number, number];
  return new Date(Date.UTC(y, mo - 1, d) + days * DAY_MS).toISOString().slice(0, 10);
}

type Med = typeof medications.$inferSelect;

/** Scheduled occurrences of a medication with from < scheduledAt <= to. */
export function occurrencesBetween(med: Med, from: Date, to: Date) {
  const out: { occurrenceId: string; scheduledAt: Date; time: string }[] = [];
  const last = addDays(localDateIn(to, med.timezone), 1);
  for (let day = addDays(localDateIn(from, med.timezone), -1); day <= last; day = addDays(day, 1)) {
    for (const time of med.times) {
      const scheduledAt = zonedTimeToUtc(day, time, med.timezone);
      if (scheduledAt > from && scheduledAt <= to) {
        out.push({ occurrenceId: occurrenceId(med.id, day, time), scheduledAt, time });
      }
    }
  }
  return out;
}

/**
 * Raises one dose_missed alert per occurrence that has no taken/skipped record once the grace
 * period has passed. The grace runs from the scheduled time, or from the latest snooze.
 */
export async function checkMissedDoses(deps: Deps) {
  const now = deps.clock();
  const graceMs = deps.doseGraceMinutes * 60 * 1000;
  const meds = await deps.db
    .select()
    .from(medications)
    .where(sql`jsonb_array_length(${medications.times}) > 0`);

  const candidates: { med: Med; occurrenceId: string; scheduledAt: Date; time: string }[] = [];
  for (const med of meds) {
    // Doses scheduled before the medication was created or its schedule last changed never count as missed.
    const from = new Date(Math.max(med.scheduleUpdatedAt.getTime(), now.getTime() - LOOKBACK_MS));
    const to = new Date(now.getTime() - graceMs);
    if (to <= from) continue;
    for (const occ of occurrencesBetween(med, from, to)) candidates.push({ med, ...occ });
  }
  if (candidates.length === 0) return 0;

  const records = await deps.db
    .select()
    .from(doseRecords)
    .where(and(inArray(doseRecords.occurrenceId, candidates.map((c) => c.occurrenceId))));
  const byId = new Map(records.map((r) => [r.occurrenceId, r]));

  let raised = 0;
  for (const c of candidates) {
    const record = byId.get(c.occurrenceId);
    if (record && record.status !== "snoozed") continue;
    const startedAt = record ? Math.max(c.scheduledAt.getTime(), record.recordedAt.getTime()) : c.scheduledAt.getTime();
    if (startedAt + graceMs > now.getTime()) continue;
    const alert = await raiseServerAlert(deps, c.med.seniorId, "dose_missed", `dose_missed:${c.occurrenceId}`, {
      medicationId: c.med.id,
      medicationName: c.med.name,
      occurrenceId: c.occurrenceId,
      scheduledFor: c.scheduledAt.toISOString(),
      localTime: c.time,
      timezone: c.med.timezone,
    });
    if (alert) raised++;
  }
  return raised;
}

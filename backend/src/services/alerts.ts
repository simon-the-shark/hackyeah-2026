import { and, eq, isNotNull } from "drizzle-orm";
import { alerts, careLinks, devices, events, users } from "../db/schema.js";
import type { GeoPoint } from "../db/schema.js";
import { ApiError } from "../errors.js";
import type { Auth, Deps } from "../types.js";

type AlertKind = (typeof alerts.$inferSelect)["kind"];
type EventType = (typeof events.$inferSelect)["type"];

export type EventInput = {
  id: string;
  type: EventType;
  occurredAt: Date;
  cancelsEventId?: string | undefined;
  tripId?: string | undefined;
  location?: GeoPoint | undefined;
};

const ALERT_KIND_FOR_EVENT: Partial<Record<EventType, AlertKind>> = {
  sos: "sos",
  area_exit: "area_exit",
  trip_deviation: "trip_deviation",
};

const TITLES: Record<AlertKind, (name: string) => string> = {
  sos: (n) => `SOS from ${n}`,
  area_exit: (n) => `${n} left the safe area`,
  dose_missed: (n) => `${n} missed a dose`,
  trip_deviation: (n) => `${n} deviated from the planned trip`,
  trip_not_completed: (n) => `${n} did not complete the planned trip`,
  monitoring_lost: (n) => `Monitoring lost for ${n}`,
};

async function seniorName(deps: Deps, seniorId: string): Promise<string> {
  const [u] = await deps.db.select({ name: users.displayName }).from(users).where(eq(users.id, seniorId));
  return u?.name ?? "Senior";
}

/** Sends a push to every guardian device and records the provider result on the alert. */
export async function notifyGuardians(
  deps: Deps,
  alert: { id: string; seniorId: string; kind: AlertKind },
  opts: { cancelled?: boolean } = {},
) {
  const rows = await deps.db
    .select({ token: devices.pushToken })
    .from(careLinks)
    .innerJoin(devices, eq(devices.userId, careLinks.guardianId))
    .where(and(eq(careLinks.seniorId, alert.seniorId), isNotNull(devices.pushToken)));
  const tokens = rows.map((r) => r.token).filter((t): t is string => !!t);
  if (tokens.length === 0) return "none" as const;

  const name = await seniorName(deps, alert.seniorId);
  const title = opts.cancelled ? `Cancelled: ${TITLES[alert.kind](name)}` : TITLES[alert.kind](name);
  const status = await deps.push.send(tokens, {
    title,
    body: "Open the app for details.",
    data: { alertId: alert.id, seniorId: alert.seniorId, kind: alert.kind },
  });
  await deps.db.update(alerts).set({ pushStatus: status }).where(eq(alerts.id, alert.id));
  return status;
}

export type IngestResult = {
  event: typeof events.$inferSelect;
  alert: typeof alerts.$inferSelect | null;
  created: boolean;
};

/** Idempotent on the client event id: a repeat returns the stored record and sends no second push. */
export async function ingestEvent(deps: Deps, auth: Auth, seniorId: string, input: EventInput): Promise<IngestResult> {
  const alertKind = ALERT_KIND_FOR_EVENT[input.type];

  const txResult = await deps.db.transaction(async (tx) => {
    const [inserted] = await tx
      .insert(events)
      .values({
        id: input.id,
        seniorId,
        deviceId: auth.deviceId,
        type: input.type,
        cancelsEventId: input.cancelsEventId ?? null,
        tripId: input.tripId ?? null,
        occurredAt: input.occurredAt,
        receivedAt: deps.clock(),
        location: input.location ?? null,
      })
      .onConflictDoNothing()
      .returning();

    if (!inserted) {
      const [existing] = await tx.select().from(events).where(eq(events.id, input.id));
      if (!existing || existing.seniorId !== seniorId) {
        throw new ApiError(409, "version_conflict", "Event id already used");
      }
      const [existingAlert] = await tx.select().from(alerts).where(eq(alerts.eventId, existing.id));
      return { event: existing, alert: existingAlert ?? null, created: false, cancelled: false };
    }

    if (input.type === "sos_cancel") {
      if (!input.cancelsEventId) {
        throw new ApiError(400, "validation_error", "sos_cancel requires cancelsEventId");
      }
      const [cancelled] = await tx
        .update(alerts)
        .set({ cancelledAt: deps.clock() })
        .where(and(eq(alerts.eventId, input.cancelsEventId), eq(alerts.seniorId, seniorId)))
        .returning();
      if (!cancelled) throw new ApiError(404, "not_found", "Event to cancel not found");
      return { event: inserted, alert: cancelled, created: true, cancelled: true };
    }

    if (!alertKind) return { event: inserted, alert: null, created: true, cancelled: false };

    const [alert] = await tx
      .insert(alerts)
      .values({ eventId: inserted.id, seniorId, kind: alertKind, createdAt: deps.clock() })
      .returning();
    return { event: inserted, alert: alert ?? null, created: true, cancelled: false };
  });

  let alert = txResult.alert;
  if (txResult.created && alert) {
    // Alert is committed before the push; a push failure never fails the request.
    const pushStatus = await notifyGuardians(deps, alert, { cancelled: txResult.cancelled });
    alert = { ...alert, pushStatus };
  }
  return { event: txResult.event, alert, created: txResult.created };
}

/** Server-generated alerts (watchdog); one per dedupKey. Returns null if it already existed. */
export async function raiseServerAlert(
  deps: Deps,
  seniorId: string,
  kind: AlertKind,
  dedupKey: string,
  details?: Record<string, unknown>,
) {
  const [alert] = await deps.db
    .insert(alerts)
    .values({ seniorId, kind, dedupKey, details: details ?? null, createdAt: deps.clock() })
    .onConflictDoNothing()
    .returning();
  if (!alert) return null;
  const pushStatus = await notifyGuardians(deps, alert);
  return { ...alert, pushStatus };
}

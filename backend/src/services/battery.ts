import { and, eq, isNotNull, isNull, sql } from "drizzle-orm";
import { alerts, devices, events, statusHeartbeats } from "../db/schema.js";
import type { Deps } from "../types.js";
import { raiseServerAlert, resolveAlerts } from "./alerts.js";

/** Battery must climb this far above the threshold before a new low_battery alert can fire. */
const RECOVERY_MARGIN = 10;

/**
 * Raises one low_battery alert per discharge of a device (the watch is the SOS surface, so a dead
 * watch matters), and resolves it once the battery has recovered past the threshold plus a margin.
 */
export async function checkBattery(
  deps: Deps,
  seniorId: string,
  deviceId: string,
  battery: number | undefined,
  source: (typeof events.$inferSelect)["source"],
) {
  if (battery === undefined) return;
  const now = deps.clock();
  if (battery <= deps.lowBatteryPercent) {
    const [claimed] = await deps.db
      .update(statusHeartbeats)
      .set({ lowBatteryAlertedAt: now })
      .where(and(eq(statusHeartbeats.deviceId, deviceId), isNull(statusHeartbeats.lowBatteryAlertedAt)))
      .returning();
    if (!claimed) return;
    const [device] = await deps.db.select({ kind: devices.kind }).from(devices).where(eq(devices.id, deviceId));
    const details = { deviceId, deviceKind: device?.kind, battery };
    await raiseServerAlert(deps, seniorId, "low_battery", `low_battery:${deviceId}:${now.getTime()}`, details, { source });
    return;
  }
  if (battery >= deps.lowBatteryPercent + RECOVERY_MARGIN) {
    const [recovered] = await deps.db
      .update(statusHeartbeats)
      .set({ lowBatteryAlertedAt: null })
      .where(and(eq(statusHeartbeats.deviceId, deviceId), isNotNull(statusHeartbeats.lowBatteryAlertedAt)))
      .returning();
    if (!recovered) return;
    await resolveAlerts(
      deps,
      seniorId,
      and(eq(alerts.kind, "low_battery"), sql`${alerts.details}->>'deviceId' = ${deviceId}`)!,
      { title: (n) => `${n}'s device is charged again`, source },
    );
  }
}

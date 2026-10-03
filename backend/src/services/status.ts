import { desc, eq } from "drizzle-orm";
import type { Db } from "../db/client.js";
import { devices, statusHeartbeats } from "../db/schema.js";

/** Latest heartbeat of each of the senior's devices, newest first; `status` is the newest of them. */
export async function seniorStatus(db: Db, seniorId: string) {
  const rows = await db
    .select({ hb: statusHeartbeats, kind: devices.kind })
    .from(statusHeartbeats)
    .innerJoin(devices, eq(devices.id, statusHeartbeats.deviceId))
    .where(eq(statusHeartbeats.seniorId, seniorId))
    .orderBy(desc(statusHeartbeats.reportedAt));
  const items = rows.map((r) => ({ ...r.hb, deviceKind: r.kind }));
  return { status: items[0] ?? null, devices: items };
}

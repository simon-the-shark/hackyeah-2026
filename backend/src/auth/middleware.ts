import { and, eq } from "drizzle-orm";
import { createMiddleware } from "hono/factory";
import type { Db } from "../db/client.js";
import { careLinks, devices, users } from "../db/schema.js";
import { ApiError } from "../errors.js";
import type { AppEnv, Auth, Deps } from "../types.js";
import { hashToken } from "./tokens.js";

export const authenticate = (deps: Pick<Deps, "db" | "clock">) =>
  createMiddleware<AppEnv>(async (c, next) => {
    const header = c.req.header("authorization") ?? "";
    const match = /^Bearer (.+)$/.exec(header);
    if (!match?.[1]) throw new ApiError(401, "unauthorized", "Missing bearer token");
    const [row] = await deps.db
      .select({ deviceId: devices.id, userId: users.id, role: users.role })
      .from(devices)
      .innerJoin(users, eq(users.id, devices.userId))
      .where(eq(devices.tokenHash, hashToken(match[1])))
      .limit(1);
    if (!row) throw new ApiError(401, "unauthorized", "Invalid token");
    await deps.db.update(devices).set({ lastSeenAt: deps.clock() }).where(eq(devices.id, row.deviceId));
    c.set("auth", row);
    await next();
  });

export function requireRole(auth: Auth, role: Auth["role"]) {
  if (auth.role !== role) throw new ApiError(403, "forbidden", `Requires ${role} role`);
}

/** Senior may access own data; guardian only seniors they are linked to. */
export async function assertLinked(db: Db, auth: Auth, seniorId: string) {
  if (auth.role === "senior") {
    if (auth.userId !== seniorId) throw new ApiError(403, "forbidden", "Not your account");
    return;
  }
  const [link] = await db
    .select({ seniorId: careLinks.seniorId })
    .from(careLinks)
    .where(and(eq(careLinks.seniorId, seniorId), eq(careLinks.guardianId, auth.userId)))
    .limit(1);
  if (!link) throw new ApiError(403, "forbidden", "Not linked to this senior");
}

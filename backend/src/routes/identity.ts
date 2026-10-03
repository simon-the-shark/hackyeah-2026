import { and, eq, gt, isNull } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { generatePairingCode, generateToken, hashToken } from "../auth/tokens.js";
import { requireRole } from "../auth/middleware.js";
import { careLinks, devices, pairingCodes, users } from "../db/schema.js";
import { ApiError } from "../errors.js";
import { deviceKind } from "../schemas.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const PAIRING_TTL_MS = 10 * 60 * 1000;

async function issueCode(deps: Deps, seniorId: string) {
  const expiresAt = new Date(deps.clock().getTime() + PAIRING_TTL_MS);
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generatePairingCode();
    const [row] = await deps.db
      .insert(pairingCodes)
      .values({ code, seniorId, expiresAt })
      .onConflictDoNothing()
      .returning();
    if (row) return { pairingCode: code, pairingExpiresAt: expiresAt };
  }
  throw new ApiError(500, "internal_error", "Could not allocate pairing code");
}

async function createDevice(deps: Deps, userId: string, kind: "phone" | "watch") {
  const token = generateToken();
  const [device] = await deps.db
    .insert(devices)
    .values({ userId, kind, tokenHash: hashToken(token) })
    .returning({ id: devices.id });
  return { deviceId: device!.id, token };
}

/** Unauthenticated bootstrap: create a senior, or claim a pairing code as a guardian. */
export function publicIdentityRoutes(deps: Deps) {
  const app = new Hono<AppEnv>();

  app.post(
    "/seniors",
    validate("json", z.object({ displayName: z.string().min(1).max(80), deviceKind: deviceKind.default("phone") })),
    async (c) => {
      const body = c.req.valid("json");
      const [senior] = await deps.db
        .insert(users)
        .values({ role: "senior", displayName: body.displayName })
        .returning({ id: users.id });
      const device = await createDevice(deps, senior!.id, body.deviceKind);
      const code = await issueCode(deps, senior!.id);
      return c.json({ seniorId: senior!.id, ...device, ...code }, 201);
    },
  );

  app.post(
    "/pairing/claim",
    validate(
      "json",
      z.object({
        code: z.string().regex(/^\d{6}$/),
        displayName: z.string().min(1).max(80),
        deviceKind: deviceKind.default("phone"),
      }),
    ),
    async (c) => {
      const body = c.req.valid("json");
      const now = deps.clock();
      // Atomic claim: only one request can flip used_at for a live code.
      const [claimed] = await deps.db
        .update(pairingCodes)
        .set({ usedAt: now })
        .where(and(eq(pairingCodes.code, body.code), isNull(pairingCodes.usedAt), gt(pairingCodes.expiresAt, now)))
        .returning();
      if (!claimed) throw new ApiError(410, "pairing_expired", "Pairing code is invalid, used or expired");
      const [guardian] = await deps.db
        .insert(users)
        .values({ role: "guardian", displayName: body.displayName })
        .returning({ id: users.id });
      await deps.db.insert(careLinks).values({ seniorId: claimed.seniorId, guardianId: guardian!.id });
      const device = await createDevice(deps, guardian!.id, body.deviceKind);
      return c.json({ guardianId: guardian!.id, seniorId: claimed.seniorId, ...device }, 201);
    },
  );

  return app;
}

export function identityRoutes(deps: Deps) {
  const app = new Hono<AppEnv>();

  app.get("/me", async (c) => {
    const auth = c.get("auth");
    const [me] = await deps.db.select().from(users).where(eq(users.id, auth.userId));
    const linked =
      auth.role === "guardian"
        ? await deps.db
            .select({ id: users.id, displayName: users.displayName })
            .from(careLinks)
            .innerJoin(users, eq(users.id, careLinks.seniorId))
            .where(eq(careLinks.guardianId, auth.userId))
        : await deps.db
            .select({ id: users.id, displayName: users.displayName })
            .from(careLinks)
            .innerJoin(users, eq(users.id, careLinks.guardianId))
            .where(eq(careLinks.seniorId, auth.userId));
    return c.json({
      id: auth.userId,
      role: auth.role,
      displayName: me?.displayName,
      deviceId: auth.deviceId,
      linked: auth.role === "guardian" ? { seniors: linked } : { guardians: linked },
    });
  });

  app.put(
    "/devices/me/push-token",
    validate("json", z.object({ pushToken: z.string().min(1).max(4096) })),
    async (c) => {
      const { pushToken } = c.req.valid("json");
      // A token identifies one device; drop it from any stale registration.
      await deps.db.update(devices).set({ pushToken: null }).where(eq(devices.pushToken, pushToken));
      await deps.db.update(devices).set({ pushToken }).where(eq(devices.id, c.get("auth").deviceId));
      return c.body(null, 204);
    },
  );

  /** A senior adds another device (e.g. the watch) and gets its token. */
  app.post("/devices", validate("json", z.object({ kind: deviceKind })), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const device = await createDevice(deps, auth.userId, c.req.valid("json").kind);
    return c.json(device, 201);
  });

  app.post("/pairing/codes", async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    return c.json(await issueCode(deps, auth.userId), 201);
  });

  return app;
}

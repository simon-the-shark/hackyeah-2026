import { and, asc, desc, eq, gt, isNull } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { generatePairingCode, generateToken, hashToken } from "../auth/tokens.js";
import { assertLinked, bearerToken, findAuth, requireRole } from "../auth/middleware.js";
import { clientIp, FixedWindow, limitByIp, tooManyRequests } from "../auth/rate-limit.js";
import { careLinks, devices, pairingCodes, statusHeartbeats, users } from "../db/schema.js";
import { ApiError } from "../errors.js";
import { deviceKind, uuid } from "../schemas.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

type PairingPurpose = (typeof pairingCodes.$inferSelect)["purpose"];

/** A watch code yields a senior-role token, so it lives shorter than a guardian code. */
const PAIRING_TTL_MS: Record<PairingPurpose, number> = { guardian: 10 * 60 * 1000, watch: 5 * 60 * 1000 };

async function issueCode(deps: Deps, seniorId: string, purpose: PairingPurpose = "guardian") {
  const now = deps.clock();
  const [activeCode] = await deps.db
    .select({ code: pairingCodes.code, expiresAt: pairingCodes.expiresAt })
    .from(pairingCodes)
    .where(
      and(
        eq(pairingCodes.seniorId, seniorId),
        eq(pairingCodes.purpose, purpose),
        isNull(pairingCodes.usedAt),
        gt(pairingCodes.expiresAt, now),
      ),
    )
    .orderBy(desc(pairingCodes.expiresAt))
    .limit(1);
  if (activeCode) return { pairingCode: activeCode.code, pairingExpiresAt: activeCode.expiresAt };

  const expiresAt = new Date(deps.clock().getTime() + PAIRING_TTL_MS[purpose]);
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generatePairingCode();
    const [row] = await deps.db
      .insert(pairingCodes)
      .values({ code, seniorId, purpose, expiresAt })
      .onConflictDoNothing()
      .returning();
    if (row) return { pairingCode: code, pairingExpiresAt: expiresAt };
  }
  throw new ApiError(500, "internal_error", "Could not allocate pairing code");
}

/** Atomic claim: only one request can flip used_at for a live code of the given purpose. */
async function claimCode(deps: Deps, code: string, purpose: PairingPurpose) {
  const now = deps.clock();
  const [claimed] = await deps.db
    .update(pairingCodes)
    .set({ usedAt: now })
    .where(
      and(
        eq(pairingCodes.code, code),
        eq(pairingCodes.purpose, purpose),
        isNull(pairingCodes.usedAt),
        gt(pairingCodes.expiresAt, now),
      ),
    )
    .returning();
  return claimed;
}

async function createDevice(deps: Deps, userId: string, kind: "phone" | "watch") {
  const token = generateToken();
  const [device] = await deps.db
    .insert(devices)
    .values({ userId, kind, tokenHash: hashToken(token) })
    .returning({ id: devices.id });
  return { deviceId: device!.id, token };
}

/** Unauthenticated bootstrap: create a senior, or claim a pairing code as a guardian or as the senior's watch. */
export function publicIdentityRoutes(deps: Deps) {
  const app = new Hono<AppEnv>();
  const nowMs = () => deps.clock().getTime();
  const bootstrapLimit = new FixedWindow(deps.rateLimits.bootstrapPerMinute, 60_000, nowMs);
  // Only failed claims count, so a family pairing several devices is never locked out, while guessing
  // 6-digit codes is capped at a handful of tries per window.
  const claimFailures = new FixedWindow(deps.rateLimits.claimFailuresPer15Min, 15 * 60_000, nowMs);

  app.post(
    "/seniors",
    limitByIp(bootstrapLimit),
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
      const ip = clientIp(c);
      const wait = claimFailures.blockedFor(ip);
      if (wait > 0) throw tooManyRequests(wait);
      // An already-paired guardian sends their token to link another senior to the same account.
      const token = bearerToken(c.req.header("authorization"));
      const existing = token ? await findAuth(deps.db, token) : null;
      if (token && !existing) throw new ApiError(401, "unauthorized", "Invalid token");
      if (existing) requireRole(existing, "guardian");
      // A watch code is never consumed here: it would otherwise link a stranger as guardian.
      const claimed = await claimCode(deps, body.code, "guardian");
      if (!claimed) {
        claimFailures.hit(ip);
        throw new ApiError(410, "pairing_expired", "Pairing code is invalid, used or expired");
      }
      if (existing) {
        await deps.db
          .insert(careLinks)
          .values({ seniorId: claimed.seniorId, guardianId: existing.userId })
          .onConflictDoNothing();
        return c.json({ guardianId: existing.userId, seniorId: claimed.seniorId, deviceId: existing.deviceId }, 201);
      }
      const [guardian] = await deps.db
        .insert(users)
        .values({ role: "guardian", displayName: body.displayName })
        .returning({ id: users.id });
      await deps.db.insert(careLinks).values({ seniorId: claimed.seniorId, guardianId: guardian!.id });
      const device = await createDevice(deps, guardian!.id, body.deviceKind);
      return c.json({ guardianId: guardian!.id, seniorId: claimed.seniorId, ...device }, 201);
    },
  );

  /** The senior's watch types a code from `POST /pairing/watch-codes` and becomes another senior device. */
  app.post("/pairing/watch-claim", validate("json", z.object({ code: z.string().regex(/^\d{6}$/) })), async (c) => {
    const { code } = c.req.valid("json");
    const ip = clientIp(c);
    // Shares the failed-claim budget with guardian claims, so guesses cannot be split across both.
    const wait = claimFailures.blockedFor(ip);
    if (wait > 0) throw tooManyRequests(wait);
    const claimed = await claimCode(deps, code, "watch");
    if (!claimed) {
      claimFailures.hit(ip);
      throw new ApiError(410, "pairing_expired", "Pairing code is invalid, used or expired");
    }
    const device = await createDevice(deps, claimed.seniorId, "watch");
    return c.json({ seniorId: claimed.seniorId, ...device }, 201);
  });

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

  /** Own devices, or (guardian, ?seniorId=) a linked senior's devices. Never returns tokens. */
  app.get("/devices", validate("query", z.object({ seniorId: uuid.optional() })), async (c) => {
    const auth = c.get("auth");
    const { seniorId } = c.req.valid("query");
    if (seniorId) await assertLinked(deps.db, auth, seniorId);
    const rows = await deps.db
      .select()
      .from(devices)
      .where(and(eq(devices.userId, seniorId ?? auth.userId), isNull(devices.revokedAt)))
      .orderBy(asc(devices.createdAt));
    return c.json({
      items: rows.map((d) => ({
        id: d.id,
        kind: d.kind,
        createdAt: d.createdAt,
        lastSeenAt: d.lastSeenAt,
        hasPushToken: d.pushToken !== null,
        isCurrent: d.id === auth.deviceId,
      })),
    });
  });

  /** Revoke one of your other devices, e.g. a lost watch. Its events are kept; it can no longer sign in. */
  app.delete("/devices/:id", validate("param", z.object({ id: uuid })), async (c) => {
    const auth = c.get("auth");
    const { id } = c.req.valid("param");
    if (id === auth.deviceId) throw new ApiError(400, "validation_error", "A device cannot revoke itself");
    const [revoked] = await deps.db
      .update(devices)
      .set({ revokedAt: deps.clock(), pushToken: null })
      .where(and(eq(devices.id, id), eq(devices.userId, auth.userId), isNull(devices.revokedAt)))
      .returning({ id: devices.id });
    if (!revoked) throw new ApiError(404, "not_found", "Device not found");
    // A revoked device must not keep the senior "monitored".
    await deps.db.delete(statusHeartbeats).where(eq(statusHeartbeats.deviceId, id));
    return c.body(null, 204);
  });

  /**
   * The senior deletes their account and all data held for them (devices, configuration, events,
   * alerts, doses, reports, routines). Guardians keep their own accounts but lose the link.
   */
  app.delete(
    "/seniors/:seniorId",
    validate("param", z.object({ seniorId: uuid })),
    validate("json", z.object({ confirm: z.literal("DELETE") })),
    async (c) => {
      const auth = c.get("auth");
      requireRole(auth, "senior");
      const { seniorId } = c.req.valid("param");
      if (auth.userId !== seniorId) throw new ApiError(403, "forbidden", "Not your account");
      await deps.db.delete(users).where(eq(users.id, seniorId));
      return c.body(null, 204);
    },
  );

  /** Either side ends a care relationship; the guardian loses all access to that senior. */
  app.delete(
    "/care-links/:seniorId/:guardianId",
    validate("param", z.object({ seniorId: uuid, guardianId: uuid })),
    async (c) => {
      const auth = c.get("auth");
      const { seniorId, guardianId } = c.req.valid("param");
      if (auth.userId !== seniorId && auth.userId !== guardianId) throw new ApiError(403, "forbidden", "Not your link");
      const deleted = await deps.db
        .delete(careLinks)
        .where(and(eq(careLinks.seniorId, seniorId), eq(careLinks.guardianId, guardianId)))
        .returning();
      if (deleted.length === 0) throw new ApiError(404, "not_found", "Care link not found");
      return c.body(null, 204);
    },
  );

  app.post("/pairing/codes", async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    return c.json(await issueCode(deps, auth.userId), 201);
  });

  /** A short-lived code for the senior's watch; never accepted by `/pairing/claim`. No body. */
  app.post("/pairing/watch-codes", async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    return c.json(await issueCode(deps, auth.userId, "watch"), 201);
  });

  return app;
}

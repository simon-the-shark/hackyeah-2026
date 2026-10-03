import { and, desc, eq, gt, lte } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { vitalSamples } from "../db/schema.js";
import { ApiError } from "../errors.js";
import { bpm, eventSource, isoDate, seniorParam } from "../schemas.js";
import { DEFAULT_WINDOW_MS, MAX_FUTURE_SKEW_MS, VITAL_RETENTION_MS } from "../services/vitals.js";
import type { AppEnv, Deps } from "../types.js";
import { validate } from "../validate.js";

const uploadBody = z.object({
  // No default: an emulator's virtual sensor must say it is simulated.
  source: eventSource.unwrap(),
  heartRate: z.array(z.object({ bpm, measuredAt: isoDate })).min(1).max(500),
});

const rangeQuery = z.object({
  from: isoDate.optional(),
  to: isoDate.optional(),
  limit: z.coerce.number().int().min(1).max(2000).default(1500),
});

const sampleView = (row: typeof vitalSamples.$inferSelect) => ({
  bpm: row.value,
  measuredAt: row.measuredAt,
  source: row.source,
  deviceId: row.deviceId,
});

/** Heart rate from the senior's watch: stored and shown to linked guardians, never evaluated by the server. */
export function vitalsRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();

  app.post("/seniors/:seniorId/vitals", validate("param", seniorParam), validate("json", uploadBody), async (c) => {
    const auth = c.get("auth");
    requireRole(auth, "senior");
    const { seniorId } = c.req.valid("param");
    await assertLinked(db, auth, seniorId);
    const body = c.req.valid("json");

    const now = deps.clock().getTime();
    const outOfRange = body.heartRate
      .map((s, i) => ({ i, t: s.measuredAt.getTime() }))
      .filter(({ t }) => t > now + MAX_FUTURE_SKEW_MS || t < now - VITAL_RETENTION_MS);
    if (outOfRange.length > 0) {
      // The whole batch is rejected so a wrong watch clock is noticed instead of silently thinning the data.
      throw new ApiError(
        400,
        "validation_error",
        "Invalid request",
        outOfRange.map(({ i }) => ({
          path: `heartRate.${i}.measuredAt`,
          message: "Must be at most 5 minutes in the future and at most 7 days old",
        })),
      );
    }

    // One row per instant: a duplicate inside the batch counts like a retried one.
    const unique = new Map<number, { bpm: number; measuredAt: Date }>();
    for (const s of body.heartRate) unique.set(s.measuredAt.getTime(), s);
    const stored = await db
      .insert(vitalSamples)
      .values(
        [...unique.values()].map((s) => ({
          seniorId,
          deviceId: auth.deviceId,
          kind: "heart_rate" as const,
          value: s.bpm,
          measuredAt: s.measuredAt,
          receivedAt: deps.clock(),
          source: body.source,
        })),
      )
      .onConflictDoNothing()
      .returning({ measuredAt: vitalSamples.measuredAt });
    return c.json(
      { stored: stored.length, duplicates: body.heartRate.length - stored.length, serverTime: deps.clock() },
      stored.length > 0 ? 201 : 200,
    );
  });

  app.get(
    "/seniors/:seniorId/vitals/heart-rate",
    validate("param", seniorParam),
    validate("query", rangeQuery),
    async (c) => {
      const { seniorId } = c.req.valid("param");
      await assertLinked(db, c.get("auth"), seniorId);
      const q = c.req.valid("query");
      const now = deps.clock();
      const to = q.to ?? now;
      const from = q.from ?? new Date(to.getTime() - DEFAULT_WINDOW_MS);
      if (to <= from || to.getTime() - from.getTime() > VITAL_RETENTION_MS) {
        throw new ApiError(400, "validation_error", "to must be after from and at most 7 days later");
      }
      const ofSenior = and(eq(vitalSamples.seniorId, seniorId), eq(vitalSamples.kind, "heart_rate"));
      const [latest, windowRows] = await Promise.all([
        db.select().from(vitalSamples).where(ofSenior).orderBy(desc(vitalSamples.measuredAt)).limit(1),
        db
          .select()
          .from(vitalSamples)
          .where(and(ofSenior, gt(vitalSamples.measuredAt, from), lte(vitalSamples.measuredAt, to)))
          .orderBy(desc(vitalSamples.measuredAt))
          .limit(q.limit + 1),
      ]);
      const truncated = windowRows.length > q.limit;
      const items = windowRows.slice(0, q.limit).reverse().map(sampleView);
      return c.json({
        latest: latest[0] ? sampleView(latest[0]) : null,
        items,
        truncated,
        serverTime: now,
      });
    },
  );

  return app;
}

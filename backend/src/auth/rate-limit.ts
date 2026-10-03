import { getConnInfo } from "@hono/node-server/conninfo";
import type { Context } from "hono";
import { createMiddleware } from "hono/factory";
import { ApiError } from "../errors.js";
import type { AppEnv } from "../types.js";

/** Client IP of the TCP connection. Forwarded headers are not trusted (no proxy is assumed). */
export function clientIp(c: Context) {
  try {
    return getConnInfo(c).remote.address ?? "unknown";
  } catch {
    return "unknown"; // no Node socket, e.g. app.request() in tests
  }
}

/**
 * In-memory fixed-window counter per key. Single-process only, which fits the hackathon deployment;
 * counters reset on restart.
 */
export class FixedWindow {
  private readonly hits = new Map<string, { count: number; resetAt: number }>();

  constructor(
    private readonly max: number,
    private readonly windowMs: number,
    private readonly now: () => number,
  ) {}

  /** Seconds until the key may try again, or 0 when it is under the limit. */
  blockedFor(key: string) {
    const entry = this.hits.get(key);
    if (!entry || entry.resetAt <= this.now()) return 0;
    return entry.count >= this.max ? Math.ceil((entry.resetAt - this.now()) / 1000) : 0;
  }

  hit(key: string) {
    const now = this.now();
    const entry = this.hits.get(key);
    if (!entry || entry.resetAt <= now) {
      this.hits.set(key, { count: 1, resetAt: now + this.windowMs });
      if (this.hits.size > 10_000) this.prune(now);
    } else {
      entry.count++;
    }
  }

  private prune(now: number) {
    for (const [key, entry] of this.hits) if (entry.resetAt <= now) this.hits.delete(key);
  }
}

export const tooManyRequests = (retryAfterSeconds: number) =>
  new ApiError(429, "rate_limited", "Too many requests; try again later", { retryAfterSeconds });

/** Counts every request from an IP and rejects with 429 once over the limit. */
export const limitByIp = (limiter: FixedWindow) =>
  createMiddleware<AppEnv>(async (c, next) => {
    const ip = clientIp(c);
    const wait = limiter.blockedFor(ip);
    if (wait > 0) throw tooManyRequests(wait);
    limiter.hit(ip);
    await next();
  });

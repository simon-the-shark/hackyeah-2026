import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { authenticate } from "./auth/middleware.js";
import { ApiError } from "./errors.js";
import { careConfigRoutes } from "./routes/care-config.js";
import { dailyCareRoutes } from "./routes/daily-care.js";
import { identityRoutes, publicIdentityRoutes } from "./routes/identity.js";
import { overviewRoutes } from "./routes/overview.js";
import { routineRoutes } from "./routes/routines.js";
import { safetyRoutes } from "./routes/safety.js";
import { redactBody } from "./log-redaction.js";
import type { AppEnv, Deps } from "./types.js";

const SENSITIVE_HEADERS = new Set(["authorization", "cookie", "proxy-authorization", "set-cookie"]);

function headersForLog(headers: Headers): Record<string, string> {
  const result: Record<string, string> = {};
  headers.forEach((value, name) => {
    result[name] = SENSITIVE_HEADERS.has(name.toLowerCase()) ? "[REDACTED]" : value;
  });
  return result;
}

async function bodyForLog(message: Request | Response): Promise<string | undefined> {
  const body = await message.clone().text();
  if (body === "") return undefined;
  try {
    return JSON.stringify(redactBody(JSON.parse(body)));
  } catch {
    return body;
  }
}

export function createApp(deps: Deps) {
  const app = new Hono<AppEnv>();

  app.use("*", async (c, next) => {
    if (process.env.NODE_ENV === "production") {
      await next();
      return;
    }
    const startedAt = performance.now();
    const requestBody = await bodyForLog(c.req.raw);
    await next();
    console.info("[request]", {
      method: c.req.method,
      url: c.req.url,
      request: {
        headers: headersForLog(c.req.raw.headers),
        body: requestBody,
      },
      response: {
        status: c.res.status,
        headers: headersForLog(c.res.headers),
        body: await bodyForLog(c.res),
      },
      durationMs: Math.round(performance.now() - startedAt),
    });
  });

  app.get("/health", (c) => c.json({ status: "ok" }));

  const v1 = new Hono<AppEnv>();
  v1.route("/", publicIdentityRoutes(deps));
  v1.use("*", authenticate(deps));
  v1.route("/", identityRoutes(deps));
  v1.route("/", careConfigRoutes(deps));
  v1.route("/", safetyRoutes(deps));
  v1.route("/", dailyCareRoutes(deps));
  v1.route("/", overviewRoutes(deps));
  v1.route("/", routineRoutes(deps));
  app.route("/v1", v1);

  app.notFound((c) => c.json({ error: { code: "not_found", message: "Route not found" } }, 404));

  app.onError((err, c) => {
    if (err instanceof ApiError) {
      return c.json({ error: { code: err.code, message: err.message, details: err.details } }, err.status);
    }
    if (err instanceof HTTPException) {
      const code = err.status === 400 ? "validation_error" : "internal_error";
      return c.json({ error: { code, message: err.message } }, err.status);
    }
    console.error("[error]", err);
    return c.json({ error: { code: "internal_error", message: "Internal server error" } }, 500);
  });

  return app;
}

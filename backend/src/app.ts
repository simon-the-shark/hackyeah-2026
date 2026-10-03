import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { authenticate } from "./auth/middleware.js";
import { ApiError } from "./errors.js";
import { careConfigRoutes } from "./routes/care-config.js";
import { dailyCareRoutes } from "./routes/daily-care.js";
import { identityRoutes, publicIdentityRoutes } from "./routes/identity.js";
import { safetyRoutes } from "./routes/safety.js";
import type { AppEnv, Deps } from "./types.js";

export function createApp(deps: Deps) {
  const app = new Hono<AppEnv>();

  app.get("/health", (c) => c.json({ status: "ok" }));

  const v1 = new Hono<AppEnv>();
  v1.route("/", publicIdentityRoutes(deps));
  v1.use("*", authenticate(deps));
  v1.route("/", identityRoutes(deps));
  v1.route("/", careConfigRoutes(deps));
  v1.route("/", safetyRoutes(deps));
  v1.route("/", dailyCareRoutes(deps));
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

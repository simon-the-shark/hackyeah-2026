import { zValidator } from "@hono/zod-validator";
import type { ZodType } from "zod";
import { ApiError } from "./errors.js";

type Target = "json" | "query" | "param";

/** zValidator that reports failures in the API's uniform error shape. */
export const validate = <T extends ZodType, Tg extends Target>(target: Tg, schema: T) =>
  zValidator(target, schema, (result) => {
    if (!result.success) {
      throw new ApiError(
        400,
        "validation_error",
        "Invalid request",
        result.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
      );
    }
  });

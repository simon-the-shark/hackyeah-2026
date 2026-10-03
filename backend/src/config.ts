import { z } from "zod";

const schema = z
  .object({
    PORT: z.coerce.number().int().positive().default(8787),
    DATABASE_URL: z.string().min(1),
    PUSH_PROVIDER: z.enum(["pushkit", "log"]).default("pushkit"),
    /** Path to the AppGallery Connect service-account key JSON (project_id, key_id, sub_account, private_key). */
    PUSH_KIT_KEY_FILE: z.string().optional(),
    HEARTBEAT_STALE_SECONDS: z.coerce.number().int().positive().default(900),
    DOSE_MISSED_GRACE_MINUTES: z.coerce.number().int().positive().default(60),
  })
  .superRefine((env, ctx) => {
    if (env.PUSH_PROVIDER === "pushkit" && !env.PUSH_KIT_KEY_FILE) {
      ctx.addIssue({
        code: "custom",
        path: ["PUSH_KIT_KEY_FILE"],
        message: "PUSH_KIT_KEY_FILE is required when PUSH_PROVIDER=pushkit (set PUSH_PROVIDER=log to opt into simulated push)",
      });
    }
  });

export type Config = z.infer<typeof schema>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const parsed = schema.safeParse(env);
  if (!parsed.success) {
    const details = parsed.error.issues.map((i) => `  ${i.path.join(".")}: ${i.message}`).join("\n");
    throw new Error(`Invalid configuration:\n${details}`);
  }
  return parsed.data;
}

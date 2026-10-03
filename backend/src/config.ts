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
    SOS_REPUSH_SECONDS: z.coerce.number().int().positive().default(300),
    WATCHDOG_INTERVAL_MS: z.coerce.number().int().min(1000).default(30_000),
    LOW_BATTERY_PERCENT: z.coerce.number().int().min(1).max(90).default(15),
    RATE_LIMIT_BOOTSTRAP_PER_MINUTE: z.coerce.number().int().positive().default(10),
    RATE_LIMIT_CLAIM_FAILURES_PER_15MIN: z.coerce.number().int().positive().default(10),
    /** Without a key the wellbeing check-in is unavailable (503), but the server still starts. */
    OPENAI_API_KEY: z.string().optional(),
    OPENAI_CHAT_MODEL: z.string().min(1).default("gpt-6-luna"),
    OPENAI_TRANSCRIBE_MODEL: z.string().min(1).default("gpt-transcribe"),
    /** Speech-to-speech model for the hands-free check-in (Realtime API). */
    OPENAI_REALTIME_MODEL: z.string().min(1).default("gpt-realtime-2.1-mini"),
    OPENAI_REALTIME_VOICE: z.string().min(1).default("marin"),
    WELLBEING_IDLE_MINUTES: z.coerce.number().int().min(1).max(1440).default(20),
    RATE_LIMIT_ASSISTANT_PER_HOUR: z.coerce.number().int().positive().default(120),
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

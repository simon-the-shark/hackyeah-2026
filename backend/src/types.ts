import type { Assistant } from "./assistant/provider.js";
import type { Db } from "./db/client.js";
import type { PushProvider } from "./push/provider.js";

export type Auth = {
  userId: string;
  role: "senior" | "guardian";
  deviceId: string;
};

export type Deps = {
  db: Db;
  push: PushProvider;
  clock: () => Date;
  staleSeconds: number;
  doseGraceMinutes: number;
  /** An unacknowledged SOS is pushed again after this many seconds (up to SOS_MAX_REMINDERS times). */
  sosRepushSeconds: number;
  /** Battery percentage at or below which a heartbeat raises low_battery (once per discharge). */
  lowBatteryPercent: number;
  /** Per-IP limits on the unauthenticated endpoints, and per-senior calls to the paid assistant. */
  rateLimits: { bootstrapPerMinute: number; claimFailuresPer15Min: number; assistantPerHour: number };
  /** Wellbeing check-in assistant; null when none is configured (the endpoints answer 503). */
  assistant: Assistant | null;
  /** An open check-in idle this long is finished (or dropped when the senior never answered) by the watchdog. */
  wellbeingIdleMinutes: number;
};

export type AppEnv = { Variables: { auth: Auth } };

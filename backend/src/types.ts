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
};

export type AppEnv = { Variables: { auth: Auth } };

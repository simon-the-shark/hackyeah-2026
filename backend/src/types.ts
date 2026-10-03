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
};

export type AppEnv = { Variables: { auth: Auth } };

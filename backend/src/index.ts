import { serve } from "@hono/node-server";
import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createDb } from "./db/client.js";
import { HarmonyPushKitProvider } from "./push/harmony-push-kit.js";
import { LogPushProvider } from "./push/log-provider.js";
import { startWatchdog } from "./services/watchdog.js";

const config = loadConfig();
const { db } = createDb(config.DATABASE_URL);
const push =
  config.PUSH_PROVIDER === "pushkit" ? new HarmonyPushKitProvider(config.PUSH_KIT_KEY_FILE!) : new LogPushProvider();
if (push.name === "log") console.warn("[push] PUSH_PROVIDER=log: notifications are SIMULATED, nothing is delivered");

const deps = {
  db,
  push,
  clock: () => new Date(),
  staleSeconds: config.HEARTBEAT_STALE_SECONDS,
  doseGraceMinutes: config.DOSE_MISSED_GRACE_MINUTES,
  sosRepushSeconds: config.SOS_REPUSH_SECONDS,
  lowBatteryPercent: config.LOW_BATTERY_PERCENT,
  rateLimits: {
    bootstrapPerMinute: config.RATE_LIMIT_BOOTSTRAP_PER_MINUTE,
    claimFailuresPer15Min: config.RATE_LIMIT_CLAIM_FAILURES_PER_15MIN,
  },
};
startWatchdog(deps);

serve({ fetch: createApp(deps).fetch, port: config.PORT }, (info) => {
  console.log(`backend listening on :${info.port} (push=${push.name})`);
});

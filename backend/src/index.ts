import { serve } from "@hono/node-server";
import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createDb } from "./db/client.js";
import { HarmonyPushKitProvider } from "./push/harmony-push-kit.js";
import { LogPushProvider } from "./push/log-provider.js";
import { OpenAiAssistant } from "./assistant/openai.js";
import type { Assistant } from "./assistant/provider.js";
import { SimulatedAssistant } from "./assistant/simulated.js";
import { startWatchdog } from "./services/watchdog.js";

const config = loadConfig();
const { db } = createDb(config.DATABASE_URL);
const push =
  config.PUSH_PROVIDER === "pushkit" ? new HarmonyPushKitProvider(config.PUSH_KIT_KEY_FILE!) : new LogPushProvider();
if (push.name === "log") console.warn("[push] PUSH_PROVIDER=log: notifications are SIMULATED, nothing is delivered");

function createAssistant(): Assistant | null {
  if (config.ASSISTANT_PROVIDER === "simulated") {
    console.warn("[assistant] ASSISTANT_PROVIDER=simulated: wellbeing check-ins use SCRIPTED replies, not AI");
    return new SimulatedAssistant();
  }
  if (!config.OPENAI_API_KEY) {
    console.warn("[assistant] OPENAI_API_KEY is not set: the wellbeing assistant is unavailable (503)");
    return null;
  }
  return new OpenAiAssistant({
    apiKey: config.OPENAI_API_KEY,
    chatModel: config.OPENAI_CHAT_MODEL,
    transcribeModel: config.OPENAI_TRANSCRIBE_MODEL,
    ttsModel: config.OPENAI_TTS_MODEL,
    ttsVoice: config.OPENAI_TTS_VOICE,
  });
}

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
    assistantPerHour: config.RATE_LIMIT_ASSISTANT_PER_HOUR,
  },
  assistant: createAssistant(),
  wellbeingIdleMinutes: config.WELLBEING_IDLE_MINUTES,
};
startWatchdog(deps, config.WATCHDOG_INTERVAL_MS);

serve({ fetch: createApp(deps).fetch, port: config.PORT }, (info) => {
  console.log(`backend listening on :${info.port} (push=${push.name}, assistant=${deps.assistant?.name ?? "none"})`);
});

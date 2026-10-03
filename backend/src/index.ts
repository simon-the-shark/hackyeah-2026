import { serve } from "@hono/node-server";
import { WebSocketServer } from "ws";
import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createDb } from "./db/client.js";
import { HarmonyPushKitProvider } from "./push/harmony-push-kit.js";
import { LogPushProvider } from "./push/log-provider.js";
import type { LiveVoice } from "./assistant/live.js";
import { OpenAiAssistant } from "./assistant/openai.js";
import { OpenAiRealtime } from "./assistant/openai-realtime.js";
import type { Assistant } from "./assistant/provider.js";
import { startWatchdog } from "./services/watchdog.js";

const config = loadConfig();
const { db } = createDb(config.DATABASE_URL);
const push =
  config.PUSH_PROVIDER === "pushkit" ? new HarmonyPushKitProvider(config.PUSH_KIT_KEY_FILE!) : new LogPushProvider();
if (push.name === "log") console.warn("[push] PUSH_PROVIDER=log: notifications are SIMULATED, nothing is delivered");

function createAssistant(): Assistant | null {
  if (!config.OPENAI_API_KEY) {
    console.warn("[assistant] OPENAI_API_KEY is not set: the wellbeing assistant is unavailable (503)");
    return null;
  }
  return new OpenAiAssistant({
    apiKey: config.OPENAI_API_KEY,
    chatModel: config.OPENAI_CHAT_MODEL,
    transcribeModel: config.OPENAI_TRANSCRIBE_MODEL,
  });
}

function createLiveVoice(): LiveVoice | null {
  if (!config.OPENAI_API_KEY) return null;
  return new OpenAiRealtime({
    apiKey: config.OPENAI_API_KEY,
    model: config.OPENAI_REALTIME_MODEL,
    voice: config.OPENAI_REALTIME_VOICE,
    transcribeModel: config.OPENAI_TRANSCRIBE_MODEL,
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
  liveVoice: createLiveVoice(),
};
startWatchdog(deps, config.WATCHDOG_INTERVAL_MS);

// Node has no built-in WebSocket server; `ws` handles the upgrades for the live voice route.
const websocket = { server: new WebSocketServer({ noServer: true }) };
serve({ fetch: createApp(deps).fetch, port: config.PORT, websocket }, (info) => {
  console.log(
    `backend listening on :${info.port} (push=${push.name}, assistant=${deps.assistant?.name ?? "none"}, ` +
      `live=${deps.liveVoice?.name ?? "none"})`,
  );
});

import type { PushMessage, PushProvider } from "./provider.js";

/** Explicit opt-in (PUSH_PROVIDER=log). Nothing is delivered; results are 'simulated'. */
export class LogPushProvider implements PushProvider {
  readonly name = "log";
  async send(tokens: string[], message: PushMessage) {
    console.log(`[push:SIMULATED] ${tokens.length} token(s)`, JSON.stringify(message));
    return "simulated" as const;
  }
}

import type { PushStatus } from "../db/schema.js";

export type PushMessage = {
  title: string;
  body: string;
  /** Delivered to the app for deep-linking (alertId, seniorId, kind). */
  data: Record<string, string>;
};

export interface PushProvider {
  readonly name: string;
  /** Resolves with the status to store; must not throw for provider-side failures. */
  send(tokens: string[], message: PushMessage): Promise<Exclude<PushStatus, "none">>;
}

import { and, eq, lt, sql } from "drizzle-orm";
import type { LiveEvent, LiveUpstream } from "../assistant/live.js";
import { wellbeingMessages, wellbeingSessions } from "../db/schema.js";
import { ApiError } from "../errors.js";
import type { Deps } from "../types.js";
import {
  alertSafetyConcern,
  chatContext,
  chatHistory,
  finishSession,
  messageView,
  SESSION_FULL_AT,
  spendAssistantCall,
  type SessionRow,
} from "./wellbeing.js";

/** An assistant transcript waits this long for the senior's transcript of the same turn, to keep the order. */
export const HOLD_ASSISTANT_MS = 3_000;
/** One live connection may last this long. */
export const MAX_LIVE_MS = 20 * 60_000;
/** Larger client audio frames are dropped (about 5 s of 24 kHz PCM16 in base64). */
const MAX_FRAME_CHARS = 256 * 1024;
const BASE64 = /^[A-Za-z0-9+/]*={0,2}$/;

/** The app's end of the connection; frames are JSON text. */
export interface ClientSocket {
  send(data: string): void;
  close(code: number, reason?: string): void;
}

export type LiveTiming = { holdMs: number; maxMs: number };

type ErrorCode = "assistant_unavailable" | "session_closed" | "session_full" | "rate_limited" | "time_limit";

/** The open live connection of each check-in, so a new one replaces the old (per deps, so tests stay apart). */
const connections = new WeakMap<Deps, Map<string, LiveRelay>>();

function registry(deps: Deps) {
  let map = connections.get(deps);
  if (!map) {
    map = new Map();
    connections.set(deps, map);
  }
  return map;
}

/**
 * Relays one hands-free voice connection: app microphone audio to the live model, its audio back to
 * the app, both transcripts into the check-in's messages, and the check-in's end into a report.
 */
export class LiveRelay {
  private upstream: LiveUpstream | null = null;
  private ready = false;
  private ended = false;
  private endRequested = false;
  private finishing = false;
  private nextReplySafety = false;
  /** The current reply sent audio that has not been marked done yet. */
  private replyAudioOpen = false;
  /** Senior turns whose transcript has not arrived yet (item ids). */
  private readonly pendingTranscripts = new Set<string>();
  private held: { text: string; safety: boolean; timer: NodeJS.Timeout } | null = null;
  private readonly maxTimer: NodeJS.Timeout;
  /** Database writes in arrival order, so messages keep the conversation order. */
  private queue: Promise<unknown> = Promise.resolve();

  constructor(
    private readonly deps: Deps,
    private session: SessionRow,
    private readonly userId: string,
    private readonly client: ClientSocket,
    private readonly timing: LiveTiming = { holdMs: HOLD_ASSISTANT_MS, maxMs: MAX_LIVE_MS },
  ) {
    this.maxTimer = setTimeout(() => this.fail("time_limit", "Voice conversations end after 20 minutes", 1000), timing.maxMs);
  }

  /** Connects upstream; replaces an earlier live connection of the same check-in. */
  async start() {
    const map = registry(this.deps);
    map.get(this.session.id)?.end(1000, "Replaced by a new voice connection");
    map.set(this.session.id, this);
    const [ctx, history] = await Promise.all([chatContext(this.deps, this.session), chatHistory(this.deps, this.session.id)]);
    if (this.ended) return;
    this.upstream = this.deps.liveVoice!.connect({ ctx, history, onEvent: (event) => this.onUpstream(event, history.length) });
  }

  onClientMessage(raw: string) {
    if (this.ended) return;
    let msg: { type?: unknown; audio?: unknown };
    try {
      msg = JSON.parse(raw) as typeof msg;
    } catch {
      return;
    }
    if (msg.type === "audio") {
      const audio = msg.audio;
      // After the goodbye nothing more is heard; the summary is being written.
      if (!this.ready || this.endRequested || typeof audio !== "string" || audio.length === 0 || audio.length > MAX_FRAME_CHARS) return;
      if (!BASE64.test(audio)) return;
      this.upstream?.appendAudio(audio);
    } else if (msg.type === "interrupt") {
      this.upstream?.cancelResponse();
    }
  }

  /** The app went away: voice mode ends, the check-in stays open. */
  onClientClose() {
    if (this.ended) return;
    this.ended = true;
    this.flushHeld();
    this.cleanup();
  }

  private send(frame: object) {
    if (this.ended) return;
    try {
      this.client.send(JSON.stringify(frame));
    } catch {
      // The socket closed under us; the close handler cleans up.
    }
  }

  private end(code: number, reason?: string) {
    if (this.ended) return;
    this.ended = true;
    this.cleanup();
    try {
      this.client.close(code, reason);
    } catch {
      // Already closed.
    }
  }

  private fail(code: ErrorCode, message: string, closeCode: number) {
    if (this.ended) return;
    this.flushHeld();
    this.send({ type: "error", code, message });
    this.end(closeCode);
  }

  private cleanup() {
    clearTimeout(this.maxTimer);
    if (this.held) clearTimeout(this.held.timer);
    this.upstream?.close();
    const map = registry(this.deps);
    if (map.get(this.session.id) === this) map.delete(this.session.id);
  }

  private enqueue(task: () => Promise<unknown>) {
    this.queue = this.queue.then(task).catch((err) => {
      console.error("[live] relay step failed", err instanceof Error ? err.message : err);
    });
    return this.queue;
  }

  private onUpstream(event: LiveEvent, historyLength: number) {
    if (this.ended && event.type !== "closed") return;
    switch (event.type) {
      case "ready":
        this.ready = true;
        this.send({ type: "ready" });
        // A new voice check-in has no greeting yet: the model speaks first.
        if (historyLength === 0) this.upstream?.requestResponse();
        break;
      case "speech_started":
        this.send({ type: "speech_started" });
        break;
      case "speech_stopped":
        this.pendingTranscripts.add(event.itemId ?? "unknown");
        this.send({ type: "speech_stopped" });
        try {
          spendAssistantCall(this.deps, this.userId);
        } catch {
          this.fail("rate_limited", "Too many messages in a short time; try again later", 1000);
        }
        break;
      case "user_transcript":
      case "user_transcript_failed": {
        this.settleTranscript(event.itemId);
        const text = event.type === "user_transcript" ? event.transcript.trim() : "";
        void this.enqueue(async () => {
          if (text !== "") await this.storeSenior(text);
          if (this.pendingTranscripts.size === 0) this.flushHeld();
        });
        break;
      }
      case "audio":
        this.replyAudioOpen = true;
        this.send({ type: "audio", audio: event.audio });
        break;
      case "audio_done":
        this.closeReplyAudio();
        break;
      case "assistant_transcript": {
        const safety = this.nextReplySafety;
        this.nextReplySafety = false;
        if (this.pendingTranscripts.size > 0) {
          // The senior's words of this turn are still being transcribed; keep the order.
          this.flushHeld();
          const timer = setTimeout(() => this.flushHeld(), this.timing.holdMs);
          this.held = { text: event.transcript, safety, timer };
        } else {
          void this.enqueue(() => this.storeAssistant(event.transcript, safety));
        }
        break;
      }
      case "tool_call":
        this.onToolCall(event.callId, event.name);
        break;
      case "response_done":
        this.closeReplyAudio();
        if (this.endRequested) void this.finish();
        break;
      case "error":
        if (event.fatal) this.fail("assistant_unavailable", "The voice assistant is unavailable; try again later", 1011);
        break;
      case "closed":
        if (!this.ended && !this.finishing) {
          this.fail("assistant_unavailable", "The voice assistant disconnected; try again later", 1011);
        }
        break;
    }
  }

  private closeReplyAudio() {
    if (!this.replyAudioOpen) return;
    this.replyAudioOpen = false;
    this.send({ type: "audio_done" });
  }

  /** Marks one senior turn as transcribed; without an item id the oldest pending one. */
  private settleTranscript(itemId: string | null) {
    if (itemId && this.pendingTranscripts.delete(itemId)) return;
    const first = this.pendingTranscripts.values().next();
    if (!first.done) this.pendingTranscripts.delete(first.value);
  }

  private flushHeld() {
    const held = this.held;
    if (!held) return;
    this.held = null;
    clearTimeout(held.timer);
    void this.enqueue(() => this.storeAssistant(held.text, held.safety));
  }

  private onToolCall(callId: string, name: string) {
    if (name === "report_safety_concern") {
      this.nextReplySafety = true;
      this.send({ type: "safety_concern" });
      // Keep talking: the model now tells the senior to press SOS or call 112.
      this.upstream?.sendToolResult(callId, JSON.stringify({ ok: true }), true);
      void this.enqueue(() => alertSafetyConcern(this.deps, this.session));
    } else if (name === "end_check_in") {
      this.endRequested = true;
      this.upstream?.sendToolResult(callId, JSON.stringify({ ok: true }), false);
    } else {
      this.upstream?.sendToolResult(callId, JSON.stringify({ error: "unknown tool" }), true);
    }
  }

  private async storeSenior(text: string) {
    const now = this.deps.clock();
    const stored = await this.deps.db.transaction(async (tx) => {
      // Counting in the UPDATE (open sessions only) keeps the limits right with concurrent typed messages.
      const [updated] = await tx
        .update(wellbeingSessions)
        .set({
          seniorMessages: sql`${wellbeingSessions.seniorMessages} + 1`,
          voiceMessages: sql`${wellbeingSessions.voiceMessages} + 1`,
          lastActivityAt: now,
        })
        .where(
          and(
            eq(wellbeingSessions.id, this.session.id),
            eq(wellbeingSessions.status, "open"),
            lt(wellbeingSessions.seniorMessages, SESSION_FULL_AT),
          ),
        )
        .returning();
      if (!updated) return null;
      const [message] = await tx
        .insert(wellbeingMessages)
        .values({ sessionId: this.session.id, role: "senior", text, inputMode: "voice", createdAt: now })
        .returning();
      return { session: updated, message: message! };
    });
    if (!stored) return this.onNotStored();
    this.session = stored.session;
    this.send({ type: "message", message: messageView(stored.message) });
    if (stored.session.seniorMessages >= SESSION_FULL_AT) {
      this.upstream?.cancelResponse();
      this.endRequested = true;
      // Not awaited: this runs inside the write queue, and finishing queues behind it.
      void this.finish();
    }
  }

  private async storeAssistant(text: string, safety: boolean) {
    const now = this.deps.clock();
    const stored = await this.deps.db.transaction(async (tx) => {
      const [updated] = await tx
        .update(wellbeingSessions)
        .set({ lastActivityAt: now })
        .where(and(eq(wellbeingSessions.id, this.session.id), eq(wellbeingSessions.status, "open")))
        .returning();
      if (!updated) return null;
      const [message] = await tx
        .insert(wellbeingMessages)
        .values({ sessionId: this.session.id, role: "assistant", text, safetyConcern: safety, createdAt: now })
        .returning();
      return { session: updated, message: message! };
    });
    if (!stored) return this.onNotStored();
    this.session = stored.session;
    this.send({ type: "message", message: messageView(stored.message) });
  }

  /** The session stopped accepting messages: finished elsewhere, or full. */
  private async onNotStored() {
    const [current] = await this.deps.db
      .select()
      .from(wellbeingSessions)
      .where(eq(wellbeingSessions.id, this.session.id));
    if (!current || current.status !== "open") {
      if (!this.finishing) this.fail("session_closed", "This check-in has finished", 1000);
    } else if (current.seniorMessages >= SESSION_FULL_AT) {
      this.endRequested = true;
      void this.finish();
    }
  }

  /** Summary report, conversation deleted, guardians told; then the connection closes. */
  private async finish() {
    if (this.finishing || this.ended) return;
    this.finishing = true;
    this.flushHeld();
    await this.enqueue(async () => {
      try {
        const [current] = await this.deps.db
          .select()
          .from(wellbeingSessions)
          .where(eq(wellbeingSessions.id, this.session.id));
        if (!current) {
          this.send({ type: "finished", session: null, report: null });
          this.end(1000);
          return;
        }
        const result = await finishSession(this.deps, current, "assistant");
        this.send({ type: "finished", session: result.session, report: result.report });
        this.end(1000);
      } catch (err) {
        const known = err instanceof ApiError && err.code === "assistant_unavailable";
        if (!known) console.error("[live] finishing failed", err instanceof Error ? err.message : err);
        this.fail("assistant_unavailable", "The summary could not be written; the check-in stays open", known ? 1000 : 1011);
      }
    });
    this.finishing = false;
  }
}

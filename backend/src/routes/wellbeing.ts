import { upgradeWebSocket } from "@hono/node-server";
import { and, eq, lt, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { AUDIO_FORMATS } from "../assistant/provider.js";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { wellbeingMessages, wellbeingSessions } from "../db/schema.js";
import { ApiError } from "../errors.js";
import { seniorParam, timezone, uuid } from "../schemas.js";
import type { AppEnv, Auth, Deps } from "../types.js";
import { validate } from "../validate.js";
import {
  alertSafetyConcern,
  assistantStatus,
  callAssistant,
  chatContext,
  chatHistory,
  finishSession,
  guardiansOf,
  liveAvailable,
  messageView,
  requireAssistant,
  SESSION_FULL_AT,
  sessionMessages,
  sessionView,
  spendAssistantCall,
  SUGGEST_FINISH_AT,
  type SessionRow,
} from "../services/wellbeing.js";
import { LiveRelay } from "../services/wellbeing-live.js";

const MAX_AUDIO_BYTES = 2 * 1024 * 1024;
/** Longer transcripts are cut, so one recording cannot crowd out the rest of the conversation. */
const MAX_TRANSCRIPT_CHARS = 2000;

const startBody = z.object({
  language: z.string().trim().min(1).max(35).optional(),
  timezone: timezone.optional(),
  /** The app will talk hands-free over the live connection, which greets the senior itself. */
  voice: z.boolean().optional(),
});

// Exactly one of text or audio: unknown keys are rejected, so both together fail validation.
const messageBody = z.union([
  z.strictObject({ text: z.string().trim().min(1).max(1000) }),
  z.strictObject({
    audio: z.base64().max(Math.ceil(MAX_AUDIO_BYTES / 3) * 4),
    audioFormat: z.enum(AUDIO_FORMATS),
  }),
]);

const finishBody = z.object({ reason: z.enum(["senior", "assistant"]).default("senior") });
const sessionParam = z.object({ seniorId: uuid, sessionId: uuid });

/**
 * Wellbeing check-in: the senior talks or writes with the assistant, and when the check-in ends the
 * guardians get a summary report. The conversation itself is deleted at that point.
 */
export function wellbeingRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();
  /** The checked session of a live upgrade request, handed from the checks to the socket handler. */
  const liveSessions = new WeakMap<Request, SessionRow>();

  async function seniorOnly(auth: Auth, seniorId: string) {
    requireRole(auth, "senior");
    await assertLinked(db, auth, seniorId);
  }

  async function ownSession(seniorId: string, sessionId: string) {
    const [session] = await db
      .select()
      .from(wellbeingSessions)
      .where(and(eq(wellbeingSessions.id, sessionId), eq(wellbeingSessions.seniorId, seniorId)));
    if (!session) throw new ApiError(404, "not_found", "Check-in not found");
    return session;
  }

  async function openSession(seniorId: string) {
    const [session] = await db
      .select()
      .from(wellbeingSessions)
      .where(and(eq(wellbeingSessions.seniorId, seniorId), eq(wellbeingSessions.status, "open")));
    return session ?? null;
  }

  app.get("/seniors/:seniorId/wellbeing/session", validate("param", seniorParam), async (c) => {
    const { seniorId } = c.req.valid("param");
    await seniorOnly(c.get("auth"), seniorId);
    const [session, guardians] = await Promise.all([openSession(seniorId), guardiansOf(deps, seniorId)]);
    const messages = session ? await sessionMessages(deps, session.id) : [];
    return c.json({
      session: session ? sessionView(session) : null,
      messages: messages.map(messageView),
      assistant: assistantStatus(deps),
      guardians,
    });
  });

  /**
   * Starts a check-in with the assistant's greeting, or resumes the open one. With `voice: true` and
   * live voice available, the check-in starts empty: the live connection speaks the greeting.
   */
  app.post(
    "/seniors/:seniorId/wellbeing/sessions",
    validate("param", seniorParam),
    validate("json", startBody),
    async (c) => {
      const auth = c.get("auth");
      const { seniorId } = c.req.valid("param");
      await seniorOnly(auth, seniorId);
      const existing = await openSession(seniorId);
      if (existing) {
        const messages = await sessionMessages(deps, existing.id);
        return c.json({ session: sessionView(existing), messages: messages.map(messageView) }, 200);
      }
      const assistant = requireAssistant(deps);
      const body = c.req.valid("json");
      const settings = { seniorId, language: body.language ?? null, timezone: body.timezone ?? null };
      let greeting: { reply: string } | null = null;
      if (!(body.voice && liveAvailable(deps))) {
        spendAssistantCall(deps, auth.userId);
        greeting = await callAssistant(async () => assistant.reply(await chatContext(deps, settings), []));
      }

      const now = deps.clock();
      const created = await db.transaction(async (tx) => {
        // The partial unique index allows one open check-in per senior; a concurrent start wins.
        const [session] = await tx
          .insert(wellbeingSessions)
          .values({
            ...settings,
            deviceId: auth.deviceId,
            startedAt: now,
            lastActivityAt: now,
            assistant: assistant.name,
            simulated: assistant.simulated,
          })
          .onConflictDoNothing()
          .returning();
        if (!session) return null;
        if (!greeting) return { session, messages: [] };
        const [message] = await tx
          .insert(wellbeingMessages)
          .values({ sessionId: session.id, role: "assistant", text: greeting.reply, createdAt: now })
          .returning();
        return { session, messages: [message!] };
      });
      if (!created) {
        const session = await openSession(seniorId);
        if (!session) throw new ApiError(409, "session_closed", "The check-in ended while starting; start again");
        const messages = await sessionMessages(deps, session.id);
        return c.json({ session: sessionView(session), messages: messages.map(messageView) }, 200);
      }
      return c.json({ session: sessionView(created.session), messages: created.messages.map(messageView) }, 201);
    },
  );

  /** One senior message (typed, or recorded and transcribed) and the assistant's reply. Nothing is stored if the reply fails. */
  app.post(
    "/seniors/:seniorId/wellbeing/sessions/:sessionId/messages",
    validate("param", sessionParam),
    validate("json", messageBody),
    async (c) => {
      const auth = c.get("auth");
      const { seniorId, sessionId } = c.req.valid("param");
      await seniorOnly(auth, seniorId);
      const session = await ownSession(seniorId, sessionId);
      if (session.status !== "open") throw new ApiError(409, "session_closed", "This check-in has finished");
      if (session.seniorMessages >= SESSION_FULL_AT) {
        throw new ApiError(409, "session_full", "This check-in is long enough; please finish it");
      }
      const assistant = requireAssistant(deps);
      const body = c.req.valid("json");

      let text: string;
      let inputMode: "text" | "voice";
      if ("text" in body) {
        text = body.text;
        inputMode = "text";
      } else {
        const audio = new Uint8Array(Buffer.from(body.audio, "base64"));
        if (audio.length === 0 || audio.length > MAX_AUDIO_BYTES) {
          throw new ApiError(400, "validation_error", "Invalid request", [
            { path: "audio", message: "Audio must be between 1 byte and 2 MB" },
          ]);
        }
        if (!assistant.voice) throw new ApiError(503, "assistant_unavailable", "Voice messages are not available");
        spendAssistantCall(deps, auth.userId);
        const transcript = await callAssistant(() => assistant.transcribe(audio, body.audioFormat));
        text = transcript.trim().slice(0, MAX_TRANSCRIPT_CHARS);
        if (text === "") throw new ApiError(422, "no_speech", "No speech was recognised in the recording");
        inputMode = "voice";
      }

      spendAssistantCall(deps, auth.userId);
      const [ctx, history] = await Promise.all([chatContext(deps, session), chatHistory(deps, session.id)]);
      const reply = await callAssistant(() => assistant.reply(ctx, [...history, { role: "senior", text }]));

      const now = deps.clock();
      const stored = await db.transaction(async (tx) => {
        // Counting in the UPDATE (open sessions only) keeps the limits right under concurrent messages.
        const [updated] = await tx
          .update(wellbeingSessions)
          .set({
            seniorMessages: sql`${wellbeingSessions.seniorMessages} + 1`,
            voiceMessages: sql`${wellbeingSessions.voiceMessages} + ${inputMode === "voice" ? 1 : 0}`,
            lastActivityAt: now,
          })
          .where(
            and(
              eq(wellbeingSessions.id, session.id),
              eq(wellbeingSessions.status, "open"),
              lt(wellbeingSessions.seniorMessages, SESSION_FULL_AT),
            ),
          )
          .returning();
        if (!updated) return null;
        const [senior, answer] = await tx
          .insert(wellbeingMessages)
          .values([
            { sessionId: session.id, role: "senior", text, inputMode, createdAt: now },
            {
              sessionId: session.id,
              role: "assistant",
              text: reply.reply,
              safetyConcern: reply.safetyConcern,
              createdAt: now,
            },
          ])
          .returning();
        return { session: updated, senior: senior!, answer: answer! };
      });
      if (!stored) throw new ApiError(409, "session_closed", "This check-in has finished");

      if (reply.safetyConcern) await alertSafetyConcern(deps, stored.session);
      return c.json(
        {
          message: messageView(stored.senior),
          reply: messageView(stored.answer),
          suggestFinish: reply.suggestFinish || stored.session.seniorMessages >= SUGGEST_FINISH_AT,
          safetyConcern: reply.safetyConcern,
        },
        201,
      );
    },
  );

  /** Ends the check-in: summary report for the guardians, conversation deleted. Idempotent. */
  app.post(
    "/seniors/:seniorId/wellbeing/sessions/:sessionId/finish",
    validate("param", sessionParam),
    async (c) => {
      const auth = c.get("auth");
      const { seniorId, sessionId } = c.req.valid("param");
      await seniorOnly(auth, seniorId);
      // The body is optional, so it is parsed here rather than by the JSON validator.
      const raw = await c.req.text();
      let json: unknown = {};
      try {
        json = raw.trim() === "" ? {} : JSON.parse(raw);
      } catch {
        throw new ApiError(400, "validation_error", "Malformed JSON body");
      }
      const parsed = finishBody.safeParse(json);
      if (!parsed.success) {
        throw new ApiError(
          400,
          "validation_error",
          "Invalid request",
          parsed.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
        );
      }
      const session = await ownSession(seniorId, sessionId);
      if (session.status === "open" && session.seniorMessages > 0) spendAssistantCall(deps, auth.userId);
      return c.json(await finishSession(deps, session, parsed.data.reason), 200);
    },
  );

  /**
   * Hands-free voice: the app upgrades to a WebSocket and streams microphone PCM; the backend relays it
   * to the live model and stores both transcripts (protocol in the README, "Live voice").
   */
  app.get(
    "/seniors/:seniorId/wellbeing/sessions/:sessionId/live",
    validate("param", sessionParam),
    async (c, next) => {
      const auth = c.get("auth");
      const { seniorId, sessionId } = c.req.valid("param");
      await seniorOnly(auth, seniorId);
      const session = await ownSession(seniorId, sessionId);
      if (session.status !== "open") throw new ApiError(409, "session_closed", "This check-in has finished");
      if (session.seniorMessages >= SESSION_FULL_AT) {
        throw new ApiError(409, "session_full", "This check-in is long enough; please finish it");
      }
      if (!liveAvailable(deps)) throw new ApiError(503, "assistant_unavailable", "Hands-free voice is not available");
      if (c.req.header("upgrade")?.toLowerCase() !== "websocket") {
        throw new ApiError(400, "validation_error", "Expected a WebSocket upgrade");
      }
      spendAssistantCall(deps, auth.userId);
      liveSessions.set(c.req.raw, session);
      await next();
    },
    upgradeWebSocket((c) => {
      const session = liveSessions.get(c.req.raw)!;
      const userId = c.get("auth").userId;
      let relay: LiveRelay | null = null;
      return {
        onOpen(_event, ws) {
          relay = new LiveRelay(
            deps,
            session,
            userId,
            { send: (data) => ws.send(data), close: (code, reason) => ws.close(code, reason) },
            deps.liveTiming,
          );
          relay.start().catch((err) => {
            console.error("[live] could not start", err instanceof Error ? err.message : err);
            ws.close(1011, "Could not start");
          });
        },
        onMessage(event) {
          if (typeof event.data === "string") relay?.onClientMessage(event.data);
        },
        onClose() {
          relay?.onClientClose();
        },
        onError() {
          relay?.onClientClose();
        },
      };
    }),
  );

  return app;
}

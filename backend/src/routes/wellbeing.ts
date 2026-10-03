import { and, eq, lt, sql } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { AUDIO_FORMATS } from "../assistant/provider.js";
import { assertLinked, requireRole } from "../auth/middleware.js";
import { FixedWindow, tooManyRequests } from "../auth/rate-limit.js";
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
  messageView,
  requireAssistant,
  SESSION_FULL_AT,
  sessionMessages,
  sessionView,
  SUGGEST_FINISH_AT,
} from "../services/wellbeing.js";

const MAX_AUDIO_BYTES = 2 * 1024 * 1024;
/** Longer transcripts are cut, so one recording cannot crowd out the rest of the conversation. */
const MAX_TRANSCRIPT_CHARS = 2000;

const startBody = z.object({
  language: z.string().trim().min(1).max(35).optional(),
  timezone: timezone.optional(),
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
const speechBody = z.object({ text: z.string().trim().min(1).max(1000) });
const sessionParam = z.object({ seniorId: uuid, sessionId: uuid });

/**
 * Wellbeing check-in: the senior talks or writes with the assistant, and when the check-in ends the
 * guardians get a summary report. The conversation itself is deleted at that point.
 */
export function wellbeingRoutes(deps: Deps) {
  const { db } = deps;
  const app = new Hono<AppEnv>();
  const assistantCalls = new FixedWindow(deps.rateLimits.assistantPerHour, 60 * 60_000, () => deps.clock().getTime());

  /** Every paid assistant call counts against the senior's hourly budget. */
  function spendAssistantCall(auth: Auth) {
    const wait = assistantCalls.blockedFor(auth.userId);
    if (wait > 0) throw tooManyRequests(wait);
    assistantCalls.hit(auth.userId);
  }

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

  /** Starts a check-in with the assistant's greeting, or resumes the open one. */
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
      spendAssistantCall(auth);
      const body = c.req.valid("json");
      const settings = { seniorId, language: body.language ?? null, timezone: body.timezone ?? null };
      const greeting = await callAssistant(async () =>
        assistant.reply(await chatContext(deps, settings), []),
      );

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
        const [message] = await tx
          .insert(wellbeingMessages)
          .values({ sessionId: session.id, role: "assistant", text: greeting.reply, createdAt: now })
          .returning();
        return { session, message: message! };
      });
      if (!created) {
        const session = await openSession(seniorId);
        if (!session) throw new ApiError(409, "session_closed", "The check-in ended while starting; start again");
        const messages = await sessionMessages(deps, session.id);
        return c.json({ session: sessionView(session), messages: messages.map(messageView) }, 200);
      }
      return c.json({ session: sessionView(created.session), messages: [messageView(created.message)] }, 201);
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
        spendAssistantCall(auth);
        const transcript = await callAssistant(() => assistant.transcribe(audio, body.audioFormat));
        text = transcript.trim().slice(0, MAX_TRANSCRIPT_CHARS);
        if (text === "") throw new ApiError(422, "no_speech", "No speech was recognised in the recording");
        inputMode = "voice";
      }

      spendAssistantCall(auth);
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
      if (session.status === "open" && session.seniorMessages > 0) spendAssistantCall(auth);
      return c.json(await finishSession(deps, session, parsed.data.reason), 200);
    },
  );

  /** Reads an assistant reply aloud (MP3). Any text works, since the reply may already be deleted after finishing. */
  app.post(
    "/seniors/:seniorId/wellbeing/speech",
    validate("param", seniorParam),
    validate("json", speechBody),
    async (c) => {
      const auth = c.get("auth");
      const { seniorId } = c.req.valid("param");
      await seniorOnly(auth, seniorId);
      const assistant = requireAssistant(deps);
      if (!assistant.voice) throw new ApiError(503, "assistant_unavailable", "Reading aloud is not available");
      spendAssistantCall(auth);
      const audio = await callAssistant(() => assistant.speak(c.req.valid("json").text));
      return c.body(new Uint8Array(audio), 200, { "Content-Type": "audio/mpeg", "Cache-Control": "no-store" });
    },
  );

  return app;
}

import { and, asc, desc, eq, gt, lt, sql } from "drizzle-orm";
import { AssistantError, type Assistant, type Attention, type ChatContext, type ChatTurn, type WellbeingSummary } from "../assistant/provider.js";
import { alerts, careLinks, reports, users, wellbeingMessages, wellbeingSessions } from "../db/schema.js";
import { ApiError } from "../errors.js";
import type { Deps } from "../types.js";
import { pushToGuardians, raiseServerAlert, seniorName, WELLBEING_BODY } from "./alerts.js";

export type SessionRow = typeof wellbeingSessions.$inferSelect;
type MessageRow = typeof wellbeingMessages.$inferSelect;
type ReportRow = typeof reports.$inferSelect;
type FinishReason = NonNullable<SessionRow["finishReason"]>;

/** Past this many senior messages every reply suggests finishing. */
export const SUGGEST_FINISH_AT = 30;
/** A session with this many senior messages accepts no more. */
export const SESSION_FULL_AT = 40;
/** Messages sent to the model as context. */
const HISTORY_LIMIT = 40;
/** A session the assistant could not summarise for this long is closed with a report without summary. */
export const FALLBACK_AFTER_MS = 24 * 60 * 60 * 1000;

export const sessionView = (s: SessionRow) => ({
  id: s.id,
  status: s.status,
  startedAt: s.startedAt,
  lastActivityAt: s.lastActivityAt,
  finishedAt: s.finishedAt,
  finishReason: s.finishReason,
  seniorMessages: s.seniorMessages,
  voiceMessages: s.voiceMessages,
  reportId: s.reportId,
  assistant: s.assistant,
  simulated: s.simulated,
});

export const messageView = (m: MessageRow) => ({
  id: m.id,
  role: m.role,
  text: m.text,
  inputMode: m.inputMode,
  safetyConcern: m.safetyConcern,
  createdAt: m.createdAt,
});

export const assistantStatus = (deps: Deps) => ({
  available: deps.assistant !== null,
  simulated: deps.assistant?.simulated ?? false,
  voice: deps.assistant?.voice ?? false,
});

export function requireAssistant(deps: Deps): Assistant {
  if (!deps.assistant) throw new ApiError(503, "assistant_unavailable", "The wellbeing assistant is not configured");
  return deps.assistant;
}

/** Runs an assistant call; any assistant failure becomes 503 so the caller's state stays unchanged. */
export async function callAssistant<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    if (err instanceof AssistantError) {
      console.warn(`[assistant] ${err.message}`);
      throw new ApiError(503, "assistant_unavailable", "The wellbeing assistant is unavailable; try again later");
    }
    throw err;
  }
}

export async function guardiansOf(deps: Deps, seniorId: string) {
  return deps.db
    .select({ id: users.id, displayName: users.displayName })
    .from(careLinks)
    .innerJoin(users, eq(users.id, careLinks.guardianId))
    .where(eq(careLinks.seniorId, seniorId))
    .orderBy(asc(careLinks.createdAt));
}

function localTime(now: Date, timezone: string | null) {
  if (!timezone) return null;
  try {
    return new Intl.DateTimeFormat("en-GB", { timeZone: timezone, weekday: "long", hour: "2-digit", minute: "2-digit" }).format(now);
  } catch {
    return null;
  }
}

/** Local calendar date of the check-in, used as the report's `period`. */
function localDate(at: Date, timezone: string | null) {
  try {
    return new Intl.DateTimeFormat("en-CA", { timeZone: timezone ?? "UTC" }).format(at);
  } catch {
    return at.toISOString().slice(0, 10);
  }
}

export async function chatContext(deps: Deps, session: Pick<SessionRow, "seniorId" | "language" | "timezone">): Promise<ChatContext> {
  const [name, guardians] = await Promise.all([seniorName(deps, session.seniorId), guardiansOf(deps, session.seniorId)]);
  return {
    seniorName: name,
    guardianNames: guardians.map((g) => g.displayName),
    language: session.language,
    localTime: localTime(deps.clock(), session.timezone),
  };
}

export async function sessionMessages(deps: Deps, sessionId: string) {
  return deps.db
    .select()
    .from(wellbeingMessages)
    .where(eq(wellbeingMessages.sessionId, sessionId))
    .orderBy(asc(wellbeingMessages.seq));
}

/** The newest messages for the model, oldest first. */
export async function chatHistory(deps: Deps, sessionId: string): Promise<ChatTurn[]> {
  const rows = await deps.db
    .select({ role: wellbeingMessages.role, text: wellbeingMessages.text })
    .from(wellbeingMessages)
    .where(eq(wellbeingMessages.sessionId, sessionId))
    .orderBy(desc(wellbeingMessages.seq))
    .limit(HISTORY_LIMIT);
  return rows.reverse();
}

/**
 * Raised once per session when the assistant thinks the senior may need help now. The assistant
 * only tells the senior to use SOS; it never sends one.
 */
export async function alertSafetyConcern(deps: Deps, session: SessionRow) {
  const [claimed] = await deps.db
    .update(wellbeingSessions)
    .set({ safetyAlerted: true })
    .where(and(eq(wellbeingSessions.id, session.id), eq(wellbeingSessions.safetyAlerted, false)))
    .returning({ id: wellbeingSessions.id });
  if (!claimed) return;
  await raiseServerAlert(
    deps,
    session.seniorId,
    "wellbeing",
    `wellbeing:${session.id}`,
    { sessionId: session.id, attention: "urgent", during: "conversation" },
    { source: session.simulated ? "simulated" : "device" },
  );
}

type ReportContent = { summary: WellbeingSummary | null };

function structuredReport(session: SessionRow, finishedAt: Date, reason: FinishReason, { summary }: ReportContent) {
  const meta = {
    sessionId: session.id,
    startedAt: session.startedAt.toISOString(),
    finishedAt: finishedAt.toISOString(),
    finishReason: reason,
    seniorMessages: session.seniorMessages,
    voiceMessages: session.voiceMessages,
    assistant: session.assistant,
  };
  if (!summary) {
    return {
      kind: "wellbeing_chat",
      mood: "unclear",
      energy: "unclear",
      sleep: "unclear",
      pain: "unclear",
      concerns: [],
      attention: "none",
      attentionReason: null,
      language: session.language,
      summaryUnavailable: true,
      ...meta,
    };
  }
  return {
    kind: "wellbeing_chat",
    mood: summary.mood,
    energy: summary.energy,
    sleep: summary.sleep,
    pain: summary.pain,
    concerns: summary.concerns,
    attention: summary.attention,
    attentionReason: summary.attentionReason,
    language: summary.language ?? session.language,
    ...meta,
  };
}

export type FinishResult = { session: ReturnType<typeof sessionView> | null; report: ReportRow | null };

async function finishedResult(deps: Deps, sessionId: string): Promise<FinishResult> {
  const [session] = await deps.db.select().from(wellbeingSessions).where(eq(wellbeingSessions.id, sessionId));
  if (!session) return { session: null, report: null };
  const [report] = session.reportId ? await deps.db.select().from(reports).where(eq(reports.id, session.reportId)) : [];
  return { session: sessionView(session), report: report ?? null };
}

/**
 * Closes the check-in: stores the report, deletes the conversation, then tells the guardians.
 * `summary: null` stores a report without a summary (the assistant failed for a whole day).
 * The finish is claimed atomically, so a concurrent finish returns the first one's result.
 */
async function completeSession(deps: Deps, session: SessionRow, reason: FinishReason, content: ReportContent) {
  const now = deps.clock();
  const outcome = await deps.db.transaction(async (tx) => {
    const [claimed] = await tx
      .update(wellbeingSessions)
      .set({ status: "finished", finishedAt: now, finishReason: reason, lastActivityAt: now })
      .where(and(eq(wellbeingSessions.id, session.id), eq(wellbeingSessions.status, "open")))
      .returning();
    if (!claimed) return null;
    const [report] = await tx
      .insert(reports)
      .values({
        seniorId: claimed.seniorId,
        period: localDate(claimed.startedAt, claimed.timezone),
        structured: structuredReport(claimed, now, reason, content),
        summary: content.summary?.summary ?? null,
        source: !content.summary ? "structured" : claimed.simulated ? "simulated" : "ai",
        createdAt: now,
      })
      .returning();
    const [finished] = await tx
      .update(wellbeingSessions)
      .set({ reportId: report!.id })
      .where(eq(wellbeingSessions.id, claimed.id))
      .returning();
    // Privacy: only the summary outlives the check-in.
    await tx.delete(wellbeingMessages).where(eq(wellbeingMessages.sessionId, claimed.id));
    return { session: finished!, report: report! };
  });
  if (!outcome) return finishedResult(deps, session.id);

  await notifyReport(deps, outcome.session, outcome.report, content.summary?.attention ?? "none");
  return { session: sessionView(outcome.session), report: outcome.report };
}

/** One push per report; urgent ones also raise (or complete) the session's `wellbeing` alert. */
async function notifyReport(deps: Deps, session: SessionRow, report: ReportRow, attention: Attention) {
  const name = await seniorName(deps, session.seniorId);
  let title = attention === "none" ? `${name} shared a wellbeing check-in` : `${name}'s wellbeing check-in: please read soon`;
  if (session.simulated) title = `[Simulation] ${title}`;
  const body =
    report.source === "ai"
      ? WELLBEING_BODY
      : report.source === "simulated"
        ? "Scripted demo summary, not AI. Open the app for details."
        : "The summary could not be written. Open the app for details.";
  await pushToGuardians(
    deps,
    session.seniorId,
    title,
    { reportId: report.id, seniorId: session.seniorId, kind: "wellbeing_report" },
    body,
  );

  const dedupKey = `wellbeing:${session.id}`;
  const structured = report.structured as { attentionReason?: string | null };
  if (attention === "urgent") {
    const raised = await raiseServerAlert(
      deps,
      session.seniorId,
      "wellbeing",
      dedupKey,
      { sessionId: session.id, reportId: report.id, attention, reason: structured.attentionReason ?? null },
      { source: session.simulated ? "simulated" : "device" },
    );
    if (raised) return;
  }
  // An alert raised during the conversation now points at its report.
  await deps.db
    .update(alerts)
    .set({ details: sql`coalesce(${alerts.details}, '{}'::jsonb) || ${JSON.stringify({ reportId: report.id })}::jsonb` })
    .where(eq(alerts.dedupKey, dedupKey));
}

/**
 * Finishes a check-in with the assistant's summary. A session the senior never answered is dropped
 * instead (`session: null`). Throws ApiError 503 when the assistant cannot summarise.
 */
export async function finishSession(deps: Deps, session: SessionRow, reason: FinishReason): Promise<FinishResult> {
  if (session.status === "finished") return finishedResult(deps, session.id);
  if (session.seniorMessages === 0) {
    await deps.db
      .delete(wellbeingSessions)
      .where(and(eq(wellbeingSessions.id, session.id), eq(wellbeingSessions.status, "open")));
    return { session: null, report: null };
  }
  const assistant = requireAssistant(deps);
  const [ctx, history] = await Promise.all([chatContext(deps, session), chatHistory(deps, session.id)]);
  const summary = await callAssistant(() => assistant.summarize(ctx, history));
  return completeSession(deps, session, reason, { summary });
}

/**
 * Watchdog: finishes check-ins left idle for `wellbeingIdleMinutes`, and drops idle ones the senior
 * never answered. When the assistant cannot summarise, the session waits another idle period; after
 * a day it is closed with a report that says the summary is unavailable.
 */
export async function finishIdleWellbeingSessions(deps: Deps) {
  const now = deps.clock();
  const cutoff = new Date(now.getTime() - deps.wellbeingIdleMinutes * 60_000);
  const open = eq(wellbeingSessions.status, "open");
  await deps.db
    .delete(wellbeingSessions)
    .where(and(open, eq(wellbeingSessions.seniorMessages, 0), lt(wellbeingSessions.lastActivityAt, cutoff)));
  const idle = await deps.db
    .select()
    .from(wellbeingSessions)
    .where(and(open, gt(wellbeingSessions.seniorMessages, 0), lt(wellbeingSessions.lastActivityAt, cutoff)))
    .orderBy(asc(wellbeingSessions.lastActivityAt))
    .limit(20);
  let finished = 0;
  for (const session of idle) {
    try {
      await finishSession(deps, session, "idle");
      finished++;
    } catch (err) {
      if (!(err instanceof ApiError && err.code === "assistant_unavailable")) throw err;
      if (now.getTime() - session.startedAt.getTime() >= FALLBACK_AFTER_MS) {
        await completeSession(deps, session, "idle", { summary: null });
        finished++;
      } else {
        await deps.db
          .update(wellbeingSessions)
          .set({ lastActivityAt: now })
          .where(and(eq(wellbeingSessions.id, session.id), open));
      }
    }
  }
  return finished;
}

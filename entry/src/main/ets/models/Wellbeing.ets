// Wellbeing check-in: the senior's chat with the assistant and the summary report the guardian reads.
// Wire shapes follow backend/README.md; every field is checked before use.

export enum ChatRole {
  Assistant = 'assistant',
  Senior = 'senior'
}

export interface RemoteChatMessage {
  id?: string;
  role?: string;
  text?: string;
  inputMode?: string | null;
  safetyConcern?: boolean;
  createdAt?: string;
}

export interface RemoteChatSession {
  id?: string;
  status?: string;
  startedAt?: string;
  seniorMessages?: number;
  voiceMessages?: number;
  simulated?: boolean;
}

export interface RemoteAssistantInfo {
  available?: boolean;
  simulated?: boolean;
  voice?: boolean;
}

export interface RemoteGuardian {
  id?: string;
  displayName?: string;
}

/** `GET /seniors/:id/wellbeing/session`. */
export interface RemoteCheckInState {
  session?: RemoteChatSession | null;
  messages?: RemoteChatMessage[];
  assistant?: RemoteAssistantInfo | null;
  guardians?: RemoteGuardian[];
}

/** `POST .../wellbeing/sessions`. */
export interface RemoteStartedSession {
  session?: RemoteChatSession | null;
  messages?: RemoteChatMessage[];
}

/** `POST .../sessions/:id/messages`. */
export interface RemoteExchange {
  message?: RemoteChatMessage | null;
  reply?: RemoteChatMessage | null;
  suggestFinish?: boolean;
  safetyConcern?: boolean;
}

/** `structured` of a chat report. Older or hand-written reports may lack any of these. */
export interface RemoteReportFields {
  kind?: string;
  mood?: string;
  energy?: string;
  sleep?: string;
  pain?: string;
  concerns?: string[];
  attention?: string;
  attentionReason?: string | null;
  startedAt?: string;
  finishedAt?: string;
  finishReason?: string;
  seniorMessages?: number;
  voiceMessages?: number;
  assistant?: string;
  summaryUnavailable?: boolean;
}

export interface RemoteReport {
  id?: string;
  structured?: RemoteReportFields | null;
  summary?: string | null;
  source?: string;
  createdAt?: string;
}

export interface RemoteReportList {
  items?: RemoteReport[];
}

/** `POST .../sessions/:id/finish`. */
export interface RemoteFinished {
  session?: RemoteChatSession | null;
  report?: RemoteReport | null;
}

export class ChatMessage {
  id: string = '';
  role: ChatRole = ChatRole.Assistant;
  text: string = '';
  /** The senior spoke this message; `text` is the transcript. */
  voice: boolean = false;
  /** The assistant thought the senior may need help now. */
  safetyConcern: boolean = false;
  createdAt: number = 0;
}

export class ChatSession {
  id: string = '';
  startedAt: number = 0;
  seniorMessages: number = 0;
  /** Scripted demo assistant, not AI. */
  simulated: boolean = false;
}

export class AssistantInfo {
  available: boolean = false;
  /** Scripted demo replies instead of a model. */
  simulated: boolean = false;
  /** Speech input and read-aloud work. */
  voice: boolean = false;
}

export class CheckInState {
  session: ChatSession | undefined = undefined;
  messages: ChatMessage[] = [];
  assistant: AssistantInfo = new AssistantInfo();
  guardianNames: string[] = [];
}

export class Exchange {
  message: ChatMessage = new ChatMessage();
  reply: ChatMessage = new ChatMessage();
  suggestFinish: boolean = false;
  safetyConcern: boolean = false;
}

export enum Attention {
  None = 'none',
  Soon = 'soon',
  Urgent = 'urgent'
}

/** How a report rating reads: colour is never the only signal, the label always says it in words. */
export enum RatingTone {
  Good,
  Neutral,
  Concern,
  Unknown
}

export enum ReportTopic {
  Mood = 'mood',
  Energy = 'energy',
  Sleep = 'sleep',
  Pain = 'pain'
}

export const REPORT_TOPICS: ReportTopic[] = [ReportTopic.Mood, ReportTopic.Energy, ReportTopic.Sleep, ReportTopic.Pain];

export class WellbeingReport {
  id: string = '';
  createdAt: number = 0;
  /** Empty when no summary could be written. */
  summary: string = '';
  /** `ai`, `simulated` or `structured`. */
  source: string = '';
  mood: string = 'unclear';
  energy: string = 'unclear';
  sleep: string = 'unclear';
  pain: string = 'unclear';
  concerns: string[] = [];
  attention: Attention = Attention.None;
  attentionReason: string = '';
  /** 0 when unknown. */
  startedAt: number = 0;
  finishedAt: number = 0;
  finishReason: string = '';
  seniorMessages: number = 0;
  voiceMessages: number = 0;
  /** Provider and model that wrote the summary, e.g. "openai:gpt-6-luna". */
  assistantName: string = '';
  summaryUnavailable: boolean = false;
}

function text(value: string | null | undefined): string {
  return typeof value === 'string' ? value : '';
}

function timestamp(value: string | null | undefined): number {
  const parsed = typeof value === 'string' ? Date.parse(value) : NaN;
  return isNaN(parsed) ? 0 : parsed;
}

function rating(value: string | undefined): string {
  return typeof value === 'string' && value !== '' ? value : 'unclear';
}

function count(value: number | undefined): number {
  return typeof value === 'number' && isFinite(value) && value > 0 ? Math.floor(value) : 0;
}

/** Undefined for a message the app cannot show. */
export function chatMessageFrom(dto: RemoteChatMessage | null | undefined): ChatMessage | undefined {
  if (dto === undefined || dto === null || typeof dto.id !== 'string' || typeof dto.text !== 'string') {
    return undefined;
  }
  if (dto.role !== ChatRole.Assistant && dto.role !== ChatRole.Senior) {
    return undefined;
  }
  const message = new ChatMessage();
  message.id = dto.id;
  message.role = dto.role === ChatRole.Senior ? ChatRole.Senior : ChatRole.Assistant;
  message.text = dto.text;
  message.voice = dto.inputMode === 'voice';
  message.safetyConcern = dto.safetyConcern === true;
  message.createdAt = timestamp(dto.createdAt);
  return message;
}

export function chatMessagesFrom(items: RemoteChatMessage[] | undefined): ChatMessage[] {
  const messages: ChatMessage[] = [];
  (Array.isArray(items) ? items : []).forEach((item: RemoteChatMessage) => {
    const message = chatMessageFrom(item);
    if (message !== undefined) {
      messages.push(message);
    }
  });
  return messages;
}

/** Undefined when there is no open session. */
export function chatSessionFrom(dto: RemoteChatSession | null | undefined): ChatSession | undefined {
  if (dto === undefined || dto === null || typeof dto.id !== 'string' || dto.status === 'finished') {
    return undefined;
  }
  const session = new ChatSession();
  session.id = dto.id;
  session.startedAt = timestamp(dto.startedAt);
  session.seniorMessages = count(dto.seniorMessages);
  session.simulated = dto.simulated === true;
  return session;
}

export function checkInStateFrom(dto: RemoteCheckInState): CheckInState {
  const state = new CheckInState();
  state.session = chatSessionFrom(dto.session);
  state.messages = state.session === undefined ? [] : chatMessagesFrom(dto.messages);
  const assistant = dto.assistant;
  if (assistant !== undefined && assistant !== null) {
    state.assistant.available = assistant.available === true;
    state.assistant.simulated = assistant.simulated === true;
    state.assistant.voice = assistant.voice === true;
  }
  (Array.isArray(dto.guardians) ? dto.guardians : []).forEach((guardian: RemoteGuardian) => {
    if (typeof guardian.displayName === 'string' && guardian.displayName.trim() !== '') {
      state.guardianNames.push(guardian.displayName.trim());
    }
  });
  return state;
}

function attentionFrom(value: string | undefined): Attention {
  if (value === Attention.Urgent) {
    return Attention.Urgent;
  }
  return value === Attention.Soon ? Attention.Soon : Attention.None;
}

/** Undefined for a report the app cannot show (no id or time). */
export function wellbeingReportFrom(dto: RemoteReport | null | undefined): WellbeingReport | undefined {
  if (dto === undefined || dto === null || typeof dto.id !== 'string') {
    return undefined;
  }
  const createdAt = timestamp(dto.createdAt);
  if (createdAt === 0) {
    return undefined;
  }
  const report = new WellbeingReport();
  report.id = dto.id;
  report.createdAt = createdAt;
  report.summary = text(dto.summary).trim();
  report.source = text(dto.source);
  const fields = dto.structured;
  if (fields !== undefined && fields !== null && typeof fields === 'object') {
    report.mood = rating(fields.mood);
    report.energy = rating(fields.energy);
    report.sleep = rating(fields.sleep);
    report.pain = rating(fields.pain);
    report.concerns = (Array.isArray(fields.concerns) ? fields.concerns : [])
      .filter((concern: string) => typeof concern === 'string' && concern.trim() !== '')
      .map((concern: string) => concern.trim());
    report.attention = attentionFrom(fields.attention);
    report.attentionReason = text(fields.attentionReason).trim();
    report.startedAt = timestamp(fields.startedAt);
    report.finishedAt = timestamp(fields.finishedAt);
    report.finishReason = text(fields.finishReason);
    report.seniorMessages = count(fields.seniorMessages);
    report.voiceMessages = count(fields.voiceMessages);
    report.assistantName = text(fields.assistant);
    report.summaryUnavailable = fields.summaryUnavailable === true;
  }
  return report;
}

/** Newest first, whatever order the server used. */
export function wellbeingReportsFrom(items: RemoteReport[] | undefined): WellbeingReport[] {
  const reports: WellbeingReport[] = [];
  (Array.isArray(items) ? items : []).forEach((item: RemoteReport) => {
    const report = wellbeingReportFrom(item);
    if (report !== undefined) {
      reports.push(report);
    }
  });
  return reports.sort((a: WellbeingReport, b: WellbeingReport) => b.createdAt - a.createdAt);
}

export function topicTitle(topic: ReportTopic): string {
  if (topic === ReportTopic.Mood) {
    return 'Mood';
  }
  if (topic === ReportTopic.Energy) {
    return 'Energy';
  }
  return topic === ReportTopic.Sleep ? 'Sleep' : 'Pain';
}

export function ratingOf(report: WellbeingReport, topic: ReportTopic): string {
  if (topic === ReportTopic.Mood) {
    return report.mood;
  }
  if (topic === ReportTopic.Energy) {
    return report.energy;
  }
  return topic === ReportTopic.Sleep ? report.sleep : report.pain;
}

/** The rating in words, e.g. "Good", "No pain", "Not discussed". */
export function ratingLabel(topic: ReportTopic, value: string): string {
  if (topic === ReportTopic.Pain) {
    if (value === 'none') {
      return 'No pain';
    }
    if (value === 'mild') {
      return 'Some pain';
    }
    if (value === 'strong') {
      return 'Strong pain';
    }
    return 'Not discussed';
  }
  if (value === 'good') {
    return 'Good';
  }
  if (value === 'okay') {
    return 'Okay';
  }
  if (value === 'low') {
    return 'Low';
  }
  if (value === 'poor') {
    return 'Poor';
  }
  return 'Not discussed';
}

export function ratingTone(topic: ReportTopic, value: string): RatingTone {
  if (topic === ReportTopic.Pain) {
    return value === 'none' ? RatingTone.Good : value === 'mild' ? RatingTone.Neutral :
      value === 'strong' ? RatingTone.Concern : RatingTone.Unknown;
  }
  if (value === 'good') {
    return RatingTone.Good;
  }
  if (value === 'okay') {
    return RatingTone.Neutral;
  }
  return value === 'low' || value === 'poor' ? RatingTone.Concern : RatingTone.Unknown;
}

/** Empty when the report needs no particular attention. */
export function attentionLabel(attention: Attention): string {
  if (attention === Attention.Urgent) {
    return 'May need help now';
  }
  return attention === Attention.Soon ? 'Please read soon' : '';
}

/** Who wrote the summary, so the guardian never mistakes it for the senior's own words or a clinician's. */
export function reportSourceLabel(report: WellbeingReport): string {
  if (report.summaryUnavailable) {
    return 'No summary: the assistant could not write one';
  }
  if (report.source === 'simulated') {
    return 'Demo summary (scripted, not AI)';
  }
  if (report.source === 'ai') {
    const model = report.assistantName.indexOf(':') >= 0 ?
      report.assistantName.substring(report.assistantName.indexOf(':') + 1) : report.assistantName;
    return model === '' ? 'Written by an AI assistant' : `Written by an AI assistant (${model})`;
  }
  return 'Check-in report';
}

/** "Marek", "Marek and Anna", "Marek, Anna and Ewa"; "your guardian" when nobody is linked yet. */
export function guardianNamesText(names: string[]): string {
  if (names.length === 0) {
    return 'your guardian';
  }
  if (names.length === 1) {
    return names[0];
  }
  return `${names.slice(0, names.length - 1).join(', ')} and ${names[names.length - 1]}`;
}

/** "Spoke 3 times, typed twice" style summary of how the senior answered. */
export function answersLabel(report: WellbeingReport): string {
  const typed = Math.max(0, report.seniorMessages - report.voiceMessages);
  const times = (n: number): string => n === 1 ? 'once' : n === 2 ? 'twice' : `${n} times`;
  if (report.seniorMessages === 0) {
    return 'No answers recorded';
  }
  if (report.voiceMessages === 0) {
    return `Typed ${times(typed)}`;
  }
  if (typed === 0) {
    return `Spoke ${times(report.voiceMessages)}`;
  }
  return `Spoke ${times(report.voiceMessages)}, typed ${times(typed)}`;
}

/** How the check-in ended, in words. */
export function finishReasonLabel(reason: string): string {
  if (reason === 'idle') {
    return 'Sent automatically after a pause';
  }
  if (reason === 'assistant') {
    return 'Finished when the conversation ended';
  }
  return reason === 'senior' ? 'Finished by the senior' : '';
}

/** "4 min" for the time between the first and the last message; empty when unknown. */
export function durationLabel(report: WellbeingReport): string {
  if (report.startedAt === 0 || report.finishedAt <= report.startedAt) {
    return '';
  }
  const minutes = Math.max(1, Math.round((report.finishedAt - report.startedAt) / 60000));
  return minutes < 60 ? `${minutes} min` : `${Math.floor(minutes / 60)} h ${minutes % 60} min`;
}

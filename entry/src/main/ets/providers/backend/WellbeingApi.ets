import {
  chatMessageFrom,
  chatMessagesFrom,
  ChatMessage,
  ChatSession,
  chatSessionFrom,
  CheckInState,
  checkInStateFrom,
  Exchange,
  RemoteCheckInState,
  RemoteExchange,
  RemoteFinished,
  RemoteReport,
  RemoteReportList,
  RemoteStartedSession,
  WellbeingReport,
  wellbeingReportFrom,
  wellbeingReportsFrom
} from '../../models/Wellbeing';
import { BackendClient, invalidResponse } from './BackendClient';

class StartBody {
  language: string;
  timezone: string;

  constructor(language: string, timezone: string) {
    this.language = language;
    this.timezone = timezone;
  }
}

class TextBody {
  text: string;

  constructor(text: string) {
    this.text = text;
  }
}

class AudioBody {
  audio: string;
  audioFormat: string;

  constructor(audio: string, audioFormat: string) {
    this.audio = audio;
    this.audioFormat = audioFormat;
  }
}

class FinishBody {
  reason: string;

  constructor(reason: string) {
    this.reason = reason;
  }
}

export class StartedSession {
  readonly session: ChatSession;
  readonly messages: ChatMessage[];

  constructor(session: ChatSession, messages: ChatMessage[]) {
    this.session = session;
    this.messages = messages;
  }
}

/** Why the check-in ended: the senior pressed Finish, or the assistant said goodbye. */
export enum FinishReason {
  Senior = 'senior',
  Assistant = 'assistant'
}

// Wellbeing check-in endpoints. The senior chats and finishes; only guardians read the reports.
export class WellbeingApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  async state(seniorId: string): Promise<CheckInState> {
    return checkInStateFrom(await this.client.get<RemoteCheckInState>(`${this.base(seniorId)}/wellbeing/session`));
  }

  /** Starts a check-in, or returns the one still open with its messages. */
  async start(seniorId: string, language: string, timezone: string): Promise<StartedSession> {
    const dto = await this.client.post<RemoteStartedSession>(`${this.base(seniorId)}/wellbeing/sessions`,
      new StartBody(language, timezone));
    const session = chatSessionFrom(dto.session);
    if (session === undefined) {
      throw invalidResponse('check-in');
    }
    return new StartedSession(session, chatMessagesFrom(dto.messages));
  }

  async sendText(seniorId: string, sessionId: string, text: string): Promise<Exchange> {
    return this.exchange(seniorId, sessionId, new TextBody(text));
  }

  /** `audio` is base64; `format` is the container, e.g. "m4a". */
  async sendVoice(seniorId: string, sessionId: string, audio: string, format: string): Promise<Exchange> {
    return this.exchange(seniorId, sessionId, new AudioBody(audio, format));
  }

  /** The report that was shared, or undefined when there was nothing to report. */
  async finish(seniorId: string, sessionId: string, reason: FinishReason): Promise<WellbeingReport | undefined> {
    const dto = await this.client.post<RemoteFinished>(
      `${this.base(seniorId)}/wellbeing/sessions/${encodeURIComponent(sessionId)}/finish`, new FinishBody(reason));
    return wellbeingReportFrom(dto.report);
  }

  /** MP3 audio of `text` read aloud. */
  async speech(seniorId: string, text: string): Promise<ArrayBuffer> {
    return this.client.postForBytes(`${this.base(seniorId)}/wellbeing/speech`, new TextBody(text));
  }

  /** The senior withdraws a shared summary; guardians no longer see it. */
  async withdraw(seniorId: string, reportId: string): Promise<void> {
    await this.client.delete(`${this.base(seniorId)}/reports/${encodeURIComponent(reportId)}`);
  }

  async reports(seniorId: string, limit: number): Promise<WellbeingReport[]> {
    const list = await this.client.get<RemoteReportList>(`${this.base(seniorId)}/reports?limit=${limit}`);
    if (!Array.isArray(list.items)) {
      throw invalidResponse('report list');
    }
    return wellbeingReportsFrom(list.items);
  }

  async report(seniorId: string, reportId: string): Promise<WellbeingReport> {
    const report = wellbeingReportFrom(await this.client.get<RemoteReport>(
      `${this.base(seniorId)}/reports/${encodeURIComponent(reportId)}`));
    if (report === undefined) {
      throw invalidResponse('report');
    }
    return report;
  }

  private async exchange(seniorId: string, sessionId: string, body: Object): Promise<Exchange> {
    const dto = await this.client.post<RemoteExchange>(
      `${this.base(seniorId)}/wellbeing/sessions/${encodeURIComponent(sessionId)}/messages`, body);
    const message = chatMessageFrom(dto.message);
    const reply = chatMessageFrom(dto.reply);
    if (message === undefined || reply === undefined) {
      throw invalidResponse('reply');
    }
    const exchange = new Exchange();
    exchange.message = message;
    exchange.reply = reply;
    exchange.suggestFinish = dto.suggestFinish === true;
    exchange.safetyConcern = dto.safetyConcern === true || reply.safetyConcern;
    return exchange;
  }

  private base(seniorId: string): string {
    return `/v1/seniors/${encodeURIComponent(seniorId)}`;
  }
}

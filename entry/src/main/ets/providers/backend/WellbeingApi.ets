import {
  chatMessagesFrom,
  ChatMessage,
  ChatSession,
  chatSessionFrom,
  CheckInState,
  checkInStateFrom,
  RemoteCheckInState,
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
  /** The check-in will be spoken: the live connection greets instead of a typed greeting. */
  voice: boolean;

  constructor(language: string, timezone: string, voice: boolean) {
    this.language = language;
    this.timezone = timezone;
    this.voice = voice;
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
  async start(seniorId: string, language: string, timezone: string, voice: boolean): Promise<StartedSession> {
    const dto = await this.client.post<RemoteStartedSession>(`${this.base(seniorId)}/wellbeing/sessions`,
      new StartBody(language, timezone, voice));
    const session = chatSessionFrom(dto.session);
    if (session === undefined) {
      throw invalidResponse('check-in');
    }
    return new StartedSession(session, chatMessagesFrom(dto.messages));
  }

  /** The report that was shared, or undefined when there was nothing to report. */
  async finish(seniorId: string, sessionId: string, reason: FinishReason): Promise<WellbeingReport | undefined> {
    const dto = await this.client.post<RemoteFinished>(
      `${this.base(seniorId)}/wellbeing/sessions/${encodeURIComponent(sessionId)}/finish`, new FinishBody(reason));
    return wellbeingReportFrom(dto.report);
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

  private base(seniorId: string): string {
    return `/v1/seniors/${encodeURIComponent(seniorId)}`;
  }
}

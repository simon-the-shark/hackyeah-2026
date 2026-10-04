import { PAIRING_EXPIRED_DETAIL } from './BackendErrors';
import {
  CareOverview,
  overviewFrom,
  RemoteDoseSchedule,
  RemoteOverview,
  ScheduledDose,
  scheduledDosesFrom,
  withRecordedDoses
} from '../models/CareOverview';
import { ApiError, ApiErrorKind, BackendClient, invalidResponse } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { apiSession } from './CareApi';
import { guardianSessionReady, NOT_GUARDIAN_MESSAGE } from './GuardianContactsService';

/** The backend accepts at most 7 days per `/dose-schedule` request. */
export const DOSE_HISTORY_DAYS: number = 7;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Reads the guardian overview and the senior's recent dose answers. */
export class GuardianOverview {
  async overview(): Promise<CareOverview> {
    const dto = await this.client().get<RemoteOverview>(`${this.senior()}/overview`);
    if (typeof dto.serverTime !== 'string') {
      throw invalidResponse('overview');
    }
    return overviewFrom(dto, Date.now());
  }

  /**
   * Every scheduled dose of the last `DOSE_HISTORY_DAYS` days up to now, with the server's status, plus answers
   * the schedule no longer lists because the medication's times changed afterwards.
   */
  async doseHistory(): Promise<ScheduledDose[]> {
    const to = new Date();
    const from = new Date(to.getTime() - DOSE_HISTORY_DAYS * DAY_MS);
    const range = `?from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}`;
    const client = this.client();
    const lists = await Promise.all([
      client.get<RemoteDoseSchedule>(`${this.senior()}/dose-schedule${range}`),
      client.get<RemoteDoseSchedule>(`${this.senior()}/doses${range}`)
    ]);
    if (!Array.isArray(lists[0].items) || !Array.isArray(lists[1].items)) {
      throw invalidResponse('dose schedule');
    }
    return withRecordedDoses(scheduledDosesFrom(lists[0].items), lists[1].items);
  }

  // Built per call so pairing again or signing out takes effect immediately.
  private client(): BackendClient {
    if (!guardianSessionReady()) {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', NOT_GUARDIAN_MESSAGE);
    }
    return new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token));
  }

  private senior(): string {
    return `/v1/seniors/${encodeURIComponent(apiSession.seniorId)}`;
  }
}

export const guardianOverview: GuardianOverview = new GuardianOverview();

/** `what` names the screen's data, e.g. "the overview". */
export function describeOverviewError(error: Object, what: string): string {
  if (!(error instanceof ApiError)) {
    return `Could not load ${what}.`;
  }
  if (error.kind === ApiErrorKind.Network) {
    return 'Cannot reach the Carely server. Check the internet connection and try again.';
  }
  if (error.status === 401) {
    return PAIRING_EXPIRED_DETAIL;
  }
  if (error.status === 403) {
    return error.message === NOT_GUARDIAN_MESSAGE ? NOT_GUARDIAN_MESSAGE : 'This phone cannot see this senior.';
  }
  return `Could not load ${what}.`;
}

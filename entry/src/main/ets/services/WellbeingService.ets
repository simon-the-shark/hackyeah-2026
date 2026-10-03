import { common } from '@kit.AbilityKit';
import { i18n } from '@kit.LocalizationKit';
import { CheckInState, WellbeingReport } from '../models/Wellbeing';
import { deviceTimeZone } from '../platform/DeviceTimeZone';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { FinishReason, StartedSession, WellbeingApi } from '../providers/backend/WellbeingApi';
import { NOT_CONFIGURED_MESSAGE } from './BackendErrors';
import { apiSession } from './CareApi';
import { guardianSessionReady, NOT_GUARDIAN_MESSAGE } from './GuardianContactsService';
import { SafePreferences } from './SafePreferences';

/** Writing the summary with a model can take a while; the default 15 s is too short. */
const AI_TIMEOUT_MS = 60000;
const STORE_NAME = 'carely_wellbeing';
const REPORT_PAGE = 50;

/** What this phone last shared, kept on the phone because the senior cannot read reports back. */
export class SharedSummary {
  id: string = '';
  summary: string = '';
  createdAt: number = 0;
  guardians: string = '';
}

interface StoredSummary {
  id?: string;
  summary?: string;
  createdAt?: number;
  guardians?: string;
}

function client(): BackendClient {
  return new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token), AI_TIMEOUT_MS);
}

/** BCP 47 tag of the phone's language, a hint for the assistant's first message. */
function deviceLanguage(): string {
  try {
    return i18n.System.getSystemLanguage();
  } catch (error) {
    return 'en';
  }
}

/** The senior's check-in with the assistant. Requests are built per call so re-pairing takes effect at once. */
export class WellbeingCheckIn {
  private readonly store = new SafePreferences(STORE_NAME);

  async state(): Promise<CheckInState> {
    return this.api().state(this.seniorId());
  }

  /** `voice`: the senior will talk hands-free, so the live connection says the greeting. */
  async start(voice: boolean): Promise<StartedSession> {
    return this.api().start(this.seniorId(), deviceLanguage(), deviceTimeZone(), voice);
  }

  /** The paired senior, for the live voice connection. */
  currentSeniorId(): string {
    return this.seniorId();
  }

  async finish(sessionId: string, reason: FinishReason): Promise<WellbeingReport | undefined> {
    return this.api().finish(this.seniorId(), sessionId, reason);
  }

  async withdraw(context: common.Context, reportId: string): Promise<void> {
    await this.api().withdraw(this.seniorId(), reportId);
    await this.store.putStrings(context, { 'lastShared': '' });
  }

  async lastShared(context: common.Context): Promise<SharedSummary | undefined> {
    const raw = await this.store.getString(context, 'lastShared', '');
    if (raw === '') {
      return undefined;
    }
    try {
      const stored = JSON.parse(raw) as StoredSummary;
      if (typeof stored.id !== 'string' || typeof stored.createdAt !== 'number') {
        return undefined;
      }
      const shared = new SharedSummary();
      shared.id = stored.id;
      shared.summary = typeof stored.summary === 'string' ? stored.summary : '';
      shared.createdAt = stored.createdAt;
      shared.guardians = typeof stored.guardians === 'string' ? stored.guardians : '';
      return shared;
    } catch (error) {
      return undefined;
    }
  }

  async rememberShared(context: common.Context, report: WellbeingReport, guardians: string): Promise<void> {
    const shared = new SharedSummary();
    shared.id = report.id;
    shared.summary = report.summary;
    shared.createdAt = report.createdAt;
    shared.guardians = guardians;
    await this.store.putStrings(context, { 'lastShared': JSON.stringify(shared) });
  }

  private api(): WellbeingApi {
    if (!apiSession.configured() || apiSession.role === 'guardian') {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', NOT_CONFIGURED_MESSAGE);
    }
    return new WellbeingApi(client());
  }

  private seniorId(): string {
    return apiSession.seniorId;
  }
}

export const wellbeingCheckIn: WellbeingCheckIn = new WellbeingCheckIn();

/** The guardian's read-only view of the summaries the senior's check-ins produced. */
export class GuardianWellbeing {
  async reports(): Promise<WellbeingReport[]> {
    return this.api().reports(apiSession.seniorId, REPORT_PAGE);
  }

  async report(reportId: string): Promise<WellbeingReport> {
    return this.api().report(apiSession.seniorId, reportId);
  }

  private api(): WellbeingApi {
    if (!guardianSessionReady()) {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', NOT_GUARDIAN_MESSAGE);
    }
    return new WellbeingApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
  }
}

export const guardianWellbeing: GuardianWellbeing = new GuardianWellbeing();

/** Senior-facing wording for a failed check-in call; `fallback` says what could not be done. */
export function describeCheckInError(error: Object, fallback: string): string {
  if (!(error instanceof ApiError)) {
    return fallback;
  }
  if (error.kind === ApiErrorKind.Network) {
    return 'Cannot reach the Carely server. Check the internet connection and try again.';
  }
  if (error.code === 'assistant_unavailable') {
    return 'The assistant is not available right now. Please try again in a few minutes.';
  }
  if (error.code === 'no_speech') {
    return 'Sorry, I could not hear any words. Please try again, a little closer to the phone, or type instead.';
  }
  if (error.code === 'session_closed') {
    return 'This check-in has already ended. You can start a new one.';
  }
  if (error.code === 'session_full') {
    return 'This check-in is already long. Please press Finish to send the summary.';
  }
  if (error.code === 'rate_limited') {
    return 'Too many messages in a short time. Please wait a little and try again.';
  }
  if (error.status === 401 || error.status === 403) {
    return error.message === NOT_CONFIGURED_MESSAGE ? NOT_CONFIGURED_MESSAGE :
      'This phone is not connected to a care plan. Ask your guardian to pair it again.';
  }
  return fallback;
}

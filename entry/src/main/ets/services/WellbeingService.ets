import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SharedCheckIn, StructuredCheckIn } from '../models/Wellbeing';
import { CheckInStore } from '../platform/CheckInStore';
import { ApiError, ApiErrorKind } from '../providers/backend/BackendClient';
import { ReportBody, ReportsApi } from '../providers/backend/ReportsApi';
import { generateEventId } from './CareApi';
import { SeniorAccount, seniorAccount } from './SeniorAccount';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'WellbeingService';
const HISTORY_LIMIT = 30;
// The note is always built from the answers by templates; on-device AI results travel in `structured.aiCheck`.
const SUMMARY_SOURCE = 'structured';

interface SharedCheckInJson {
  localId?: string;
  reportId?: string;
  period?: string;
  sharedAt?: number;
  summary?: string;
  source?: string;
  structured?: StructuredCheckIn;
}

export function encodeSharedCheckIns(items: SharedCheckIn[]): string {
  return JSON.stringify(items.map((item: SharedCheckIn): SharedCheckInJson => ({
    localId: item.localId,
    reportId: item.reportId,
    period: item.period,
    sharedAt: item.sharedAt,
    summary: item.summary,
    source: item.source,
    structured: item.structured
  })));
}

// Skips malformed entries rather than losing the whole history.
export function decodeSharedCheckIns(encoded: string): SharedCheckIn[] {
  try {
    const parsed = JSON.parse(encoded) as SharedCheckInJson[];
    if (!Array.isArray(parsed)) {
      return [];
    }
    const items: SharedCheckIn[] = [];
    parsed.forEach((json: SharedCheckInJson) => {
      if (typeof json.localId === 'string' && typeof json.sharedAt === 'number' && json.structured !== undefined &&
        json.structured !== null) {
        items.push(new SharedCheckIn(json.localId, typeof json.reportId === 'string' ? json.reportId : '',
          typeof json.period === 'string' ? json.period : '', json.sharedAt,
          typeof json.summary === 'string' ? json.summary : '', typeof json.source === 'string' ? json.source : '',
          json.structured));
      }
    });
    return items;
  } catch (err) {
    return [];
  }
}

// The local calendar day of the check-in, sent as the report's `period`.
export function periodOf(date: Date): string {
  const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function isNetworkError(err: Object): boolean {
  return err instanceof ApiError && err.kind === ApiErrorKind.Network;
}

function isPermanentRejection(err: Object): boolean {
  return err instanceof ApiError && err.kind === ApiErrorKind.Http && err.status >= 400 && err.status < 500 &&
    err.status !== 401 && err.status !== 408 && err.status !== 429;
}

// Sends approved check-ins to the guardian, queues them while offline, and withdraws them on request.
// Only the approved facts and summary are sent; the conversation itself never leaves the phone.
export class WellbeingService {
  private readonly account: SeniorAccount;
  private readonly api: ReportsApi;
  private readonly store: CheckInStore;
  private items: SharedCheckIn[] = [];
  private loaded: Promise<void> | undefined = undefined;
  private delivering: Promise<void> | undefined = undefined;

  constructor(account: SeniorAccount, store: CheckInStore) {
    this.account = account;
    this.api = new ReportsApi(account.client);
    this.store = store;
  }

  // Newest first.
  async history(): Promise<SharedCheckIn[]> {
    await this.ensureLoaded();
    return this.items.slice();
  }

  // Shares a check-in. Returns the stored entry: sent, or waiting when the server is unreachable.
  // Other failures (for example an expired pairing) are thrown and nothing is kept.
  async share(facts: StructuredCheckIn, summary: string, now: Date): Promise<SharedCheckIn> {
    await this.ensureLoaded();
    let entry = new SharedCheckIn(generateEventId(), '', periodOf(now), now.getTime(), summary, SUMMARY_SOURCE, facts);
    try {
      entry = entry.withReportId(await this.submit(entry));
    } catch (err) {
      if (!isNetworkError(err as Object)) {
        throw err as Error;
      }
    }
    this.items = [entry].concat(this.items).slice(0, HISTORY_LIMIT);
    await this.persist();
    return entry;
  }

  // Removes a shared check-in for the guardian too. A check-in still waiting is simply not sent.
  async withdraw(localId: string): Promise<void> {
    await this.ensureLoaded();
    const entry = this.items.find((item: SharedCheckIn) => item.localId === localId);
    if (entry === undefined) {
      return;
    }
    if (entry.reportId.length > 0) {
      await this.api.withdraw(await this.account.currentSeniorId(), entry.reportId);
    }
    this.items = this.items.filter((item: SharedCheckIn) => item.localId !== localId);
    await this.persist();
  }

  // Best effort: stops at the first network failure and keeps the rest for later.
  async deliverPending(): Promise<void> {
    await this.ensureLoaded();
    if (this.delivering === undefined) {
      this.delivering = this.deliverQueue().finally(() => {
        this.delivering = undefined;
      });
    }
    return this.delivering;
  }

  private async deliverQueue(): Promise<void> {
    const waiting = this.items.filter((item: SharedCheckIn) => item.reportId.length === 0).reverse();
    let changed = false;
    for (const entry of waiting) {
      try {
        const reportId = await this.submit(entry);
        this.items = this.items.map((item: SharedCheckIn) => item.localId === entry.localId ?
          item.withReportId(reportId) : item);
        changed = true;
      } catch (err) {
        if (isPermanentRejection(err as Object)) {
          hilog.warn(LOG_DOMAIN, LOG_TAG, `Dropping rejected check-in: ${(err as ApiError).code}`);
          this.items = this.items.filter((item: SharedCheckIn) => item.localId !== entry.localId);
          changed = true;
        } else {
          break;
        }
      }
    }
    if (changed) {
      await this.persist();
    }
  }

  private async submit(entry: SharedCheckIn): Promise<string> {
    const seniorId = await this.account.currentSeniorId();
    return this.api.submit(seniorId, new ReportBody(entry.period, entry.structured, entry.summary, entry.source));
  }

  private async ensureLoaded(): Promise<void> {
    if (this.loaded === undefined) {
      this.loaded = this.store.load().then((encoded: string) => {
        this.items = decodeSharedCheckIns(encoded);
      });
    }
    return this.loaded;
  }

  private async persist(): Promise<void> {
    await this.store.save(encodeSharedCheckIns(this.items));
  }
}

let sharedService: WellbeingService | undefined = undefined;

// Undefined until this phone is paired with a Carely care plan.
export function wellbeingService(context: common.Context): WellbeingService | undefined {
  if (sharedService === undefined) {
    const account = seniorAccount();
    if (account !== undefined) {
      sharedService = new WellbeingService(account, new CheckInStore(context));
    }
  }
  return sharedService;
}

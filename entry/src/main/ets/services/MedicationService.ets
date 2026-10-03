import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CatalogProduct, DoseOccurrence, DoseRecord, DoseStatus, Medication } from '../models/Medication';
import { DoseOutboxStore } from '../platform/DoseOutboxStore';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { loadBackendConfig } from '../providers/backend/BackendConfig';
import { CarelyApi } from '../providers/backend/CarelyApi';
import { mergeDoseRecords, startOfDay } from './MedicationSchedule';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'MedicationService';

export class MedicationOverview {
  readonly medications: Medication[];
  // Today's answers by occurrence ID, including ones still waiting to be delivered.
  readonly records: Map<string, DoseRecord>;

  constructor(medications: Medication[], records: Map<string, DoseRecord>) {
    this.medications = medications;
    this.records = records;
  }
}

function isNetworkError(err: Object): boolean {
  return err instanceof ApiError && err.kind === ApiErrorKind.Network;
}

// A rejected record that can never succeed (for example its medication was deleted) is dropped;
// server errors and timeouts are retried later.
function isPermanentRejection(err: Object): boolean {
  return err instanceof ApiError && err.kind === ApiErrorKind.Http && err.status >= 400 && err.status < 500 &&
    err.status !== 401 && err.status !== 408 && err.status !== 429;
}

// Senior medication data from the backend, with dose answers queued on the device while offline.
export class MedicationService {
  private readonly api: CarelyApi;
  private readonly outbox: DoseOutboxStore;
  private pending: DoseRecord[];
  private seniorId: string | undefined = undefined;
  private delivering: Promise<void> | undefined = undefined;

  constructor(api: CarelyApi, outbox: DoseOutboxStore) {
    this.api = api;
    this.outbox = outbox;
    this.pending = outbox.load();
  }

  async loadToday(now: Date): Promise<MedicationOverview> {
    const seniorId = await this.currentSeniorId();
    await this.deliverPending();
    const medications = await this.api.medications(seniorId);
    const server = await this.api.doseRecords(seniorId, startOfDay(now));
    return new MedicationOverview(medications, mergeDoseRecords(server, this.pending));
  }

  // Returns the stored answer. When the backend is unreachable the answer is queued and returned unsynced;
  // other failures are thrown so the UI can tell the senior it was not saved.
  async recordDose(dose: DoseOccurrence, status: DoseStatus, now: Date): Promise<DoseRecord> {
    const record = new DoseRecord(dose.occurrenceId, dose.medication.id, status, dose.scheduledFor.getTime(),
      now.getTime(), false);
    try {
      const seniorId = await this.currentSeniorId();
      return await this.api.recordDose(seniorId, record);
    } catch (err) {
      if (!isNetworkError(err as Object)) {
        throw err as Error;
      }
      await this.enqueue(record);
      return record;
    }
  }

  async lookUpBarcode(barcode: string): Promise<CatalogProduct | undefined> {
    return this.api.catalogProduct(barcode);
  }

  private async currentSeniorId(): Promise<string> {
    if (this.seniorId === undefined) {
      this.seniorId = await this.api.currentSeniorId();
    }
    return this.seniorId;
  }

  private async enqueue(record: DoseRecord): Promise<void> {
    if (!this.pending.some((queued: DoseRecord) => queued.occurrenceId === record.occurrenceId)) {
      this.pending = this.pending.concat([record]);
      await this.outbox.save(this.pending);
    }
  }

  // Best effort: stops at the first network failure and keeps the rest of the queue for the next load.
  private async deliverPending(): Promise<void> {
    if (this.delivering === undefined) {
      this.delivering = this.deliverQueue().finally(() => {
        this.delivering = undefined;
      });
    }
    return this.delivering;
  }

  private async deliverQueue(): Promise<void> {
    if (this.pending.length === 0) {
      return;
    }
    const seniorId = await this.currentSeniorId();
    const batch = this.pending;
    const remaining: DoseRecord[] = [];
    let offline = false;
    for (const record of batch) {
      if (offline) {
        remaining.push(record);
        continue;
      }
      try {
        await this.api.recordDose(seniorId, record);
      } catch (err) {
        if (isPermanentRejection(err as Object)) {
          hilog.warn(LOG_DOMAIN, LOG_TAG, `Dropping rejected dose record: ${(err as ApiError).code}`);
        } else {
          offline = isNetworkError(err as Object);
          remaining.push(record);
        }
      }
    }
    // Keep answers queued by recordDose while this batch was being delivered.
    const queuedMeanwhile = this.pending.filter((record: DoseRecord) => batch.indexOf(record) < 0);
    this.pending = remaining.concat(queuedMeanwhile);
    await this.outbox.save(this.pending);
  }
}

let sharedService: MedicationService | undefined = undefined;

// Undefined until the device has a backend configuration (see entry/backend.example.json).
export function medicationService(context: common.Context): MedicationService | undefined {
  if (sharedService === undefined) {
    const config = loadBackendConfig(context);
    if (config !== undefined) {
      sharedService = new MedicationService(new CarelyApi(new BackendClient(config)), new DoseOutboxStore(context));
    }
  }
  return sharedService;
}

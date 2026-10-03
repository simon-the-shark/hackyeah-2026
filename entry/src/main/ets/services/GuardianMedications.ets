import { CatalogProduct, DoseRecord, Medication } from '../models/Medication';
import { MedicationDraft, MedicationRequestBody } from '../models/MedicationDraft';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { MedicationApi, MedicationConflictError } from '../providers/backend/MedicationApi';
import { apiSession } from './CareApi';

export const NOT_GUARDIAN_MESSAGE = 'This phone is not paired as a guardian. Pair it from the start screen first.';

const HISTORY_DAYS = 14;
const HISTORY_LIMIT = 5;
const DAY_MS = 24 * 60 * 60 * 1000;

export function isGuardianPaired(): boolean {
  return apiSession.configured() && apiSession.role === 'guardian';
}

// Guardian-facing explanation of a failed medication call. `fallback` names what failed.
export function describeGuardianError(err: Object, fallback: string): string {
  if (err instanceof MedicationConflictError) {
    return err.message;
  }
  if (err instanceof ApiError) {
    if (err.kind === ApiErrorKind.Network) {
      return 'Cannot reach the Carely server. Check the connection and try again.';
    }
    if (err.status === 401 || err.status === 403) {
      return NOT_GUARDIAN_MESSAGE;
    }
    if (err.status === 400) {
      return `The server rejected the medication: ${err.message}`;
    }
    return err.message;
  }
  return fallback;
}

// Guardian medication management for the senior linked through pairing. It reuses the senior feature's
// MedicationApi and BackendClient, but authenticates with the paired guardian session (apiSession). The client
// is built per call, so sign-out or re-pairing takes effect immediately.
export class GuardianMedications {
  private api(): MedicationApi {
    if (!isGuardianPaired()) {
      throw new ApiError(ApiErrorKind.Http, 401, 'unauthorized', NOT_GUARDIAN_MESSAGE);
    }
    return new MedicationApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
  }

  async list(): Promise<Medication[]> {
    const items = await this.api().medications(apiSession.seniorId);
    return items.sort((a: Medication, b: Medication) => a.name.localeCompare(b.name));
  }

  // The stored medication, or undefined when it no longer exists.
  async find(id: string): Promise<Medication | undefined> {
    const items = await this.list();
    return items.find((item: Medication) => item.id === id);
  }

  async create(draft: MedicationDraft): Promise<Medication> {
    return this.api().createMedication(apiSession.seniorId, new MedicationRequestBody(draft, false));
  }

  // Throws MedicationConflictError when the draft's version is no longer current.
  async update(draft: MedicationDraft): Promise<Medication> {
    return this.api().updateMedication(apiSession.seniorId, draft.id, new MedicationRequestBody(draft, true));
  }

  async remove(id: string): Promise<void> {
    return this.api().deleteMedication(apiSession.seniorId, id);
  }

  // Undefined when the barcode is not in the (synthetic) catalog. A match is a candidate, never a prescription.
  async lookUpBarcode(barcode: string): Promise<CatalogProduct | undefined> {
    return this.api().catalogProduct(barcode.trim());
  }

  // The last few taken/skipped answers for one medication, newest first.
  async recentDoses(medicationId: string, now: Date): Promise<DoseRecord[]> {
    const records = await this.api().doseRecords(apiSession.seniorId, new Date(now.getTime() - HISTORY_DAYS * DAY_MS));
    return records
      .filter((record: DoseRecord) => record.medicationId === medicationId)
      .sort((a: DoseRecord, b: DoseRecord) => b.recordedAt - a.recordedAt)
      .slice(0, HISTORY_LIMIT);
  }
}

export const guardianMedications: GuardianMedications = new GuardianMedications();

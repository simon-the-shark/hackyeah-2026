import { CatalogProduct, DoseRecord, DoseStatus, Medication } from '../../models/Medication';
import { MedicationRequestBody } from '../../models/MedicationDraft';
import { ApiError, BackendClient, invalidResponse } from './BackendClient';

// Wire shapes from backend/README.md. Fields are optional because the payload is checked before use.
interface MedicationDto {
  id?: string;
  name?: string;
  doseText?: string | null;
  instructions?: string | null;
  barcode?: string | null;
  times?: string[];
  timezone?: string;
  version?: number;
  modelAssetKey?: string | null;
}

interface ConflictDetailsDto {
  current?: MedicationDto | null;
}

interface MedicationListDto {
  items?: MedicationDto[];
}

interface DoseRecordDto {
  occurrenceId?: string;
  medicationId?: string | null;
  status?: string;
  scheduledFor?: string | null;
  recordedAt?: string;
}

interface DoseRecordListDto {
  items?: DoseRecordDto[];
}

interface CatalogDto {
  barcode?: string;
  name?: string;
  isSynthetic?: boolean;
  form?: string | null;
  modelAssetKey?: string | null;
}

// A guardian edit was based on an outdated version (HTTP 409). `current` is the stored copy, or undefined
// when the backend did not include it.
export class MedicationConflictError extends Error {
  readonly current: Medication | undefined;

  constructor(current: Medication | undefined) {
    super('This medication was changed on another device.');
    this.name = 'MedicationConflictError';
    this.current = current;
  }
}

class DoseRecordBody {
  occurrenceId: string;
  medicationId: string;
  status: string;
  scheduledFor: string;
  recordedAt: string;

  constructor(record: DoseRecord) {
    this.occurrenceId = record.occurrenceId;
    this.medicationId = record.medicationId;
    this.status = record.status;
    this.scheduledFor = new Date(record.scheduledFor).toISOString();
    this.recordedAt = new Date(record.recordedAt).toISOString();
  }
}

const TIME_OF_DAY = new RegExp('^([01]\\d|2[0-3]):[0-5]\\d$');

function text(value: string | null | undefined): string {
  return typeof value === 'string' ? value : '';
}

function toMedication(dto: MedicationDto): Medication {
  if (typeof dto.id !== 'string' || typeof dto.name !== 'string' || !Array.isArray(dto.times)) {
    throw invalidResponse('medication');
  }
  // Skip malformed times rather than dropping the whole medicine from the senior's list.
  const times = (dto.times as Object[]).filter((time: Object) => typeof time === 'string' &&
  TIME_OF_DAY.test(time as string)) as string[];
  return new Medication(dto.id, dto.name, text(dto.doseText), text(dto.instructions), text(dto.barcode), times,
    text(dto.timezone), typeof dto.version === 'number' ? dto.version : 0, text(dto.modelAssetKey));
}

function toDoseRecord(dto: DoseRecordDto): DoseRecord | undefined {
  const recordedAt = typeof dto.recordedAt === 'string' ? Date.parse(dto.recordedAt) : NaN;
  const scheduledFor = typeof dto.scheduledFor === 'string' ? Date.parse(dto.scheduledFor) : NaN;
  if (typeof dto.occurrenceId !== 'string' || isNaN(recordedAt)) {
    return undefined;
  }
  // Snoozed records are not final, so the dose still needs an answer.
  const status = dto.status === DoseStatus.Taken ? DoseStatus.Taken :
    dto.status === DoseStatus.Skipped ? DoseStatus.Skipped : undefined;
  if (status === undefined) {
    return undefined;
  }
  return new DoseRecord(dto.occurrenceId, text(dto.medicationId), status, isNaN(scheduledFor) ? recordedAt :
    scheduledFor, recordedAt, true);
}

// Medication endpoints from backend/README.md. Reads work for the linked senior and guardian; writes
// (create, update, delete) are guardian-only on the backend.
export class MedicationApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  async medications(seniorId: string): Promise<Medication[]> {
    const list = await this.client.get<MedicationListDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/medications`);
    if (!Array.isArray(list.items)) {
      throw invalidResponse('medication list');
    }
    return (list.items as MedicationDto[]).map((dto: MedicationDto) => toMedication(dto));
  }

  async createMedication(seniorId: string, body: MedicationRequestBody): Promise<Medication> {
    return toMedication(await this.client.post<MedicationDto>(
      `/v1/seniors/${encodeURIComponent(seniorId)}/medications`, body));
  }

  // `body.version` must be the version the edit is based on; a stale one throws MedicationConflictError.
  async updateMedication(seniorId: string, medicationId: string, body: MedicationRequestBody): Promise<Medication> {
    try {
      return toMedication(await this.client.put<MedicationDto>(
        `/v1/seniors/${encodeURIComponent(seniorId)}/medications/${encodeURIComponent(medicationId)}`, body));
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        const current = (err.details as ConflictDetailsDto | undefined)?.current;
        throw new MedicationConflictError(current === undefined || current === null ? undefined :
          toMedication(current));
      }
      throw err as Error;
    }
  }

  // Already deleted elsewhere (HTTP 404) counts as success: the end state is the same.
  async deleteMedication(seniorId: string, medicationId: string): Promise<void> {
    try {
      await this.client.delete(
        `/v1/seniors/${encodeURIComponent(seniorId)}/medications/${encodeURIComponent(medicationId)}`);
    } catch (err) {
      if (!(err instanceof ApiError && err.status === 404)) {
        throw err as Error;
      }
    }
  }

  // Taken and skipped records whose recordedAt is at or after `since`.
  async doseRecords(seniorId: string, since: Date): Promise<DoseRecord[]> {
    const list = await this.client.get<DoseRecordListDto>(
      `/v1/seniors/${encodeURIComponent(seniorId)}/doses?from=${encodeURIComponent(since.toISOString())}`);
    if (!Array.isArray(list.items)) {
      throw invalidResponse('dose list');
    }
    const records: DoseRecord[] = [];
    (list.items as DoseRecordDto[]).forEach((dto: DoseRecordDto) => {
      const record = toDoseRecord(dto);
      if (record !== undefined) {
        records.push(record);
      }
    });
    return records;
  }

  // Idempotent on occurrenceId: the backend keeps the first final answer and returns it on repeats.
  async recordDose(seniorId: string, record: DoseRecord): Promise<DoseRecord> {
    const stored = await this.client.post<DoseRecordDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/doses`,
      new DoseRecordBody(record));
    return toDoseRecord(stored) ?? record.asSynced();
  }

  // Undefined when the code is not in the catalog (HTTP 404).
  async catalogProduct(barcode: string): Promise<CatalogProduct | undefined> {
    try {
      const dto = await this.client.get<CatalogDto>(`/v1/catalog/${encodeURIComponent(barcode)}`);
      if (typeof dto.barcode !== 'string' || typeof dto.name !== 'string') {
        throw invalidResponse('catalog entry');
      }
      return new CatalogProduct(dto.barcode, dto.name, dto.isSynthetic !== false, text(dto.form),
        text(dto.modelAssetKey));
    } catch (err) {
      if (err instanceof ApiError && err.status === 404) {
        return undefined;
      }
      throw err as Error;
    }
  }
}

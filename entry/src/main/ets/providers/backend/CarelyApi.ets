import { CatalogProduct, DoseRecord, DoseStatus, Medication } from '../../models/Medication';
import { ApiError, ApiErrorKind, BackendClient } from './BackendClient';

// Wire shapes from backend/README.md. Fields are optional because the payload is checked before use.
interface MeDto {
  id?: string;
  role?: string;
}

interface MedicationDto {
  id?: string;
  name?: string;
  doseText?: string | null;
  instructions?: string | null;
  barcode?: string | null;
  times?: string[];
  timezone?: string;
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

function invalid(what: string): ApiError {
  return new ApiError(ApiErrorKind.InvalidResponse, 200, '', `The server sent an unreadable ${what}.`);
}

function text(value: string | null | undefined): string {
  return typeof value === 'string' ? value : '';
}

function toMedication(dto: MedicationDto): Medication {
  if (typeof dto.id !== 'string' || typeof dto.name !== 'string' || !Array.isArray(dto.times)) {
    throw invalid('medication');
  }
  // Skip malformed times rather than dropping the whole medicine from the senior's list.
  const times = (dto.times as Object[]).filter((time: Object) => typeof time === 'string' &&
  TIME_OF_DAY.test(time as string)) as string[];
  return new Medication(dto.id, dto.name, text(dto.doseText), text(dto.instructions), text(dto.barcode), times,
    text(dto.timezone));
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

// Typed access to the senior-side endpoints the medication feature uses.
export class CarelyApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  // The senior this device belongs to. Throws ApiError with status 403 for a guardian device.
  async currentSeniorId(): Promise<string> {
    const me = await this.client.get<MeDto>('/v1/me');
    if (typeof me.id !== 'string') {
      throw invalid('account');
    }
    if (me.role !== 'senior') {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', 'This device is not paired as a senior.');
    }
    return me.id;
  }

  async medications(seniorId: string): Promise<Medication[]> {
    const list = await this.client.get<MedicationListDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/medications`);
    if (!Array.isArray(list.items)) {
      throw invalid('medication list');
    }
    return (list.items as MedicationDto[]).map((dto: MedicationDto) => toMedication(dto));
  }

  // Taken and skipped records whose recordedAt is at or after `since`.
  async doseRecords(seniorId: string, since: Date): Promise<DoseRecord[]> {
    const list = await this.client.get<DoseRecordListDto>(
      `/v1/seniors/${encodeURIComponent(seniorId)}/doses?from=${encodeURIComponent(since.toISOString())}`);
    if (!Array.isArray(list.items)) {
      throw invalid('dose list');
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
        throw invalid('catalog entry');
      }
      return new CatalogProduct(dto.barcode, dto.name, dto.isSynthetic !== false);
    } catch (err) {
      if (err instanceof ApiError && err.status === 404) {
        return undefined;
      }
      throw err as Error;
    }
  }
}

import { DoseOccurrence, DoseRecord, DoseStatus, Medication } from '../models/Medication';

function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function dateKey(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function timeKey(date: Date): string {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

// Times are interpreted in the device's time zone; see Medication.timezone.
export function todaysDoses(medications: Medication[], today: Date): DoseOccurrence[] {
  const day = dateKey(today);
  const doses: DoseOccurrence[] = [];
  medications.forEach((medication: Medication) => {
    medication.times.forEach((time: string) => {
      const hours = Number(time.substring(0, 2));
      const minutes = Number(time.substring(3, 5));
      const scheduledFor = new Date(today.getFullYear(), today.getMonth(), today.getDate(), hours, minutes);
      doses.push(new DoseOccurrence(`${medication.id}@${day}T${time}`, medication, time, scheduledFor));
    });
  });
  return doses.sort((a: DoseOccurrence, b: DoseOccurrence) => a.time.localeCompare(b.time));
}

export function dosesOf(doses: DoseOccurrence[], medicationId: string): DoseOccurrence[] {
  return doses.filter((dose: DoseOccurrence) => dose.medication.id === medicationId);
}

// The first dose still waiting for an answer, including overdue ones, or undefined once all are answered.
export function openDose(doses: DoseOccurrence[], records: Map<string, DoseRecord>): DoseOccurrence | undefined {
  return doses.find((dose: DoseOccurrence) => !records.has(dose.occurrenceId));
}

// The first unanswered dose at or after the current time, or undefined once none remain.
export function nextDose(doses: DoseOccurrence[], now: Date, records: Map<string, DoseRecord>):
  DoseOccurrence | undefined {
  const current = timeKey(now);
  return doses.find((dose: DoseOccurrence) => dose.time >= current && !records.has(dose.occurrenceId));
}

// Medicines ordered by their first unanswered dose; fully answered medicines go last.
export function sortByOpenDose(medications: Medication[], doses: DoseOccurrence[],
  records: Map<string, DoseRecord>): Medication[] {
  const rank = (medication: Medication): string =>
    openDose(dosesOf(doses, medication.id), records)?.time ?? '99:99';
  return medications.slice().sort((a: Medication, b: Medication) => {
    const byTime = rank(a).localeCompare(rank(b));
    return byTime !== 0 ? byTime : a.name.localeCompare(b.name);
  });
}

// The backend keeps the first final answer for an occurrence, so its record wins over a local one.
export function mergeDoseRecords(server: DoseRecord[], pending: DoseRecord[]): Map<string, DoseRecord> {
  const merged = new Map<string, DoseRecord>();
  pending.forEach((record: DoseRecord) => merged.set(record.occurrenceId, record));
  server.forEach((record: DoseRecord) => merged.set(record.occurrenceId, record));
  return merged;
}

interface PendingDoseEntry {
  occurrenceId?: string;
  medicationId?: string;
  status?: string;
  scheduledFor?: number;
  recordedAt?: number;
}

class PendingDoseJson {
  occurrenceId: string;
  medicationId: string;
  status: string;
  scheduledFor: number;
  recordedAt: number;

  constructor(record: DoseRecord) {
    this.occurrenceId = record.occurrenceId;
    this.medicationId = record.medicationId;
    this.status = record.status;
    this.scheduledFor = record.scheduledFor;
    this.recordedAt = record.recordedAt;
  }
}

export function encodePendingDoses(records: DoseRecord[]): string[] {
  return records.map((record: DoseRecord) => JSON.stringify(new PendingDoseJson(record)));
}

// Malformed entries are dropped instead of blocking the rest of the queue.
export function decodePendingDoses(entries: string[]): DoseRecord[] {
  const records: DoseRecord[] = [];
  entries.forEach((entry: string) => {
    try {
      const value = JSON.parse(entry) as PendingDoseEntry;
      const status = value.status === DoseStatus.Taken ? DoseStatus.Taken :
        value.status === DoseStatus.Skipped ? DoseStatus.Skipped : undefined;
      if (typeof value.occurrenceId === 'string' && typeof value.medicationId === 'string' &&
        status !== undefined && typeof value.scheduledFor === 'number' && typeof value.recordedAt === 'number') {
        records.push(new DoseRecord(value.occurrenceId, value.medicationId, status, value.scheduledFor,
          value.recordedAt, false));
      }
    } catch (err) {
      // Not JSON; skip it.
    }
  });
  return records;
}

// GS1 DataMatrix on medicine packs encodes the product number after Application Identifier "01".
const GS1_GTIN = new RegExp('^(?:\\]d2)?\\x1D?01(\\d{14})');

function normalizeProductCode(raw: string): string {
  const value = raw.trim();
  const gs1 = GS1_GTIN.exec(value);
  const code = gs1 !== null && value.length >= 16 ? gs1[1] : value;
  // EAN-13, UPC-A and GTIN-14 forms of the same product differ only by leading zeros.
  return new RegExp('^\\d+$').test(code) ? code.replace(new RegExp('^0+'), '') : code.toUpperCase();
}

export function barcodesMatch(expected: string, scanned: string): boolean {
  const expectedCode = normalizeProductCode(expected);
  return expectedCode.length > 0 && expectedCode === normalizeProductCode(scanned);
}

export function findMedicationByBarcode(medications: Medication[], scanned: string): Medication | undefined {
  return medications.find((medication: Medication) => barcodesMatch(medication.barcode, scanned));
}

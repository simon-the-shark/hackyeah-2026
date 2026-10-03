import { DoseOccurrence, Medication } from '../models/Medication';

function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function dateKey(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function timeKey(date: Date): string {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function todaysDoses(medications: Medication[], today: Date): DoseOccurrence[] {
  const day = dateKey(today);
  const doses: DoseOccurrence[] = [];
  medications.forEach((medication: Medication) => {
    medication.times.forEach((time: string) => {
      doses.push(new DoseOccurrence(`${medication.id}@${day}T${time}`, medication, time));
    });
  });
  return doses.sort((a: DoseOccurrence, b: DoseOccurrence) => a.time.localeCompare(b.time));
}

// The first dose not yet taken at or after the current time, or undefined once none remain.
export function nextDose(doses: DoseOccurrence[], now: Date, taken: Map<string, number>): DoseOccurrence | undefined {
  const current = timeKey(now);
  return doses.find((dose: DoseOccurrence) => dose.time >= current && !taken.has(dose.occurrenceId));
}

// Entries are stored as "occurrenceId|takenAtMillis"; only the given day's records are kept.
export function encodeTakenDoses(taken: Map<string, number>): string[] {
  const entries: string[] = [];
  taken.forEach((takenAt: number, occurrenceId: string) => {
    entries.push(`${occurrenceId}|${takenAt}`);
  });
  return entries;
}

export function decodeTakenDoses(entries: string[], day: string): Map<string, number> {
  const taken = new Map<string, number>();
  entries.forEach((entry: string) => {
    const separator = entry.lastIndexOf('|');
    const occurrenceId = entry.substring(0, separator);
    const takenAt = Number(entry.substring(separator + 1));
    if (separator > 0 && occurrenceId.includes(`@${day}T`) && !isNaN(takenAt)) {
      taken.set(occurrenceId, takenAt);
    }
  });
  return taken;
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

export function findScheduledMedication(doses: DoseOccurrence[], scanned: string): Medication | undefined {
  return doses.find((dose: DoseOccurrence) => barcodesMatch(dose.medication.barcode, scanned))?.medication;
}

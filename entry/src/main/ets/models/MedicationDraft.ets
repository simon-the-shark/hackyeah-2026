import { Medication } from './Medication';

// Limits from the backend's medication schema (backend/src/routes/care-config.ts).
export const MAX_TIMES: number = 12;
export const NAME_MAX: number = 120;
export const DOSE_MAX: number = 200;
export const INSTRUCTIONS_MAX: number = 1000;
export const BARCODE_MAX: number = 64;

// Synthetic code from the backend seed catalog ("Demo Pain Relief 500 mg (synthetic)"). Used only by the
// clearly labelled "Use demo barcode (simulated)" path for emulators without a camera.
export const DEMO_BARCODE: string = '5900000000011';

export const SUGGESTED_TIMES: string[] = ['08:00', '12:00', '18:00', '21:00'];

const TIME_INPUT = new RegExp('^(\\d{1,2})[:.]?(\\d{2})$');
const DIGITS = new RegExp('^\\d+$');

// Normalizes "8:00", "08.00" or "0800" to "HH:MM". Returns '' when the input is not a 24-hour time of day.
export function normalizeTime(input: string): string {
  const match = TIME_INPUT.exec(input.trim());
  if (match === null) {
    return '';
  }
  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  if (hours > 23 || minutes > 59) {
    return '';
  }
  return `${hours < 10 ? '0' : ''}${hours}:${match[2]}`;
}

export function sortTimes(times: string[]): string[] {
  return times.slice().sort((a: string, b: string) => a.localeCompare(b));
}

export function timesLabel(times: string[]): string {
  return times.length === 0 ? 'No dose times' : sortTimes(times).join(' · ');
}

// Digits printed under an EAN/UPC barcode, as typed by the guardian.
export function isValidManualBarcode(input: string): boolean {
  const value = input.trim();
  return value.length > 0 && value.length <= BARCODE_MAX && DIGITS.test(value);
}

export class AddTimeResult {
  readonly times: string[];
  // Empty when the time was added.
  readonly error: string;

  constructor(times: string[], error: string) {
    this.times = times;
    this.error = error;
  }
}

// Adds one dose time to a sorted list, rejecting invalid, duplicate and excess entries.
export function addDoseTime(times: string[], input: string): AddTimeResult {
  const time = normalizeTime(input);
  if (time === '') {
    return new AddTimeResult(times, 'Use 24-hour time, for example 08:00 or 20:30.');
  }
  if (times.indexOf(time) >= 0) {
    return new AddTimeResult(times, `${time} is already in the list.`);
  }
  if (times.length >= MAX_TIMES) {
    return new AddTimeResult(times, `At most ${MAX_TIMES} dose times per medication.`);
  }
  return new AddTimeResult(sortTimes(times.concat([time])), '');
}

// Editable copy of a medication on the guardian's add/edit form.
export class MedicationDraft {
  // Empty for a new medication.
  id: string = '';
  // 0 for a new medication; otherwise the version the edit is based on.
  version: number = 0;
  name: string = '';
  doseText: string = '';
  instructions: string = '';
  barcode: string = '';
  modelAssetKey: string = '';
  times: string[] = [];
  timezone: string = '';

  static fromMedication(medication: Medication): MedicationDraft {
    const draft = new MedicationDraft();
    draft.id = medication.id;
    draft.version = medication.version;
    draft.name = medication.name;
    draft.doseText = medication.doseText;
    draft.instructions = medication.instructions;
    draft.barcode = medication.barcode;
    draft.modelAssetKey = medication.modelAssetKey;
    draft.times = sortTimes(medication.times);
    draft.timezone = medication.timezone;
    return draft;
  }
}

// Per-field problems; every field is empty when the draft can be saved.
export class DraftErrors {
  name: string = '';
  doseText: string = '';
  instructions: string = '';
  times: string = '';
  timezone: string = '';

  isValid(): boolean {
    return this.name === '' && this.doseText === '' && this.instructions === '' && this.times === '' &&
      this.timezone === '';
  }
}

export function validateDraft(draft: MedicationDraft): DraftErrors {
  const errors = new DraftErrors();
  const name = draft.name.trim();
  if (name === '') {
    errors.name = 'Enter the medicine name.';
  } else if (name.length > NAME_MAX) {
    errors.name = `Use at most ${NAME_MAX} characters.`;
  }
  if (draft.doseText.trim().length > DOSE_MAX) {
    errors.doseText = `Use at most ${DOSE_MAX} characters.`;
  }
  if (draft.instructions.trim().length > INSTRUCTIONS_MAX) {
    errors.instructions = `Use at most ${INSTRUCTIONS_MAX} characters.`;
  }
  if (draft.times.length === 0) {
    errors.times = 'Add at least one dose time.';
  } else if (draft.times.length > MAX_TIMES || draft.times.some((time: string) => normalizeTime(time) !== time)) {
    errors.times = 'Dose times must be 24-hour HH:MM values.';
  }
  if (draft.timezone.trim() === '') {
    errors.timezone = 'The time zone is unknown.';
  }
  return errors;
}

// JSON body for POST/PUT /v1/seniors/:id/medications. Empty optional fields are omitted, which the
// backend stores as null on PUT, so clearing a field in the form clears it on the server.
export class MedicationRequestBody {
  name: string;
  doseText?: string;
  instructions?: string;
  barcode?: string;
  modelAssetKey?: string;
  times: string[];
  timezone: string;
  version?: number;

  constructor(draft: MedicationDraft, includeVersion: boolean) {
    this.name = draft.name.trim();
    const dose = draft.doseText.trim();
    if (dose !== '') {
      this.doseText = dose;
    }
    const instructions = draft.instructions.trim();
    if (instructions !== '') {
      this.instructions = instructions;
    }
    const barcode = draft.barcode.trim();
    if (barcode !== '') {
      this.barcode = barcode;
    }
    if (draft.modelAssetKey !== '') {
      this.modelAssetKey = draft.modelAssetKey;
    }
    this.times = sortTimes(draft.times);
    this.timezone = draft.timezone.trim();
    if (includeVersion) {
      this.version = draft.version;
    }
  }
}

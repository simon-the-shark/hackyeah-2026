// A medicine on the senior's care plan, as configured by the guardian on the backend.
export class Medication {
  readonly id: string;
  readonly name: string;
  // User-confirmed dose text; never inferred from a barcode. Empty when the guardian left it out.
  readonly doseText: string;
  readonly instructions: string;
  // Product code printed on the box; the scanned code is compared against it. Empty when unknown.
  readonly barcode: string;
  // Local dose times in 24-hour "HH:mm" format.
  readonly times: string[];
  // IANA time zone the times are expressed in.
  readonly timezone: string;

  constructor(id: string, name: string, doseText: string, instructions: string, barcode: string, times: string[],
    timezone: string) {
    this.id = id;
    this.name = name;
    this.doseText = doseText;
    this.instructions = instructions;
    this.barcode = barcode;
    this.times = times;
    this.timezone = timezone;
  }
}

export class DoseOccurrence {
  // Stable per medication, day and time, so repeated taps and retries are deduplicated by the backend.
  readonly occurrenceId: string;
  readonly medication: Medication;
  readonly time: string;
  // Scheduled moment in device-local time.
  readonly scheduledFor: Date;

  constructor(occurrenceId: string, medication: Medication, time: string, scheduledFor: Date) {
    this.occurrenceId = occurrenceId;
    this.medication = medication;
    this.time = time;
    this.scheduledFor = scheduledFor;
  }
}

export enum DoseStatus {
  Taken = 'taken',
  Skipped = 'skipped'
}

// What the senior recorded for one dose occurrence.
export class DoseRecord {
  readonly occurrenceId: string;
  readonly medicationId: string;
  readonly status: DoseStatus;
  readonly scheduledFor: number;
  readonly recordedAt: number;
  // False while the record is stored on the device and still waiting to reach the backend.
  readonly synced: boolean;

  constructor(occurrenceId: string, medicationId: string, status: DoseStatus, scheduledFor: number,
    recordedAt: number, synced: boolean) {
    this.occurrenceId = occurrenceId;
    this.medicationId = medicationId;
    this.status = status;
    this.scheduledFor = scheduledFor;
    this.recordedAt = recordedAt;
    this.synced = synced;
  }

  asSynced(): DoseRecord {
    return new DoseRecord(this.occurrenceId, this.medicationId, this.status, this.scheduledFor, this.recordedAt,
      true);
  }
}

// Product found in the backend's barcode catalog. A catalog entry is a candidate, never a prescription.
export class CatalogProduct {
  readonly barcode: string;
  readonly name: string;
  readonly isSynthetic: boolean;

  constructor(barcode: string, name: string, isSynthetic: boolean) {
    this.barcode = barcode;
    this.name = name;
    this.isSynthetic = isSynthetic;
  }
}

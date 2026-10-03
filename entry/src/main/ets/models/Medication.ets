export class Medication {
  readonly id: string;
  readonly name: string;
  readonly doseText: string;
  readonly instructions: string;
  // Product code printed on the box; the scanned code is compared against it.
  readonly barcode: string;
  // Local dose times in 24-hour "HH:mm" format.
  readonly times: string[];
  readonly photo?: Resource;

  constructor(id: string, name: string, doseText: string, instructions: string, barcode: string, times: string[],
    photo?: Resource) {
    this.id = id;
    this.name = name;
    this.doseText = doseText;
    this.instructions = instructions;
    this.barcode = barcode;
    this.times = times;
    this.photo = photo;
  }
}

export class DoseOccurrence {
  // Stable per medication, day and time so dose records can be deduplicated later.
  readonly occurrenceId: string;
  readonly medication: Medication;
  readonly time: string;

  constructor(occurrenceId: string, medication: Medication, time: string) {
    this.occurrenceId = occurrenceId;
    this.medication = medication;
    this.time = time;
  }
}

// Synthetic demo medicines. The 200-prefixed codes are GS1 restricted-circulation
// numbers, so they never identify a real product. Replace with the backend
// medication schedule once it is available. Photos are generic illustrations.
export const DEMO_MEDICATIONS: Medication[] = [
  new Medication('demo-metformin', 'Metformin', '500 mg · 1 tablet', 'With breakfast and dinner',
    '2000000001012', ['08:00', '19:00'], $r('app.media.med_metformin')),
  new Medication('demo-vitamin-d', 'Vitamin D3', '2000 IU · 1 capsule', 'With lunch', '2000000002026', ['13:00'],
    $r('app.media.med_vitamin_d')),
  new Medication('demo-atorvastatin', 'Atorvastatin', '20 mg · 1 tablet', 'In the evening', '2000000003030',
    ['21:00'], $r('app.media.med_atorvastatin'))
];

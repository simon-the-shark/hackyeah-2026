import { describe, it, expect } from '@ohos/hypium';
import { Medication } from '../main/ets/models/Medication';
import {
  addDoseTime,
  isValidManualBarcode,
  MAX_TIMES,
  MedicationDraft,
  MedicationRequestBody,
  normalizeTime,
  validateDraft
} from '../main/ets/models/MedicationDraft';

function draft(): MedicationDraft {
  const value = new MedicationDraft();
  value.name = '  Vitamin D ';
  value.doseText = '1 capsule';
  value.times = ['20:00', '08:00'];
  value.timezone = 'Europe/Warsaw';
  return value;
}

export default function medicationDraftTest() {
  describe('medicationDraft', () => {
    it('normalizesTimeInput', 0, () => {
      expect(normalizeTime('8:00')).assertEqual('08:00');
      expect(normalizeTime(' 20.30 ')).assertEqual('20:30');
      expect(normalizeTime('0745')).assertEqual('07:45');
      expect(normalizeTime('23:59')).assertEqual('23:59');
      expect(normalizeTime('24:00')).assertEqual('');
      expect(normalizeTime('12:60')).assertEqual('');
      expect(normalizeTime('noon')).assertEqual('');
      expect(normalizeTime('')).assertEqual('');
    });

    it('addsSortedUniqueTimes', 0, () => {
      const added = addDoseTime(['20:00'], '8:00');
      expect(added.error).assertEqual('');
      expect(added.times.join(',')).assertEqual('08:00,20:00');
      expect(addDoseTime(added.times, '08:00').error.length > 0).assertTrue();
      expect(addDoseTime(added.times, '25:00').error.length > 0).assertTrue();
      const full: string[] = [];
      for (let hour = 0; hour < MAX_TIMES; hour++) {
        full.push(normalizeTime(`${hour}:00`));
      }
      const rejected = addDoseTime(full, '23:00');
      expect(rejected.error.length > 0).assertTrue();
      expect(rejected.times.length).assertEqual(MAX_TIMES);
    });

    it('validatesRequiredFields', 0, () => {
      expect(validateDraft(draft()).isValid()).assertTrue();
      const empty = new MedicationDraft();
      const errors = validateDraft(empty);
      expect(errors.isValid()).assertFalse();
      expect(errors.name.length > 0).assertTrue();
      expect(errors.times.length > 0).assertTrue();
      expect(errors.timezone.length > 0).assertTrue();
      const badTime = draft();
      badTime.times = ['8:00'];
      expect(validateDraft(badTime).times.length > 0).assertTrue();
    });

    it('mapsNewDraftToCreateBody', 0, () => {
      const value = draft();
      value.instructions = '   ';
      value.barcode = '5900000000011';
      const body = new MedicationRequestBody(value, false);
      expect(body.name).assertEqual('Vitamin D');
      expect(body.doseText).assertEqual('1 capsule');
      expect(body.instructions).assertUndefined();
      expect(body.barcode).assertEqual('5900000000011');
      expect(body.modelAssetKey).assertUndefined();
      expect(body.times.join(',')).assertEqual('08:00,20:00');
      expect(body.version).assertUndefined();
      expect(JSON.stringify(body)).assertEqual('{"name":"Vitamin D","doseText":"1 capsule",' +
        '"barcode":"5900000000011","times":["08:00","20:00"],"timezone":"Europe/Warsaw"}');
    });

    it('keepsVersionAndStoredFieldsOnEdit', 0, () => {
      const stored = new Medication('m1', 'Demo', '', 'After food', '5900000000028', ['20:00', '08:00'],
        'Europe/Warsaw', 3, 'pill-oval');
      const value = MedicationDraft.fromMedication(stored);
      expect(value.times.join(',')).assertEqual('08:00,20:00');
      const body = new MedicationRequestBody(value, true);
      expect(body.version).assertEqual(3);
      expect(body.doseText).assertUndefined();
      expect(body.instructions).assertEqual('After food');
      expect(body.barcode).assertEqual('5900000000028');
      expect(body.modelAssetKey).assertEqual('pill-oval');
      expect(body.timezone).assertEqual('Europe/Warsaw');
    });

    it('acceptsOnlyDigitBarcodes', 0, () => {
      expect(isValidManualBarcode(' 5900000000011 ')).assertTrue();
      expect(isValidManualBarcode('59000-11')).assertFalse();
      expect(isValidManualBarcode('')).assertFalse();
    });
  });
}

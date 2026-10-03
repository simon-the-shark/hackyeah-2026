import { describe, it, expect } from '@ohos/hypium';
import { DoseOccurrence, DoseRecord, DoseStatus, Medication } from '../main/ets/models/Medication';
import {
  barcodesMatch,
  decodePendingDoses,
  dosesOf,
  encodePendingDoses,
  findMedicationByBarcode,
  mergeDoseRecords,
  nextDose,
  openDose,
  sortByOpenDose,
  todaysDoses
} from '../main/ets/services/MedicationSchedule';

const ZONE = 'Europe/Warsaw';
const MEDICATIONS: Medication[] = [
  new Medication('evening', 'Evening', '1 tablet', '', '2000000001012', ['21:00'], ZONE),
  new Medication('twice', 'Twice', '1 tablet', '', '2000000002026', ['19:00', '08:00'], ZONE)
];
const NOON = new Date(2026, 9, 3, 12, 0);

function record(occurrenceId: string, status: DoseStatus, synced: boolean): DoseRecord {
  return new DoseRecord(occurrenceId, 'twice', status, 1791012345000, 1791012346000, synced);
}

export default function medicationScheduleTest() {
  describe('medicationSchedule', () => {
    it('ordersTodaysDosesByTime', 0, () => {
      const doses = todaysDoses(MEDICATIONS, NOON);
      expect(doses.map((dose: DoseOccurrence) => dose.time).join(',')).assertEqual('08:00,19:00,21:00');
      expect(doses[0].occurrenceId).assertEqual('twice@2026-10-03T08:00');
      expect(doses[0].scheduledFor.getTime()).assertEqual(new Date(2026, 9, 3, 8, 0).getTime());
    });

    it('findsNextUnansweredDose', 0, () => {
      const doses = todaysDoses(MEDICATIONS, NOON);
      const none = new Map<string, DoseRecord>();
      expect(nextDose(doses, NOON, none)?.time).assertEqual('19:00');
      expect(nextDose(doses, new Date(2026, 9, 3, 19, 0), none)?.time).assertEqual('19:00');
      expect(nextDose(doses, new Date(2026, 9, 3, 22, 0), none)).assertUndefined();
      const answered = new Map<string, DoseRecord>([
        ['twice@2026-10-03T19:00', record('twice@2026-10-03T19:00', DoseStatus.Skipped, true)]
      ]);
      expect(nextDose(doses, NOON, answered)?.time).assertEqual('21:00');
    });

    it('keepsOverdueDosesOpenUntilAnswered', 0, () => {
      const twice = dosesOf(todaysDoses(MEDICATIONS, NOON), 'twice');
      expect(openDose(twice, new Map<string, DoseRecord>())?.time).assertEqual('08:00');
      const morningTaken = new Map<string, DoseRecord>([
        ['twice@2026-10-03T08:00', record('twice@2026-10-03T08:00', DoseStatus.Taken, true)]
      ]);
      expect(openDose(twice, morningTaken)?.time).assertEqual('19:00');
    });

    it('sortsMedicationsByFirstOpenDose', 0, () => {
      const doses = todaysDoses(MEDICATIONS, NOON);
      const allTwiceAnswered = new Map<string, DoseRecord>([
        ['twice@2026-10-03T08:00', record('twice@2026-10-03T08:00', DoseStatus.Taken, true)],
        ['twice@2026-10-03T19:00', record('twice@2026-10-03T19:00', DoseStatus.Taken, true)]
      ]);
      const open = sortByOpenDose(MEDICATIONS, doses, new Map<string, DoseRecord>());
      expect(open.map((medication: Medication) => medication.id).join(',')).assertEqual('twice,evening');
      const answered = sortByOpenDose(MEDICATIONS, doses, allTwiceAnswered);
      expect(answered.map((medication: Medication) => medication.id).join(',')).assertEqual('evening,twice');
    });

    it('prefersServerRecordsOverPendingOnes', 0, () => {
      const pending = [record('a', DoseStatus.Skipped, false), record('b', DoseStatus.Taken, false)];
      const merged = mergeDoseRecords([record('a', DoseStatus.Taken, true)], pending);
      expect(merged.size).assertEqual(2);
      expect(merged.get('a')?.status).assertEqual(DoseStatus.Taken);
      expect(merged.get('a')?.synced).assertTrue();
      expect(merged.get('b')?.synced).assertFalse();
    });

    it('roundTripsPendingDoses', 0, () => {
      const entries = encodePendingDoses([record('twice@2026-10-03T08:00', DoseStatus.Taken, false)]);
      entries.push('malformed', '{"occurrenceId":"x","medicationId":"twice","status":"snoozed"}');
      const decoded = decodePendingDoses(entries);
      expect(decoded.length).assertEqual(1);
      expect(decoded[0].occurrenceId).assertEqual('twice@2026-10-03T08:00');
      expect(decoded[0].status).assertEqual(DoseStatus.Taken);
      expect(decoded[0].recordedAt).assertEqual(1791012346000);
      expect(decoded[0].synced).assertFalse();
    });

    it('findsScannedMedicationOnTheList', 0, () => {
      expect(findMedicationByBarcode(MEDICATIONS, '2000000002026')?.id).assertEqual('twice');
      expect(findMedicationByBarcode(MEDICATIONS, '2000000009998')).assertUndefined();
      const noCode = [new Medication('plain', 'Plain', '', '', '', ['08:00'], ZONE)];
      expect(findMedicationByBarcode(noCode, '')).assertUndefined();
    });

    it('matchesEquivalentProductCodes', 0, () => {
      expect(barcodesMatch('2000000001012', ' 2000000001012 ')).assertTrue();
      expect(barcodesMatch('0012345678905', '012345678905')).assertTrue();
      expect(barcodesMatch('5901234123457', '01059012341234571726123110ABC')).assertTrue();
      expect(barcodesMatch('5901234123457', ']d2010590123412345717261231')).assertTrue();
      expect(barcodesMatch('5901234123457', '0105901234123457')).assertTrue();
    });

    it('rejectsDifferentOrEmptyCodes', 0, () => {
      expect(barcodesMatch('2000000001012', '2000000002026')).assertFalse();
      expect(barcodesMatch('2000000001012', '')).assertFalse();
      expect(barcodesMatch('', '')).assertFalse();
    });
  });
}

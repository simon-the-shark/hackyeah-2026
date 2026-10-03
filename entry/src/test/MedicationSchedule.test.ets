import { describe, it, expect } from '@ohos/hypium';
import { DoseOccurrence, Medication } from '../main/ets/models/Medication';
import {
  barcodesMatch,
  decodeTakenDoses,
  encodeTakenDoses,
  findScheduledMedication,
  nextDose,
  todaysDoses
} from '../main/ets/services/MedicationSchedule';

const MEDICATIONS: Medication[] = [
  new Medication('evening', 'Evening', '1 tablet', '', '2000000001012', ['21:00']),
  new Medication('twice', 'Twice', '1 tablet', '', '2000000002026', ['19:00', '08:00'])
];

export default function medicationScheduleTest() {
  describe('medicationSchedule', () => {
    it('ordersTodaysDosesByTime', 0, () => {
      const doses = todaysDoses(MEDICATIONS, new Date(2026, 9, 3, 12, 0));
      expect(doses.map((dose: DoseOccurrence) => dose.time).join(',')).assertEqual('08:00,19:00,21:00');
      expect(doses[0].occurrenceId).assertEqual('twice@2026-10-03T08:00');
    });

    it('findsNextUntakenDose', 0, () => {
      const doses = todaysDoses(MEDICATIONS, new Date(2026, 9, 3, 12, 0));
      const none = new Map<string, number>();
      expect(nextDose(doses, new Date(2026, 9, 3, 12, 0), none)?.time).assertEqual('19:00');
      expect(nextDose(doses, new Date(2026, 9, 3, 19, 0), none)?.time).assertEqual('19:00');
      expect(nextDose(doses, new Date(2026, 9, 3, 22, 0), none)).assertUndefined();
      const taken = new Map<string, number>([['twice@2026-10-03T19:00', 1]]);
      expect(nextDose(doses, new Date(2026, 9, 3, 12, 0), taken)?.time).assertEqual('21:00');
    });

    it('roundTripsTodaysTakenDoses', 0, () => {
      const taken = new Map<string, number>([['twice@2026-10-03T08:00', 1791012345000]]);
      const entries = encodeTakenDoses(taken);
      entries.push('twice@2026-10-02T08:00|1790925945000', 'malformed', 'evening@2026-10-03T21:00|x');
      const decoded = decodeTakenDoses(entries, '2026-10-03');
      expect(decoded.size).assertEqual(1);
      expect(decoded.get('twice@2026-10-03T08:00')).assertEqual(1791012345000);
    });

    it('findsScannedMedicationOnTodaysList', 0, () => {
      const doses = todaysDoses(MEDICATIONS, new Date(2026, 9, 3, 12, 0));
      expect(findScheduledMedication(doses, '2000000002026')?.id).assertEqual('twice');
      expect(findScheduledMedication(doses, '2000000009998')).assertUndefined();
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

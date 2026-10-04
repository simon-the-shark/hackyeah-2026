import { describe, it, expect } from '@ohos/hypium';
import {
  doseStatusText,
  groupByDay,
  overviewFrom,
  RemoteOverview,
  RemoteScheduledDose,
  ScheduledDose,
  ScheduledDoseStatus,
  scheduledDoseFrom,
  scheduledDosesFrom,
  tallyOf,
  withRecordedDoses
} from '../main/ets/models/CareOverview';

function item(occurrenceId: string, scheduledFor: string, status: string): RemoteScheduledDose {
  return {
    occurrenceId: occurrenceId,
    medicationName: 'Metformin',
    doseText: '500 mg',
    localTime: occurrenceId.slice(-5),
    scheduledFor: scheduledFor,
    status: status,
    recordedAt: null
  };
}

export default function careOverviewTest() {
  describe('careOverview', () => {
    it('addsAnswersTheScheduleNoLongerLists', 0, () => {
      const schedule = scheduledDosesFrom([item('med-1@2026-10-04T20:00', '2026-10-04T18:00:00Z', 'pending')]);
      const taken: RemoteScheduledDose = {
        occurrenceId: 'med-1@2026-10-04T06:30',
        medicationName: 'Aspirin',
        scheduledFor: '2026-10-04T04:30:00Z',
        status: 'taken',
        recordedAt: '2026-10-04T04:54:00Z'
      };
      const merged = withRecordedDoses(schedule, [taken, item('med-1@2026-10-04T20:00', '2026-10-04T18:00:00Z', 'pending')]);
      expect(merged.length).assertEqual(2);
      expect(merged[1].localTime).assertEqual('06:30');
      expect(merged[1].localDate).assertEqual('2026-10-04');
      expect(tallyOf(merged).taken).assertEqual(1);
    });

    it('readsTheLocalDateFromTheOccurrenceId', 0, () => {
      // 23:30 in Warsaw is already the next day in UTC; the occurrence id keeps the scheduled local date.
      const dose = scheduledDoseFrom(item('med-1@2026-10-02T23:30', '2026-10-02T21:30:00Z', 'taken')) as ScheduledDose;
      expect(dose.localDate).assertEqual('2026-10-02');
      expect(dose.localTime).assertEqual('23:30');
      expect(dose.status).assertEqual(ScheduledDoseStatus.Taken);
      expect(dose.recordedAt).assertEqual(0);
    });

    it('dropsItemsItCannotShow', 0, () => {
      const doses = scheduledDosesFrom([
        item('med-1@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'taken'),
        item('med-1@2026-10-03T12:00', 'not a date', 'taken'),
        item('med-1@2026-10-03T18:00', '2026-10-03T16:00:00Z', 'unknown')
      ]);
      expect(doses.length).assertEqual(1);
    });

    it('groupsNewestDayAndDoseFirst', 0, () => {
      const days = groupByDay(scheduledDosesFrom([
        item('med-1@2026-10-02T08:00', '2026-10-02T06:00:00Z', 'taken'),
        item('med-1@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'skipped'),
        item('med-1@2026-10-03T20:00', '2026-10-03T18:00:00Z', 'missed')
      ]));
      expect(days.length).assertEqual(2);
      expect(days[0].date).assertEqual('2026-10-03');
      expect(days[0].doses[0].localTime).assertEqual('20:00');
      expect(days[1].doses.length).assertEqual(1);
    });

    it('countsEachAnswer', 0, () => {
      const tally = tallyOf(scheduledDosesFrom([
        item('a@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'taken'),
        item('b@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'taken'),
        item('c@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'skipped'),
        item('d@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'snoozed'),
        item('e@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'missed'),
        item('f@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'pending')
      ]));
      expect(tally.taken).assertEqual(2);
      expect(tally.skipped).assertEqual(1);
      expect(tally.snoozed).assertEqual(1);
      expect(tally.missed).assertEqual(1);
    });

    it('saysWhetherAPendingDoseIsDue', 0, () => {
      const dose = scheduledDoseFrom(item('a@2026-10-03T08:00', '2026-10-03T06:00:00Z', 'pending')) as ScheduledDose;
      expect(doseStatusText(dose, dose.scheduledFor + 1)).assertEqual('Due, no answer yet');
      expect(doseStatusText(dose, dose.scheduledFor - 1)).assertEqual('Upcoming');
    });

    it('readsTheOverview', 0, () => {
      const dto: RemoteOverview = {
        senior: { id: 's', displayName: 'Anna' },
        status: null,
        devices: [],
        alerts: { unacknowledged: 2, unresolved: 3 },
        nextDoses: [item('a@2026-10-03T14:00', '2026-10-03T12:00:00Z', 'pending')],
        missedDosesLast24h: 1,
        latestReportAt: '2026-10-03T10:00:00Z',
        safeAreaVersion: null,
        serverTime: '2026-10-03T12:00:00Z'
      };
      const overview = overviewFrom(dto, 1000);
      expect(overview.snapshot.seniorName).assertEqual('Anna');
      expect(overview.snapshot.hasStatus).assertFalse();
      expect(overview.unacknowledgedAlerts).assertEqual(2);
      expect(overview.nextDoses.length).assertEqual(1);
      expect(overview.missedLast24h).assertEqual(1);
      expect(overview.latestReportAgeMs).assertEqual(2 * 60 * 60 * 1000);
      expect(overview.hasSafeArea).assertFalse();
    });
  });
}

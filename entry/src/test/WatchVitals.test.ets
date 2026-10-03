import { describe, it, expect } from '@ohos/hypium';
import {
  ageMs,
  describeHeartRateAlert,
  formatAge,
  HeartRateAlertSummary,
  sparklinePoints
} from '../main/ets/models/WatchVitals';

export default function watchVitalsTest() {
  describe('watchVitals', () => {
    it('measuresAgeOnTheServerClock', 0, () => {
      expect(ageMs('2026-10-03T12:05:00Z', '2026-10-03T12:00:00Z')).assertEqual(300000);
      // A sample stamped slightly ahead of the server never shows a negative age.
      expect(ageMs('2026-10-03T12:00:00Z', '2026-10-03T12:00:05Z')).assertEqual(0);
      expect(ageMs('not a date', '2026-10-03T12:00:00Z')).assertEqual(0);
    });

    it('formatsAgesForPeople', 0, () => {
      expect(formatAge(20000)).assertEqual('just now');
      expect(formatAge(3 * 60000)).assertEqual('3 min ago');
      expect(formatAge(2 * 3600000)).assertEqual('2 h ago');
      expect(formatAge(26 * 3600000)).assertEqual('1 day ago');
    });

    it('describesAnEpisodeWithoutDiagnosing', 0, () => {
      const alert = new HeartRateAlertSummary();
      alert.bpm = 134;
      alert.direction = 'high';
      alert.lowBpm = 45;
      alert.highBpm = 120;
      alert.sustainedSeconds = 120;
      expect(describeHeartRateAlert(alert)).assertEqual('Heart rate stayed above 120 bpm for 2 min (134 bpm).');
      alert.direction = 'low';
      alert.bpm = 40;
      expect(describeHeartRateAlert(alert)).assertEqual('Heart rate stayed below 45 bpm for 2 min (40 bpm).');
    });

    it('drawsHigherReadingsHigherUp', 0, () => {
      const points = sparklinePoints([60, 90, 120], 100, 50);
      expect(points.length).assertEqual(3);
      expect(points[0][0]).assertEqual(0);
      expect(points[2][0]).assertEqual(100);
      expect(points[0][1]).assertEqual(50);
      expect(points[1][1]).assertEqual(25);
      expect(points[2][1]).assertEqual(0);
      // A flat series sits in the middle instead of dividing by zero.
      expect(sparklinePoints([72, 72], 100, 50)[1][1]).assertEqual(25);
      expect(sparklinePoints([], 100, 50).length).assertEqual(0);
    });
  });
}

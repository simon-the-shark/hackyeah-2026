import { describe, it, expect } from '@ohos/hypium';
import { BoundaryState, GeofenceTracker } from '../main/ets/models/GeofenceTracker';

export default function geofenceTrackerTest() {
  describe('GeofenceTracker', () => {
    it('requires two clear fixes and emits exit and reentry once', 0, () => {
      const tracker = new GeofenceTracker();
      expect(tracker.observe(0, 300, 10, 1000000, 1000000)).assertEqual('');
      expect(tracker.observe(0, 300, 10, 1030000, 1030000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Inside);
      expect(tracker.observe(500, 300, 10, 1060000, 1060000)).assertEqual('');
      expect(tracker.observe(500, 300, 10, 1090000, 1090000)).assertEqual('area_exit');
      expect(tracker.observe(510, 300, 10, 1120000, 1120000)).assertEqual('');
      expect(tracker.observe(0, 300, 10, 1150000, 1150000)).assertEqual('');
      expect(tracker.observe(0, 300, 10, 1180000, 1180000)).assertEqual('area_enter');
      expect(tracker.observe(0, 300, 10, 1210000, 1210000)).assertEqual('');
    });

    it('does not mistake boundary jitter for an exit', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(0, 300, 10, 1000000, 1000000);
      tracker.observe(0, 300, 10, 1030000, 1030000);
      expect(tracker.observe(305, 300, 30, 1060000, 1060000)).assertEqual('');
      expect(tracker.observe(320, 300, 30, 1090000, 1090000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Inside);
    });

    it('preserves confirmed outside across uncertain readings', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(500, 300, 10, 1000000, 1000000);
      expect(tracker.observe(500, 300, 10, 1030000, 1030000)).assertEqual('area_exit');
      tracker.observe(300, 300, 100, 1060000, 1060000);
      tracker.observe(0, 300, 600, 1090000, 1090000);
      expect(tracker.observe(500, 300, 10, 1120000, 1120000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Outside);
    });

    it('rejects stale future duplicate and out-of-order fixes', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(500, 300, 10, 1000000, 1000000);
      expect(tracker.observe(500, 300, 10, 1000000, 1030000)).assertEqual('');
      expect(tracker.observe(500, 300, 10, 990000, 1030000)).assertEqual('');
      expect(tracker.observe(500, 300, 10, 1010000, 1200000)).assertEqual('');
      expect(tracker.observe(500, 300, 10, 1400000, 1030000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Unknown);
    });

    it('requires the confirmation dwell and resets an interrupted candidate', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(500, 300, 10, 1000000, 1000000);
      expect(tracker.observe(500, 300, 10, 1005000, 1005000)).assertEqual('');
      tracker.observe(300, 300, 10, 1010000, 1010000);
      expect(tracker.observe(500, 300, 10, 1020000, 1020000)).assertEqual('');
      expect(tracker.observe(500, 300, 10, 1030000, 1030000)).assertEqual('area_exit');
    });

    it('cannot confirm a crossing across a long observation gap', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(500, 300, 10, 1000000, 1000000);
      expect(tracker.observe(500, 300, 10, 1300000, 1300000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Unknown);
      expect(tracker.observe(500, 300, 10, 1330000, 1330000)).assertEqual('area_exit');
    });

    it('resets baseline for a changed safe area', 0, () => {
      const tracker = new GeofenceTracker();
      tracker.observe(500, 300, 10, 1000000, 1000000);
      tracker.observe(500, 300, 10, 1030000, 1030000);
      tracker.reset();
      expect(tracker.confirmed).assertEqual(BoundaryState.Unknown);
      tracker.observe(0, 300, 10, 1060000, 1060000);
      expect(tracker.observe(0, 300, 10, 1090000, 1090000)).assertEqual('');
      expect(tracker.confirmed).assertEqual(BoundaryState.Inside);
    });
  });
}

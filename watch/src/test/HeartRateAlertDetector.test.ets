import { describe, it, expect } from '@ohos/hypium';
import {
  EpisodeEventKind,
  HeartRateAlertDetector,
  HeartRateEpisodeEvent,
  isPlausibleBpm,
  medianBpm
} from '../main/ets/services/HeartRateAlertDetector';

/** Feeds one reading every 10 s from `start` (ms) and returns the events produced. */
function feedEvery10s(detector: HeartRateAlertDetector, start: number, readings: number[]): HeartRateEpisodeEvent[] {
  const events: HeartRateEpisodeEvent[] = [];
  readings.forEach((bpm: number, index: number) => {
    const event = detector.feed(bpm, start + index * 10000);
    if (event !== undefined) {
      events.push(event);
    }
  });
  return events;
}

function repeat(bpm: number, count: number): number[] {
  const values: number[] = [];
  for (let i = 0; i < count; i++) {
    values.push(bpm);
  }
  return values;
}

export default function heartRateAlertDetectorTest() {
  describe('heartRateAlertDetector', () => {
    it('sendsOneEventPerSustainedEpisode', 0, () => {
      const detector = new HeartRateAlertDetector();
      // 0 s .. 180 s above 120 bpm: the event fires once, at 120 s.
      const events = feedEvery10s(detector, 0, repeat(134, 19));
      expect(events.length).assertEqual(1);
      expect(events[0].kind).assertEqual(EpisodeEventKind.OutOfRange);
      expect(events[0].direction).assertEqual('high');
      expect(events[0].at).assertEqual(120000);
    });

    it('ignoresShortSpikesAndJitter', 0, () => {
      const detector = new HeartRateAlertDetector();
      // 110 s high, one normal reading, 110 s high again: never 120 s in a row.
      const readings = repeat(130, 12).concat([80]).concat(repeat(130, 12));
      expect(feedEvery10s(detector, 0, readings).length).assertEqual(0);
    });

    it('restartsTimingAfterAGapInReadings', 0, () => {
      const detector = new HeartRateAlertDetector();
      expect(feedEvery10s(detector, 0, repeat(40, 6)).length).assertEqual(0);
      // A minute without readings: the next 60 s of low readings do not add up to 120 s.
      expect(feedEvery10s(detector, 110000, repeat(40, 7)).length).assertEqual(0);
    });

    it('resolvesAfterSustainedRecoveryAndReArms', 0, () => {
      const detector = new HeartRateAlertDetector();
      const readings = repeat(40, 13).concat(repeat(70, 13)).concat(repeat(40, 13));
      const events = feedEvery10s(detector, 0, readings);
      expect(events.length).assertEqual(3);
      expect(events[0].kind).assertEqual(EpisodeEventKind.OutOfRange);
      expect(events[0].direction).assertEqual('low');
      expect(events[1].kind).assertEqual(EpisodeEventKind.BackInRange);
      expect(events[1].direction).assertEqual('low');
      expect(events[2].kind).assertEqual(EpisodeEventKind.OutOfRange);
      expect(detector.isAlerting()).assertTrue();
    });

    it('dropsImplausibleReadings', 0, () => {
      expect(isPlausibleBpm(0)).assertFalse();
      expect(isPlausibleBpm(19)).assertFalse();
      expect(isPlausibleBpm(72.5)).assertFalse();
      expect(isPlausibleBpm(251)).assertFalse();
      expect(isPlausibleBpm(72)).assertTrue();
      const detector = new HeartRateAlertDetector();
      expect(feedEvery10s(detector, 0, repeat(0, 20)).length).assertEqual(0);
    });

    it('reducesAWindowToItsMedian', 0, () => {
      expect(medianBpm([72])).assertEqual(72);
      expect(medianBpm([90, 70, 80])).assertEqual(80);
      expect(medianBpm([70, 75, 80, 200])).assertEqual(78);
    });
  });
}

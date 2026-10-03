import { describe, it, expect } from '@ohos/hypium';
import {
  accuracyLabel,
  alertLocationFrom,
  AlertLocation,
  fixTimeLabel,
  formatCoordinates,
  mapLinkUrl,
  RemoteGeoPoint,
  sourceLabel
} from '../main/ets/models/AlertLocation';
import { formatClockTime } from '../main/ets/models/Safety';

export default function alertLocationTest() {
  describe('alertLocation', () => {
    it('readsTheEventLocation', 0, () => {
      const point: RemoteGeoPoint = {
        lat: 52.2297,
        lng: 21.0122,
        accuracyM: 24.6,
        sampledAt: '2026-10-03T12:00:00Z',
        measuredBy: 'watch'
      };
      const location = alertLocationFrom(point) as AlertLocation;
      expect(location.lat).assertEqual(52.2297);
      expect(location.lng).assertEqual(21.0122);
      expect(location.sampledAt).assertEqual(Date.parse('2026-10-03T12:00:00Z'));
      expect(sourceLabel(location)).assertEqual('From the senior\'s watch');
      expect(accuracyLabel(location)).assertEqual('Within about 25 m');
    });

    it('toleratesMissingOptionalFields', 0, () => {
      expect(alertLocationFrom(null)).assertUndefined();
      expect(alertLocationFrom(undefined)).assertUndefined();
      const point: RemoteGeoPoint = { lat: 52, lng: 21, accuracyM: null, sampledAt: null, measuredBy: null };
      const location = alertLocationFrom(point) as AlertLocation;
      expect(location.accuracyM).assertEqual(-1);
      expect(location.sampledAt).assertEqual(0);
      expect(accuracyLabel(location)).assertEqual('Accuracy unknown');
      expect(sourceLabel(location)).assertEqual('From the senior\'s device');
      expect(fixTimeLabel(location, Date.now())).assertEqual('Time of the position unknown');
    });

    it('saysHowOldTheFixWasAtTheAlert', 0, () => {
      const location = new AlertLocation();
      location.sampledAt = Date.parse('2026-10-03T12:00:00Z');
      const clock = formatClockTime(location.sampledAt);
      expect(fixTimeLabel(location, Date.parse('2026-10-03T12:00:30Z')))
        .assertEqual(`Position from ${clock}, at the time of the alert`);
      expect(fixTimeLabel(location, Date.parse('2026-10-03T12:07:00Z')))
        .assertEqual(`Position from ${clock}, 7 min before the alert`);
      expect(fixTimeLabel(location, 0)).assertEqual(`Position from ${clock}`);
    });

    it('buildsAMapLink', 0, () => {
      expect(formatCoordinates(52.2297, 21.0122)).assertEqual('52.22970, 21.01220');
      expect(mapLinkUrl(52.2297, -0.1)).assertEqual(
        'https://www.openstreetmap.org/?mlat=52.229700&mlon=-0.100000#map=17/52.229700/-0.100000');
    });
  });
}

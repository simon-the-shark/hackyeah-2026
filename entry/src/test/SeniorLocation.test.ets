import { describe, it, expect } from '@ohos/hypium';
import {
  DeviceReport,
  RemoteHeartbeat,
  RemoteStatusResponse,
  SeniorSnapshot,
  WATCH,
  deviceAgeText,
  hasAnyLocation,
  snapshotFromStatus,
  stateSentence
} from '../main/ets/models/SeniorLocation';

const SERVER_TIME = '2026-10-03T12:10:00Z';

function heartbeat(kind: string, reportedAt: string, state: string): RemoteHeartbeat {
  return { deviceKind: kind, reportedAt: reportedAt, monitoringState: state };
}

export default function seniorLocationTest() {
  describe('seniorLocation', () => {
    it('keepsThePositionTimeSeparateFromTheHeartbeat', 0, () => {
      const phone = heartbeat('phone', '2026-10-03T12:10:00Z', 'inside');
      phone.location = { lat: 52.23, lng: 21.01, sampledAt: '2026-10-03T12:08:30Z' };
      const snapshot = snapshotFromStatus({ status: phone, devices: [phone], serverTime: SERVER_TIME }, 0);
      expect((snapshot.phone as DeviceReport).reportedAgeMs).assertEqual(0);
      expect((snapshot.phone as DeviceReport).sampledAt).assertEqual('2026-10-03T12:08:30Z');
      phone.location.sampledAt = 'invalid';
      const invalid = snapshotFromStatus({ status: phone, devices: [phone], serverTime: SERVER_TIME }, 0);
      expect((invalid.phone as DeviceReport).sampledAt).assertEqual('');
    });

    it('keepsThePhoneAndTheWatchApart', 0, () => {
      const watch = heartbeat('watch', '2026-10-03T12:09:00Z', 'outside');
      watch.location = { lat: 52.24, lng: 21.03, accuracyM: 12, measuredBy: 'watch' };
      watch.battery = 64;
      watch.source = 'simulated';
      const phone = heartbeat('phone', '2026-10-03T12:00:00Z', 'inside');
      phone.location = { lat: 52.23, lng: 21.01, accuracyM: null };
      const response: RemoteStatusResponse = { status: watch, devices: [watch, phone], serverTime: SERVER_TIME };
      const snapshot = snapshotFromStatus(response, 1000);
      const phoneReport = snapshot.phone as DeviceReport;
      const watchReport = snapshot.watch as DeviceReport;
      expect(phoneReport.lat).assertEqual(52.23);
      expect(phoneReport.accuracyM).assertEqual(-1);
      expect(phoneReport.reportedAgeMs).assertEqual(600000);
      expect(watchReport.lat).assertEqual(52.24);
      expect(watchReport.battery).assertEqual(64);
      expect(watchReport.simulated).assertTrue();
      expect(phoneReport.simulated).assertFalse();
      // The newest report, here the watch, fills the headline.
      expect(snapshot.latestKind).assertEqual(WATCH);
      expect(snapshot.monitoringState).assertEqual('outside');
      expect(snapshot.reportedAgeMs).assertEqual(60000);
      expect(stateSentence(snapshot, 1000)).assertEqual('Was outside the safe area at the last update from the watch.');
    });

    it('ignoresAPhoneFixRelayedByTheWatch', 0, () => {
      const watch = heartbeat('watch', '2026-10-03T12:09:00Z', 'unknown');
      watch.location = { lat: 52.23, lng: 21.01, measuredBy: 'phone' };
      const snapshot = snapshotFromStatus({ status: watch, devices: [watch], serverTime: SERVER_TIME }, 0);
      expect((snapshot.watch as DeviceReport).hasLocation).assertFalse();
      expect(snapshot.phone).assertUndefined();
      expect(hasAnyLocation(snapshot)).assertFalse();
    });

    it('readsABackendWithoutDevicesAsThePhone', 0, () => {
      const status = heartbeat('watch', '2026-10-03T12:05:00Z', 'inside');
      status.location = { lat: 52.23, lng: 21.01 };
      const snapshot = snapshotFromStatus({ status: status, serverTime: SERVER_TIME }, 0);
      expect((snapshot.phone as DeviceReport).hasLocation).assertTrue();
      expect(snapshot.watch).assertUndefined();
      expect(snapshot.hasStatus).assertTrue();
    });

    it('reportsNothingWithoutHeartbeats', 0, () => {
      const snapshot = snapshotFromStatus({ status: null, devices: [], serverTime: SERVER_TIME }, 0);
      expect(snapshot.hasStatus).assertFalse();
      expect(snapshot.phone).assertUndefined();
      expect(snapshot.watch).assertUndefined();
    });

    it('agesEachDeviceSeparately', 0, () => {
      const snapshot = new SeniorSnapshot();
      snapshot.fetchedAt = 0;
      const recent = new DeviceReport();
      recent.reportedAgeMs = 30000;
      const old = new DeviceReport();
      old.reportedAgeMs = 20 * 60000;
      expect(deviceAgeText(recent, snapshot, 0)).assertEqual('Updated just now');
      expect(deviceAgeText(recent, snapshot, 3 * 60000)).assertEqual('Updated 3 min ago');
      expect(deviceAgeText(old, snapshot, 0)).assertEqual('No update for 20 min');
    });
  });
}

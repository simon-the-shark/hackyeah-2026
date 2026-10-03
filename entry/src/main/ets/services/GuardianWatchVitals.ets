import { ageMs, HeartRateAlertSummary, WatchVitalsSnapshot } from '../models/WatchVitals';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import {
  RemoteDeviceStatus,
  RemoteHeartRateAlert,
  RemoteHeartRateSample,
  WatchVitalsApi
} from '../providers/backend/WatchVitalsApi';
import { apiSession } from './CareApi';
import { guardianSessionReady, NOT_GUARDIAN_MESSAGE } from './GuardianContactsService';

/** The trend shown to the guardian. */
export const HEART_RATE_WINDOW_MS: number = 6 * 60 * 60 * 1000;

function finite(value: number | null | undefined): boolean {
  return typeof value === 'number' && isFinite(value);
}

/**
 * Builds the guardian's view of the senior's watch: battery, last update and
 * heart rate. The watch's position is drawn with the phone's on the Location tab.
 */
export class GuardianWatchVitals {
  async load(): Promise<WatchVitalsSnapshot> {
    const api = this.api();
    const seniorId = apiSession.seniorId;
    const snapshot = new WatchVitalsSnapshot();

    const status = await api.status(seniorId);
    // `devices` is newest first; only a heartbeat from the watch itself describes the watch.
    const watch = (status.devices ?? []).find((device: RemoteDeviceStatus) => device.deviceKind === 'watch');
    if (watch !== undefined) {
      snapshot.hasWatch = true;
      snapshot.heartbeatAgeMs = ageMs(status.serverTime, watch.reportedAt);
      snapshot.statusSimulated = watch.source !== undefined && watch.source !== 'device';
      const battery = watch.battery;
      if (battery !== null && battery !== undefined && finite(battery)) {
        snapshot.battery = battery;
      }
    }

    const heartRate = await api.heartRate(seniorId, new Date(Date.now() - HEART_RATE_WINDOW_MS));
    const latest = heartRate.latest;
    if (latest !== null && latest !== undefined) {
      snapshot.hasWatch = true;
      snapshot.latestBpm = latest.bpm;
      snapshot.latestAgeMs = ageMs(heartRate.serverTime, latest.measuredAt);
      snapshot.latestSimulated = latest.source !== 'device';
    }
    snapshot.series = (heartRate.items ?? []).map((sample: RemoteHeartRateSample) => sample.bpm);
    if (snapshot.series.length > 0) {
      snapshot.seriesMin = Math.min(...snapshot.series);
      snapshot.seriesMax = Math.max(...snapshot.series);
    }

    snapshot.alert = this.summarize(await api.latestHeartRateAlert(seniorId));
    return snapshot;
  }

  private summarize(alert: RemoteHeartRateAlert | undefined): HeartRateAlertSummary | undefined {
    if (alert === undefined) {
      return undefined;
    }
    const details = alert.details;
    const summary = new HeartRateAlertSummary();
    if (details !== null && details !== undefined) {
      summary.bpm = details.bpm ?? 0;
      summary.direction = details.direction ?? '';
      summary.lowBpm = details.lowBpm ?? 0;
      summary.highBpm = details.highBpm ?? 0;
      summary.sustainedSeconds = details.sustainedSeconds ?? 0;
    }
    const created = Date.parse(alert.createdAt);
    summary.createdAt = isFinite(created) ? created : 0;
    summary.resolved = alert.resolvedAt !== null && alert.resolvedAt !== undefined;
    const event = alert.event;
    summary.simulated = event !== null && event !== undefined && event.source !== undefined && event.source !== 'device';
    return summary;
  }

  // Built per call so pairing again or signing out takes effect immediately.
  private api(): WatchVitalsApi {
    if (!guardianSessionReady()) {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', NOT_GUARDIAN_MESSAGE);
    }
    return new WatchVitalsApi(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
  }
}

export const guardianWatchVitals: GuardianWatchVitals = new GuardianWatchVitals();

export function describeWatchVitalsError(error: Object): string {
  if (!(error instanceof ApiError)) {
    return 'Could not load the watch data.';
  }
  if (error.kind === ApiErrorKind.Network) {
    return 'Cannot reach the Carely server. Check the internet connection and try again.';
  }
  if (error.status === 401) {
    return 'This phone\'s pairing is no longer valid. Sign out and pair it again.';
  }
  if (error.status === 403) {
    return error.message === NOT_GUARDIAN_MESSAGE ? NOT_GUARDIAN_MESSAGE : 'This phone cannot see this senior\'s watch.';
  }
  return 'Could not load the watch data.';
}

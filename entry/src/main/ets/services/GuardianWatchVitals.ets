import {
  ageMs,
  distanceMeters,
  HeartRateAlertSummary,
  WatchLocation,
  WatchVitalsSnapshot
} from '../models/WatchVitals';
import { ApiError, ApiErrorKind, BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import {
  RemoteDeviceStatus,
  RemoteHeartRateAlert,
  RemoteHeartRateSample,
  RemoteSafeArea,
  WatchVitalsApi
} from '../providers/backend/WatchVitalsApi';
import { apiSession } from './CareApi';
import { guardianSessionReady, NOT_GUARDIAN_MESSAGE } from './GuardianContactsService';

/** The trend shown to the guardian. */
export const HEART_RATE_WINDOW_MS: number = 6 * 60 * 60 * 1000;

function finite(value: number | null | undefined): boolean {
  return typeof value === 'number' && isFinite(value);
}

/** Builds the guardian's view of the senior's watch: its own location, battery and heart rate. */
export class GuardianWatchVitals {
  async load(): Promise<WatchVitalsSnapshot> {
    const api = this.api();
    const seniorId = apiSession.seniorId;
    const snapshot = new WatchVitalsSnapshot();

    const status = await api.status(seniorId);
    // `devices` is newest first; only a heartbeat from the watch itself counts as the watch's location.
    const watch = (status.devices ?? []).find((device: RemoteDeviceStatus) => device.deviceKind === 'watch');
    if (watch !== undefined) {
      snapshot.hasWatch = true;
      snapshot.heartbeatAgeMs = ageMs(status.serverTime, watch.reportedAt);
      snapshot.monitoringState = watch.monitoringState;
      snapshot.locationSimulated = watch.source !== undefined && watch.source !== 'device';
      const battery = watch.battery;
      if (battery !== null && battery !== undefined && finite(battery)) {
        snapshot.battery = battery;
      }
      const point = watch.location;
      if (point !== null && point !== undefined && finite(point.lat) && finite(point.lng) &&
        point.measuredBy !== 'phone') {
        const location = new WatchLocation();
        location.lat = point.lat;
        location.lng = point.lng;
        const accuracy = point.accuracyM;
        if (accuracy !== undefined && finite(accuracy)) {
          location.accuracyM = accuracy;
        }
        const area = await this.safeArea(api, seniorId);
        if (area !== undefined) {
          location.distanceFromHomeM = distanceMeters(area.lat, area.lng, location.lat, location.lng);
        }
        snapshot.location = location;
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

  /** 404 means the guardian has not set a safe area yet, so there is no distance to show. */
  private async safeArea(api: WatchVitalsApi, seniorId: string): Promise<RemoteSafeArea | undefined> {
    try {
      return await api.safeArea(seniorId);
    } catch (error) {
      return undefined;
    }
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

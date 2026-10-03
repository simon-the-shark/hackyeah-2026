/** A heart-rate reading or alert is shown as current only up to this age. */
export const HEART_RATE_STALE_MS: number = 5 * 60 * 1000;
/** Matches the backend's default heartbeat staleness (`HEARTBEAT_STALE_SECONDS`, 900 s). */
export const WATCH_STALE_MS: number = 15 * 60 * 1000;

export class HeartRateAlertSummary {
  bpm: number = 0;
  direction: string = '';
  lowBpm: number = 0;
  highBpm: number = 0;
  sustainedSeconds: number = 0;
  createdAt: number = 0;
  resolved: boolean = false;
  simulated: boolean = false;
}

/** What the guardian knows about the senior's watch; ages are measured on the server clock. */
export class WatchVitalsSnapshot {
  hasWatch: boolean = false;
  heartbeatAgeMs: number = 0;
  /** Negative when the watch did not report a battery level. */
  battery: number = -1;
  /** The watch's last heartbeat came from an emulator or replay, not a real watch. */
  statusSimulated: boolean = false;
  /** 0 when there is no reading yet. */
  latestBpm: number = 0;
  latestAgeMs: number = 0;
  latestSimulated: boolean = false;
  /** bpm values of the window, oldest first. */
  series: number[] = [];
  seriesMin: number = 0;
  seriesMax: number = 0;
  alert: HeartRateAlertSummary | undefined = undefined;
}

/** Age between two ISO times on the server clock; 0 when either is unreadable. */
export function ageMs(serverTime: string, when: string): number {
  const now = Date.parse(serverTime);
  const then = Date.parse(when);
  return isFinite(now) && isFinite(then) ? Math.max(0, now - then) : 0;
}

export function formatAge(ms: number): string {
  const minutes = Math.floor(ms / 60000);
  if (minutes < 1) {
    return 'just now';
  }
  if (minutes < 60) {
    return `${minutes} min ago`;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return `${hours} h ago`;
  }
  const days = Math.floor(hours / 24);
  return days === 1 ? '1 day ago' : `${days} days ago`;
}

/** Plain-language summary of an episode the watch reported; never a diagnosis. */
export function describeHeartRateAlert(alert: HeartRateAlertSummary): string {
  const limit = alert.direction === 'low' ? `below ${alert.lowBpm}` : `above ${alert.highBpm}`;
  const minutes = Math.max(1, Math.round(alert.sustainedSeconds / 60));
  return `Heart rate stayed ${limit} bpm for ${minutes} min (${alert.bpm} bpm).`;
}

/**
 * Points for an ArkUI Polyline of `width` x `height` vp: oldest reading on the
 * left, higher bpm higher up. A flat series is drawn through the middle.
 */
export function sparklinePoints(values: number[], width: number, height: number): number[][] {
  if (values.length === 0) {
    return [];
  }
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min;
  const step = values.length > 1 ? width / (values.length - 1) : 0;
  return values.map((value: number, index: number) => {
    const y = span === 0 ? height / 2 : height - ((value - min) / span) * height;
    return [Math.round(index * step * 10) / 10, Math.round(y * 10) / 10];
  });
}

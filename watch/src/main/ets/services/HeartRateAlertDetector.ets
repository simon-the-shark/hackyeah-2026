/** Readings below this are "no contact with the skin", not a heart rate. Matches the backend's lower bound. */
export const MIN_VALID_BPM: number = 20;
export const MAX_VALID_BPM: number = 250;

export function isPlausibleBpm(bpm: number): boolean {
  return Number.isInteger(bpm) && bpm >= MIN_VALID_BPM && bpm <= MAX_VALID_BPM;
}

/**
 * Fixed for now and not validated for any individual. Readings are informational,
 * never a medical assessment; the guardian decides what to do with an alert.
 */
export class HeartRateThresholds {
  lowBpm: number = 45;
  highBpm: number = 120;
  /** How long a reading must stay out of range before one alert is sent. */
  sustainedMs: number = 120 * 1000;
  /** How long it must stay back in range before the alert is resolved and detection re-arms. */
  recoveryMs: number = 120 * 1000;
  /** A longer silence (watch taken off, app paused) breaks continuity: timing starts again. */
  maxGapMs: number = 30 * 1000;
}

export enum EpisodeEventKind {
  OutOfRange,
  BackInRange
}

export class HeartRateEpisodeEvent {
  readonly kind: EpisodeEventKind;
  readonly bpm: number;
  /** 'high' or 'low' for OutOfRange; the direction of the resolved episode for BackInRange. */
  readonly direction: string;
  readonly at: number;

  constructor(kind: EpisodeEventKind, bpm: number, direction: string, at: number) {
    this.kind = kind;
    this.bpm = bpm;
    this.direction = direction;
    this.at = at;
  }
}

/**
 * Turns a stream of heart-rate readings into at most one "out of range" event per
 * episode and one "back in range" event when it ends. Pure logic, so it can be
 * tested without a sensor; the watch sends each event to the care service.
 */
export class HeartRateAlertDetector {
  readonly thresholds: HeartRateThresholds;
  private lastAt: number = -1;
  private outSince: number = -1;
  private outDirection: string = '';
  private inSince: number = -1;
  private alerting: boolean = false;
  private alertDirection: string = '';

  constructor(thresholds: HeartRateThresholds = new HeartRateThresholds()) {
    this.thresholds = thresholds;
  }

  /** True while an out-of-range event was sent and not yet followed by a back-in-range event. */
  isAlerting(): boolean {
    return this.alerting;
  }

  /** Feeds one reading taken at `at` (ms). Implausible readings are ignored. */
  feed(bpm: number, at: number): HeartRateEpisodeEvent | undefined {
    if (!isPlausibleBpm(bpm)) {
      return undefined;
    }
    if (this.lastAt >= 0 && at - this.lastAt > this.thresholds.maxGapMs) {
      // Nothing was observed in between, so neither episode can count as sustained.
      this.outSince = -1;
      this.inSince = -1;
    }
    this.lastAt = at;

    const direction = bpm > this.thresholds.highBpm ? 'high' : bpm < this.thresholds.lowBpm ? 'low' : '';
    if (direction !== '') {
      this.inSince = -1;
      if (this.outSince < 0 || direction !== this.outDirection) {
        this.outSince = at;
        this.outDirection = direction;
      }
      if (!this.alerting && at - this.outSince >= this.thresholds.sustainedMs) {
        this.alerting = true;
        this.alertDirection = direction;
        return new HeartRateEpisodeEvent(EpisodeEventKind.OutOfRange, bpm, direction, at);
      }
      return undefined;
    }

    this.outSince = -1;
    if (!this.alerting) {
      return undefined;
    }
    if (this.inSince < 0) {
      this.inSince = at;
    }
    if (at - this.inSince >= this.thresholds.recoveryMs) {
      this.alerting = false;
      this.inSince = -1;
      return new HeartRateEpisodeEvent(EpisodeEventKind.BackInRange, bpm, this.alertDirection, at);
    }
    return undefined;
  }

  /** Forgets partial timing, e.g. when monitoring pauses; an open alert stays open. */
  resetTiming(): void {
    this.lastAt = -1;
    this.outSince = -1;
    this.inSince = -1;
  }
}

/** Median of a non-empty list; used to reduce a window of readings to one shared sample. */
export function medianBpm(values: number[]): number {
  const sorted = values.slice().sort((a: number, b: number) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1 ? sorted[middle] : Math.round((sorted[middle - 1] + sorted[middle]) / 2);
}

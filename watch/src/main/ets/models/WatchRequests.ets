/** Request bodies for the care service. Field names follow `backend/README.md`. */

/** A location fix measured by this watch, never relayed from the phone. */
export class WatchLocationPoint {
  lat: number;
  lng: number;
  accuracyM: number;
  sampledAt: string;
  measuredBy: string = 'watch';

  constructor(lat: number, lng: number, accuracyM: number, sampledAt: number) {
    this.lat = lat;
    this.lng = lng;
    this.accuracyM = Math.max(0, accuracyM);
    this.sampledAt = new Date(sampledAt).toISOString();
  }
}

export class StatusReport {
  monitoringState: string;
  location?: WatchLocationPoint;
  battery?: number;
  source: string;

  constructor(monitoringState: string, source: string) {
    this.monitoringState = monitoringState;
    this.source = source;
  }
}

export class HeartRateSample {
  bpm: number;
  measuredAt: string;

  constructor(bpm: number, measuredAt: number) {
    this.bpm = bpm;
    this.measuredAt = new Date(measuredAt).toISOString();
  }
}

export class HeartRateUpload {
  source: string;
  heartRate: HeartRateSample[];

  constructor(source: string, heartRate: HeartRateSample[]) {
    this.source = source;
    this.heartRate = heartRate;
  }
}

/** What the watch observed; the server stores it in the alert and never evaluates it. */
export class HeartRateEpisode {
  bpm: number;
  direction: string;
  lowBpm: number;
  highBpm: number;
  sustainedSeconds: number;

  constructor(bpm: number, direction: string, lowBpm: number, highBpm: number, sustainedSeconds: number) {
    this.bpm = bpm;
    this.direction = direction;
    this.lowBpm = lowBpm;
    this.highBpm = highBpm;
    this.sustainedSeconds = sustainedSeconds;
  }
}

export class WatchEventRequest {
  id: string;
  type: string;
  occurredAt: string;
  source: string;
  location?: WatchLocationPoint;
  heartRate?: HeartRateEpisode;

  constructor(id: string, type: string, occurredAt: number, source: string) {
    this.id = id;
    this.type = type;
    this.occurredAt = new Date(occurredAt).toISOString();
    this.source = source;
  }
}

export interface RemoteSafeArea {
  lat: number;
  lng: number;
  radiusM: number;
}

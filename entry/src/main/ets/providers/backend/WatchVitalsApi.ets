import { BackendClient } from './BackendClient';

export interface RemoteGeoPoint {
  lat: number;
  lng: number;
  accuracyM?: number;
  sampledAt?: string;
  measuredBy?: string;
}

/** One device's latest heartbeat from `GET /status` (`devices[]`). */
export interface RemoteDeviceStatus {
  deviceId: string;
  deviceKind: string;
  monitoringState: string;
  location?: RemoteGeoPoint | null;
  battery?: number | null;
  source?: string;
  reportedAt: string;
}

export interface RemoteStatusResponse {
  devices?: RemoteDeviceStatus[];
  serverTime: string;
}

export interface RemoteHeartRateSample {
  bpm: number;
  measuredAt: string;
  source: string;
  deviceId: string;
}

export interface RemoteHeartRate {
  latest: RemoteHeartRateSample | null;
  items: RemoteHeartRateSample[];
  truncated: boolean;
  serverTime: string;
}

/** What the watch reported when a heart-rate alert was raised (`alert.details`). */
export interface RemoteHeartRateDetails {
  bpm?: number;
  direction?: string;
  lowBpm?: number;
  highBpm?: number;
  sustainedSeconds?: number;
}

export interface RemoteAlertEvent {
  source?: string;
}

export interface RemoteHeartRateAlert {
  id: string;
  seniorId: string;
  kind: string;
  createdAt: string;
  resolvedAt?: string | null;
  acknowledgedAt?: string | null;
  details?: RemoteHeartRateDetails | null;
  event?: RemoteAlertEvent | null;
}

interface RemoteAlertList {
  items: RemoteHeartRateAlert[];
}

export interface RemoteWatchCode {
  pairingCode: string;
  pairingExpiresAt: string;
}

export interface RemoteDevice {
  id: string;
  kind: string;
  lastSeenAt?: string | null;
}

interface RemoteDeviceList {
  items: RemoteDevice[];
}

/** Calls behind the guardian's "Watch & vitals" screen and the senior's watch pairing card. */
export class WatchVitalsApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  async status(seniorId: string): Promise<RemoteStatusResponse> {
    return this.client.get<RemoteStatusResponse>(`${this.senior(seniorId)}/status`);
  }

  async heartRate(seniorId: string, from: Date): Promise<RemoteHeartRate> {
    return this.client.get<RemoteHeartRate>(
      `${this.senior(seniorId)}/vitals/heart-rate?from=${encodeURIComponent(from.toISOString())}`);
  }

  /** The newest heart-rate alert for this senior from the guardian inbox, if any. */
  async latestHeartRateAlert(seniorId: string): Promise<RemoteHeartRateAlert | undefined> {
    const list = await this.client.get<RemoteAlertList>('/v1/alerts?limit=50');
    return (list.items ?? []).find((alert: RemoteHeartRateAlert) =>
      alert.kind === 'heart_rate' && alert.seniorId === seniorId);
  }

  async watchCode(): Promise<RemoteWatchCode> {
    return this.client.post<RemoteWatchCode>('/v1/pairing/watch-codes', new EmptyBody());
  }

  async watches(): Promise<RemoteDevice[]> {
    const list = await this.client.get<RemoteDeviceList>('/v1/devices');
    return (list.items ?? []).filter((device: RemoteDevice) => device.kind === 'watch');
  }

  async removeDevice(deviceId: string): Promise<void> {
    await this.client.delete(`/v1/devices/${encodeURIComponent(deviceId)}`);
  }

  private senior(seniorId: string): string {
    return `/v1/seniors/${encodeURIComponent(seniorId)}`;
  }
}

class EmptyBody {}

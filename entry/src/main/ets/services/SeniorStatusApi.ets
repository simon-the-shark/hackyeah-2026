import { http } from '@kit.NetworkKit';
import { SeniorSnapshot } from '../models/SeniorLocation';
import { apiSession, careApi } from './CareApi';

interface RemoteGeoPoint {
  lat: number;
  lng: number;
  accuracyM?: number;
  sampledAt?: string;
}

interface RemoteStatus {
  monitoringState: string;
  location?: RemoteGeoPoint | null;
  battery?: number | null;
  reportedAt: string;
  staleAlertedAt?: string | null;
  deviceKind?: string;
}

interface RemoteStatusResponse {
  status: RemoteStatus | null;
  /** Latest heartbeat per device, newest first. */
  devices?: RemoteStatus[];
  serverTime: string;
}

interface RemoteSafeArea {
  lat: number;
  lng: number;
  radiusM: number;
}

interface RemoteLinkedUser {
  id: string;
  displayName: string;
}

interface RemoteLinked {
  seniors?: RemoteLinkedUser[];
}

interface RemoteMe {
  linked?: RemoteLinked;
}

function isNumber(value: number | null | undefined): boolean {
  return typeof value === 'number' && isFinite(value);
}

/**
 * Reads the senior's last heartbeat (`GET /seniors/:id/status`), the configured
 * safe area and the senior's display name for the guardian Location tab.
 */
export class SeniorStatusApi {
  private seniorName: string = '';
  private nameSeniorId: string = '';

  async load(): Promise<SeniorSnapshot> {
    const snapshot = new SeniorSnapshot();
    const response = await careApi.request(`/seniors/${apiSession.seniorId}/status`,
      http.RequestMethod.GET) as RemoteStatusResponse;
    snapshot.fetchedAt = Date.now();

    // This tab describes the senior's phone; the watch has its own screen (Watch & vitals), so a watch
    // heartbeat must never appear here as the phone's. Only a backend without `devices` falls back to `status`.
    const devices = response.devices;
    const status: RemoteStatus | null | undefined = devices !== undefined
      ? devices.find((device: RemoteStatus) => device.deviceKind === 'phone')
      : response.status;
    if (status !== null && status !== undefined) {
      snapshot.hasStatus = true;
      snapshot.monitoringState = status.monitoringState;
      const serverNow = Date.parse(response.serverTime);
      const reportedAt = Date.parse(status.reportedAt);
      snapshot.reportedAgeMs = isFinite(serverNow) && isFinite(reportedAt) ? Math.max(0, serverNow - reportedAt) : 0;
      snapshot.monitoringLostRaised = status.staleAlertedAt !== null && status.staleAlertedAt !== undefined;
      const battery = status.battery;
      if (battery !== null && battery !== undefined && isNumber(battery)) {
        snapshot.battery = battery;
      }
      const location = status.location;
      if (location !== null && location !== undefined && isNumber(location.lat) && isNumber(location.lng)) {
        snapshot.hasLocation = true;
        snapshot.lat = location.lat;
        snapshot.lng = location.lng;
        const accuracy = location.accuracyM;
        if (accuracy !== undefined && isNumber(accuracy)) {
          snapshot.accuracyM = accuracy;
        }
      }
    }

    await this.loadSafeArea(snapshot);
    snapshot.seniorName = await this.loadSeniorName();
    return snapshot;
  }

  private async loadSafeArea(snapshot: SeniorSnapshot): Promise<void> {
    try {
      const area = await careApi.request(`/seniors/${apiSession.seniorId}/safe-area`,
        http.RequestMethod.GET) as RemoteSafeArea;
      if (isNumber(area.lat) && isNumber(area.lng) && isNumber(area.radiusM)) {
        snapshot.hasSafeArea = true;
        snapshot.areaLat = area.lat;
        snapshot.areaLng = area.lng;
        snapshot.areaRadiusM = area.radiusM;
      }
    } catch (error) {
      // 404 `not_found` means the guardian has not set up a safe area yet.
      const message = error instanceof Error ? error.message : '';
      snapshot.safeAreaKnown = message.includes('not_found');
    }
  }

  /** The name is cosmetic, so a failure falls back to a generic label. */
  private async loadSeniorName(): Promise<string> {
    if (this.nameSeniorId === apiSession.seniorId && this.seniorName !== '') {
      return this.seniorName;
    }
    try {
      const me = await careApi.request('/me', http.RequestMethod.GET) as RemoteMe;
      const seniors = me.linked?.seniors ?? [];
      const match = seniors.find((senior: RemoteLinkedUser) => senior.id === apiSession.seniorId);
      if (match !== undefined && match.displayName !== '') {
        this.seniorName = match.displayName;
        this.nameSeniorId = apiSession.seniorId;
        return this.seniorName;
      }
    } catch (error) {
      console.error('[SeniorStatusApi] could not load the senior name');
    }
    return 'Your senior';
  }
}

export const seniorStatusApi: SeniorStatusApi = new SeniorStatusApi();

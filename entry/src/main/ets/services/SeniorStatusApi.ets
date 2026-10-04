import { http } from '@kit.NetworkKit';
import { RemoteStatusResponse, SeniorSnapshot, snapshotFromStatus } from '../models/SeniorLocation';
import { apiSession, careApi } from './CareApi';
import { ApiError } from '../providers/backend/BackendClient';

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
 * Reads the last heartbeat of the senior's phone and watch
 * (`GET /seniors/:id/status`), the configured safe area and the senior's
 * display name for the guardian Location tab.
 */
export class SeniorStatusApi {
  private seniorName: string = '';
  private nameSeniorId: string = '';

  async load(): Promise<SeniorSnapshot> {
    const response = await careApi.request(`/seniors/${apiSession.seniorId}/status`,
      http.RequestMethod.GET) as RemoteStatusResponse;
    const snapshot = snapshotFromStatus(response, Date.now());
    await this.loadSafeArea(snapshot);
    const name = await this.loadSeniorName();
    if (name !== '') {
      snapshot.seniorName = name;
    }
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
      // 404 means the guardian has not set up a safe area yet; anything else leaves it unknown.
      snapshot.safeAreaKnown = error instanceof ApiError && error.status === 404;
    }
  }

  /** The paired senior's display name, or '' when unknown; the name is cosmetic, so failures are not raised. */
  async loadSeniorName(): Promise<string> {
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
    return '';
  }
}

export const seniorStatusApi: SeniorStatusApi = new SeniorStatusApi();

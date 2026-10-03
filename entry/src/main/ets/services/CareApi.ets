import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { BACKEND_BASE_URL } from '../providers/backend/BackendUrl';

export function generateEventId(): string {
  const platformId = util.generateRandomUUID(true);
  if (platformId.length === 36) {
    return platformId;
  }
  // preview runtime returns an empty UUID (their entropy source is unavailable).
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (character: string): string => {
    const value = Math.floor(Math.random() * 16);
    return (character === 'x' ? value : (value & 0x3) | 0x8).toString(16);
  });
}

export class BootstrapRequest {
  displayName: string;
  deviceKind: string = 'phone';
  code?: string;

  constructor(displayName: string) {
    this.displayName = displayName;
  }
}

export class SafetyEventRequest {
  id: string;
  type: string;
  occurredAt: string;
  location?: Object;

  constructor(id: string, type: string, occurredAt?: string) {
    this.id = id;
    this.type = type;
    this.occurredAt = occurredAt ?? new Date().toISOString();
  }
}

class EmptyResponse {}

export class ApiSession {
  baseUrl: string = BACKEND_BASE_URL;
  token: string = '';
  seniorId: string = '';
  role: string = '';

  configured(): boolean {
    return this.baseUrl !== '' && this.token !== '' && this.seniorId !== '';
  }

  clear(): void {
    this.token = '';
    this.seniorId = '';
    this.role = '';
  }
}

export const apiSession: ApiSession = new ApiSession();

export class CareApi {
  async publicRequest(baseUrl: string, path: string, method: http.RequestMethod, body: Object): Promise<Object> {
    const request = http.createHttp();
    try {
      const response = await request.request(`${baseUrl}/v1${path}`, {
        method: method,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      const data = JSON.parse(response.result as string) as Object;
      if (response.responseCode < 200 || response.responseCode >= 300) throw new Error(JSON.stringify(data));
      return data;
    } finally {
      request.destroy();
    }
  }

  async request(path: string, method: http.RequestMethod, body?: Object): Promise<Object> {
    if (!apiSession.configured()) {
      throw new Error('Connect this app to the care service first.');
    }
    const request = http.createHttp();
    try {
      const response = await request.request(`${apiSession.baseUrl}/v1${path}`, {
        method: method,
        header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiSession.token}` },
        extraData: body === undefined ? undefined : JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      const data = response.result === '' ? new EmptyResponse() : JSON.parse(response.result as string) as Object;
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(JSON.stringify(data));
      }
      return data;
    } finally {
      request.destroy();
    }
  }
}

export const careApi: CareApi = new CareApi();

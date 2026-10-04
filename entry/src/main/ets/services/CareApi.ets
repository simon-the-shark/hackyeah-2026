import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
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
  /** For `cancel`: the id of the SOS or fall event being called off. */
  cancelsEventId?: string;

  constructor(id: string, type: string, occurredAt?: string) {
    this.id = id;
    this.type = type;
    this.occurredAt = occurredAt ?? new Date().toISOString();
  }
}

export class ApiSession {
  baseUrl: string = BACKEND_BASE_URL;
  token: string = '';
  seniorId: string = '';
  role: string = '';
  displayName: string = '';

  configured(): boolean {
    return this.baseUrl !== '' && this.token !== '' && this.seniorId !== '';
  }

  clear(): void {
    this.token = '';
    this.seniorId = '';
    this.role = '';
    this.displayName = '';
  }
}

export const apiSession: ApiSession = new ApiSession();

// A client bound to the current pairing. Built per call, so pairing again or signing out takes effect immediately.
export function sessionClient(readTimeoutMs?: number): BackendClient {
  const config = new BackendConfig(apiSession.baseUrl, apiSession.token);
  return readTimeoutMs === undefined ? new BackendClient(config) : new BackendClient(config, readTimeoutMs);
}

// Compatibility facade for endpoints not yet moved to typed provider APIs.
// All transport, serialization, status handling and cleanup live in BackendClient.
export class CareApi {
  async publicRequest(baseUrl: string, path: string, method: http.RequestMethod, body: Object): Promise<Object> {
    return new BackendClient(new BackendConfig(baseUrl, '')).request<Object>(method, `/v1${path}`, body, '');
  }

  async request(path: string, method: http.RequestMethod, body?: Object): Promise<Object> {
    if (!apiSession.configured()) {
      throw new Error('Connect this app to the care service first.');
    }
    return sessionClient().request<Object>(method, `/v1${path}`, body);
  }
}

export const careApi: CareApi = new CareApi();

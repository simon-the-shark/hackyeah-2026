import { http } from '@kit.NetworkKit';

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

  constructor(id: string, type: string) {
    this.id = id;
    this.type = type;
    this.occurredAt = new Date().toISOString();
  }
}

class EmptyResponse {}

export class ApiSession {
  baseUrl: string = 'http://10.250.161.104:8787';
  token: string = '';
  seniorId: string = '';
  role: string = '';

  configured(): boolean {
    return this.baseUrl !== '' && this.token !== '' && this.seniorId !== '';
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

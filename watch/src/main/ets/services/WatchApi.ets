import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';

/** Same generator as the phone app: platform UUID, with a v4 fallback where the runtime returns an empty value. */
export function generateEventId(): string {
  const platformId = util.generateRandomUUID(true);
  if (platformId.length === 36) {
    return platformId;
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (character: string): string => {
    const value = Math.floor(Math.random() * 16);
    return (character === 'x' ? value : (value & 0x3) | 0x8).toString(16);
  });
}

/** A failed request. `status` is 0 when the care service could not be reached at all. */
export class WatchApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }

  /** 4xx: the request itself is wrong, so retrying it unchanged cannot help. */
  isRejected(): boolean {
    return this.status >= 400 && this.status < 500;
  }
}

/** The watch is a device of the senior: its token acts for the senior, so it only calls what it needs. */
export class WatchSession {
  baseUrl: string = 'http://localhost:8787';
  token: string = '';
  seniorId: string = '';
  deviceId: string = '';

  configured(): boolean {
    return this.baseUrl !== '' && this.token !== '' && this.seniorId !== '';
  }

  clear(): void {
    this.token = '';
    this.seniorId = '';
    this.deviceId = '';
  }
}

export const watchSession: WatchSession = new WatchSession();

class ClaimRequest {
  code: string;

  constructor(code: string) {
    this.code = code;
  }
}

export interface ClaimResponse {
  seniorId: string;
  deviceId: string;
  token: string;
}

class EmptyResponse {}

export class WatchApi {
  /** Exchanges the 6-digit watch code shown on the senior's phone for this watch's own device token. */
  async claim(baseUrl: string, code: string): Promise<ClaimResponse> {
    return await this.send(`${baseUrl}/v1/pairing/watch-claim`, http.RequestMethod.POST, '', new ClaimRequest(code)) as
      ClaimResponse;
  }

  async request(path: string, method: http.RequestMethod, body?: Object): Promise<Object> {
    if (!watchSession.configured()) {
      throw new WatchApiError(401, 'This watch is not paired yet.');
    }
    return await this.send(`${watchSession.baseUrl}/v1${path}`, method, watchSession.token, body);
  }

  private async send(url: string, method: http.RequestMethod, token: string, body?: Object): Promise<Object> {
    const request = http.createHttp();
    try {
      const header: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token !== '') {
        header['Authorization'] = `Bearer ${token}`;
      }
      let response: http.HttpResponse;
      try {
        response = await request.request(url, {
          method: method,
          header: header,
          extraData: body === undefined ? undefined : JSON.stringify(body),
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 10000
        });
      } catch (error) {
        throw new WatchApiError(0, 'The care service could not be reached.');
      }
      const text = response.result as string;
      let data: Object = new EmptyResponse();
      if (text !== '') {
        try {
          data = JSON.parse(text) as Object;
        } catch (error) {
          throw new WatchApiError(response.responseCode, 'The care service sent an unreadable answer.');
        }
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new WatchApiError(response.responseCode, JSON.stringify(data));
      }
      return data;
    } finally {
      request.destroy();
    }
  }
}

export const watchApi: WatchApi = new WatchApi();

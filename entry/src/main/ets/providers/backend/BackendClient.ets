import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackendConfig } from './BackendConfig';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'BackendClient';
const CONNECT_TIMEOUT_MS = 10000;
const READ_TIMEOUT_MS = 15000;

export enum ApiErrorKind {
  // The request never got an HTTP response (offline, timeout, unreachable host). Safe to retry later.
  Network,
  // The backend answered with an error status.
  Http,
  // The backend answered 2xx with a body this app cannot read.
  InvalidResponse
}

interface ErrorBody {
  error?: ErrorDetails;
}

interface ErrorDetails {
  code?: string;
  message?: string;
  details?: Object;
}

export class ApiError extends Error {
  readonly kind: ApiErrorKind;
  // HTTP status, or 0 when there was no response.
  readonly status: number;
  // Backend error code such as "not_found" or "unauthorized"; empty when unknown.
  readonly code: string;
  // Backend `error.details`, e.g. `{ current }` for a 409 version conflict; undefined when absent.
  readonly details: Object | undefined;

  constructor(kind: ApiErrorKind, status: number, code: string, message: string, details?: Object) {
    super(message);
    this.name = 'ApiError';
    this.kind = kind;
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

class RawResponse {
  readonly status: number;
  readonly text: string;

  constructor(status: number, text: string) {
    this.status = status;
    this.text = text;
  }
}

class EmptyResponse {}

// For a 2xx response whose payload does not have the documented shape.
export function invalidResponse(what: string): ApiError {
  return new ApiError(ApiErrorKind.InvalidResponse, 200, '', `The server sent an unreadable ${what}.`);
}

// Thin JSON-over-HTTP client for the Carely backend. Every call sends the device token and
// maps failures to ApiError, so callers never see raw transport errors.
export class BackendClient {
  private readonly config: BackendConfig;

  constructor(config: BackendConfig) {
    this.config = config;
  }

  async get<T>(path: string): Promise<T> {
    return this.send<T>(http.RequestMethod.GET, path, undefined);
  }

  async post<T>(path: string, body: Object): Promise<T> {
    return this.send<T>(http.RequestMethod.POST, path, JSON.stringify(body));
  }

  async put<T>(path: string, body: Object): Promise<T> {
    return this.send<T>(http.RequestMethod.PUT, path, JSON.stringify(body));
  }

  // DELETE answers 204 with no body, so there is nothing to return.
  async delete(path: string): Promise<void> {
    await this.sendRaw(http.RequestMethod.DELETE, path, undefined);
  }

  // Generic request used by legacy feature endpoints that do not have a typed API yet.
  // Passing an empty token sends an unauthenticated request (for account bootstrap).
  async request<T>(method: http.RequestMethod, path: string, body?: Object,
    deviceToken: string = this.config.deviceToken): Promise<T> {
    const response = await this.sendRaw(method, path, body === undefined ? undefined : JSON.stringify(body), deviceToken);
    if (response.text.length === 0) {
      return new EmptyResponse() as T;
    }
    try {
      return JSON.parse(response.text) as T;
    } catch (err) {
      throw new ApiError(ApiErrorKind.InvalidResponse, response.status, '',
        'The server sent a response this app cannot read.');
    }
  }

  private async send<T>(method: http.RequestMethod, path: string, body: string | undefined): Promise<T> {
    const response = await this.sendRaw(method, path, body);
    if (response.text.length === 0) {
      throw new ApiError(ApiErrorKind.InvalidResponse, response.status, '', 'The server sent an empty response.');
    }
    try {
      return JSON.parse(response.text) as T;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `${method} ${path} returned invalid JSON`);
      throw new ApiError(ApiErrorKind.InvalidResponse, response.status, '',
        'The server sent a response this app cannot read.');
    }
  }

  // Sends one request and returns the 2xx status and body text; any other outcome becomes an ApiError.
  private async sendRaw(method: http.RequestMethod, path: string, body: string | undefined,
    deviceToken: string = this.config.deviceToken): Promise<RawResponse> {
    const headers: Record<string, string> = { 'Accept': 'application/json' };
    if (deviceToken !== '') {
      headers['Authorization'] = `Bearer ${deviceToken}`;
    }
    if (body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }
    const options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: CONNECT_TIMEOUT_MS,
      readTimeout: READ_TIMEOUT_MS
    };
    // Each HttpRequest object serves exactly one request and must be destroyed afterwards.
    const request = http.createHttp();
    let response: http.HttpResponse;
    try {
      response = await request.request(`${this.config.baseUrl}${path}`, options);
    } catch (err) {
      const error = err as BusinessError;
      hilog.warn(LOG_DOMAIN, LOG_TAG, `${method} ${path} failed: ${error.code} ${error.message}`);
      throw new ApiError(ApiErrorKind.Network, 0, '', 'Cannot reach the Carely server.');
    } finally {
      request.destroy();
    }

    const status = response.responseCode as number;
    const text = typeof response.result === 'string' ? response.result : '';
    if (status < 200 || status >= 300) {
      throw this.httpError(method, path, status, text);
    }
    return new RawResponse(status, text);
  }

  private httpError(method: http.RequestMethod, path: string, status: number, text: string): ApiError {
    let code = '';
    let message = `The server answered with status ${status}.`;
    let extra: Object | undefined = undefined;
    try {
      const details = (JSON.parse(text) as ErrorBody).error;
      if (details !== undefined && details !== null) {
        code = typeof details.code === 'string' ? details.code : '';
        message = typeof details.message === 'string' ? details.message : message;
        extra = details.details === null ? undefined : details.details;
      }
    } catch (err) {
      // Not the backend's JSON error shape (for example a proxy page); keep the generic message.
    }
    hilog.warn(LOG_DOMAIN, LOG_TAG, `${method} ${path} -> ${status} ${code}`);
    return new ApiError(ApiErrorKind.Http, status, code, message, extra);
  }
}

export class BackendConfig {
  // Base URL without a trailing slash, e.g. "http://192.168.1.10:8787".
  readonly baseUrl: string;
  readonly deviceToken: string;

  constructor(baseUrl: string, deviceToken: string) {
    this.baseUrl = baseUrl.replace(new RegExp('/+$'), '');
    this.deviceToken = deviceToken;
  }
}

import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'BackendConfig';
// Git-ignored development file; see entry/backend.example.json.
const CONFIG_FILE = 'backend.json';

interface BackendConfigFile {
  baseUrl?: string;
  deviceToken?: string;
}

export class BackendConfig {
  // Base URL without a trailing slash, e.g. "http://192.168.1.10:8787".
  readonly baseUrl: string;
  readonly deviceToken: string;

  constructor(baseUrl: string, deviceToken: string) {
    this.baseUrl = baseUrl.replace(new RegExp('/+$'), '');
    this.deviceToken = deviceToken;
  }
}

// Development stand-in for pairing: reads the API address and this device's token from a bundled raw file.
// Returns undefined when the file is missing or incomplete, so the UI can explain how to connect.
export function loadBackendConfig(context: common.Context): BackendConfig | undefined {
  try {
    const bytes = context.resourceManager.getRawFileContentSync(CONFIG_FILE);
    // buffer rather than util.TextDecoder: the Previewer only mocks TextDecoder and returns an empty string.
    const json = buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString('utf-8');
    const file = JSON.parse(json) as BackendConfigFile;
    const baseUrl = typeof file.baseUrl === 'string' ? file.baseUrl.trim() : '';
    const deviceToken = typeof file.deviceToken === 'string' ? file.deviceToken.trim() : '';
    if (baseUrl.length === 0 || deviceToken.length === 0) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, `${CONFIG_FILE} needs both baseUrl and deviceToken`);
      return undefined;
    }
    return new BackendConfig(baseUrl, deviceToken);
  } catch (err) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, `No usable ${CONFIG_FILE}: ${(err as BusinessError).message}`);
    return undefined;
  }
}

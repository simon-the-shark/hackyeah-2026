import { common } from '@kit.AbilityKit';
import { AccountApi } from '../providers/backend/AccountApi';
import { BackendClient } from '../providers/backend/BackendClient';
import { loadBackendConfig } from '../providers/backend/BackendConfig';

// The senior this device is paired with, shared by every senior feature that talks to the backend.
export class SeniorAccount {
  readonly client: BackendClient;
  private readonly accountApi: AccountApi;
  private seniorId: string | undefined = undefined;

  constructor(client: BackendClient) {
    this.client = client;
    this.accountApi = new AccountApi(client);
  }

  // Asks the backend once, then reuses the answer for the rest of the session.
  async currentSeniorId(): Promise<string> {
    if (this.seniorId === undefined) {
      this.seniorId = await this.accountApi.currentSeniorId();
    }
    return this.seniorId;
  }
}

let sharedAccount: SeniorAccount | undefined = undefined;

// Undefined until the device has a backend configuration (see entry/backend.example.json).
export function seniorAccount(context: common.Context): SeniorAccount | undefined {
  if (sharedAccount === undefined) {
    const config = loadBackendConfig(context);
    if (config !== undefined) {
      sharedAccount = new SeniorAccount(new BackendClient(config));
    }
  }
  return sharedAccount;
}

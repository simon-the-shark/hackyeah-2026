import { AccountApi } from '../providers/backend/AccountApi';
import { BackendClient } from '../providers/backend/BackendClient';
import { BackendConfig } from '../providers/backend/BackendConfig';
import { apiSession } from './CareApi';

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

// Undefined until this phone is paired with a Carely care plan.
export function seniorAccount(): SeniorAccount | undefined {
  if (sharedAccount === undefined) {
    if (apiSession.configured()) {
      sharedAccount = new SeniorAccount(new BackendClient(new BackendConfig(apiSession.baseUrl, apiSession.token)));
    }
  }
  return sharedAccount;
}

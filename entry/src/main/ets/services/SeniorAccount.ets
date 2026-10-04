import { AccountApi } from '../providers/backend/AccountApi';
import { BackendClient } from '../providers/backend/BackendClient';
import { apiSession, sessionClient } from './CareApi';

// The senior this device is paired with, shared by every senior feature that talks to the backend.
export class SeniorAccount {
  readonly client: BackendClient;
  // The device token this account was created for; a new pairing gets a new account.
  readonly token: string;
  private readonly accountApi: AccountApi;
  private seniorId: string | undefined = undefined;

  constructor(client: BackendClient, token: string) {
    this.client = client;
    this.token = token;
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

// Undefined until this phone is paired with a Carely care plan. Signing out or pairing again replaces
// the account, so no feature keeps talking to the backend with the previous senior's token.
export function seniorAccount(): SeniorAccount | undefined {
  if (!apiSession.configured()) {
    sharedAccount = undefined;
  } else if (sharedAccount === undefined || sharedAccount.token !== apiSession.token) {
    sharedAccount = new SeniorAccount(sessionClient(), apiSession.token);
  }
  return sharedAccount;
}

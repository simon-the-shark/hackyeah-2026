import { ApiError, ApiErrorKind, BackendClient, invalidResponse } from './BackendClient';

interface MeDto {
  id?: string;
  role?: string;
}

// Identity endpoint shared by all senior features.
export class AccountApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  // The senior this device belongs to. Throws ApiError with status 403 for a guardian device.
  async currentSeniorId(): Promise<string> {
    const me = await this.client.get<MeDto>('/v1/me');
    if (typeof me.id !== 'string') {
      throw invalidResponse('account');
    }
    if (me.role !== 'senior') {
      throw new ApiError(ApiErrorKind.Http, 403, 'forbidden', 'This device is not paired as a senior.');
    }
    return me.id;
  }
}

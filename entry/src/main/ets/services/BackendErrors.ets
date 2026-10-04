import { ApiError, ApiErrorKind } from '../providers/backend/BackendClient';

// Senior-facing explanation of a failed backend call. `fallback` names what could not be loaded.
export function describeBackendError(err: Object, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.kind === ApiErrorKind.Network) {
      return 'Cannot reach the Carely server. Check the internet connection and try again.';
    }
    if (err.status === 401) {
      return PAIRING_EXPIRED_DETAIL;
    }
    if (err.status === 403) {
      return 'This phone is not connected to a care plan. Ask your guardian to pair it again.';
    }
    if (err.status >= 500) {
      return 'The care service is temporarily unavailable. Your information has not been loaded. Please try again shortly.';
    }
    return fallback + ' Please try again.';
  }
  return fallback;
}

/** Shared wording for a 401: the server no longer knows this phone's token. RoleHome's banner offers the sign-out. */
export const PAIRING_EXPIRED_MESSAGE =
  'This phone\'s pairing is no longer valid. Sign out and pair it again with a new code from the senior\'s phone.';

/** What a screen shows for a 401 under that banner, so the full explanation is not repeated. */
export const PAIRING_EXPIRED_DETAIL = 'This phone needs to be paired again before this can load.';

export const NOT_CONFIGURED_MESSAGE = 'This phone is not connected to a Carely care plan yet. Complete setup and pairing first.';

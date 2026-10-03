import { ApiError, ApiErrorKind } from '../providers/backend/BackendClient';

// Senior-facing explanation of a failed backend call. `fallback` names what could not be loaded.
export function describeBackendError(err: Object, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.kind === ApiErrorKind.Network) {
      return 'Cannot reach the Carely server. Check the internet connection and try again.';
    }
    if (err.status === 401 || err.status === 403) {
      return 'This phone is not connected to a care plan. Ask your guardian to pair it again.';
    }
    if (err.status >= 500) {
      return 'The care service is temporarily unavailable. Your information has not been loaded. Please try again shortly.';
    }
    return fallback + ' Please try again.';
  }
  return fallback;
}

export const NOT_CONFIGURED_MESSAGE = 'This phone is not connected to a Carely care plan yet. Complete setup and pairing first.';

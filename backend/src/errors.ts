export type ErrorCode =
  | "validation_error"
  | "unauthorized"
  | "forbidden"
  | "not_found"
  | "version_conflict"
  | "pairing_expired"
  | "rate_limited"
  | "session_closed"
  | "session_full"
  | "no_speech"
  | "assistant_unavailable"
  | "internal_error";

export class ApiError extends Error {
  constructor(
    readonly status: 400 | 401 | 403 | 404 | 409 | 410 | 422 | 429 | 500 | 503,
    readonly code: ErrorCode,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
  }
}

export const notFound = (what: string) => new ApiError(404, "not_found", `${what} not found`);

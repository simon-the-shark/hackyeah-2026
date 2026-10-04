// An HTTP status that will not change on retry (validation, not found, conflict). Expired sessions (401),
// timeouts (408) and rate limits (429) are worth retrying, like server errors.
export function isPermanentRejectionStatus(status: number): boolean {
  return status >= 400 && status < 500 && status !== 401 && status !== 408 && status !== 429;
}

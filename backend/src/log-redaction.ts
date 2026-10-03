const SENSITIVE_BODY_FIELDS = /token|pairing.?code|authorization|password|secret|credential|api.?key/i;

export function redactBody(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redactBody);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [key, SENSITIVE_BODY_FIELDS.test(key) ? "[REDACTED]" : redactBody(nested)]),
    );
  }
  return value;
}

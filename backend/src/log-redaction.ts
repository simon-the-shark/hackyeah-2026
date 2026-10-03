const SENSITIVE_BODY_FIELDS = /token|pairing.?code|authorization|password|secret|credential|api.?key/i;
/** Health readings are personal data: the dev request log never shows them. */
const HEALTH_BODY_FIELDS = /bpm|heart.?rate/i;
/** What the senior said in a wellbeing check-in, its recording and its summary; exact keys only. */
const WELLBEING_BODY_FIELDS = /^(text|audio|reply|summary|concerns|attentionReason|structured|transcript)$/i;

export function redactBody(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redactBody);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [
        key,
        SENSITIVE_BODY_FIELDS.test(key) || HEALTH_BODY_FIELDS.test(key) || WELLBEING_BODY_FIELDS.test(key)
          ? "[REDACTED]"
          : redactBody(nested),
      ]),
    );
  }
  return value;
}

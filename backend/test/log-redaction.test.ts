import { describe, expect, it } from "vitest";
import { redactBody } from "../src/log-redaction.js";

describe("redactBody", () => {
  it("redacts bearer tokens and pairing codes in JSON bodies", () => {
    expect(
      redactBody({
        token: "secret-token",
        pairingCode: "123456",
        seniorId: "550e8400-e29b-41d4-a716-446655440000",
      }),
    ).toEqual({
      token: "[REDACTED]",
      pairingCode: "[REDACTED]",
      seniorId: "550e8400-e29b-41d4-a716-446655440000",
    });
  });
});

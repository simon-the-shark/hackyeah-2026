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

  it("redacts heart-rate readings but keeps their context", () => {
    expect(
      redactBody({
        kind: "heart_rate",
        heartRate: [{ bpm: 72, measuredAt: "2026-10-03T12:00:00Z" }],
        details: { bpm: 134, direction: "high", lowBpm: 45, highBpm: 120 },
        latest: { bpm: 72, measuredAt: "2026-10-03T12:00:00Z" },
      }),
    ).toEqual({
      kind: "heart_rate",
      heartRate: "[REDACTED]",
      details: { bpm: "[REDACTED]", direction: "high", lowBpm: "[REDACTED]", highBpm: "[REDACTED]" },
      latest: { bpm: "[REDACTED]", measuredAt: "2026-10-03T12:00:00Z" },
    });
  });
});

describe("redactBody for wellbeing check-ins", () => {
  it("redacts what the senior said, recordings and summaries but keeps ids and flags", () => {
    expect(
      redactBody({
        message: { id: "m1", role: "senior", text: "My knee hurts", inputMode: "voice" },
        reply: { id: "m2", text: "I am sorry to hear that." },
        audio: "AAAA",
        audioFormat: "m4a",
        report: { summary: "Halina's knee hurts.", structured: { mood: "low" }, source: "ai" },
        suggestFinish: false,
        safetyConcern: true,
      }),
    ).toEqual({
      message: { id: "m1", role: "senior", text: "[REDACTED]", inputMode: "voice" },
      reply: "[REDACTED]",
      audio: "[REDACTED]",
      audioFormat: "m4a",
      report: { summary: "[REDACTED]", structured: "[REDACTED]", source: "ai" },
      suggestFinish: false,
      safetyConcern: true,
    });
  });
});

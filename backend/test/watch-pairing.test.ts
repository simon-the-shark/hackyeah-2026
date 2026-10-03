import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.time.now = new Date("2026-10-03T12:00:00Z");
});

describe("watch pairing", () => {
  it("issues a short-lived watch code to the senior only, separate from the guardian code", async () => {
    const { seniorToken, guardianToken } = await t.pair();
    expect((await t.call("POST", "/v1/pairing/watch-codes", guardianToken)).status).toBe(403);

    const first = await t.call("POST", "/v1/pairing/watch-codes", seniorToken);
    expect(first.status).toBe(201);
    expect(first.body.pairingCode).toMatch(/^\d{6}$/);
    expect(new Date(first.body.pairingExpiresAt).toISOString()).toBe("2026-10-03T12:05:00.000Z");

    // The active code is reused, and it is never the guardian code.
    const again = (await t.call("POST", "/v1/pairing/watch-codes", seniorToken)).body;
    expect(again.pairingCode).toBe(first.body.pairingCode);
    const guardianCode = (await t.call("POST", "/v1/pairing/codes", seniorToken)).body;
    expect(guardianCode.pairingCode).not.toBe(first.body.pairingCode);
  });

  it("rotates a live code on request so the old one stops working", async () => {
    const { seniorToken } = await t.pair();
    for (const path of ["/v1/pairing/codes", "/v1/pairing/watch-codes"]) {
      const old = (await t.call("POST", path, seniorToken)).body.pairingCode;
      const rotated = await t.call("POST", `${path}?rotate=true`, seniorToken);
      expect(rotated.status).toBe(201);
      expect(rotated.body.pairingCode).toMatch(/^\d{6}$/);
      expect(rotated.body.pairingCode).not.toBe(old);
      // Without rotate, the new code is the live one.
      expect((await t.call("POST", path, seniorToken)).body.pairingCode).toBe(rotated.body.pairingCode);
    }
    const guardianCode = (await t.call("POST", "/v1/pairing/codes", seniorToken)).body.pairingCode;
    const watchCode = (await t.call("POST", "/v1/pairing/watch-codes", seniorToken)).body.pairingCode;
    await t.call("POST", "/v1/pairing/codes?rotate=true", seniorToken);
    await t.call("POST", "/v1/pairing/watch-codes?rotate=true", seniorToken);
    const claim = await t.call("POST", "/v1/pairing/claim", undefined, { code: guardianCode, displayName: "Eve" });
    expect(claim.status).toBe(410);
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: watchCode })).status).toBe(410);
    expect((await t.call("POST", "/v1/pairing/codes?rotate=maybe", seniorToken)).status).toBe(400);
  });

  it("turns a claimed code into a watch device of the senior that can report its own location", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    const code = (await t.call("POST", "/v1/pairing/watch-codes", seniorToken)).body.pairingCode;

    const claim = await t.call("POST", "/v1/pairing/watch-claim", undefined, { code });
    expect(claim.status).toBe(201);
    expect(claim.body.seniorId).toBe(seniorId);
    const watchToken = claim.body.token as string;

    const me = (await t.call("GET", "/v1/me", watchToken)).body;
    expect(me.role).toBe("senior");
    expect(me.id).toBe(seniorId);
    const devices = (await t.call("GET", "/v1/devices", seniorToken)).body.items;
    expect(devices.map((d: { kind: string }) => d.kind)).toEqual(["phone", "watch"]);

    // Location needs no watch-specific endpoint: the per-device heartbeat already carries it.
    const hb = await t.call("PUT", `/v1/seniors/${seniorId}/status`, watchToken, {
      monitoringState: "unknown",
      location: { lat: 52.23, lng: 21.01, accuracyM: 12, measuredBy: "watch" },
      battery: 64,
      source: "simulated",
    });
    expect(hb.status).toBe(200);
    const status = (await t.call("GET", `/v1/seniors/${seniorId}/status`, guardianToken)).body;
    const watch = status.devices.find((d: { deviceKind: string }) => d.deviceKind === "watch");
    expect(watch.location.measuredBy).toBe("watch");
    expect(watch.battery).toBe(64);
    expect(watch.source).toBe("simulated");
  });

  it("rejects used and expired codes", async () => {
    const { seniorToken } = await t.pair();
    const code = (await t.call("POST", "/v1/pairing/watch-codes", seniorToken)).body.pairingCode;
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code })).status).toBe(201);
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code })).status).toBe(410);

    const fresh = (await t.call("POST", "/v1/pairing/watch-codes", seniorToken)).body.pairingCode;
    t.time.now = new Date("2026-10-03T12:05:01Z");
    const expired = await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: fresh });
    expect(expired.status).toBe(410);
    expect(expired.body.error.code).toBe("pairing_expired");
  });

  it("never lets a guardian code add a watch, nor a watch code link a guardian", async () => {
    const senior = (await t.call("POST", "/v1/seniors", undefined, { displayName: "Halina" })).body;
    const watchCode = (await t.call("POST", "/v1/pairing/watch-codes", senior.token)).body.pairingCode;

    // A guardian code at the watch endpoint is refused and stays usable.
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: senior.pairingCode })).status).toBe(410);
    // A watch code at the guardian endpoint is refused, stays usable, and links nobody.
    const asGuardian = await t.call("POST", "/v1/pairing/claim", undefined, { code: watchCode, displayName: "Eve" });
    expect(asGuardian.status).toBe(410);
    expect((await t.call("GET", "/v1/me", senior.token)).body.linked.guardians).toEqual([]);

    expect(
      (await t.call("POST", "/v1/pairing/claim", undefined, { code: senior.pairingCode, displayName: "Marek" })).status,
    ).toBe(201);
    expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code: watchCode })).status).toBe(201);
  });

  it("validates the code format", async () => {
    for (const code of ["12345", "abcdef", "1234567"]) {
      expect((await t.call("POST", "/v1/pairing/watch-claim", undefined, { code })).status).toBe(400);
    }
  });
});

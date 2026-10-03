import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.time.now = new Date("2026-10-03T12:00:00Z");
});

describe("care links", () => {
  it("links an existing guardian to a second senior", async () => {
    const a = await t.pair();
    const b = (await t.call("POST", "/v1/seniors", undefined, { displayName: "Zofia" })).body;
    const res = await t.call("POST", "/v1/pairing/claim", a.guardianToken, { code: b.pairingCode, displayName: "ignored" });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeUndefined();
    const me = (await t.call("GET", "/v1/me", a.guardianToken)).body;
    expect(me.linked.seniors.map((s: { displayName: string }) => s.displayName).sort()).toEqual(["Halina", "Zofia"]);
    expect((await t.call("GET", `/v1/seniors/${b.seniorId}/status`, a.guardianToken)).status).toBe(200);
  });

  it("rejects a senior token or an invalid token on claim", async () => {
    const a = await t.pair();
    const b = (await t.call("POST", "/v1/seniors", undefined, { displayName: "Zofia" })).body;
    const body = { code: b.pairingCode, displayName: "x" };
    expect((await t.call("POST", "/v1/pairing/claim", "nope", body)).status).toBe(401);
    expect((await t.call("POST", "/v1/pairing/claim", a.seniorToken, body)).status).toBe(403);
    // The code was not consumed by the rejected attempts.
    expect((await t.call("POST", "/v1/pairing/claim", undefined, body)).status).toBe(201);
  });

  it("lets either side unlink, after which the guardian is forbidden", async () => {
    const a = await t.pair();
    const me = (await t.call("GET", "/v1/me", a.guardianToken)).body;
    const other = await t.pair();
    const path = `/v1/care-links/${a.seniorId}/${me.id}`;
    expect((await t.call("DELETE", path, other.guardianToken)).status).toBe(403);
    expect((await t.call("DELETE", path, a.seniorToken)).status).toBe(204);
    expect((await t.call("DELETE", path, a.seniorToken)).status).toBe(404);
    expect((await t.call("GET", `/v1/seniors/${a.seniorId}/alerts`, a.guardianToken)).status).toBe(403);
  });
});

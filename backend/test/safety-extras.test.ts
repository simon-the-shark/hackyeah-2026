import { randomUUID } from "node:crypto";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.push.result = "sent";
  t.time.now = new Date("2026-10-03T12:00:00Z");
});

const event = (type: string, extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  type,
  occurredAt: "2026-10-03T11:59:58Z",
  ...extra,
});

describe("event provenance", () => {
  it("labels simulated events in the alert and the push title", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("area_exit", { source: "trace_replay" }));
    expect(t.push.calls[0]!.message.title).toMatch(/^\[Simulation\] /);
    const list = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body;
    expect(list.items[0].event.source).toBe("trace_replay");
  });

  it("defaults to device and keeps the location's measuring device", async () => {
    const { seniorId, seniorToken, guardianToken } = await t.pair();
    await t.call(
      "POST",
      `/v1/seniors/${seniorId}/events`,
      seniorToken,
      event("sos", { location: { lat: 50.06, lng: 19.93, measuredBy: "phone" } }),
    );
    expect(t.push.calls[0]!.message.title).not.toMatch(/Simulation/);
    const alert = (await t.call("GET", `/v1/seniors/${seniorId}/alerts`, guardianToken)).body.items[0];
    expect(alert.event.source).toBe("device");
    expect(alert.event.location.measuredBy).toBe("phone");
  });

  it("rejects an unknown source", async () => {
    const { seniorId, seniorToken } = await t.pair();
    const res = await t.call("POST", `/v1/seniors/${seniorId}/events`, seniorToken, event("sos", { source: "guess" }));
    expect(res.status).toBe(400);
  });
});

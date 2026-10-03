import { eq } from "drizzle-orm";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { vitalSamples } from "../src/db/schema.js";
import { runWatchdogOnce } from "../src/services/watchdog.js";
import { setup } from "./helpers.js";

const t = setup();
afterAll(() => t.close());
beforeEach(async () => {
  await t.reset();
  t.push.calls = [];
  t.time.now = new Date("2026-10-03T12:00:00Z");
});

async function withWatch() {
  const pair = await t.pair();
  const code = (await t.call("POST", "/v1/pairing/watch-codes", pair.seniorToken)).body.pairingCode;
  const watch = (await t.call("POST", "/v1/pairing/watch-claim", undefined, { code })).body;
  return { ...pair, watchToken: watch.token as string, watchId: watch.deviceId as string };
}

const at = (iso: string, bpm: number) => ({ bpm, measuredAt: iso });
const upload = (seniorId: string, token: string, heartRate: unknown[], source = "simulated") =>
  t.call("POST", `/v1/seniors/${seniorId}/vitals`, token, { source, heartRate });
const read = (seniorId: string, token: string, query = "") =>
  t.call("GET", `/v1/seniors/${seniorId}/vitals/heart-rate${query}`, token);

describe("heart-rate samples", () => {
  it("stores a batch and shows it to the guardian oldest first, with the latest reading", async () => {
    const { seniorId, watchToken, watchId, guardianToken } = await withWatch();
    const res = await upload(seniorId, watchToken, [
      at("2026-10-03T11:59:00Z", 72),
      at("2026-10-03T11:58:00Z", 70),
      at("2026-10-03T11:59:30Z", 75),
    ]);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ stored: 3, duplicates: 0 });

    const view = (await read(seniorId, guardianToken)).body;
    expect(view.items.map((s: { bpm: number }) => s.bpm)).toEqual([70, 72, 75]);
    expect(view.latest).toMatchObject({ bpm: 75, source: "simulated", deviceId: watchId });
    expect(view.truncated).toBe(false);
  });

  it("is idempotent per device and instant", async () => {
    const { seniorId, watchToken } = await withWatch();
    const batch = [at("2026-10-03T11:58:00Z", 70), at("2026-10-03T11:59:00Z", 72)];
    await upload(seniorId, watchToken, batch);
    const retry = await upload(seniorId, watchToken, batch);
    expect(retry.status).toBe(200);
    expect(retry.body).toMatchObject({ stored: 0, duplicates: 2 });

    const overlap = await upload(seniorId, watchToken, [batch[1], at("2026-10-03T11:59:30Z", 74), at("2026-10-03T11:59:30Z", 74)]);
    expect(overlap.status).toBe(201);
    expect(overlap.body).toMatchObject({ stored: 1, duplicates: 2 });
  });

  it("rejects implausible values, empty or oversized batches and a missing source", async () => {
    const { seniorId, watchToken } = await withWatch();
    const ok = "2026-10-03T11:59:00Z";
    for (const heartRate of [[at(ok, 0)], [at(ok, 251)], [at(ok, 72.5)], []]) {
      expect((await upload(seniorId, watchToken, heartRate)).status).toBe(400);
    }
    const tooMany = Array.from({ length: 501 }, (_, i) => at(new Date(Date.parse(ok) - i * 1000).toISOString(), 70));
    expect((await upload(seniorId, watchToken, tooMany)).status).toBe(400);
    const noSource = await t.call("POST", `/v1/seniors/${seniorId}/vitals`, watchToken, { heartRate: [at(ok, 70)] });
    expect(noSource.status).toBe(400);
  });

  it("rejects the whole batch when a timestamp is in the future or too old", async () => {
    const { seniorId, watchToken, guardianToken } = await withWatch();
    const future = await upload(seniorId, watchToken, [at("2026-10-03T11:59:00Z", 70), at("2026-10-03T12:06:00Z", 71)]);
    expect(future.status).toBe(400);
    expect(future.body.error.details[0].path).toBe("heartRate.1.measuredAt");
    expect((await upload(seniorId, watchToken, [at("2026-09-25T12:00:00Z", 70)])).status).toBe(400);
    expect((await read(seniorId, guardianToken)).body.latest).toBeNull();
  });

  it("lets only the senior upload and only linked users read", async () => {
    const { seniorId, seniorToken, guardianToken } = await withWatch();
    expect((await upload(seniorId, guardianToken, [at("2026-10-03T11:59:00Z", 70)])).status).toBe(403);
    expect((await read(seniorId, seniorToken)).status).toBe(200);
    const stranger = await t.pair();
    expect((await read(seniorId, stranger.guardianToken)).status).toBe(403);
    expect((await read(seniorId, stranger.seniorToken)).status).toBe(403);
  });

  it("reads a time window with a limit", async () => {
    const { seniorId, watchToken, guardianToken } = await withWatch();
    await upload(seniorId, watchToken, [
      at("2026-10-02T11:00:00Z", 60),
      at("2026-10-03T10:00:00Z", 65),
      at("2026-10-03T11:59:00Z", 70),
    ]);
    const day = (await read(seniorId, guardianToken)).body;
    expect(day.items.map((s: { bpm: number }) => s.bpm)).toEqual([65, 70]);
    expect(day.latest.bpm).toBe(70);

    const explicit = (await read(seniorId, guardianToken, "?from=2026-10-02T00:00:00Z&to=2026-10-03T11:00:00Z")).body;
    expect(explicit.items.map((s: { bpm: number }) => s.bpm)).toEqual([60, 65]);

    const limited = (await read(seniorId, guardianToken, "?limit=1")).body;
    expect(limited.items.map((s: { bpm: number }) => s.bpm)).toEqual([70]);
    expect(limited.truncated).toBe(true);

    expect((await read(seniorId, guardianToken, "?from=2026-09-20T00:00:00Z&to=2026-10-03T00:00:00Z")).status).toBe(400);
    expect((await read(seniorId, guardianToken, "?from=2026-10-03T11:00:00Z&to=2026-10-03T10:00:00Z")).status).toBe(400);
  });

  it("drops readings after the retention period and when the senior deletes the account", async () => {
    const { seniorId, seniorToken, watchToken, guardianToken } = await withWatch();
    await upload(seniorId, watchToken, [at("2026-10-03T11:59:00Z", 70)]);
    t.time.now = new Date("2026-10-11T12:00:00Z");
    await runWatchdogOnce(t.deps);
    expect((await read(seniorId, guardianToken)).body.latest).toBeNull();

    t.time.now = new Date("2026-10-03T12:00:00Z");
    await upload(seniorId, watchToken, [at("2026-10-03T11:59:00Z", 70)]);
    await t.call("DELETE", `/v1/seniors/${seniorId}`, seniorToken, { confirm: "DELETE" });
    expect(await t.db.select().from(vitalSamples).where(eq(vitalSamples.seniorId, seniorId))).toHaveLength(0);
  });
});

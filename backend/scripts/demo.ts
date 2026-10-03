/**
 * Deterministic demo scenario (MOBILE_PLAN.md "Deterministic Demo Script") driven through the HTTP API.
 * Every event and heartbeat is sent with source "simulated", so guardians see it labelled as a
 * simulation. Run against a dev server: `pnpm dev` (ideally PUSH_PROVIDER=log), then `pnpm demo`.
 */
import { randomUUID } from "node:crypto";

const base = (process.env.DEMO_BASE_URL ?? "http://localhost:8787").replace(/\/$/, "");

async function call<T = any>(method: string, path: string, token?: string, body?: unknown): Promise<T> {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text}`);
  return (text ? JSON.parse(text) : null) as T;
}

const step = (n: number, what: string) => console.log(`\n${n}. ${what}`);
const event = (type: string, extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  type,
  occurredAt: new Date().toISOString(),
  source: "simulated",
  ...extra,
});

// Synthetic coordinates (central Kraków), not a real person's home.
const home = { lat: 50.0614, lng: 19.9366 };
const outside = { lat: 50.0682, lng: 19.9455, accuracyM: 25, measuredBy: "phone" };

step(1, "Create a synthetic senior and pair a guardian");
const senior = await call("POST", "/v1/seniors", undefined, { displayName: "Demo Halina" });
const guardian = await call("POST", "/v1/pairing/claim", undefined, { code: senior.pairingCode, displayName: "Demo Marek" });
const s = `/v1/seniors/${senior.seniorId}`;
console.log(`   senior ${senior.seniorId}, guardian ${guardian.guardianId}`);
// Synthetic push tokens: with PUSH_PROVIDER=log the server prints each notification instead of sending it.
await call("PUT", "/v1/devices/me/push-token", guardian.token, { pushToken: `demo-guardian-${randomUUID()}` });
await call("PUT", "/v1/devices/me/push-token", senior.token, { pushToken: `demo-senior-${randomUUID()}` });

step(2, "Guardian sets the home circle, a contact and a medication");
await call("PUT", `${s}/safe-area`, guardian.token, { ...home, radiusM: 150 });
await call("POST", `${s}/contacts`, guardian.token, { name: "Demo Marek", phone: "+48 600 000 001", isEmergency: true });
await call("POST", `${s}/medications`, guardian.token, {
  name: "Demo Blood Pressure 5 mg (synthetic)",
  times: ["08:00", "20:00"],
  timezone: "Europe/Warsaw",
});

step(3, "Senior phone reports it is inside the safe area");
await call("PUT", `${s}/status`, senior.token, { monitoringState: "inside", battery: 80, source: "simulated" });

step(4, "Labelled trace replay: inside -> outside, then back");
const exit = await call("POST", `${s}/events`, senior.token, event("area_exit", { location: outside }));
console.log(`   area_exit alert ${exit.alert.id} push=${exit.alert.pushStatus}`);
await call("POST", `${s}/events`, senior.token, event("area_enter", { location: { ...home, measuredBy: "phone" } }));

step(5, "SOS (simulated trigger); guardian acknowledges");
const sos = await call("POST", `${s}/events`, senior.token, event("sos"));
await call("POST", `/v1/alerts/${sos.alert.id}/ack`, guardian.token);

step(6, "Dose schedule and guardian overview");
const schedule = await call("GET", `${s}/dose-schedule`, guardian.token);
for (const d of schedule.items) console.log(`   ${d.scheduledFor} ${d.medicationName} ${d.status}`);
const overview = await call("GET", `${s}/overview`, guardian.token);
console.log(`   open alerts: ${JSON.stringify(overview.alerts)}, monitoring: ${overview.status?.monitoringState}`);

step(7, "Alert timeline as the guardian sees it");
const { items } = await call("GET", "/v1/alerts", guardian.token);
for (const a of [...items].reverse()) {
  const state = [
    a.event?.source !== "device" ? "SIMULATED" : null,
    a.acknowledgedAt ? "acknowledged" : null,
    a.resolvedAt ? "resolved" : null,
    a.cancelledAt ? "cancelled" : null,
  ].filter(Boolean);
  console.log(`   ${a.createdAt} ${a.kind.padEnd(16)} push=${a.pushStatus.padEnd(9)} ${state.join(", ")}`);
}

console.log(`\nDone. Guardian token for manual checks (demo data only): ${guardian.token}`);

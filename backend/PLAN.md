# Backend Plan — Elderly-Care Companion (Hono + PostgreSQL)

## Context

The mobile app (ArkTS, plan in `MOBILE_PLAN.md`, owned by a parallel agent) needs a
backend for the cross-device parts: senior ↔ guardian pairing, guardian-managed care
configuration, safety events (SOS / safe-area exit), guardian alerts with push delivery,
dose adherence records and approved wellbeing reports. This plan creates `/backend`
from scratch and implements the "Backend Coordination: Mobile Needs Only" section of
`MOBILE_PLAN.md` as a concrete API contract.

User decisions: **Hono (latest, 4.13.x) + pnpm**, **PostgreSQL**, guardian is a **second
role/mode in the ArkTS app** (pure JSON API, no web UI), alerts go out via **HarmonyOS
Push Kit** (the DevEco Studio emulator supports push, per
`hackathon-resources/emulator-capability-comparison.md`), and docs should say
**HarmonyOS instead of OpenHarmony/Oniro**.

## Feature split: backend vs mobile-only

| Feature | Backend | Mobile only |
| --- | --- | --- |
| Geofencing (P0) | Stores the safe area (center, radius, version). Accepts exit/enter events. Stores status heartbeats. Raises a **"monitoring lost"** alert when heartbeats go stale | Location sampling, the geofence state machine, hysteresis, the persistent event queue |
| SOS (P0, phone + watch) | Idempotent event intake → alert → push to guardian devices. Acknowledgement. Cancellation updates | Button UX, queue/retry, last-known location |
| Guardian alerts (P0) | Alert list/detail, `since` refresh, ack, push token registration, push send via Push Kit | Notification display, deep link |
| Medication (P1) | Schedule CRUD (guardian-edited, versioned). Dose records (taken/skipped/snoozed, idempotent by occurrence ID). Optional "dose missed" event → alert. Small **synthetic** barcode catalog (`barcode → name, form, modelAssetKey`) | Local reminders, barcode scanning (camera), 3D rendering of bundled models |
| Easy contacts (P1) | Contacts CRUD (guardian-managed, synced) | Dialing, voice call handoff, speech |
| AI assistant (P1) | Stores **user-approved** reports only (structured fields plus summary, with `source: ai\|structured\|simulated`). Guardian reads them | All inference (on-device LLM), raw check-ins, prompts, history |
| Planned trips v1 (P2) | Trip CRUD (destination circle plus time window). Accepts trip events. Raises "trip not completed" when the window ends with no arrival event | Route tracking, deviation detection |
| Learned routines v2, fall detection (P2) | Out of scope for now | Out of scope / feasibility spike |

Principle: the backend never evaluates raw location or health data. It stores configuration,
relays events and delivers alerts, which keeps private data on the device as the mobile plan requires.

## Stack (versions checked with `npm view` on 2026-10-03)

- `hono` ^4.13.12, `@hono/node-server` ^2.1.3: Node runtime (local Node is v23.11)
- `zod` ^4.6.5 + `@hono/zod-validator` ^0.9.1: request validation
- `drizzle-orm` ^0.45.3 with the `postgres` ^3.4.9 (postgres.js) driver (`drizzle-orm/postgres-js`). The schema is written in TypeScript (`src/db/schema.ts`)
- `drizzle-kit` ^0.31.11 (dev) generates SQL migrations into `drizzle/`. `pnpm db:generate` runs `drizzle-kit generate`, and `pnpm db:migrate` uses the drizzle-orm `migrate()` runner, so migrations are committed and reproducible (no `push`)
- Request validation uses hand-written zod schemas. `drizzle-zod` is skipped unless its zod 4 support checks out in Context7
- Dev: `typescript`, `tsx` (dev runner), `vitest`, `@types/node`
- Push Kit JWT signing uses `node:crypto` (PS256), so it needs no JWT library. Its HTTP calls use the global `fetch`
- `docker-compose.yml` runs local Postgres 17 (`app` DB plus `app_test` DB)
- Before coding, verify the Hono / zod-validator / drizzle-orm / drizzle-kit APIs with Context7 (per AGENTS.md)

## Layout (`/backend`)

```
backend/
  package.json  pnpm-lock.yaml  tsconfig.json  vitest.config.ts
  .env.example  docker-compose.yml  README.md  drizzle.config.ts
  drizzle/              # generated SQL migrations (committed)
  src/
    index.ts            # serve() entry
    app.ts              # createApp({ db, push, clock }), so tests can inject deps
    config.ts           # zod-parsed env (DATABASE_URL, PORT, PUSH_PROVIDER, PUSH_KIT_*)
    db/schema.ts  db/client.ts  db/migrate.ts  db/seed.ts   # seed = synthetic demo senior/guardian/catalog
    auth/tokens.ts  auth/middleware.ts        # opaque bearer tokens, sha256-hashed in DB
    push/provider.ts  push/harmony-push-kit.ts  push/log-provider.ts
    services/alerts.ts      # createAlertFromEvent + notify guardians (single place)
    services/watchdog.ts    # interval: stale heartbeat → monitoring_lost; ended trip windows
    routes/  pairing.ts devices.ts config.ts contacts.ts medications.ts
             events.ts alerts.ts doses.ts reports.ts catalog.ts trips.ts status.ts
  test/   *.test.ts     # app.request() against app_test DB
```

## Data model (`src/db/schema.ts` as Drizzle `pgTable`s, with `pgEnum` for roles, kinds and statuses)

Idempotent inserts use `.onConflictDoNothing()` and then re-select the row. Version checks use `update … where id = ? and version = ?` with `.returning()`, and an empty result means 409.

`users(id, role senior|guardian, display_name)`, `care_links(senior_id, guardian_id)`,
`pairing_codes(code, senior_id, expires_at, used_at)`,
`devices(id, user_id, kind phone|watch, push_token, token_hash, last_seen_at)`,
`safe_areas(senior_id PK, lat, lng, radius_m, version)`,
`contacts(id, senior_id, name, phone, sort_order)`,
`medications(id, senior_id, name, dose_text, instructions, barcode, model_asset_key, times jsonb, timezone, version)`,
`dose_records(occurrence_id PK, medication_id nullable (set null on delete), medication_name snapshot, status taken|skipped|snoozed, recorded_at)`,
`events(id uuid PK client-generated, senior_id, device_id, type sos|sos_cancel|area_exit|area_enter|dose_missed|trip_started|trip_arrived|trip_deviation, occurred_at, received_at, location jsonb null)`,
`alerts(id, event_id, senior_id, kind, created_at, push_status none|sent|failed|simulated, acknowledged_at, acknowledged_by)`,
`status_heartbeats(senior_id PK, device_id, monitoring_state inside|outside|unknown|unavailable, location jsonb, battery, reported_at)`,
`reports(id, senior_id, period, structured jsonb, summary text, source ai|structured|simulated, created_at)`,
`trips(id, senior_id, dest_lat, dest_lng, radius_m, window_start, window_end, status)`,
`medication_catalog(barcode PK, name, form, model_asset_key, is_synthetic)`.

## API contract (`/v1`, JSON, `Authorization: Bearer <deviceToken>`)

- `POST /v1/seniors` creates a senior and their first device. It returns the senior device token and a 6-digit pairing code (10 min TTL). The demo bootstrap is unauthenticated.
- `POST /v1/pairing/claim {code, displayName, deviceKind}` creates the guardian and the care link, and returns the guardian device token. `POST /v1/pairing/codes` (senior) issues a new code, e.g. for a watch.
- `PUT /v1/devices/me/push-token` (any role) registers the token. `GET /v1/me` returns the role, linked seniors and guardians.
- Config: `GET|PUT /v1/seniors/:id/safe-area`, `GET|POST|PUT|DELETE …/contacts`, `…/medications`, `…/trips`. Guardian writes; the senior reads. Writes carry `version`, and a mismatch returns **409** with the current entity.
- `POST /v1/seniors/:id/events` (senior) is **idempotent on client `id`**: a repeat returns 200 with the original record. A first insert returns 201. Both return `{event, alert:{id, pushStatus}}`. `sos_cancel` references `cancelsEventId` and updates the alert, never deletes it.
- `GET /v1/seniors/:id/alerts?since=` and `GET /v1/alerts/:id` (guardian). `POST /v1/alerts/:id/ack` is idempotent.
- `PUT /v1/seniors/:id/status` (senior heartbeat). `GET …/status` (guardian) includes `reportedAt` so the UI can show freshness.
- `POST /v1/seniors/:id/doses` (idempotent by `occurrenceId`). `GET …/doses?from=&to=`.
- `POST /v1/seniors/:id/reports` (senior, approved content only). `GET …/reports` (guardian only).
- `GET /v1/catalog/:barcode` returns 404 for unknown codes, and the mobile app falls back to manual entry.
- `GET /health`.
- Errors use a uniform `{error:{code, message}}` shape: 400 validation, 401 unauthenticated, 403 not linked, 404, 409 version conflict, 410 expired pairing code.

Every route checks through one `assertLinked(user, seniorId)` helper in `auth/middleware.ts`.

## Push delivery

`PushProvider.send(tokens, {title, body, data:{alertId, seniorId, kind}})` → `sent|failed`.
- `harmony-push-kit.ts` implements the Push Kit REST v3 send endpoint with service-account JWT auth. Credentials come only from the service-account key file named by `PUSH_KIT_KEY_FILE` (it holds `project_id`, `key_id`, `sub_account` and `private_key`); the file is git-ignored. **Before coding, verify the endpoint, JWT claims and payload shape against the official HarmonyOS Push Kit server docs.**
- **The real Push Kit provider is the default** (`PUSH_PROVIDER=pushkit`). If its credentials are missing, the server refuses to start with a clear error rather than silently falling back.
- `log-provider.ts` runs only when explicitly opted in with `PUSH_PROVIDER=log`. It exists for teammates who don't have the AGC key, because secrets can't be in the public repo. It records `push_status = 'simulated'`, never `sent`.
- Unit tests inject an in-memory fake through `createApp({ push })`. They never call Huawei.
- `push_status` tracks only that the send request succeeded, not that a guardian saw it. Guardian acknowledgement is the only proof, which matches the mobile plan's delivery states.
- The alert is stored **before** the push is attempted. A push failure doesn't fail the event request, and the guardian app can still refresh alerts.

## Docs: switch to HarmonyOS (outside `/backend`, done as a separate commit)

The user asked for this, so it is the one exception to the `/backend`-only rule. Replace the "OpenHarmony / Oniro" targeting with "HarmonyOS" in `AGENTS.md`, `README.md`, `HACKATHON_BRIEF.md` and `docs/TECH_STACK.md`.
- **Do not edit** `docs/challenge/*`, `hackathon-resources/*` or `hackathon-skills/*`. They are copies of the authoritative challenge material.
- **Do not edit** `MOBILE_PLAN.md`, which belongs to the mobile agent. Report to the user that it still says "HarmonyOS proprietary services are not assumed" and needs updating there.
- Flag (don't change) the follow-ups this requires on the mobile side: `build-profile.json5` `runtimeOS: "HarmonyOS"`, AppGallery Connect signing (`oniro-app sign --harmonyos`), and a Push Kit project.

Under AGENTS.md's AI transparency rule, `AI_WORKFLOW.md` gets a Claude Code / `claude-opus-5-5` row in Tools Used and a work-log entry.

## Implementation order

**README rule (applies to every step, not only step 7):** `backend/README.md` is created in step 1. Any step that changes setup, env vars, scripts, migrations, endpoints, request/response shapes, auth or error codes updates the README **in the same commit**. The README's API section is the contract the mobile agent integrates against. Breaking changes, meaning a removed or renamed field or endpoint or a changed semantic, also get a dated entry in a "Breaking changes" section at the end of the README, so the mobile side can track them.

1. Scaffold: `pnpm init`, deps, tsconfig (ESM, strict), docker-compose, `.env.example`, `/health`.
2. Drizzle schema, `drizzle-kit generate`, migrate script, seed with synthetic data.
3. Auth, pairing, devices, `/me`.
4. P0: safe area, events (idempotent), alerts service, push providers, ack, status heartbeat, watchdog.
5. P1: contacts, medications plus doses, catalog, reports.
6. P2: trips plus watchdog window check.
7. README final pass: check that setup (`docker compose up -d`, `pnpm i`, `pnpm db:migrate`, `pnpm db:seed`, `pnpm dev`), the note on how the emulator reaches the host (host LAN IP or `hdc rport`), and the curl examples still match the code.
8. Docs HarmonyOS switch plus `AI_WORKFLOW.md` update.

## Verification

- `pnpm typecheck` and `pnpm test` (vitest, `app.request()` against `app_test`). Tests cover:
  - pairing (expired or used code)
  - unlinked guardian gets 403
  - event idempotency (same id twice = one alert, one push call through a fake provider)
  - `sos_cancel` keeps the original alert
  - version conflict gets 409
  - dose occurrence dedupe
  - watchdog stale heartbeat produces exactly one `monitoring_lost` alert
  - a push failure still stores the alert
- Manual: run `pnpm dev`, then a curl script: create senior → claim → set safe area → post SOS twice → guardian lists alerts (one) → ack.
- Real Push Kit end-to-end: put AGC service-account credentials in a git-ignored `.env`, take a push token from the guardian app on the DevEco HarmonyOS emulator, send an SOS and confirm the notification shows on the emulator. This needs the user's AGC project and the mobile app switched to HarmonyOS signing. Until that is done it is reported as unverified.

## Implementation notes (deviations from the plan above)

- Postgres runs from docker-compose on the default port 5432.
- Push Kit credentials come from a single service-account key file (`PUSH_KIT_KEY_FILE`) rather than four env vars; the file already holds `project_id`, `key_id`, `sub_account` and `private_key`.
- Added `POST /v1/devices` (senior adds a watch device and gets its token) and `events.trip_id` for trip events.
- `status_heartbeats.reported_at` is server receipt time; the device's own sample time lives in `location.sampledAt`.
- Dose records keep history when a medication is deleted (`medication_id` set null, plus a `medication_name` snapshot).
- Added a `trip_started` event (planned to active) and a guardian-wide `GET /v1/alerts?unacknowledged=true` inbox, so the app can resolve a notification tap without push payload data.
- `HEARTBEAT_STALE_SECONDS` stays 900, documented as unvalidated.
- Seniors may also read their own alerts (to show accepted vs guardian-acknowledged).
- Push Kit notification click-through data is not sent yet (payload shape unverified); `GET /v1/alerts` covers the tap case.
- The docs switch to HarmonyOS and the `AI_WORKFLOW.md` entry were not made: they are outside `/backend`.

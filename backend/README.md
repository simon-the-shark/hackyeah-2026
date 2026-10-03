# Elder-care backend

Hono + Drizzle ORM + PostgreSQL API for the elder-care companion app. It stores
configuration, relays safety events and delivers guardian alerts. It never
evaluates raw location or health data: geofencing, medication reminders,
barcode scanning, 3D models and AI inference stay on the device.
See `PLAN.md` for scope and the backend/mobile split, and `../MOBILE_PLAN.md`
for the mobile side.

## Setup

Requirements: Node 22+, pnpm, Docker.

```sh
cd backend
cp .env.example .env          # defaults work with docker-compose; PUSH_PROVIDER=log
docker compose up -d          # Postgres 17 on :5432 (databases elder_care, elder_care_test)
pnpm install
pnpm db:migrate
pnpm db:seed                  # synthetic demo senior/guardian; prints device tokens once
pnpm dev                      # http://localhost:8787
```

Scripts: `pnpm test` (needs the compose DB), `pnpm typecheck`,
`pnpm db:generate` (after editing `src/db/schema.ts`; commit the generated SQL).

From a HarmonyOS emulator the host is not `localhost`; use the host's LAN IP
(or an HDC port-forward) as the API base URL. Not yet verified on an emulator.

## Push delivery

`PUSH_PROVIDER` defaults to `pushkit` (HarmonyOS Push Kit REST v3). It needs
`PUSH_KIT_KEY_FILE`, the AppGallery Connect service-account key JSON
(`project_id`, `key_id`, `sub_account`, `private_key`); the server refuses to
start without it. Keep the file out of git (`*.pem`, `*.key`, `secrets/` are
ignored).

`PUSH_PROVIDER=log` is an explicit opt-in for development without credentials:
nothing is delivered and alerts get `pushStatus: "simulated"`.

**Status: the Push Kit request format was assembled from public documentation
and community write-ups and has NOT been verified against a live project or
emulator.** `pushStatus: "sent"` means only that Push Kit accepted the request,
never that a guardian saw it. Guardian acknowledgement (`acknowledgedAt`) is the
only proof of a human seeing an alert. Notification click-through data (deep
link payload) is not sent yet; the app should refresh `GET .../alerts` on open.

## API (`/v1`, JSON)

Auth: `Authorization: Bearer <device token>`. Tokens are issued once at
bootstrap/pairing and stored only as a SHA-256 hash. Errors always look like
`{"error":{"code","message","details?"}}` with codes `validation_error` (400),
`unauthorized` (401), `forbidden` (403), `not_found` (404),
`version_conflict` (409, `details.current` holds the stored entity),
`pairing_expired` (410, also for unknown or used codes), `internal_error` (500).
Timestamps are ISO 8601 with offset.

| Method and path | Who | Notes |
| --- | --- | --- |
| `GET /health` | none | |
| `POST /v1/seniors` `{displayName, deviceKind?}` | none | Returns `seniorId, deviceId, token, pairingCode, pairingExpiresAt` (code lives 10 min) |
| `POST /v1/pairing/claim` `{code, displayName, deviceKind?}` | none | Creates the guardian and care link. Returns `guardianId, seniorId, deviceId, token` |
| `POST /v1/pairing/codes` | senior | New pairing code |
| `POST /v1/devices` `{kind}` | senior | Extra device (e.g. watch) for the same senior; returns its token |
| `PUT /v1/devices/me/push-token` `{pushToken}` | any | 204 |
| `GET /v1/me` | any | Role and linked seniors (guardian) or guardians (senior) |
| `GET/PUT /v1/seniors/:id/safe-area` `{lat,lng,radiusM,version?}` | read: linked, write: guardian | First PUT omits `version` (201). Later PUTs need the current `version` |
| `GET/POST /v1/seniors/:id/contacts`, `PUT/DELETE .../contacts/:id` | read: linked, write: guardian | PUT needs `version` |
| `GET/POST /v1/seniors/:id/medications`, `PUT/DELETE .../medications/:id` | read: linked, write: guardian | `times` are `HH:MM`, `timezone` is IANA. Dose text is user-entered |
| `GET/POST /v1/seniors/:id/trips`, `PUT/DELETE .../trips/:id` | read: linked, write: guardian | P2. Server marks a trip `missed` and alerts when the window ends without `trip_arrived` |
| `POST /v1/seniors/:id/events` | senior | Idempotent on client `id` (UUID): 201 first time, 200 on repeat, never a second push. Types: `sos`, `sos_cancel` (needs `cancelsEventId`), `area_exit`, `area_enter`, `dose_missed`, `trip_arrived`, `trip_deviation` (both need `tripId`). Optional `location {lat,lng,accuracyM?,sampledAt?}`. `sos`, `area_exit`, `dose_missed` and `trip_deviation` create an alert; a cancel marks the original alert `cancelledAt` and notifies, it never deletes |
| `GET /v1/seniors/:id/alerts?since=&limit=` | linked | Newest first, with the source event. Seniors can read their own alerts to show accepted vs acknowledged |
| `GET /v1/alerts/:id` | linked | |
| `POST /v1/alerts/:id/ack` | guardian | Idempotent; first acknowledgement wins |
| `PUT /v1/seniors/:id/status` `{monitoringState, location?, battery?}` | senior | Heartbeat. `reportedAt` is server receipt time. No heartbeat for `HEARTBEAT_STALE_SECONDS` (default 900) raises one `monitoring_lost` alert per gap |
| `GET /v1/seniors/:id/status` | linked | `{status, serverTime}`; `status` is null before the first heartbeat. Show age, never an unqualified "safe" |
| `POST /v1/seniors/:id/doses`, `GET .../doses?from=&to=` | senior / linked | Idempotent on `occurrenceId`; a `snoozed` record can later become `taken` or `skipped`, final records are not overwritten (200 with stored record) |
| `POST /v1/seniors/:id/reports`, `GET .../reports` | senior / linked | Only user-approved content. `source` is `ai`, `structured` or `simulated` |
| `GET /v1/catalog/:barcode` | any | Synthetic demo catalog. 404 means unknown: fall back to manual entry. A barcode is a candidate, not a prescription |

Alert `kind`: `sos`, `area_exit`, `dose_missed`, `trip_deviation`,
`trip_not_completed`, `monitoring_lost`. Alert `pushStatus`: `none` (no guardian
device had a push token), `sent`, `failed`, `simulated`.

## Limitations

- Pairing and the demo bootstrap are unauthenticated and meant for the hackathon
  demo, not production: no rate limiting, token rotation or revocation.
- One alert is stored before pushing; a failed push is not retried. Clients
  recover by refreshing alerts.
- The seed data and barcode catalog are synthetic.

## Breaking changes

None yet. Changes to request or response shapes, error codes or semantics are
recorded here with a date so the mobile side can follow.

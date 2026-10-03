# Elder-care backend

Hono + Drizzle ORM + PostgreSQL API for the elder-care companion app. It stores
configuration, relays safety events and delivers guardian alerts. It never
evaluates raw location or health data: geofencing, medication reminders,
barcode scanning, 3D models and AI inference stay on the device.
See `PLAN.md` for scope and the backend/mobile split, and `../MOBILE_PLAN.md`
for the mobile side.

## Setup

Requirements: Node, pnpm, Docker. Developed and tested on Node 23.11; the dev scripts use `node --env-file-if-exists` through `tsx`, so use a recent Node 22 or newer (older 22.x releases were not tested).

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

## Container image

Build the backend image from this directory:

```sh
docker build -t elder-care-backend .
```

The image runs as the unprivileged `node` user, listens on port 8787, and has a
`/health` health check. It does not run migrations automatically: run them as a
separate deployment step before starting the application. Provide `DATABASE_URL`
and the push configuration through the runtime environment; do not copy an
`.env` file or Push Kit key into the image. For local development without Push
Kit credentials, set `PUSH_PROVIDER=log` explicitly.

The build uses the pnpm version pinned in `package.json` and explicitly installs
dev dependencies (`--prod=false`), including the `tsx` runtime. The container
starts with `node --import tsx`, so it neither downloads pnpm nor reinstalls or
prunes dependencies as the unprivileged user at startup.

For Coolify, use `backend/` as the build context and its `Dockerfile`, expose
port 8787, and provide application configuration at runtime. Set `NODE_ENV` to
runtime-only in Coolify; the image already defaults to `production`. Keep the
Dockerfile health check enabled: it uses Node's built-in `fetch`, so no curl or
wget package is required. Rebuild and redeploy after updating the Dockerfile.

Detailed HTTP request/response diagnostics are enabled only outside production
and redact credential-like JSON fields. Set `NODE_ENV=production` to disable
these per-request diagnostic logs.

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
link payload) is not sent yet, because its format is unverified. On a
notification tap the guardian app should open and call
`GET /v1/alerts?unacknowledged=true`, then show the newest entry; this needs no
push payload data.

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
| `POST /v1/pairing/claim` with a guardian bearer token | guardian | Links the **existing** guardian to the code's senior (no new account or token; `displayName` is ignored). Returns `guardianId, seniorId, deviceId`. Invalid token: 401; senior token: 403 (the code is not consumed) |
| `DELETE /v1/care-links/:seniorId/:guardianId` | that senior or guardian | Ends the relationship (204); the guardian immediately loses access |
| `POST /v1/pairing/codes` | senior | Active pairing code; creates one only when none is valid |
| `POST /v1/devices` `{kind}` | senior | Extra device (e.g. watch) for the same senior; returns its token |
| `PUT /v1/devices/me/push-token` `{pushToken}` | any | 204 |
| `GET /v1/devices?seniorId=` | any | Own devices, or (guardian) a linked senior's devices: `id, kind, createdAt, lastSeenAt, hasPushToken, isCurrent`. Never returns tokens |
| `DELETE /v1/devices/:id` | owner | Revokes one of your **other** devices (a device cannot revoke itself: 400). Its token stops working (401) and its push token and heartbeat are removed; its events and alerts are kept |
| `GET /v1/me` | any | Role and linked seniors (guardian) or guardians (senior) |
| `GET /v1/seniors/:id/config` | linked | Everything the senior device needs to run offline: `safeArea` (or null), `contacts`, `medications`, planned or active `trips`, active `routines`, plus `configVersion` (a content hash). The response carries `ETag: "<configVersion>"`; send it back as `If-None-Match` to get `304` when nothing changed. Poll this to reschedule reminders after guardian edits; there is no "config changed" push yet |
| `GET/PUT /v1/seniors/:id/safe-area` `{lat,lng,radiusM,version?}` | read: linked, write: guardian | First PUT omits `version` (201). Later PUTs need the current `version` |
| `GET/POST /v1/seniors/:id/contacts`, `PUT/DELETE .../contacts/:id` | read: linked, write: guardian | `{name, phone, sortOrder?, isEmergency?}`. `isEmergency` marks the person to offer first when an SOS cannot be delivered. PUT needs `version` and, like `sortOrder`, resets an omitted `isEmergency` to `false` |
| `GET/POST /v1/seniors/:id/medications`, `PUT/DELETE .../medications/:id` | read: linked, write: guardian | `times` are `HH:MM`, `timezone` is IANA. Dose text is user-entered. Optional `missedGraceMinutes` and `maxSnoozes`, see Missed doses |
| `GET/POST /v1/seniors/:id/trips`, `PUT/DELETE .../trips/:id` | read: linked, write: guardian | P2. `{label, destLat, destLng, radiusM, windowStart, windowEnd, route?, corridorM?}`: `route` is 2 to 200 `{lat,lng}` points and `corridorM` (20 to 2000, needs a route) the allowed distance from it. The server only stores the route; the device detects deviation and sends `trip_deviation`. PUT replaces the trip, so an omitted route or corridor is cleared. Status: `planned`, then `active` (`trip_started`), then `completed` (`trip_arrived`). The server marks a trip `missed` and alerts once when the window ends without `trip_arrived` |
| `POST /v1/seniors/:id/routine-suggestions` | senior | P2 learned routines. A routine the device inferred **on the device**: `{label, destLat, destLng, radiusM, route?, weekdays, startTime, endTime, timezone, source?}`. `weekdays` are ISO (1 = Monday ... 7 = Sunday), times are local `HH:MM` with `endTime` after `startTime` on the same day. Send only this summary, never raw location history |
| `GET /v1/seniors/:id/routine-suggestions?status=` | linked | Newest first; `status` is `pending`, `accepted` or `rejected` |
| `POST .../routine-suggestions/:sid/accept`, `.../reject` | guardian | Decides a pending suggestion once (409 with `details.current` after that). Accept returns `{suggestion, routine}` |
| `GET/POST /v1/seniors/:id/routines`, `PUT/DELETE .../routines/:id` | read: linked, write: guardian | Recurring trips, same fields as a suggestion plus `corridorM?` and `active` (default true). PUT needs `version`. The watchdog creates one planned trip per matching day (today and tomorrow, local dates) before its window starts; those trips carry `routineId` and `localDate` and follow the normal trip lifecycle. Editing a routine rebuilds its upcoming trips; deleting it removes them and keeps past ones |
| `POST /v1/seniors/:id/events` | senior | Idempotent on client `id` (UUID): 201 first time, 200 on repeat, never a second push. Types: `sos`, `fall_detected`, `cancel` / `sos_cancel` (needs `cancelsEventId` of an `sos` or `fall_detected` event; `sos_cancel` is kept as an alias), `area_exit`, `area_enter`, `dose_missed`, `trip_started`, `trip_arrived`, `trip_deviation` (the three trip types need `tripId`). `trip_started` creates no alert and moves a `planned` trip to `active` (a missed or completed trip is never revived). `trip_arrived` always marks the trip `completed`, even after it was marked `missed`: a late arrival is still an arrival, and the earlier `trip_not_completed` alert stays as history. Optional `location {lat,lng,accuracyM?,sampledAt?,measuredBy?}` (`measuredBy`: `phone` or `watch`, the device that took the fix). Optional `source`: `device` (default), `trace_replay` or `simulated`; anything other than `device` is returned on the alert's `event.source` and prefixes the push title with `[Simulation]`. `sos`, `fall_detected` (alert kind `fall`), `area_exit` and `trip_deviation` create an alert. `fall_detected` **must** send `source` explicitly (400 otherwise), so a synthetic trigger can never pass as sensor data. SOS and fall alerts are "urgent": they can be cancelled, get reminders and tell the senior when acknowledged. `dose_missed` is **deprecated**: it is still accepted and stored, but creates no alert, because the server detects missed doses itself (see below). Apps should stop sending it; a cancel marks the original alert `cancelledAt` and notifies, it never deletes |
| `GET /v1/alerts?unacknowledged=true&unresolved=true&since=&limit=` | guardian | Inbox across all linked seniors, newest first, includes `seniorName`. Cancelled alerts are included with `cancelledAt` set. `unresolved=true` drops resolved and cancelled alerts |
| `GET /v1/seniors/:id/alerts?since=&limit=` | linked | Newest first, with the source event. Seniors can read their own alerts to show accepted vs acknowledged |
| `GET /v1/alerts/:id` | linked | |
| `POST /v1/alerts/:id/ack` | guardian | Idempotent; first acknowledgement wins. Acknowledging an uncancelled `sos` sends one push to the senior's devices ("<guardian> has seen your SOS"), so seniors should register a push token too |
| `PUT /v1/seniors/:id/status` `{monitoringState, location?, battery?, source?}` | senior | Heartbeat. `reportedAt` is server receipt time. When **no** device of the senior has sent a heartbeat for `HEARTBEAT_STALE_SECONDS` (default 900), one `monitoring_lost` alert is raised per gap, with each device's last `reportedAt` in `details.devices`. A heartbeat from any device ends the gap. See the note below |
| `GET /v1/seniors/:id/status` | linked | `{status, devices, serverTime}`. Heartbeats are stored per device, so phone and watch never overwrite each other: `devices` lists the latest heartbeat of each device (newest first, with `deviceKind`), and `status` is the newest of them (null before the first heartbeat). Show age, never an unqualified "safe" |
| `POST /v1/seniors/:id/doses`, `GET .../doses?from=&to=` | senior / linked | Idempotent on `occurrenceId`, which must be `<medicationId>@<YYYY-MM-DD>T<HH:MM>` using the scheduled local date and time in the medication's time zone (otherwise 400). A `snoozed` record can later become `taken` or `skipped`, final records are not overwritten (200 with stored record). Each record keeps a `medicationName` snapshot; deleting or replacing a medication keeps the history and sets `medicationId` to null |
| `GET /v1/seniors/:id/overview` | linked | One call for the guardian overview: `senior`, `status` and `devices` (as in `/status`), `alerts {unacknowledged, unresolved}` (uncancelled counts), `nextDoses` (up to 3 open occurrences from the dose schedule), `missedDosesLast24h`, `latestReportAt`, `safeAreaVersion`, `plannedOrActiveTrips`, `serverTime` |
| `GET /v1/seniors/:id/dose-schedule?from=&to=` | linked | Scheduled occurrences with `from < scheduledFor <= to` (default: 12 h ago to 24 h ahead, at most 7 days), oldest first. Each item: `occurrenceId, medicationId, medicationName, doseText, localTime, timezone, scheduledFor, status, recordedAt`. `status` is `pending`, `taken`, `skipped`, `snoozed` or `missed` (same rule as the alert). Occurrences before a medication's last schedule change are left out |
| `POST /v1/seniors/:id/reports`, `GET .../reports?before=&limit=` | POST: senior, GET: guardian | Only user-approved content. `source` is `ai`, `structured` or `simulated`. The guardian list is newest first; page with `before` (an ISO time, exclusive) |
| `GET /v1/me/reports` | senior | Sharing controls: the senior's own shared reports, newest first |
| `DELETE /v1/seniors/:id/reports/:reportId` | senior | Withdraws a shared report; guardians no longer see it (204) |
| `GET /v1/catalog/:barcode` | any | Synthetic demo catalog. 404 means unknown: fall back to manual entry. A barcode is a candidate, not a prescription |

### Re-sends

The watchdog re-sends pushes that may not have reached anyone. Alerts expose
`pushAttempts` and `lastPushAt`:

- An `sos` or `fall` that is not acknowledged, cancelled or resolved is pushed again every
  `SOS_REPUSH_SECONDS` (default 120, unvalidated) as "Reminder: … (not yet
  acknowledged)", at most 3 times.
- Any other alert whose push `failed` is retried once, a minute later.

### Alert resolution

An alert is **resolved** when its condition ends. Resolution is separate from
acknowledgement (a guardian still acknowledges), never deletes the alert, and
sends one push to guardians:

| Alert | Resolved by | Push title |
| --- | --- | --- |
| `area_exit` | an `area_enter` event (`resolvedByEventId` set) | "… is back in the safe area" |
| `trip_not_completed`, `trip_deviation` | `trip_arrived` for the same trip | "… arrived at the trip destination" |
| `monitoring_lost` | the next heartbeat from any device | "Monitoring restored for …" |
| `dose_missed` | a late `taken` or `skipped` record for that occurrence | "… took/skipped the missed dose of …" |

Alerts expose `resolvedAt` and `resolvedByEventId` (null when not resolved, or
resolved by a heartbeat or dose record). `sos` is ended by cancellation
(`cancelledAt`), not resolution.

Alert `kind`: `sos`, `area_exit`, `dose_missed`, `trip_deviation`,
`trip_not_completed`, `monitoring_lost`, `fall`. Alert `pushStatus`: `none` (no guardian
device had a push token), `sent`, `failed`, `simulated`.

## Missed doses

The server's watchdog (every 30 s) works out each medication's scheduled doses
from its `times` and `timezone`, DST included. A dose with no `taken` or
`skipped` record `DOSE_MISSED_GRACE_MINUTES` (default 60) after its scheduled
time raises one `dose_missed` alert and one push. A `snoozed` record restarts
the grace period from the snooze's `recordedAt`.

- The server's schedule is authoritative. The app must record doses with the
  canonical `occurrenceId` above, or the server cannot match them and will
  report the dose as missed.
- Building the id needs no time-zone arithmetic: use the `times` entry exactly
  as stored (e.g. `08:00`) and the calendar date of that dose in the
  medication's `timezone`. Daylight-saving changes move the UTC instant
  (`scheduledFor`) but never the id, so the app and server cannot disagree on
  it because of DST.
- Doses scheduled before a medication was created, or before its `times` or
  `timezone` last changed, are never reported. Editing the name, dose text,
  instructions, barcode or model does not reset detection.
- Only the last 24 hours are checked, so a server restart does not flood old
  alerts; doses missed during a longer outage are not reported.
- These alerts have no source event (`event: null`). Instead `details` holds
  `medicationId`, `medicationName`, `occurrenceId`, `scheduledFor` (UTC),
  `localTime` and `timezone`.
- The 60-minute default is unvalidated, like the heartbeat threshold. A
  medication can override it with `missedGraceMinutes` (5 to 1440).
- A medication's `maxSnoozes` (1 to 10, null means no cap) limits how many
  snoozes restart the grace period. Later snoozes are still recorded
  (`snoozeCount` on the dose record) but no longer delay the alert. Without a cap,
  a dose snoozed again before each grace period ends is never reported.

## Heartbeat threshold

`HEARTBEAT_STALE_SECONDS` defaults to 900 (15 min). That default has **not been
validated against real use**: a nap with the phone face-down or a short errand
can trigger `monitoring_lost`. The app's heartbeat interval should be at most a
third of the threshold (5 min or less at the default). Tune it after emulator and
device testing.

## Limitations

- Pairing and the demo bootstrap are unauthenticated and meant for the hackathon
  demo, not production: no rate limiting or token rotation. A lost device can be
  revoked from another device of the same user.
- Push retries are limited: one retry for a failed non-SOS push, and at most
  three SOS reminders. Clients still recover by refreshing alerts.
- The seed data and barcode catalog are synthetic.

## Breaking changes

Changes to request or response shapes, error codes or semantics are recorded
here with a date so the mobile side can follow.

- 2026-10-03: `sos_cancel` (and the new `cancel`) only cancels `sos` and
  `fall` alerts; pointing it at another event returns 404. Before, it cancelled
  whatever alert that event had.

- 2026-10-03: heartbeats are stored per device. `GET .../status` adds
  `devices` (`status` keeps its meaning: the newest heartbeat). `monitoring_lost`
  now fires only when every device of the senior is stale, so a working watch
  covers a phone left at home.

- 2026-10-03: `GET /v1/seniors/:id/reports` is now guardian-only (a senior gets
  403). Previously any linked user could read.
- 2026-10-03: dose `occurrenceId` must follow
  `<medicationId>@<YYYY-MM-DD>T<HH:MM>` (400 otherwise), so the server can match
  doses to its schedule.
- 2026-10-03: missed doses are detected on the server. A device-sent
  `dose_missed` event no longer creates an alert. Alerts gained a `details`
  field, which is null except on server-generated `dose_missed` alerts.
- 2026-10-03: dose records can have `medicationId: null` (medication deleted) and
  now include `medicationName`. Deleting a medication no longer deletes its doses.

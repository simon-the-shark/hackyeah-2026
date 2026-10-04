# Elder-care backend

Hono + Drizzle ORM + PostgreSQL API for the elder-care companion app. It stores
configuration, relays safety events and delivers guardian alerts. It never
evaluates raw location or health data: geofencing, medication reminders,
barcode scanning and 3D models stay on the device. The one exception is the
wellbeing check-in chat, which the backend relays to OpenAI (see
[Wellbeing check-in](#wellbeing-check-in-openai)).
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
and redact credential-like and heart-rate JSON fields. Set `NODE_ENV=production` to disable
these per-request diagnostic logs.

From a HarmonyOS emulator the host is not `localhost`; use the host's LAN IP
(or an HDC port-forward) as the API base URL. Not yet verified on an emulator.

## Demo scenario

`pnpm demo` drives the mobile plan's deterministic demo script through the
HTTP API against `DEMO_BASE_URL` (default `http://localhost:8787`). It creates a
synthetic senior and guardian with synthetic push tokens, sets up a safe area,
contact and medication, replays a trace (exit, then re-entry), raises an SOS
that the guardian acknowledges, and prints the dose schedule, the overview and
the guardian's alert timeline. Every event and heartbeat it sends has
`source: "simulated"`, so all of it is labelled as a simulation. Run the server
with `PUSH_PROVIDER=log` to see each notification in the server log. A
shorter `WATCHDOG_INTERVAL_MS` (default 30000) makes watchdog effects appear
sooner. Missed doses are not part of the script, because detection ignores doses
scheduled before a medication was created.

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
link payload) is not sent yet, because its format is unverified. Invalid push
tokens are not cleared automatically for the same reason: the HarmonyOS Push Kit
result codes could not be confirmed (the official reference pages render only
client-side, and search results describe the older HMS Core API). On a
notification tap the guardian app should open and call
`GET /v1/alerts?unacknowledged=true`, then show the newest entry; this needs no
push payload data.

## API (`/v1`, JSON)

Auth: `Authorization: Bearer <device token>`. Tokens are issued once at
bootstrap/pairing and stored only as a SHA-256 hash. Errors always look like
`{"error":{"code","message","details?"}}` with codes `validation_error` (400),
`unauthorized` (401), `forbidden` (403), `not_found` (404),
`version_conflict` (409, `details.current` holds the stored entity),
`session_closed` / `session_full` (409, wellbeing check-in),
`pairing_expired` (410, also for unknown or used codes), `no_speech` (422),
`rate_limited` (429, `details.retryAfterSeconds`), `internal_error` (500),
`assistant_unavailable` (503).
Timestamps are ISO 8601 with offset.

| Method and path | Who | Notes |
| --- | --- | --- |
| `GET /health` | none | |
| `POST /v1/seniors` `{displayName, deviceKind?}` | none | Returns `seniorId, deviceId, token, pairingCode, pairingExpiresAt` (code lives 10 min) |
| `POST /v1/pairing/claim` `{code, displayName, deviceKind?}` | none | Creates the guardian and care link. Returns `guardianId, seniorId, deviceId, token`. Accepts only guardian codes: a watch code returns 410 and is not consumed |
| `POST /v1/pairing/claim` with a guardian bearer token | guardian | Links the **existing** guardian to the code's senior (no new account or token; `displayName` is ignored). Returns `guardianId, seniorId, deviceId`. Invalid token: 401; senior token: 403 (the code is not consumed) |
| `POST /v1/pairing/watch-claim` `{code}` | none | The senior's watch claims a code from `POST /v1/pairing/watch-codes` and becomes another device **of the senior** (`kind: watch`). Returns `seniorId, deviceId, token`. Only watch codes are accepted (a guardian code returns 410 and is not consumed). Failed guesses share the `/pairing/claim` rate limit |
| `DELETE /v1/seniors/:id` `{confirm: "DELETE"}` | that senior | Deletes the senior's account and everything stored for them (devices, configuration, events, alerts, doses, reports, routines, heart-rate samples). Guardian accounts remain but lose the link. Irreversible (204) |
| `DELETE /v1/care-links/:seniorId/:guardianId` | that senior or guardian | Ends the relationship (204); the guardian immediately loses access. A guardian left with no seniors keeps their account and can link again by claiming a new code with their token |
| `POST /v1/pairing/codes?rotate=` | senior | Active guardian pairing code; creates one only when none is valid. `rotate=true` expires the active code and always issues a new one |
| `POST /v1/pairing/watch-codes?rotate=` | senior | Active **watch** pairing code (lives 5 min, because it yields a senior token); creates one only when none is valid; `rotate=true` expires it and issues a new one. Never the same code as the guardian one. No body |
| `POST /v1/devices` `{kind}` | senior | Extra device (e.g. watch) for the same senior; returns its token. A watch that cannot receive a token this way uses the watch pairing code instead |
| `PUT /v1/devices/me/push-token` `{pushToken}` | any | 204 |
| `GET /v1/devices?seniorId=` | any | Own devices, or (guardian) a linked senior's devices: `id, kind, createdAt, lastSeenAt, hasPushToken, isCurrent`. Never returns tokens |
| `DELETE /v1/devices/:id` | owner | Revokes one of your **other** devices (a device cannot revoke itself: 400). Its token stops working (401) and its push token and heartbeat are removed; its events and alerts are kept. Monitoring then counts only the remaining devices: if they are all stale, the next watchdog pass raises `monitoring_lost`, which is intended, because nobody is being monitored |
| `GET /v1/me` | any | Role and linked seniors (guardian) or guardians (senior) |
| `GET /v1/seniors/:id/config` | linked | Everything the senior device needs to run offline: `safeArea` (or null), `contacts`, `medications`, planned or active `trips`, active `routines`, plus `configVersion` (a content hash). The response carries `ETag: "<configVersion>"`; send it back as `If-None-Match` to get `304` when nothing changed. Poll this to reschedule reminders after guardian edits; there is no "config changed" push yet. Suggested: on app start and foreground, and at most every 15 minutes in the background (unvalidated); with `If-None-Match` an unchanged poll is a bodiless 304. Doses record `snoozeCount`, so the app can warn when a snooze past `maxSnoozes` no longer delays the missed-dose alert |
| `GET/PUT /v1/seniors/:id/safe-area` `{lat,lng,radiusM,version?}` | read: linked, write: guardian | First PUT omits `version` (201). Later PUTs need the current `version` |
| `GET/POST /v1/seniors/:id/contacts`, `PUT/DELETE .../contacts/:id` | read: linked, write: guardian | `{name, phone, sortOrder?, isEmergency?}`. `isEmergency` marks the person to offer first when an SOS cannot be delivered (stored only; no app screen uses it yet). PUT needs `version` and, like `sortOrder`, resets an omitted `isEmergency` to `false` |
| `GET/POST /v1/seniors/:id/medications`, `PUT/DELETE .../medications/:id` | read: linked, write: guardian | `times` are `HH:MM`, `timezone` is IANA. Dose text is user-entered. Optional `missedGraceMinutes` and `maxSnoozes`, see Missed doses |
| `GET/POST /v1/seniors/:id/trips`, `PUT/DELETE .../trips/:id` | read: linked, write: guardian | P2. `{label, destLat, destLng, radiusM, windowStart, windowEnd, route?, corridorM?}`: `route` is 2 to 200 `{lat,lng}` points and `corridorM` (20 to 2000, needs a route) the allowed distance from it. The server only stores the route; the device detects deviation and sends `trip_deviation`. On PUT, an omitted `route` or `corridorM` keeps the stored value and `null` clears it; clearing the route also clears the corridor, and a corridor without a route is rejected (400). Editing only the time window therefore never drops the route. Status: `planned`, then `active` (`trip_started`), then `completed` (`trip_arrived`). The server marks a trip `missed` and alerts once when the window ends without `trip_arrived` |
| `POST /v1/seniors/:id/routine-suggestions` | senior | P2 learned routines. A routine the device inferred **on the device**: `{label, destLat, destLng, radiusM, route?, weekdays, startTime, endTime, timezone, source?}`. `weekdays` are ISO (1 = Monday ... 7 = Sunday), times are local `HH:MM` with `endTime` after `startTime` on the same day. Send only this summary, never raw location history |
| `GET /v1/seniors/:id/routine-suggestions?status=` | linked | Newest first; `status` is `pending`, `accepted` or `rejected` |
| `POST .../routine-suggestions/:sid/accept`, `.../reject` | guardian | Decides a pending suggestion once (409 with `details.current` after that). Accept returns `{suggestion, routine}` |
| `GET/POST /v1/seniors/:id/routines`, `PUT/DELETE .../routines/:id` | read: linked, write: guardian | Recurring trips, same fields as a suggestion plus `corridorM?` and `active` (default true). PUT needs `version`. The watchdog creates one planned trip per matching day (today and tomorrow, local dates) before its window starts; those trips carry `routineId` and `localDate` and follow the normal trip lifecycle. Trips exist only for today and tomorrow, so a trip list shows a weekly routine's later days only once they come within that window; show the routine itself for the week view. `route`/`corridorM` follow the trip PUT rules. Editing a routine rebuilds its upcoming trips; deleting it removes them and keeps past ones |
| `POST /v1/seniors/:id/events` | senior | Idempotent on client `id` (UUID): 201 first time, 200 on repeat, never a second push. Types: `sos`, `fall_detected`, `cancel` / `sos_cancel` (needs `cancelsEventId` of an `sos` or `fall_detected` event; `sos_cancel` is kept as an alias), `area_exit`, `area_enter`, `dose_missed`, `trip_started`, `trip_arrived`, `trip_deviation` (the three trip types need `tripId`), `heart_rate_out_of_range`, `heart_rate_in_range` (see Heart rate below; both **must** send `source`, and `heart_rate_out_of_range` needs `heartRate`, which no other type may carry). `trip_started` creates no alert and moves a `planned` trip to `active` (a missed or completed trip is never revived). `trip_arrived` always marks the trip `completed`, even after it was marked `missed`: a late arrival is still an arrival, and the earlier `trip_not_completed` alert stays as history. Optional `location {lat,lng,accuracyM?,sampledAt?,measuredBy?}` (`measuredBy`: `phone` or `watch`, the device that took the fix). Optional `source`: `device` (default), `trace_replay` or `simulated`; anything other than `device` is returned on the alert's `event.source` and prefixes the push title with `[Simulation]`. `sos`, `fall_detected` (alert kind `fall`), `area_exit` and `trip_deviation` create an alert. `fall_detected` **must** send `source` explicitly (400 otherwise), so a synthetic trigger can never pass as sensor data. SOS and fall alerts are "urgent": they can be cancelled, get reminders and tell the senior when acknowledged. `dose_missed` is **deprecated**: it is still accepted and stored, but creates no alert, because the server detects missed doses itself (see below). Apps should stop sending it; a cancel marks the original alert `cancelledAt` and notifies, it never deletes |
| `GET /v1/alerts?unacknowledged=true&unresolved=true&since=&limit=` | guardian | Inbox across all linked seniors, newest first, includes `seniorName`. Cancelled alerts are included with `cancelledAt` set. `unresolved=true` drops resolved and cancelled alerts |
| `GET /v1/seniors/:id/alerts?since=&limit=` | linked | Newest first, with the source event. Seniors can read their own alerts to show accepted vs acknowledged |
| `GET /v1/alerts/:id` | linked | |
| `POST /v1/alerts/:id/ack` | guardian | Idempotent; first acknowledgement wins. Acknowledging an uncancelled `sos` sends one push to the senior's devices ("<guardian> has seen your SOS"), so seniors should register a push token too |
| `PUT /v1/seniors/:id/status` `{monitoringState, location?, battery?, source?}` | senior | Heartbeat. `reportedAt` is server receipt time. When **no** device of the senior has sent a heartbeat for `HEARTBEAT_STALE_SECONDS` (default 900), one `monitoring_lost` alert is raised per gap, with each device's last `reportedAt` in `details.devices`. A heartbeat from any device ends the gap. See the note below |
| `GET /v1/seniors/:id/status` | linked | `{status, devices, serverTime}`. Heartbeats are stored per device, so phone and watch never overwrite each other: `devices` lists the latest heartbeat of each device (newest first, with `deviceKind`), and `status` is the newest of them (null before the first heartbeat). Show age, never an unqualified "safe" |
| `POST /v1/seniors/:id/doses`, `GET .../doses?from=&to=` | senior / linked | Idempotent on `occurrenceId`, which must be `<medicationId>@<YYYY-MM-DD>T<HH:MM>` using the scheduled local date and time in the medication's time zone (otherwise 400). A `snoozed` record can later become `taken` or `skipped`, final records are not overwritten (200 with stored record). Each record keeps a `medicationName` snapshot; deleting or replacing a medication keeps the history and sets `medicationId` to null |
| `GET /v1/seniors/:id/overview` | linked | One call for the guardian overview: `senior`, `status` and `devices` (as in `/status`), `alerts {unacknowledged, unresolved}` (uncancelled counts), `nextDoses` (up to 3 open occurrences from the dose schedule), `missedDosesLast24h`, `latestReportAt`, `latestReport {id, createdAt, attention, source}` (null before the first report; `attention` is `none`, `soon`, `urgent`, or null for reports that are not wellbeing chats), `safeAreaVersion`, `plannedOrActiveTrips`, `serverTime` |
| `GET /v1/seniors/:id/dose-schedule?from=&to=` | linked | Scheduled occurrences with `from < scheduledFor <= to` (default: 12 h ago to 24 h ahead, at most 7 days), oldest first. Each item: `occurrenceId, medicationId, medicationName, doseText, localTime, timezone, scheduledFor, status, recordedAt`. `status` is `pending`, `taken`, `skipped`, `snoozed` or `missed` (same rule as the alert). Occurrences before a medication's last schedule change are left out |
| `POST /v1/seniors/:id/reports`, `GET .../reports?before=&limit=` | POST: senior, GET: guardian | Only user-approved content. `source` is `ai`, `structured` or `simulated`. The guardian list is newest first; page with `before` (an ISO time, exclusive) |
| `GET /v1/seniors/:id/reports/:reportId` | guardian | One report (404 if unknown or withdrawn), e.g. from a `wellbeing` alert's `details.reportId` or a report push |
| `DELETE /v1/seniors/:id/reports/:reportId` | senior | Withdraws a shared report (id from the POST response, or the wellbeing finish response); guardians no longer see it and are not told (204). Seniors still cannot read reports back; the app keeps its own record of what it shared |
| `GET /v1/seniors/:id/wellbeing/session` | that senior | `{session, messages, assistant: {available, simulated, voice, live}, guardians: [{id, displayName}]}`. `live` says hands-free voice is available (see [Live voice](#live-voice-hands-free)). `session` is the open check-in (null if none) and `messages` its messages, oldest first. See [Wellbeing check-in](#wellbeing-check-in-openai) |
| `POST /v1/seniors/:id/wellbeing/sessions` `{language?, timezone?, voice?}` | that senior | Starts a check-in: 201 `{session, messages}` with the assistant's greeting. With `voice: true` and `assistant.live`, the check-in starts with `messages: []` and the live connection speaks the greeting. `language` is a BCP 47 hint (max 35 characters), `timezone` an IANA zone. An open check-in is returned as is (200, no new greeting). 503 `assistant_unavailable`, with nothing stored, when no assistant is configured or it fails |
| `POST .../wellbeing/sessions/:sessionId/messages` `{text}` or `{audio, audioFormat}` | that senior | Exactly one of `text` (1 to 1000 characters) or `audio` (base64, 1 byte to 2 MB decoded) with `audioFormat` `m4a`, `mp3`, `wav`, `webm` or `ogg`. Audio is transcribed first (422 `no_speech` when nothing was recognised). 201 `{message, reply, suggestFinish, safetyConcern}`. Nothing is stored unless the reply succeeded (503 otherwise). 404 for an unknown or someone else's check-in, 409 `session_closed` after it finished, 409 `session_full` at 40 senior messages; `suggestFinish` is always true from the 30th |
| `POST .../wellbeing/sessions/:sessionId/finish` `{reason?}` | that senior | Body optional; `reason` is `senior` (default) or `assistant` (the app finishes after a reply with `suggestFinish`). 200 `{session, report}`: the summary report is stored and pushed, the conversation deleted. Idempotent (`report` is null once withdrawn). A check-in without senior messages is deleted: `{session: null, report: null}`. 503 when the summary fails; the check-in stays open |
| `GET .../wellbeing/sessions/:sessionId/live` (WebSocket) | that senior | Hands-free voice: upgrade with the normal bearer header, then JSON frames. See [Live voice](#live-voice-hands-free) |
| `GET /v1/catalog?q=` | any | Case-insensitive name search (2 to 64 characters, `%` and `_` match literally), up to 10 entries. Helps manual entry after an unknown barcode |
| `GET /v1/catalog/:barcode` | any | Synthetic demo catalog. 404 means unknown: fall back to manual entry. A barcode is a candidate, not a prescription |
| `POST /v1/seniors/:id/vitals` `{source, heartRate: [{bpm, measuredAt}]}` | senior | Heart-rate readings from the watch, 1 to 500 per batch. `source` is required (`device`, `trace_replay` or `simulated`). `bpm` is an integer from 20 to 250. A reading more than 5 minutes ahead of server time or older than 7 days rejects the **whole** batch (400 with the offending `heartRate.<i>.measuredAt` paths). Idempotent per device and `measuredAt`: returns `{stored, duplicates, serverTime}`, 201 when anything was stored, 200 for a pure retry |
| `GET /v1/seniors/:id/vitals/heart-rate?from=&to=&limit=` | linked | `{latest, items, truncated, serverTime}`. `items` are readings with `from < measuredAt <= to` (default: the 24 h up to now, at most 7 days), oldest first, each `{bpm, measuredAt, source, deviceId}`. `limit` (1 to 2000, default 1500) keeps the newest readings; `truncated` says some were left out. `latest` is the newest reading regardless of the window (null if none) |

### Low battery

A heartbeat with `battery` at or below `LOW_BATTERY_PERCENT` (default 15,
unvalidated) raises one `low_battery` alert for that device, with
`details {deviceId, deviceKind, battery}`. No new alert fires for the same
device until its battery has climbed to the threshold plus 10, so a battery
hovering around the threshold does not flood guardians. The watch matters most
here, because it is the intended SOS surface.

### Re-sends

The watchdog re-sends pushes that may not have reached anyone. Alerts expose
`pushAttempts` and `lastPushAt`:

- An `sos` or `fall` that is not acknowledged, cancelled or resolved is pushed again every
  `SOS_REPUSH_SECONDS` (default 300, unvalidated; long enough that a delayed
  first push and its reminders do not arrive in a burst) as "Reminder: … (not yet
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
| `low_battery` | a heartbeat from that device with battery at least `LOW_BATTERY_PERCENT` + 10 | "…'s device is charged again" |
| `dose_missed` | a late `taken` or `skipped` record for that occurrence | "… took/skipped the missed dose of …" |
| `heart_rate` | a `heart_rate_in_range` event (`resolvedByEventId` set) | "…'s watch: heart rate back in the set range" |

Alerts expose `resolvedAt` and `resolvedByEventId` (null when not resolved, or
resolved by a heartbeat or dose record). `sos` is ended by cancellation
(`cancelledAt`), not resolution.

Alert `kind`: `sos`, `area_exit`, `dose_missed`, `trip_deviation`,
`trip_not_completed`, `monitoring_lost`, `fall`, `low_battery`, `heart_rate`, `wellbeing`. Alert `pushStatus`: `none` (no guardian
device had a push token), `sent`, `failed`, `simulated`. `wellbeing` alerts are
never resolved; guardians acknowledge them.

### Heart rate (watch)

The watch measures heart rate and decides itself when a reading is out of
range; the server never evaluates health data, it stores and relays what the
watch reports. Readings are informational and **not a medical assessment**.

- The watch uploads readings with `POST .../vitals` (at most one per 30 s is
  enough for the guardian's trend view) and drops readings of 0 bpm (watch not
  worn) or with unreliable sensor accuracy, because one invalid reading rejects
  the whole batch. It retries 5xx and network errors with the same batch and
  drops a batch that got a 4xx.
- When a reading stays above `highBpm` or below `lowBpm` for `sustainedSeconds`
  (watch defaults: 120 and 45 bpm for 120 s, fixed in the app), the watch sends
  one `heart_rate_out_of_range` event per episode with
  `heartRate {bpm, direction: "high"|"low", lowBpm, highBpm, sustainedSeconds}`.
  It becomes a `heart_rate` alert whose `details` hold that object. Once the
  reading is back in range, `heart_rate_in_range` resolves it.
- While a `heart_rate` alert younger than 60 minutes is still open, further
  `heart_rate_out_of_range` events are stored but create no alert and no push,
  so a flapping reading cannot page guardians repeatedly (`alert: null` in the
  response).
- `heart_rate` is not urgent: it cannot be cancelled, gets no reminders, and
  acknowledging it sends nothing to the senior.
- Push notifications never contain the reading: the title is "…'s watch: heart
  rate outside the set range" and the body says it is a watch reading, not a
  medical assessment. A non-`device` `source` (an emulator's virtual sensor
  must send `simulated`) gets the `[Simulation]` prefix like other events.
- Readings are kept for 7 days (pruned by the watchdog) and are redacted from
  the development request log.

## Wellbeing check-in (OpenAI)

The senior talks with Carely's assistant about how they feel (the app uses
[Live voice](#live-voice-hands-free); the typed and push-to-talk endpoints above
remain in the API but the app no longer calls them). When
the check-in ends, the guardians get a short summary; they never see the
conversation itself. The assistant is informational: it does not diagnose, gives
no medical or medication advice, and never sends an SOS itself.

**Provider.** OpenAI, called from the backend only; the API key
(`OPENAI_API_KEY`) never reaches a device. Without a key the server still
starts, logs a warning, and the assistant endpoints answer 503
`assistant_unavailable` (`GET .../wellbeing/session` reports
`assistant.available: false` and `assistant.live: false`).

| Variable | Default | Use |
| --- | --- | --- |
| `OPENAI_REALTIME_MODEL`, `OPENAI_REALTIME_VOICE` | `gpt-realtime-2.1-mini`, `marin` | The spoken conversation (Realtime API over a WebSocket) |
| `OPENAI_TRANSCRIBE_MODEL` | `gpt-transcribe` | Transcript of the senior's speech (Realtime input transcription; also the unused push-to-talk endpoint) |
| `OPENAI_CHAT_MODEL` | `gpt-6-luna` | The guardian summary (reasoning effort `medium`, strict JSON schema); also the unused typed replies |
| `WELLBEING_IDLE_MINUTES` | 20 | Idle check-ins are finished by the watchdog |
| `RATE_LIMIT_ASSISTANT_PER_HOUR` | 120 | Paid calls (each live connection, each spoken turn, the summary, and the unused typed endpoints) per senior; 429 above |

**Data flow.** Each reply sends OpenAI the system instructions (in
`src/assistant/prompts.ts`), the senior's display name, the guardians' display
names, the phone's language and local time, and at most the last 40 messages of
the open check-in. Voice messages are uploaded to OpenAI for transcription and
only the transcript is stored. Requests use `store: false`. While a check-in is
open its messages are stored in `wellbeing_messages`; **finishing deletes them**,
keeping only the session metadata (times, message counts, finish reason, model)
and the report. No other health data (heart rate, doses, location) is sent to
OpenAI. Message text, recordings and summaries are redacted from the
development request log, and audio responses are not logged.

**Ending.** A check-in ends when the senior presses Finish, when the app
finishes it after a reply with `suggestFinish` (`reason: "assistant"`), or when
the watchdog finds it idle for `WELLBEING_IDLE_MINUTES` (`finishReason: "idle"`).
An idle check-in the senior never answered is deleted without a report. If the
summary fails, the check-in stays open: the app can retry, and the watchdog
retries after each idle period; after 24 hours it is closed with a report that
has no summary (`source: "structured"`, `structured.summaryUnavailable: true`).

**Report.** `structured` holds `kind: "wellbeing_chat"`, `mood` and `energy`
(`good`, `okay`, `low`, `unclear`), `sleep` (`good`, `okay`, `poor`, `unclear`),
`pain` (`none`, `mild`, `strong`, `unclear`), `concerns` (up to 5 short facts in
the senior's words), `attention` (`none`, `soon`, `urgent`), `attentionReason`,
`language`, `sessionId`, `startedAt`, `finishedAt`, `finishReason`,
`seniorMessages`, `voiceMessages` and `assistant` (e.g. `openai/gpt-6-luna`).
`summary` is 2 to 4 plain sentences in the language of the conversation.
`period` is the check-in's local date. The model is told to use only what the
senior said and `unclear` for anything not discussed, but a summary can still
be wrong: show it as an AI summary, not as fact.

**Notifications.** Every report is pushed to the guardians: "<name> shared a
wellbeing check-in", or "<name>'s wellbeing check-in: please read soon" when
`attention` is `soon` or `urgent`, with data `{reportId, seniorId, kind:
"wellbeing_report"}`. A `wellbeing` alert ("<name>'s wellbeing check-in needs
attention", dedup key `wellbeing:<sessionId>`, at most one per check-in) is
raised when a reply flags a possible emergency (`details {sessionId, attention:
"urgent", during: "conversation"}`; the reply tells the senior to press SOS or
call 112) or when the summary rates attention `urgent` (`details {sessionId,
reportId, attention, reason}`). An alert raised during the conversation gains
`details.reportId` when the report is made. Pushes never contain what the senior
said. `wellbeing` is not an urgent kind: no reminders, no cancellation.

**Unverified:** the OpenAI requests follow the current API reference; against
the live API only a greeting has been received so far. The contract is covered
by tests with a stubbed `fetch` and a fake assistant. Transcription, the
summary, the prompts and the attention rating have not been evaluated on real
conversations.

### Live voice (hands-free)

The senior talks without pressing anything: the app streams the microphone to
the backend over a WebSocket, the backend relays it to the OpenAI Realtime API
(speech to speech), and the model's voice streams back. The model's semantic
voice activity detection (eagerness `low`, so pauses are not cut off) decides
when the senior has finished; the app holds no OpenAI logic or key. Available
only with `OPENAI_API_KEY` set (`assistant.live`); the summary
is still written by `OPENAI_CHAT_MODEL`.

**Connecting.** `GET /v1/seniors/:id/wellbeing/sessions/:sessionId/live` with
`Upgrade: websocket` and `Authorization: Bearer <device token>`. Only the senior,
only an open check-in. A refused upgrade gets the usual status (401, 403, 404,
409 `session_closed`/`session_full`, 429, 503 when live voice is not available,
400 without the upgrade header); the WebSocket handshake carries no body, so only
the status reaches the client. One live connection per check-in: a new one
closes the older (1000). Start a voice check-in with `POST .../sessions
{voice: true}` so the live connection greets; on a check-in that already has
messages (for example after typing) the model continues the same conversation
and waits for the senior.

**Frames (JSON text).** Audio is base64 PCM16 little-endian mono at 24 kHz.

| Direction | Frame | Meaning |
| --- | --- | --- |
| app → server | `{type: "audio", audio}` | About 100 ms of microphone audio. Dropped when malformed, over 256 KB, before `ready` or after the goodbye |
| app → server | `{type: "interrupt"}` | Stop the current reply (the app also clears its own playback) |
| server → app | `{type: "ready"}` | Upstream configured; start streaming. An empty check-in gets the spoken greeting right after |
| server → app | `{type: "speech_started"}`, `{type: "speech_stopped"}` | Voice activity of the senior |
| server → app | `{type: "audio", audio}` | Chunk of the assistant's voice, in order |
| server → app | `{type: "audio_done"}` | The current reply's audio is complete |
| server → app | `{type: "message", message}` | A stored message, same shape as the HTTP API: the senior's transcript (`inputMode: "voice"`) or the assistant's. Order is kept: an assistant transcript waits up to 3 s for the senior's transcript of that turn |
| server → app | `{type: "safety_concern"}` | The model reported a possible emergency: the app should show SOS. The `wellbeing` alert is raised as for typed check-ins and the next assistant message has `safetyConcern: true` |
| server → app | `{type: "finished", session, report}` | The model said goodbye and called `end_check_in`; after its audio, the check-in was finished exactly like `POST .../finish` with `reason: "assistant"`. Then the server closes (1000) |
| server → app | `{type: "error", code, message}` | `assistant_unavailable` (upstream failed: close 1011; or the summary failed: close 1000 and the check-in stays open), `session_closed`, `session_full`, `rate_limited`, `time_limit`; then the server closes |

Closing the socket only ends voice mode; the check-in stays open and can
continue as text or with a new connection.

**Model tools.** `report_safety_concern` (an emergency was described; the
model keeps talking and tells the senior to press SOS or call 112; it never
sends an SOS) and `end_check_in` (called after the goodbye). Instructions:
`voiceInstructions` in `src/assistant/prompts.ts`.

**Limits.** Each connection and each spoken turn count against
`RATE_LIMIT_ASSISTANT_PER_HOUR`. At 40 senior messages the check-in is finished.
A connection lasts at most 20 minutes (`time_limit`).

**Privacy.** Audio passes through the backend to OpenAI and is never stored or
logged; only the transcripts are stored, as messages of the open check-in, and
finishing deletes them like typed ones. Each connection sends OpenAI the voice
instructions, the senior's and guardians' display names, the language hint and
local time, and the last 40 messages of the check-in.

**Dependencies.** `ws` (with `@types/ws`): Node has no built-in WebSocket
server, and the OpenAI connection needs an `Authorization` header, which the
standard WebSocket client cannot send. `@hono/node-server` 2 handles the upgrade
with `upgradeWebSocket` and a `ws` `WebSocketServer({ noServer: true })`; no
extra Hono package is needed. Behind a reverse proxy (Coolify/Traefik), WebSocket
upgrades must be allowed on the same host.

**Verified:** one live connection against the real API: configured in about
2 s, first greeting audio after about 3 s, the greeting stored as a message.
Not verified: a full spoken conversation, the tools, and the safety and goodbye
behaviour with real speech.

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
  demo, not production: no token rotation. A lost device can be revoked from
  another device of the same user.
- Rate limits are per client IP and in memory (one process, reset on restart):
  `POST /v1/seniors` allows `RATE_LIMIT_BOOTSTRAP_PER_MINUTE` (default 10)
  requests a minute, and `POST /v1/pairing/claim` blocks an IP for the rest of a
  15-minute window after `RATE_LIMIT_CLAIM_FAILURES_PER_15MIN` (default 10)
  failed claims. Successful claims never count. Forwarded headers are not
  trusted, so behind a reverse proxy every client shares the proxy's limit.
- Push retries are limited: one retry for a failed non-SOS push, and at most
  three SOS reminders. Clients still recover by refreshing alerts.
- The seed data and barcode catalog are synthetic.
- A watch token is a full senior token (it could revoke devices or delete the
  account); the watch app only uses the endpoints it needs. The 5-minute watch
  code and the shared failed-claim limit are the only safeguards.
- Heart-rate thresholds are fixed in the watch app, not part of the guardian
  configuration, and have not been validated for any individual. There is no
  per-guardian consent switch for heart-rate sharing yet, and no server-side
  downsampling.
- The wellbeing assistant sends what the senior says to OpenAI (see above),
  including the live audio stream in hands-free voice. Its per-senior call limit
  is in memory like the other rate limits, and there is no spending cap beyond
  it. The live relay and its one-connection-per-check-in rule assume a single
  backend process.

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
- 2026-10-03: pairing codes have a purpose. `POST /v1/pairing/claim` now
  rejects (410, not consumed) codes from the new `POST /v1/pairing/watch-codes`;
  `POST /v1/pairing/codes` and existing codes are guardian codes as before.
  Event `type` gains `heart_rate_out_of_range` and `heart_rate_in_range`, and
  alert `kind` gains `heart_rate` (exhaustive switches must handle it);
  event-backed `heart_rate` alerts carry `details`.
- 2026-10-04: alert `kind` gains `wellbeing` (exhaustive switches must handle
  it); its `details` hold `sessionId`, `attention` and, once the report exists,
  `reportId`. `GET .../overview` adds `latestReport` (`latestReportAt` is
  unchanged). New error codes `session_closed`, `session_full` (409), `no_speech`
  (422) and `assistant_unavailable` (503) come only from the new wellbeing
  endpoints.
- 2026-10-04: `GET .../wellbeing/session` adds `assistant.live`, and
  `POST .../wellbeing/sessions` accepts `voice` (a voice check-in starts without
  a typed greeting when live voice is available). New WebSocket route
  `GET .../wellbeing/sessions/:sessionId/live` (hands-free voice).

- 2026-10-04: `POST /v1/seniors/:id/wellbeing/speech` (read-aloud) and the
  `ASSISTANT_PROVIDER` / `OPENAI_TTS_*` settings are removed: the Realtime model
  speaks itself, and the scripted assistant had no voice. Its reports
  (`source: "simulated"`) can no longer be created.

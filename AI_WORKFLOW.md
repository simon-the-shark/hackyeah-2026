# AI Workflow

This project uses AI-assisted development. Keep this document current and
public-safe. Do not include credentials, tokens, personal data, private
endpoints, or confidential prompts.

## Tools Used

| Model, agent, MCP server, or Agent Skill | Version or source | Role in the project |
| --- | --- | --- |
| OpenCode | `openai/gpt-5.6-terra` | Repository setup, implementation, and validation assistance |
| OpenCode | `openai/gpt-6-astra` | Product documentation and mobile implementation planning |
| OpenCode | `openai/gpt-6.1-sol` | Backend container startup diagnosis and deployment fix |
| context7-mcp Agent Skill | Local skill | Current pnpm configuration documentation for the deployment fix |
| Cursor Agent | Claude Opus 5.5 | Navigation baseline and build validation |
| Claude Code | Claude Opus 5.5 | Senior home navigation refinements and build validation |
| Claude Code | Claude Opus 5.5, Claude Sonnet 5.5 | Backend planning, implementation, tests, PR review fixes, and documentation |
| Prelint | GitHub app (prelint.com) | Automated AI code and product-decision review on pull requests |
| Context7 MCP | Context7 | Current third-party library documentation when required |

## Important Prompts And Instructions

- `AGENTS.md` defines the repository's platform, validation, and hackathon constraints.
- The HackYeah 2026 challenge statement defines the public submission requirements.
- Product planning request: document an elderly-care companion with phone/watch
  geofencing and SOS, medication reminders/barcodes/3D references, easy contacts,
  and on-device wellbeing AI with guardian reporting. Prepare `MOBILE_PLAN.md`;
  backend implementation belongs to a separate parallel agent. Planned trips,
  learned routes, voice interaction, and fall detection are stretch features.
- Backend request: decide which features need a backend versus mobile only, and
  build it in `backend/` with the latest Hono and pnpm. User decisions: PostgreSQL
  with Drizzle ORM, the guardian as a second role in the ArkTS app, HarmonyOS Push
  Kit as the real default push provider (a log provider only by explicit opt-in),
  the backend README updated with every contract change, and project docs
  switched from OpenHarmony/Oniro to HarmonyOS.

## AI-Assisted Work Log

| Date | Tool/model | Request or task | Generated or changed | Human review and validation |
| --- | --- | --- | --- | --- |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Align project with the HackYeah challenge starter and requirements | Challenge documentation, resource references, skills archive, SDK policy, and starter screen | Build verification pending |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Configure DevEco environment and build across several sessions | Located DevEco's bundled hvigor and SDK root, resolved SDK sync configuration, added the macOS build wrapper, and assessed API 23 installation | `assembleHap` completed successfully with API 24; API 23 is being installed through DevEco Studio. Signing, emulator installation, and launch remain unverified. |
| 2026-10-03 | OpenCode / `openai/gpt-6-astra` | Document selected concept and plan mobile delivery | Updated README, brief, repository instructions, technical stack, and AI disclosure; added `MOBILE_PLAN.md` with priorities, role flows, architecture, feasibility gates, integration needs, and validation plan | Reviewed against the current official challenge statement and checked documentation diff; documentation-only work, no new build or runtime validation. Platform APIs, watch support, push transport, and local inference remain unverified. |
| 2026-10-03 | Cursor Agent / Claude Opus 5.5 | Build the navigation baseline from the mobile and backend feature lists | Role picker, senior and guardian home screens with grouped features, a shared "Coming soon" placeholder screen using `Navigation`/`NavPathStack`, light/dark color resources, and SDK-verified system symbols | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); `git diff --check` clean. Not run on an emulator because no target was connected. No feature behavior, data, platform service, or integration was added. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Move senior Medication, Contacts and Wellbeing from the home list into a bottom navigation bar | Senior home now uses `Tabs` with a large-label custom bottom bar (Home, Medication, Contacts, Wellbeing); placeholder content extracted into a reusable `FeaturePlaceholder`; guardian home unchanged | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); `git diff --check` clean. Not run on an emulator because no HDC target was connected. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra`, Context7 MCP | Implement the phone safety slice and developer-only test tools | Added a configurable session-only home circle, foreground `geoLocationManager.on('locationChange')` auto-reporting after consent, local SOS and safe-area-exit events, guardian alert list/detail, and permission recovery through system settings. Deterministic trace replay and the phone-hosted watch simulation are hidden behind session-only Developer Mode in Settings. | Consulted current public OpenHarmony LocationKit and permission documentation. `./scripts/build-hap.sh` and `git diff --check` passed before the final UI-only removal of the nested SOS control. No emulator or device runtime validation was performed. Background location, remote delivery, and watch connectivity remain unimplemented and unverified. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra`, Context7 MCP | Prepare local mobile-to-backend connectivity | Added NetworkKit HTTP client, Internet permission, and session-only Connection onboarding UI. Started PostgreSQL 17 in Apple Container on host port 5433, applied backend migrations and synthetic seed, and started the backend on host port 8787 with simulated push. | Verified `GET /health` at `http://127.0.0.1:8787`. Emulator/device reachability and end-to-end mobile requests remain unverified; do not commit generated tokens or local host addresses beyond loopback defaults. |
| 2026-10-03 | Cursor Agent / Claude Opus 5.5 | Visual and UX pass over the phone safety slice | Added a dedicated senior SOS screen (5-second countdown with Send now/Cancel, then an honest local-only confirmation); color-coded Safe Area status and plain-language location sharing card; guardian alert list with New/Seen state, readable times and empty state; alert detail with working acknowledge; safe-area setup with radius presets, decimal-friendly inputs and inline validation; restyled Settings, trace replay and a watch-face simulation. Fixed alerts and acknowledgement not refreshing, duplicated page titles, and low-accuracy live samples being labelled as demo traces. Shared `IconBadge`, `NoticeBanner` and `ActionRow` components. | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP) with no ArkTS warnings; `git diff --check` clean. Symbols and `NavDestination.onShown`, `getPromptAction` were checked against the installed SDK.  |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Senior medication tab: today's schedule and barcode check against the expected medicine code | Medication tab lists today's doses (synthetic demo medicines with GS1 restricted-circulation codes) and highlights the next dose; each dose has a "Check medicine box" button that opens the Scan Kit default scanner (`scanBarcode.startScanForResult`, verified in the installed HMS SDK and official guide) and compares the scanned code with the expected one, normalizing EAN/UPC/GTIN leading zeros and GS1 DataMatrix AI 01. Devices without Scan Kit get a clearly labelled simulated correct/wrong scan. Scanner wrapped in `platform/BarcodeScanner.ets`; logic in `services/MedicationSchedule.ets` | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); local hypium unit tests for dose ordering, next dose and barcode matching pass via hvigor `test`. Live camera scanning not verified: no HDC target was connected, and Scan Kit availability on the emulator is unknown. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Replace per-dose scanning with a Taken action; move scanning to a page FAB that checks today's list and opens a medicine detail view | Each dose has a Taken button with undo that records the time taken on the device (`@kit.ArkData` preferences, today's records only); a "Scan medicine" FAB scans with Scan Kit, looks the code up in today's schedule and opens a detail page (illustration, name, dose, today's times with Taken) or explains that the box is not on today's list. Demo medicine images are generic SVG illustrations. The simulated scan path remains for targets without Scan Kit | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); hypium unit tests for next untaken dose, taken-dose encoding and scanned-code lookup pass via hvigor `test`. Not run on an emulator because no HDC target was connected; taken doses are not yet sent to the backend. |

| 2026-10-03 | Claude Code / Claude Opus 5.5 | Backend scope and plan | `backend/PLAN.md`: backend/mobile feature split, data model, API contract, push design, verification plan | Reviewed and amended by the user (Drizzle ORM, real push default, README-per-change rule) before implementation. |
| 2026-10-03 | Claude Code / Claude Sonnet 5.5 | Implement the backend | `backend/`: Hono API, Drizzle schema and migrations, pairing and device tokens, versioned guardian config, idempotent events, alerts with Push Kit and log providers, heartbeat/trip watchdog, doses, reports, synthetic catalog and seed data, README contract | `pnpm typecheck` clean; 19 integration tests passed against Postgres in Docker; curl smoke test on the running server. Push Kit request format taken from secondary sources because the official pages did not render; never sent live. |
| 2026-10-03 | Claude Code / Claude Sonnet 5.5 | Address Prelint review on the backend PR | Guardian-only report reads, dose history kept after medication deletion, `trip_started` event, guardian-wide alert inbox, documented heartbeat threshold and late trip arrival | 28 integration tests passed; curl checks of each fix; PR squash-merged after the final review reported no code defects (the last doc-only commit was not re-reviewed). |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Switch project docs to HarmonyOS | `AGENTS.md`, `README.md`, `HACKATHON_BRIEF.md`, `docs/TECH_STACK.md`, `MOBILE_PLAN.md`, this file | Checked against `build-profile.json5`, which already sets `runtimeOS: "HarmonyOS"` and SDK `6.1.1(24)`. Documentation only; no build or emulator run. Challenge copies under `docs/challenge/` were left unchanged. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Rename the app to Carely and apply the team-provided icon | App and launcher labels set to Carely, role-picker title updated, ability descriptions filled in; layered icon foreground/background replaced in `AppScope` and `entry` with the provided 1024x1024 PNGs; start-window icon regenerated from the same layers (144x144, rounded) | `./scripts/build-hap.sh` passed with API 24; icon composite previewed locally. Not run on an emulator because no HDC target was connected, so the launcher appearance is unverified. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Detect missed doses on the server | Watchdog computes scheduled doses per medication time zone (DST-aware), raises one `dose_missed` alert after a grace period; canonical dose occurrence ids; alert `details`; migration `0002` | 39 integration tests passed, including DST conversion, snooze, dedup and lookback cases; live check on the running server with a 1-minute grace raised the alert through the watchdog timer. Not run against an emulator. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Address Prelint review of the missed-dose PR | Only `times`/`timezone` edits restart detection (`schedule_updated_at`); device `dose_missed` event marked deprecated; occurrence-id rule, authoritative server schedule and limitations documented; Prelint section added here | 39 integration tests passed, including a name-only edit that still raises the alert. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra`, Context7 MCP | Add backend request logs | Added a global Hono middleware that logs each request URL, headers, body, final response status, response headers/body, and duration for local diagnostics. Authorization and cookie headers are always redacted. | `pnpm typecheck` passed. A live `GET /health` recorded complete request/response details and a 200 response. `pnpm test` was blocked before discovery because its configured PostgreSQL user `elder` does not exist. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra`, HarmonyOS SDK declarations | Fix empty mobile event UUIDs | Added a shared event-ID generator. It prefers the public ArkTS `util.generateRandomUUID(true)` and produces a UUID v4 fallback only when the runtime returns an empty value, as observed in the emulator request log. SOS and safe-area-exit now use it. | `./scripts/build-hap.sh` passed (unsigned HAP), as did `git diff --check`. Runtime retest on the emulator remains pending. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Run migrations with backend tmux development command | Updated `pnpm dev:tmux` to execute database migrations before it starts or reattaches to the backend tmux session, preventing active code from running against an outdated local schema. | `bash -n scripts/dev-tmux.sh` passed and migrations were applied to the active local Postgres database. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Show senior pairing code in Settings | Added a Senior-only Settings card that loads and displays the active guardian pairing code. The backend pairing-code endpoint now returns an unexpired unused code before creating a new one; its README contract was updated. | `pnpm typecheck`, `./scripts/build-hap.sh`, and `git diff --check` passed. Emulator runtime validation remains pending. |
| 2026-10-03 | OpenCode / `openai/gpt-6-luna` | Address production log exposure and Safe Area versioning review | Disabled detailed HTTP diagnostics when `NODE_ENV=production`; recursively redacted token, pairing-code, credential, password, and secret fields in JSON logs. Safe Area Settings now fetches the stored entity/version and sends the version with subsequent updates. Documented the production logging switch in the backend README. | `pnpm typecheck`, `./scripts/build-hap.sh`, and `git diff --check` passed. No emulator runtime check. Backend tests were not run because the local test DB is configured with a PostgreSQL role that is absent in the active container. |
| 2026-10-03 | Cursor Agent / Claude Opus 5.5 | Address Prelint review on geo-features PR | Redacted response-body secrets in dev HTTP logs; mapped each backend alert `kind` to distinct guardian copy; stable SOS event id per screen session; persisted API session in preferences; queued failed `area_exit` events for retry; updated safe-area and location-sharing copy. | `pnpm typecheck`, `./scripts/build-hap.sh` passed. Backend vitest not run (test DB role missing). No emulator run. |
| 2026-10-03 | OpenCode / `openai/gpt-6-luna` & space bunny free, HarmonyOS SDK declarations | Fix startup crash from persisted session, and close the safe-area sync gap | A device run showed `TypeError: Cannot read property getSync of undefined` in `ApiSessionStore.restore`. `preferences.getPreferencesSync` (since 11, atomicservice) returned `undefined` on the emulator. Replaced all synchronous Preferences access with a shared fail-safe `SafePreferences` wrapper on the documented async `getPreferences` API: it caches the instance, never throws, and returns fallbacks, so a storage failure can no longer prevent the app from launching. Sign-out now clears the in-memory session before touching storage, so it cannot leave a live token behind. Also loaded the guardian-configured safe area into the senior's local geofence, which previously always used the hardcoded Warsaw default while the backend used the configured boundary. | Verified the SDK signatures for `getPreferences`/`get`/`put`/`flush` and confirmed no synchronous Preferences calls remain. `./scripts/build-hap.sh` and `git diff --check` passed. Backend suite: 40 tests passed across 3 files after creating the missing `elder_care_test` database in the local Apple Container. **Not verified on an emulator or device** (no HDC target connected); the reported crash is fixed by construction and API contract, not by observation. |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra`, Context7 MCP | Containerize the backend | Added `backend/Dockerfile` for Node 22, lockfile-based pnpm installation, unprivileged runtime, port 8787, and a local `/health` health check. Added `.dockerignore` to exclude local environment files, credentials, dependencies, and tests from the build context. Documented the image build and explicit migration/runtime configuration requirements. | `pnpm typecheck` and `git diff --check` passed. Docker daemon was unavailable, so the image was not built or run. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Give the guardian a bottom navigation bar like the senior's | Guardian home now uses the shared `Tabs` bar (Home, Alerts, Location, Medication, Contacts); Alerts, Trusted Contacts and Medication Schedule moved from the home list into tabs. The alert inbox was extracted into a reusable `AlertsList` that reloads when its tab or page is shown. Location, Medication and Contacts tabs are placeholders until their screens land. | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP). Not run on an emulator because no HDC target was connected. |
| 2026-10-03 | OpenCode / `openai/gpt-6.1-sol`, Context7 MCP, context7-mcp Agent Skill | Fix Coolify container startup permission failure | Replaced `pnpm start` in the Dockerfile with direct Node/tsx startup to prevent runtime dependency installation, pinned pnpm to locally installed 11.7.0, removed obsolete package-level build allowance (workspace `allowBuilds` remains), and documented Coolify configuration. | `pnpm typecheck` passed; the exact startup command served HTTP 200 with `{"status":"ok"}` locally under production mode using synthetic configuration and simulated push. `git diff --check` passed. Docker daemon unavailable, so image build, unprivileged container execution, database integration, and Coolify redeployment remain unverified. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Load the senior medication list from the backend; Taken/Skip on list and detail; scan checks the server list | Medication tab now fetches `GET /v1/me`, `/medications` and today's `/doses` through a Network Kit client (`providers/backend`), shows one card per medicine with today's times and a confirmed Taken/Skip action, opens a detail view on tap, and records answers with `POST /doses` (idempotent occurrence IDs). Answers made while offline are queued on the device (`@kit.ArkData` preferences) and delivered on the next load. Scanning matches the server list and otherwise names the product from `GET /v1/catalog/:barcode`. Loading, error, empty and not-configured states and pull-to-refresh added; local demo medicines and their images removed. Dev-only `backend.json` raw file (git-ignored) holds the API address and device token until pairing exists. Network Kit, cleartext HTTP defaults, `@Require` and `Refresh` checked against official docs via Context7 and the installed SDK | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); 10 hypium unit tests pass via hvigor `test` (schedule, open/next dose, sorting, record merge, outbox encoding, barcode lookup). Request shapes verified with curl against the local backend (201 first answer, 200 on repeat, `from` filter, catalog 200/404). Not run on an emulator because no HDC target was connected, so live HTTP from the device, Scan Kit and the offline queue are unverified on a target. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Guardian Medication tab: list, details, edit/delete, and barcode-first add flow | Guardian Medication tab lists the senior's medications (name, dose, times) with loading/empty/error states and reloads when the tab or screen is shown again. A details screen shows all fields and the last taken/skipped answers from `GET /doses`, edits with `PUT` and the stored `version` (409 reloads the latest values and asks to review), and deletes after confirmation. The add flow starts with Scan Kit `scanBarcode.startScanForResult` (default UI, no camera permission; reuses the senior feature's wrapper) and falls back to manual barcode entry or a labelled "Use demo barcode (simulated)" seed code; `GET /v1/catalog/:barcode` prefills the name as a candidate that must be confirmed against the package (404 means manual entry); dose, instructions and one or more `HH:MM` times are entered by the guardian; the time zone is the device IANA zone from `i18n.getTimeZone().getID()`. Guardian calls reuse the branch's `MedicationApi`/`BackendClient` (now with PUT, DELETE and error details) authenticated with the paired guardian session (`apiSession`) instead of the senior's dev `backend.json`. Scan Kit, i18n, Network Kit request methods and AlertDialog options checked against the installed SDK declarations and Context7 docs | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP), no new ArkTS warnings; 16 hypium unit tests pass via hvigor `test` (6 new: time parsing, time list rules, validation, create/edit request mapping, manual barcode); `git diff --check` clean. Not run on an emulator or device (no HDC target), so the live HTTP calls, Scan Kit UI and dialogs are unverified on a target. Request shapes follow the backend routes but were not exercised against a running server. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Senior Contacts tab: trusted contacts from the backend, tap to call | Contacts tab lists `GET /v1/seniors/:id/contacts` in the guardian's order as large cards (initials avatar, name, number, call button); tapping opens the system dial screen with `call.makeCall` (no permission needed; checked in the installed SDK). The senior cannot add or edit contacts. The last list is cached on the device (`@kit.ArkData` preferences) and shown with an offline notice when the backend is unreachable. Shared backend client, config, `SeniorAccount` and status views are byte-identical to the medication branch so both merge cleanly | `./scripts/build-hap.sh` passed with API 24; hypium unit tests pass via hvigor `test` (contact order, initials, dialable number, cache encoding). Contacts endpoint checked with curl against the local backend. Not run on an emulator or phone: the dialer handoff, offline cache and Previewer behaviour are unverified on a target. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Guardian Contacts tab: manage the senior's trusted contacts | The guardian Contacts tab lists the senior's contacts (initials, name, number, call button), reloads when the tab or page is shown, and opens an add/edit screen with large name and phone inputs (phone keyboard, inline validation matching the backend rules). Edits send `version` and a 409 `version_conflict` shows the newer stored copy; delete asks for confirmation. Guardian calls reuse the branch's typed contacts client (`BackendClient` gained PUT/DELETE and error details) but authenticate with the paired guardian session from pairing instead of the senior dev config file. "Choose from phone contacts" uses the system picker `contact.selectContacts` (`@kit.ContactsKit`, since 10, no `@permission`, not system API; checked in the installed SDK), so the app needs no READ_CONTACTS permission | `./scripts/build-hap.sh` passed with API 24 and no new ArkTS warnings; hypium unit tests pass via hvigor `test` (name/phone validation, address-book number normalization, next sort order). Not run on an emulator, phone or against the backend: list/add/edit/delete, the conflict path, the contact picker and the dialer handoff are unverified on a target. |

## Workflow

### Ideation And Architecture

Selected concept: an elderly-care companion with senior phone/watch and guardian
phone experiences. Human-Centric Technology is the lead theme, with planned
on-device AI supporting Intelligent Experiences. `HACKATHON_BRIEF.md` records
scope; `MOBILE_PLAN.md` defines staged implementation. Backend work is separate.

### Implementation

AI-assisted changes are reviewed against the challenge statement and existing
ArkTS project configuration before acceptance.

### Testing And Debugging

Record builds, linting, tests, emulator runs, logs, screenshots, and manual
checks here as they are completed.

- Backend: `pnpm typecheck` and `pnpm test` (39 integration tests through
  `app.request()` against a PostgreSQL test database with an injected fake push
  provider), plus curl checks against the running server with seed data.

### Automated Review (Prelint)

Prelint is an AI review service installed as a GitHub app. On every pull
request it runs two checks, **Prelint** (code findings, posted as inline
comments) and **Prelint: Decision Review** (product decisions with a verdict
such as "Ship with changes", posted as a PR comment). Its findings are
advisory: each one was checked against the code, and fixes were verified with
the backend test suite before merging. Findings it raised and how they were
handled:

| Pull request | Findings | Outcome |
| --- | --- | --- |
| #1 Backend implementation | Seniors could read wellbeing reports (contract says guardian-only); `PLAN.md` contradicted itself on push credentials; medication deletion erased dose history; trip `active` state unreachable; late trip arrival behaviour unclear; `PLAN.md` data model and alert access out of date; README Node version | All fixed in code or docs over three rounds, with new tests; open product questions answered in the PR. Merged after the last review found no code defects |
| #4 HarmonyOS docs switch | None ("no product decisions identified") | Approved and merged |
| #6 Server-side missed doses | Any medication edit (even a name fix) reset detection and could hide missed doses; device `dose_missed` event silently became a no-op; possible app/server occurrence-id mismatch; unlimited snoozes; one grace period for all medicines | Reset limited to schedule edits with a new test; event marked deprecated; id rule documented as DST-independent with the server schedule authoritative; snooze cap and per-medication grace recorded as limitations |

## Unsuccessful Approaches

- `npx hvigor` did not resolve the build tool; DevEco's bundled wrapper worked.
- Selecting API 23 before its SDK was available failed; the recorded build used API 24.
- Fetching Huawei's Push Kit documentation pages returned only navigation text
  (client-side rendering); the request format came from secondary sources.
- Starting Postgres in Docker first failed because the Docker disk was full; the
  user approved removing unused Docker data.

## Known Limitations

- Phone safety is implemented only for the active app session. The configured
  home circle and alerts are not persisted. Remote SOS/guardian delivery is a
  clearly labelled local fixture; no backend or push transport is connected.
- Current-location access uses public LocationKit after user consent, but has
  not been exercised on an emulator or device. Background location is not
  requested or claimed; it requires separate target validation and a continuous
  LOCATION task before implementation.
- Watch Safety is a phone-hosted simulation only. No wearable module, device
  connection, or watch location path has been verified.
- Apart from the senior medication tab (today's schedule from synthetic demo
  data and barcode check), features are "Coming soon" placeholders. The
  medication schedule is not yet loaded from the backend, taken doses are only
  stored on the device, and reminders are not implemented.
- Live barcode scanning relies on HarmonyOS Scan Kit and has not been verified on
  an emulator or device; the simulated scan path is a demo fallback only.
- The `.hap` is unsigned because no signing profile is configured. Emulator
  installation and launch remain unverified.
- Backend Push Kit delivery is unverified against a real AppGallery Connect
  project and the HarmonyOS emulator. The push payload carries no
  click-through data yet, and the backend has not been called from an emulator.
- Backend pairing and demo bootstrap are unauthenticated and not rate limited;
  they are meant for the hackathon demo only.

## Lessons Learned

- Verify the installed SDK and bundled toolchain rather than assuming npm
  tooling or a requested API version is available.
- Separate product intent from verified behavior: watch support, background
  monitoring, push delivery, and local inference need target-specific evidence.

## AI Feature Disclosure

### Planned Feature (Not Implemented)

- **Purpose:** Summarize voluntary wellbeing check-ins and support everyday
  wellbeing conversations; share a reviewed report with the guardian.
- **Model/service:** Not selected. The mobile goal is on-device inference;
  on-premise server inference would require a separate decision. Record the
  eventual runtime, model/version, license, quantization, and resource budget.
- **Inference flow:** Structured check-in plus a limited local history subset →
  local inference → validated summary → user preview → explicitly shared report.
- **Data/privacy:** Keep raw check-ins and inference inputs on device by default;
  expose sharing controls and local deletion. Only approved report data crosses
  the mobile integration boundary. Use synthetic data in the public demo.
- **Failure behavior:** Preserve structured check-ins without the model; show
  unavailable state on timeout, memory failure, or invalid output. Do not label
  scripted responses as local AI. SOS/geofence logic stays independent of AI.
- **Limitations:** No clinical diagnosis, medication changes, or claim of passive
  health monitoring. Generated summaries can omit or invent information and
  must be checked against the recorded facts.
- **Evaluation:** Synthetic check-ins covering factuality, missing data,
  unsupported advice and malformed outputs; verify offline inference and record
  latency/memory on the actual target. No product AI evaluation has run yet.

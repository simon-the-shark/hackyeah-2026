# AI Workflow

This project uses AI-assisted development. Keep this document current and
public-safe. Do not include credentials, tokens, personal data, private
endpoints, or confidential prompts.

## Tools Used

| Model, agent, MCP server, or Agent Skill | Version or source | Role in the project |
| --- | --- | --- |
| OpenCode | `openai/gpt-5.6-terra` | Repository setup, implementation, and validation assistance |
| OpenCode | `openai/gpt-6-astra` | Product documentation and mobile implementation planning |
| Cursor Agent | Claude Opus 5.5 | Navigation baseline and build validation |
| Claude Code | Claude Opus 5.5 | Senior home navigation refinements and build validation |
| Claude Code | Claude Opus 5.5, Claude Sonnet 5.5 | Backend planning, implementation, tests, PR review fixes, and documentation |
| Prelint | GitHub app | Automated decision review on backend pull requests |
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

| 2026-10-03 | Claude Code / Claude Opus 5.5 | Backend scope and plan | `backend/PLAN.md`: backend/mobile feature split, data model, API contract, push design, verification plan | Reviewed and amended by the user (Drizzle ORM, real push default, README-per-change rule) before implementation. |
| 2026-10-03 | Claude Code / Claude Sonnet 5.5 | Implement the backend | `backend/`: Hono API, Drizzle schema and migrations, pairing and device tokens, versioned guardian config, idempotent events, alerts with Push Kit and log providers, heartbeat/trip watchdog, doses, reports, synthetic catalog and seed data, README contract | `pnpm typecheck` clean; 19 integration tests passed against Postgres in Docker; curl smoke test on the running server. Push Kit request format taken from secondary sources because the official pages did not render; never sent live. |
| 2026-10-03 | Claude Code / Claude Sonnet 5.5 | Address Prelint review on the backend PR | Guardian-only report reads, dose history kept after medication deletion, `trip_started` event, guardian-wide alert inbox, documented heartbeat threshold and late trip arrival | 28 integration tests passed; curl checks of each fix; PR squash-merged after the final review reported no code defects (the last doc-only commit was not re-reviewed). |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Switch project docs to HarmonyOS | `AGENTS.md`, `README.md`, `HACKATHON_BRIEF.md`, `docs/TECH_STACK.md`, `MOBILE_PLAN.md`, this file | Checked against `build-profile.json5`, which already sets `runtimeOS: "HarmonyOS"` and SDK `6.1.1(24)`. Documentation only; no build or emulator run. Challenge copies under `docs/challenge/` were left unchanged. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Rename the app to Carely and apply the team-provided icon | App and launcher labels set to Carely, role-picker title updated, ability descriptions filled in; layered icon foreground/background replaced in `AppScope` and `entry` with the provided 1024x1024 PNGs; start-window icon regenerated from the same layers (144x144, rounded) | `./scripts/build-hap.sh` passed with API 24; icon composite previewed locally. Not run on an emulator because no HDC target was connected, so the launcher appearance is unverified. |

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

- Backend: `pnpm typecheck` and `pnpm test` (28 integration tests through
  `app.request()` against a PostgreSQL test database with an injected fake push
  provider), plus curl checks against the running server with seed data.

## Unsuccessful Approaches

- `npx hvigor` did not resolve the build tool; DevEco's bundled wrapper worked.
- Selecting API 23 before its SDK was available failed; the recorded build used API 24.
- Fetching Huawei's Push Kit documentation pages returned only navigation text
  (client-side rendering); the request format came from secondary sources.
- Starting Postgres in Docker first failed because the Docker disk was full; the
  user approved removing unused Docker data.

## Known Limitations

- The app contains only role navigation and "Coming soon" feature screens; no
  product functionality is implemented.
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

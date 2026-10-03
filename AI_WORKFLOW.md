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
| Context7 MCP | Context7 | Current third-party library documentation when required |

## Important Prompts And Instructions

- `AGENTS.md` defines the repository's platform, validation, and hackathon constraints.
- The HackYeah 2026 challenge statement defines the public submission requirements.
- Product planning request: document an elderly-care companion with phone/watch
  geofencing and SOS, medication reminders/barcodes/3D references, easy contacts,
  and on-device wellbeing AI with guardian reporting. Prepare `MOBILE_PLAN.md`;
  backend implementation belongs to a separate parallel agent. Planned trips,
  learned routes, voice interaction, and fall detection are stretch features.

## AI-Assisted Work Log

| Date | Tool/model | Request or task | Generated or changed | Human review and validation |
| --- | --- | --- | --- | --- |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Align project with the HackYeah challenge starter and requirements | Challenge documentation, resource references, skills archive, SDK policy, and starter screen | Build verification pending |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Configure DevEco environment and build across several sessions | Located DevEco's bundled hvigor and SDK root, resolved SDK sync configuration, added the macOS build wrapper, and assessed API 23 installation | `assembleHap` completed successfully with API 24; API 23 is being installed through DevEco Studio. Signing, emulator installation, and launch remain unverified. |
| 2026-10-03 | OpenCode / `openai/gpt-6-astra` | Document selected concept and plan mobile delivery | Updated README, brief, repository instructions, technical stack, and AI disclosure; added `MOBILE_PLAN.md` with priorities, role flows, architecture, feasibility gates, integration needs, and validation plan | Reviewed against the current official challenge statement and checked documentation diff; documentation-only work, no new build or runtime validation. Platform APIs, watch support, push transport, and local inference remain unverified. |
| 2026-10-03 | Cursor Agent / Claude Opus 5.5 | Build the navigation baseline from the mobile and backend feature lists | Role picker, senior and guardian home screens with grouped features, a shared "Coming soon" placeholder screen using `Navigation`/`NavPathStack`, light/dark color resources, and SDK-verified system symbols | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); `git diff --check` clean. Not run on an emulator because no target was connected. No feature behavior, data, platform service, or integration was added. |
| 2026-10-03 | Claude Code / Claude Opus 5.5 | Move senior Medication, Contacts and Wellbeing from the home list into a bottom navigation bar | Senior home now uses `Tabs` with a large-label custom bottom bar (Home, Medication, Contacts, Wellbeing); placeholder content extracted into a reusable `FeaturePlaceholder`; guardian home unchanged | `./scripts/build-hap.sh` passed with API 24 (unsigned HAP); `git diff --check` clean. Not run on an emulator because no HDC target was connected. |

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

## Unsuccessful Approaches

- `npx hvigor` did not resolve the build tool; DevEco's bundled wrapper worked.
- Selecting API 23 before its SDK was available failed; the recorded build used API 24.

## Known Limitations

- The app contains only role navigation and "Coming soon" feature screens; no
  product functionality is implemented.
- The `.hap` is unsigned because no signing profile is configured. Emulator
  installation and launch remain unverified.
- API 23 cannot be selected until its SDK components are downloaded in DevEco
  Studio; the project currently compiles with the installed API 24 SDK.

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

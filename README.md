# HackYeah 2026

An elderly-care companion for HarmonyOS, built with ArkTS, ArkUI,
and the Stage model. It helps an older person stay within a designated safe
area, ask for help, follow a medication schedule, and contact trusted people.
A guardian receives alerts and wellbeing updates. The smartwatch is the
primary intended SOS surface; a phone provides the full companion experience.

## Product Scope And Status

- Core: safe-area exit alerts, SOS on phone/watch, medication reminders,
  barcode-assisted medication entry, 3D medication references, and easy calling.
- Planned intelligence: an on-device wellbeing assistant and guardian summaries.
- Stretch: guardian-defined trips, learned routine deviations, voice interaction,
  and fall detection.

The repository currently contains the starter application and a verified API 24
build, not these product features. Watch support, background monitoring, remote
push delivery, and local LLM execution require feasibility verification.
The backend (Hono + Drizzle + PostgreSQL API, with HarmonyOS Push Kit for
guardian alerts) lives in `backend/`; see `backend/README.md`.

## Requirements

- DevEco Studio with its bundled HarmonyOS SDK `6.1.1(24)`
- A HarmonyOS API 24 emulator (DevEco Studio Device Manager) for runtime testing

`build-profile.json5` sets `runtimeOS: "HarmonyOS"`, compiles and targets
`6.1.1(24)`, and declares `6.0.0(20)` as the compatible SDK, so the app keeps
API 20 compatibility (the hackathon minimum).

## Build

On macOS, run:

```zsh
./scripts/build-hap.sh
```

The script uses DevEco Studio's bundled hvigor wrapper and SDK. If DevEco Studio
is installed elsewhere, set `DEVECO_STUDIO_HOME` to its `.app` directory before
running the script. Use Previewer for fast ArkUI iteration and the DevEco Studio
HarmonyOS emulator for runtime, lifecycle, permission, and platform-integration
verification.

## Run

Create and boot a compatible virtual device in DevEco Studio's Device Manager,
then run the `entry` module on it. The starter screen displays `Hello World`
and changes to `Welcome` when tapped.

### Connect The App To The Backend

The Carely production backend address is built into the app. Create a senior
account and pair the guardian in the Connection screen; both phones then retain
their own authenticated session.

## Project Documents

- `HACKATHON_BRIEF.md` records the agreed product scope and demo path.
- `MOBILE_PLAN.md` defines mobile priorities, screens, architecture, feasibility
  gates, integration needs, and acceptance tests.
- `docs/TECH_STACK.md` records platform choices and unresolved capabilities.
- `backend/README.md` is the backend setup guide and the API contract for the
  mobile app; `backend/PLAN.md` records the backend scope.
- `AI_WORKFLOW.md` records AI-assisted development and validation.
- `hackathon-resources/` contains challenge-provided emulator and DevEco CLI
  guidance.
- `docs/challenge/` contains the challenge statement, setup references, and the
  upstream template agent guide.
- `hackathon-skills/` vendors the challenge-provided agent skills for local
  reference. They must be installed or configured separately to become active
  in a coding agent.

## Submission

Before submission, provide reproducible setup/build/install/launch instructions,
a working `.hap`, a short demo recording, an architecture summary, and the
completed AI workflow disclosure.

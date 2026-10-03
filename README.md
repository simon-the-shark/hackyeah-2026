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

### Phone Background Location

On the paired senior phone, open **Safe Area → Turn on sharing** and grant
precise location and notifications. Sharing uses a HarmonyOS location continuous
task so it can continue with another app open or the screen locked, with a system
notification. The requested update interval is 30 seconds. Explicit stop or a
system cancellation ends monitoring; force-stop/reboot do not self-restart it.

See [background location behavior and runtime checks](docs/BACKGROUND_LOCATION.md)
for configuration caching, confirmed exit/re-entry detection, offline retries,
build/test commands, and validation limits. Background execution still needs
verification with a signed build on the target device. Guardian background push
delivery is a separate integration; its current local polling is foreground-only.

### Smartwatch App

The `watch` module is a separate HarmonyOS app entry for a wearable
(`deviceTypes: ["wearable"]`, round 466×466 screen) in the same bundle.
`./scripts/build-hap.sh` builds both HAPs:
`entry/build/default/outputs/default/entry-default-unsigned.hap` and
`watch/build/default/outputs/default/watch-default-unsigned.hap`. Sign them with
your own DevEco Studio debug signature before installing; signing material is
local and never committed.

The watch pairs to the senior with a 6-digit code, then:

- sends SOS (3-second countdown to cancel) with its own last location;
- reports its own location heartbeat (`measuredBy: "watch"`, never the phone's);
- reads heart rate with Sensor Service Kit (`ohos.permission.READ_HEALTH_DATA`),
  uploads one median sample per 30 s, and sends one alert event when the reading
  stays above 120 or below 45 bpm for 2 minutes (resolved after 2 minutes back in
  range). Readings are informational, not a medical assessment.

Sensors and location run only while Carely is open on the watch (sensor use in
the background is not allowed). On an emulator, or when the sensor reports
itself as a mock, data is sent with `source: "simulated"` and shown as
SIMULATED on both watch and guardian screens.

To try it on the DevEco Studio emulator (team images use API 23):

1. Install and create a wearable emulator, for example
   `Emulator -install -deviceType wearable -osVersion "HarmonyOS 6.1.0(23)"`
   then `Emulator -create Carely_Watch_23 -deviceType wearable -osVersion "HarmonyOS 6.1.0(23)"`
   (`Emulator` lives in `DevEco-Studio.app/Contents/tools/emulator/`), or use
   the Device Manager. When a phone emulator already runs on the default hdc
   port 5555, start the watch on another one: `Emulator -start Carely_Watch_23 -hdcPort 5557`.
2. The watch uses the same built-in production backend address as the phone
   (`watch/src/main/ets/services/BackendUrl.ets`). The watch endpoints must be
   deployed there first (see `backend/README.md`).
3. On the senior phone: Settings, Smartwatch, Pair a watch. Enter the code on
   the watch within 5 minutes and allow heart rate and location.
4. Set a heart rate in the emulator's Virtual Sensor panel and a position in
   its GPS panel.
5. On the guardian phone: Home, Safety, Watch & vitals.

## Project Documents

- `HACKATHON_BRIEF.md` records the agreed product scope and demo path.
- `MOBILE_PLAN.md` defines mobile priorities, screens, architecture, feasibility
  gates, integration needs, and acceptance tests.
- `docs/TECH_STACK.md` records platform choices and unresolved capabilities.
- `docs/DESIGN_SYSTEM_AUDIT.md` records the app-wide control, navigation, color,
  accessibility and validation audit.
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

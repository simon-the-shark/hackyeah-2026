# HackYeah 2026

An OpenHarmony / Oniro hackathon application built with ArkTS, ArkUI, and the
Stage model. The product concept is not selected yet.

## Requirements

- DevEco Studio with OpenHarmony SDK 6.1
- API 24 compile SDK (the version supported by the installed DevEco SDK)
- API 24 emulator for runtime testing

The project retains compatibility with API 20, the hackathon minimum.

## API 23 Setup

The challenge baseline is API 23 for compilation, API 24 for runtime testing,
and API 20 as the minimum supported API. This machine currently has only the
API 24 SDK installed. In DevEco Studio, open **DevEco Studio > Settings >
OpenHarmony SDK**, select **API Version 23**, and click **Apply** to download
the ArkTS, toolchain, and previewer components. Once the download completes,
change `compileSdkVersion` in `build-profile.json5` to `6.1.0(23)` and rebuild.

## Build

On macOS, run:

```zsh
./scripts/build-hap.sh
```

The script uses DevEco Studio's bundled hvigor wrapper and SDK. If DevEco Studio
is installed elsewhere, set `DEVECO_STUDIO_HOME` to its `.app` directory before
running the script. Use Previewer for fast ArkUI iteration and an OpenHarmony
or Oniro emulator for runtime, lifecycle, permission, and platform-integration
verification.

## Run

Create and boot a compatible virtual device in DevEco Studio's Device Manager,
then run the `entry` module on it. The starter screen displays `Hello World`
and changes to `Welcome` when tapped.

## Project Documents

- `HACKATHON_BRIEF.md` records the agreed product scope and demo path.
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

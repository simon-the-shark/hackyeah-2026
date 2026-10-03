# HarmonyOS App Troubleshooting (CLI-first)

Build, install, launch, logs, and UI actions go through **`devecocli`**. Common cases:

## Build

### `devecocli build` fails before compiling (toolchain not found)
- **Cause:** Node.js/npm, DevEco CLI, or a DevEco Studio toolchain component is unavailable.
- **Fix:** verify `devecocli -V`, then check that `hvigor`, `ohpm`, and `hdc` are available.
  For a hackathon installation, rerun the [installation prompt](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/INSTALLATION_PROMPT.md#install-deveco-cli) if the CLI is missing or has the wrong version.

### `devecocli build` fails with an ArkTS compile error
- **Cause:** a source error — ArkTS strict mode, a missing dependency, or native/CMake.
- **Fix:**
  1. Read the failing task in the stderr log (e.g. `CompileArkTS`, `BuildNativeWithCmake`).
   2. `devecocli check lint --format json <project-root>` catches ArkTS strict-mode violations early
     (see [`arkts-strict.md`](./arkts-strict.md)).
    3. Dependency change: edit `oh-package.json5`, then `devecocli build` — it runs
      `ohpm install` as part of the build.

### Signing or installation failure
- **Cause:** the project has no valid signing configuration or the target rejects the package.
- **Fix:** Configure signing through the supported project workflow, then run
  `devecocli run --skip-build --module <module> --device <serial>`.

### HDC reports `connect-key` or `Not match target founded`
- **Cause:** the HDC daemon sees the target but its connection-key session is stale, or
  the CLI output redacted the serial.
- **Fix:** if `devecocli device list --format json` shows a redacted serial such as
  `[IP_ADDRESS]:5555`, pass the displayed device name to `devecocli run`. Otherwise use
  the real serial returned by the HDC process, not a redacted address copied from output.
  Store it in `$serial`, then run
  `hdc kill -r`, `hdc tconn $serial`, `hdc list targets`, and
  `hdc -t $serial shell echo hdc-ready`. Retry `devecocli run --skip-build` only when
  the shell check succeeds.

## Device / Emulator

### `devecocli device list` returns no devices (first emulator run)
- **Cause:** on a fresh DevEco Studio install, no virtual device has been created yet, or one
  was created but its system image was never downloaded, or it was downloaded but the
  emulator was never started. None of this is something `devecocli` can do — it is a manual,
  GUI-only step in DevEco Studio's Device Manager, and the system image download can be
  several gigabytes, so it takes real time and only goes quickly if the
  [DevEco Studio region was already switched to CN](../../../FAQ.md#how-do-i-switch-the-deveco-studio-region-to-china-manually).
- **Fix:** treat this the same way as any other manual step handed to the user — do not loop
  on `devecocli device list` expecting it to change on its own.
  1. Ask the user to open DevEco Studio, go to **Device Manager**, create a virtual device
     (or select an existing one) matching the project's target device type and API level, and
     download its system image if it is not already downloaded.
  2. Ask the user to start that emulator and wait for it to fully boot.
  3. Only then rerun `devecocli device list`. If it is still empty, stop and report that device
     validation is blocked — do not guess at a device serial or fall back to raw `hdc` commands.

## SDK / API level

Read `compatibleSdkVersion` and `targetSdkVersion` in `build-profile.json5` and verify that
the corresponding SDK is installed in the DevEco Studio toolchain.

---

For the full inner-loop workflow (run, logs, UI) see the parent **`ohos-app-dev`** skill;
for system / persistent bundles, use the project's system-development workflow rather than this app inner loop.

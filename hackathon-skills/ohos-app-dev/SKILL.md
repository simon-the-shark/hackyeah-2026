---
name: ohos-app-dev
description: Develop, build, deploy, and validate ordinary sandboxed HarmonyOS applications on a connected device. Use for the inner dev loop on an existing project when its APIs and permissions are available to ordinary apps. If they may require `hos_system_app`, an elevated APL, ACL/provisioning, or a Full SDK system API, use `ohos-system-app-dev` for privilege preflight.
---

# OpenHarmony App Dev

Inner-loop skill for working on an **existing** OpenHarmony / HarmonyOS app. Every
toolchain and device action goes through the **`devecocli` CLI**. The CLI delegates to the
DevEco toolchain (`hvigor`, `ohpm`, `hdc`, and the HarmonyOS lint tools). Use only commands
documented by `devecocli help`; do not assume unsupported flags or subcommands.

For ArkUI source design and `.ets` implementation, consume the handoff from
`hmos-arkui-develop-skill`. For architecture and state-boundary decisions, consume
`hmos-arkui-mvvm-pattern`. For uncertain API signatures or API-level support, use
`hmos-arkts-knowledge-retriever`. For an explicit V1/V2 migration, consume the
recorded inventory and migration plan before verification. This skill remains the
canonical executor for lint, build, device, runtime, logs, and UI evidence.

## Efficiency Defaults

- Use the smallest inner loop that matches the Track. For a local or logic
  change, stop at lint/build; do not launch a device unless runtime behavior is
  in scope.
- For a UI Track, take one initial screenshot and one approved interaction pass.
  Do not repeat build/run/layout/screenshot after an unchanged successful pass.
- Prefer `devecocli build --modules <module> --build-mode debug` for module-scoped source
  changes, then `devecocli run --skip-build --device <serial> --module <module>`. Use
  `--hotreload-apply` only when the
  project has a valid `.hvigor` hot-reload file and the user path does not need
  a fresh install. File-level recompilation remains controlled by Hvigor's
  dependency graph; never promise that an arbitrary edit compiles in isolation.
- Never print an unfiltered `devecocli log` result. Capture it through
  `compact_command.py` or filter immediately with `rg "TypeError|JS_ERROR|Fatal|ERROR"`.
- Never pass raw `devecocli docs search` output into the conversation. Use
  `devecocli_docs_bridge.py`, which fixes `--format json --limit 3`, removes
  long fields, and marks short non-English snippets for local model translation.
  Do not discard a relevant Chinese result solely because its source language
  is Chinese.
- The bridge's `translation_queue` is intermediate input to the local model;
  only translated English `ready_context` may be reused as later context.
- Keep full command output in `artifacts/logs/`; show only the marker, exit code,
  first actionable error, and artifact path in the conversation.
- Use the `devecocli` installation and DevEco Studio toolchain resolved by the
  workflow environment. Do not overwrite the caller's PATH or mix executables
  from unrelated Node installations.

> **Prereqs:** Node.js and npm, `devecocli` installed by the hackathon setup and on PATH,
> and an available DevEco Studio toolchain (`hvigor`, `ohpm`, `hdc`, etc.). Check with
> `devecocli -V`.

### Windows toolchain selection

Require the caller's `PATH` to put the DevEco Studio Node directory first, followed by
the npm global bin directory and DevEco toolchain directories. Do not hard-code, probe,
or modify installation paths in this skill. Verify the resolved tools:

```powershell
Get-Command node, npm, devecocli
node --version; npm --version; devecocli -V
```

Do not mix executables from different Node installations. If the resolved tools are not
the intended DevEco environment, stop and report the PATH issue.

## Verified CLI Reference

### Windows runner

Use `devecocli build` as the default build command. Do not invoke `hvigorw
assembleHap` directly unless the user explicitly requests lower-level Hvigor
diagnostics. Put the DevEco Studio Node directory first on `PATH` before
invoking the CLI: `C:\Program Files\Huawei\DevEco Studio\tools\node`.

Run `devecocli build` with a bounded timeout. Treat a non-zero CLI exit code or
`BUILD FAILED`, `ERROR`, or `Script Error` as an immediate build failure. On
timeout, record `DEVECOCLI_BUILD_TIMEOUT`; do not kill unrelated Node, Java, or
Hvigor processes.

After each build command, report `DEVECOCLI_BUILD_EXIT_CODE=<code>`. Build
completion requires exit code `0` and successful build output.


These commands and flags were verified against the installed `devecocli` CLI.
Do not repeatedly call `--help` for them. Run help only when the CLI version
changes or a needed command/argument is not listed here.

| Purpose | Command |
| --- | --- |
| Version | `devecocli -V` |
| Lint | `devecocli check lint --format json <project-root>` |
| Build | `devecocli build` |
| Devices | `devecocli device list --format json` (use the device name if the serial is redacted) |
| Device details | `devecocli device view` |
| Install and launch | `devecocli run --skip-build --module <module> --device <serial>` |
| UI layout | `devecocli ui layout --device <device-name>` |
| UI screenshot | `devecocli ui screenshot --device <device-name> --path <directory|png> [--display <id>]` |
| UI click | `devecocli ui click --device <device-name> <x> <y>` |
| UI text | `devecocli ui text --device <device-name> <text> [x] [y]` |
| Logs | `devecocli log` |

If `devecocli check lint` or `devecocli build` returns a Windows `spawn EINVAL`,
record the DevEco CLI/toolchain blocker and stop that verification step.

For `devecocli ui text`, whitespace-containing input may be rejected by some
CLI versions; use a single token or explicit coordinates and record the issue in
`conductor/learning.md`. Do not switch to raw `hdc` without confirmation.

## When to use

Trigger on: "build the app", "deploy / run it on device", "lint these files", "grab the
logs", "take a screenshot", "tap this button", "why is it crashing on launch", or a
verification request from a Conductor Track. Project scaffolding, standalone system-app
privilege/signing work, and system-bundle development are outside this skill's scope.

## Directives

1. **CLI-first.** Use `devecocli` for build, install, launch, lint, logs, and UI operations.
    Use the verified CLI references above instead of repeatedly
   probing `--help`.
2. **Lint timing.** For non-UI changes or an explicit lint request, run `devecocli check lint --format json`
   after editing and resolve errors; use its automatic-fix option only after reviewing the
   proposed changes. For UI changes executed under Conductor, the first post-implementation
   action is the build-to-device checkpoint; run lint after the user approves the current UI and
   before final verification or commit.
   Resolve errors; justify warnings. If lint or build fails, update the project's
   `conductor/learning.md` before retrying and display the updated Lessons Learned.
    If the project is not Conductor-managed, use `artifacts/logs/learning.md` as
    the fallback log; create it with a `# Learning Log` heading when needed.
     A non-zero exit or explicit `BUILD FAILED` result ends the current command
     and the current verification step. Capture the first actionable cause,
     update and display the learning log, then return a concise failure report.
     Do not wait after the launcher has exited, continue to device/UI validation,
     or retry implicitly. A retry requires a separately announced recovery step
     and must not happen for a missing launcher or command-not-found error.
      3. **Build completion is a two-part check.** A build is successful only when the
      DevEco build result is successful and `devecocli` returns exit code `0`. Always
      print or capture `DEVECOCLI_BUILD_EXIT_CODE=<code>` after the command. If the exit code is non-zero, the build
    is failed and the workflow must return the failure immediately. Do not start device
    validation while the command is still running after the success marker. A persistent
    Hvigor daemon alone is normal.
  4. **Build-to-device gate.** After a successful build, always run `devecocli device list`
      before deployment. `devecocli run` accepts a device serial or name. If the serial contains
      `[IP_ADDRESS]` or another redaction placeholder, use the displayed device name instead.
      If no device is listed, do not stop at a generic "blocked" report: this is commonly a
      first-time-emulator issue (no virtual device created yet, or its system image was never
      downloaded) rather than a CLI problem — see
      [`references/troubleshooting.md`](./references/troubleshooting.md#device--emulator) and
      hand the Device Manager steps to the user as an explicit manual step, then wait. If
      multiple devices are listed, ask the user to select one and never
     silently choose one. A `Connected` row is only discovery evidence, not an install
     readiness check. Keep the real serial in a shell variable instead of copying a
     redacted address from displayed output:
     `$serial = (hdc list targets | Where-Object { $_ -match ':\\d+$' } | Select-Object -First 1).Trim()`.
     Run `hdc -t $serial shell echo hdc-ready`. If that command fails, run `hdc kill -r`,
     `hdc tconn $serial`, and the shell check again. Stop if the shell check still fails;
     do not attempt install or launch.
5. **No destructive device operations without confirmation.** Treat uninstalling apps,
   modifying device data, and deleting emulators as destructive.
6. **UI inspection.** Use `devecocli ui layout` and `devecocli ui screenshot`. Use the
   documented `devecocli ui click`, `doubleclick`, `longclick`, `swipe`, `fling`, `dircfling`,
   and `drag` commands for interaction.
7. **Implementation handoff.** Before verification, read the changed files and any
    Conductor handoff/API-evidence artifacts. Confirm the target module, SDK/API level,
    state-management version, expected user paths, and known risks. Do not infer missing
    acceptance criteria from the source code.
8. **ArkUI diagnosis.** If lint/build fails on an ArkUI API, import, callback type, state
   decorator, rendering rule, or API-level issue, classify the first actionable error and
   use `hmos-arkts-knowledge-retriever` or the ArkUI references before proposing a fix.
    Do not mechanically replace `@ohos.*` with `@kit.*`; verify the current SDK and project
    convention first.
9. **State-management migration.** If the handoff declares a migration, read the
    migration inventory and target version before verification. Check for unresolved V1
    decorators, invalid V1/V2 mixing, incomplete parent/child event flow, missing V2
    initialization, and unsupported APIs. If the handoff does not declare a migration,
    do not suggest V1-to-V2 conversion as an incidental cleanup.

## Inner-loop workflow

For a UI track running under Conductor:

1. **Edit** sources after the written work plan is approved.
  2. **Build** — `devecocli build`. Treat the build as complete only after the
      command exit check and successful build output.
   On failure, stop, capture the failing phase and first actionable error, update
   the applicable learning log, display the lesson, fix the cause, then rerun the failed
   build-to-device checkpoint.
  3. **Device gate** — run `devecocli device list` after build success. Stop if there
    is no target; resolve multiple targets explicitly and select the target serial.
  4. **Install and launch** — `devecocli run --skip-build --module <module> --device <serial>`.
   If HDC reports `connect-key` or `Not match target founded`, run `hdc kill -r`,
    reconnect with `hdc tconn $serial`, verify `hdc list targets`, then rerun the shell
    readiness check. Retry deployment only after the shell check passes.
5. **Observe and pause** — capture the first screenshot, then use the interactive `question`
   tool to ask for UI approval and automated interaction consent. Record interaction consent
   immediately with `record_test_consent.py`, before lint or any tap/type action. If the UI is
   rejected, return to Edit and repeat steps 2-5. If the question tool cannot render, use a
   Markdown table only after the tool call fails or is dismissed.
  6. **Lint after UI approval** — `devecocli check lint --format json <project-root>`.
7. **Regression observe**
   - **Logs:** `devecocli log` for HiLog output or crash logs.
   - **Screenshot:** `devecocli ui screenshot`.
   - **Layout:** `devecocli ui layout`.
   - **Drive:** use the `devecocli ui` interaction commands listed above.
   - **Record:** report each planned user path as pass, fail, or blocked and attach its
     screenshot/log evidence. A successful launch alone is not UI-path validation.
   - **Migration paths:** when applicable, report simple state updates, nested-object
     updates, parent/child communication, list mutations, persistence restore, and
     animation behavior separately.

## Recipes

### Quick rebuild & reinstall
`devecocli check lint --format json <project-root>` → `devecocli build` plus exit-code verification →
`devecocli device list` → `devecocli run --skip-build` → `devecocli log`.

### Windows build-process verification
Run `devecocli build` and report `DEVECOCLI_BUILD_EXIT_CODE=0` together
with successful build output. Never report the Track complete from an
exit code alone.

### Diagnose a runtime crash
`devecocli build` → `devecocli run --skip-build` to reproduce →
`devecocli log` to inspect HiLog and crash output.

### UI validation against a design
`devecocli ui layout --device <device-name>` → `devecocli ui screenshot --device <device-name>
--path artifacts/snapshots/<task_id>.png` → read & compare. Read `build-profile.json5`
for the target API level (table below) — some components render differently across levels.

### UI validation against acceptance paths

For each UI Track, obtain the initial state, actions, expected result, and evidence path
from the implementation handoff. Execute the smallest meaningful regression path after
launch. Include empty, loading, error, and persistence states when they are in scope.

For a non-UI track, use the shorter sequence: Edit -> Lint -> Build -> Device gate when
applicable -> Run/Tests -> Logs.

### API or ArkUI diagnostic failure

When a compiler or lint failure concerns an API or ArkUI rule:

1. Stop at the first actionable error.
2. Check the local ArkUI references.
3. Call `hmos-arkts-knowledge-retriever` if the signature, import, or version is unclear.
4. Record the evidence and first fix attempt in the applicable learning log.
5. Let the implementation skill apply the source change, then rerun this skill's gates.

### State-management migration validation

For a V1/V2 migration, use the migration matrix to drive verification. At minimum,
check decorator coverage, state refresh, parent-to-child updates, child-to-parent events,
list insert/delete/update behavior, application-level state, and persistence after
relaunch when those capabilities are in scope. A successful compile does not prove
semantic equivalence.

### Dependency change
Edit `oh-package.json5` → `devecocli build` (run `ohpm install` when needed).

### Common raw-device ops (no dedicated command)
- List targets: `hdc list targets -v`
- For operations not exposed by DevEco CLI, ask for confirmation before using the underlying
  DevEco toolchain command. Do not invent an equivalent `devecocli` subcommand.

## SDK / API level reference

Read `build-profile.json5` for `compatibleSdkVersion` / `targetSdkVersion`.

## Out of scope

- Scaffolding or templating a fresh project.
- System/persistent bundle development and OHOS source-tree builds.
- Product discovery, Track planning, and architecture decisions owned by Conductor or
  the architecture specialist.

## References

App-engineering knowledge for ArkTS / ArkUI work — this skill is the canonical home; the
other skills point here rather than restating it:
- [`references/arkts-strict.md`](./references/arkts-strict.md) — ArkTS strict-mode rules the
  compiler / `devecocli check lint --format json` enforce.
- [`references/architecture.md`](./references/architecture.md) — Clean-Architecture layering
  for ArkTS apps (Domain / Data / Presentation).
- [`references/troubleshooting.md`](./references/troubleshooting.md) — common `devecocli`
  build / SDK failures and fixes.
- [`references/arkui-validation.md`](./references/arkui-validation.md) — ArkUI handoff,
  diagnostic routing, and UI-path verification guidance.
- [`references/state-migration-validation.md`](./references/state-migration-validation.md) —
  V1/V2 migration preflight and behavioral regression matrix.

# Conductor Execution Policy

Read this file only when selecting a Track profile or verification set.

## Profiles

- `quick`: low-risk local changes with no device, persistence, network,
  security, or architecture signal.
- `lean`: default for hackathon work and low-risk changes.
- `strict`: regulated, safety-critical, security-sensitive, high-risk, or
  explicitly requested work.

`workflow_profile` controls ceremony depth; `execution_profile` controls risk
verification. Use `standard` for normal UI work and `strict` for submission or
high-risk work. `quick` never applies to device-dependent Tracks.

Record `risk_level`, `execution_profile`, `track_kind`, and `ui_impact` in
`SESSION_STATE.json` and the Track plan.

## Risk and UI Impact

- `low`: wording, isolated styling, local logic, or documentation with no
  persistence, navigation, device capability, packaging, or public API change.
- `medium`: page interaction, multiple UI states, uncertain APIs, or component
  boundary changes.
- `high`: persistence, networking, shared state, navigation architecture,
  security, device capability, signing, or V1/V2 migration.
- `none`: no user-visible UI effect; no screenshot needed.
- `visual`: layout, style, copy, or visual state; one screenshot approval when
  the user needs visual confirmation.
- `interaction`: user path or state transition; exercise the affected path and
  capture UI evidence.
- `runtime`: behavior that depends on device/runtime state; use the complete
  device pass.

For `visual`, `interaction`, and `runtime` impact, set
`ui_checkpoint.status` to `pending` before validation and `accepted` only with
the source revision, snapshot path, and user decision. `none` uses
`ui_checkpoint.status: not_required`.

## Verification

1. During implementation, run focused compile/checks for the changed module or
   user path.
2. At the boundary of an application-changing phase, ensure one complete
   build/sign/device pass exists. Reuse a successful unchanged UI checkpoint;
   otherwise run the boundary pass.
3. Repeat the complete pass only after failure, source change, packaging or
   signing change, or possible runtime/device impact.
4. Documentation-only, planning-only, and non-runtime phases do not need the
   complete pass.
5. `lean` uses focused checks and the boundary pass. `strict` adds changed-file
   lint, focused tests, API evidence, and relevant regression/device checks.
6. Missing signing configuration is recorded as `signing: not_configured`.
   Missing required devices keep the phase blocked.

## Command and Output Budgets

- `quick`: 40,000 token working budget; scoped discovery, one focused check,
  and no full device pass unless explicitly requested.
- `standard`: 80,000 token working budget; one scoped discovery, one build pass,
  and one runtime pass when device behavior is in scope.
- `strict`: 140,000 token working budget; retain complete evidence but show only
  compact command output in the conversation.
- L0: short reads, path checks, and cached lookups; no live status message.
- L1: normal checks; batch their result into the next milestone update.
- L2: compile/lint; report once before and after the command.
- L3: build/device/emulator commands; report phase, result, exit state, and next
  action before and after the command.
- Show only the first actionable failure and new learning entry. Do not print a
  complete learning log, command transcript, or handover history by default.
- Success status may be one line. Expand status only for failure, timeout,
  blocker, or user approval.
- A timeout is never success. Treat it as wrapper-exit-unconfirmed until a
  separately authorized retry captures both the success marker and exit code.
- Never use an unscoped `**/*` repository listing. Start with the target module
  and root configuration files.
- Filter noisy diagnostics with `compact_command.py` or targeted `rg` patterns;
  preserve full output only in artifact logs.
- `--execution` validates recorded context reuse, `--phase-boundary` selects
  the complete pass, and `--post-verification` proves the actual lint result
  and boundary result were recorded. These are separate checkpoints.

## Approval Gates

- Product confirmation is never skipped by `lean`: an app name or category is
  not enough to define the product. The user must confirm the problem, primary
  user, intended outcome, and any assumptions used to proceed.
- Low + lean: keep product confirmation and Work Plan Approval separate. The
  recommendation text may be concise, but source editing still requires an
  explicit Work Plan Approval.
- Strict or medium/high risk: keep recommendation and Work Plan approval as
  separate decisions.
- A successful UI approval checkpoint satisfies the boundary pass for the same
  unchanged UI state.
- For `low + lean`, use concise recommendation text followed by a separate
  Work Plan Approval request. Do not print duplicate copies of the plan.
- For `quick`, combine the brief and Work Plan Approval in one bounded question.
  The quick confirmation only needs problem, desired outcome, MVP, and
  acceptance criteria; it must not trigger full Track creation.

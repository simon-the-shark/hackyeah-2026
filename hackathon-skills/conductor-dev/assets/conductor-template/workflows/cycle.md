---
description: Concise Conductor cycle from TASKS.md
---

1. **Product Gate**
   - Read `bootstrap.md` first when it exists; read `product.md` only if the
     direction or brief is incomplete.
   - Clear direction requires a problem/opportunity, primary user, and intended
     outcome; ask only missing brief questions after those are present.
   - An app name or category such as "create a Todo app" is vague. Run bounded
     discovery or ask focused questions, present choices, and wait for the
     user's explicit choice or custom definition before creating a Track.
    - Use the interactive `question` tool for discrete choices so the client
      renders an option bar. This is mandatory when the tool is available. If
      unavailable or dismissed, use a Markdown table with stable option IDs,
      short trade-offs, then wait; never silently choose.
   - Never invent the audience, MVP, visual direction, non-goals, platform
     capability, or acceptance criteria. Set `product_status` only after the
     user confirms the brief or explicitly accepts stated assumptions.
    - Before creating a Track, confirm all brief fields: problem, user, outcome,
      core flow, MVP, non-goals, device, data behavior, visual direction, and
      acceptance criteria. Direction selection alone is not confirmation.
    - Select `workflow_profile` before planning: `quick` for low-risk local work,
      `standard` for normal UI work, and `strict` for device, persistence,
      networking, signing, or submission work.
    - Run `workflow_plan.py --record` once. For `quick`, use `quick_complete.py` after
      focused verification instead of opening the full phase chain.
    - Record product and Work Plan decisions with `record_question_gate.py`;
      plain text choices do not satisfy the execution gate.

2. **Initialization**
   - Load `SESSION_STATE.json`, the active task, and the Track plan.
   - Record `risk_level`, `execution_profile`, `track_kind`, and `ui_impact`.
   - Load only the specialists selected by the Track complexity.
   - Record `required_skills` and reuse them for the Track; do not reload optional specialists without a new implementation need.
   - Use `initialize_state.py` to write risk/profile/kind/UI impact. Do not
     hand-write an invalid profile combination.
   - Do not run script `--help` during normal flow; use the documented command
     form and inspect help only after an invocation error.
   - Pass `--risk-signal persistence` for Preferences/local storage and
     `--risk-signal device` for device-dependent behavior; these signals require
     strict execution.
    - After each Skill load, record it in `loaded_skills`; record cited API or
      language sources in `api_evidence_sources`.
    - In `quick`, load only the implementation Skill required by the changed
      files; load retriever or device Skills only when actually needed.

3. **Strategy and Approval**
   - Define smallest useful increment, files, architecture decisions, risks,
     acceptance criteria, non-goals, and verification.
    - Keep Work Plan Approval as a separate explicit confirmation for every
      profile. Lean may shorten the plan text, but may not skip this gate.
    - In `quick`, combine product confirmation and Work Plan Approval in one
      bounded question and keep the plan to files, behavior, and one check.

4. **Implementation**
    - At execution start, run `context_cache.py`; if it returns
      `RELOAD_CONTEXT`, read the files, run it again with `--record`, then run
      `verification_gate.py --execution`.
    - Run `change_impact.py` before reading broad context. Read only changed
      files, affected module configuration, and one directly referenced API
      source. If the result is `REUSE_CONTEXT`, do not reread unchanged files.
   - After `GATE_PASS`, run `authorize_execution.py` with the current source
     revision. Do not edit application source before `EXECUTION_AUTHORIZED`.
   - Run focused compile/checks while implementing.
   - Record `phase_requires_boundary_pass` and the intended verification result.
   - Do not edit application source unless `work_plan_status` is `approved`.
   - Before execution, run the state validator; missing required Skill records
     or required API evidence block the phase. For ArkUI Tracks, complete one
     focused local API retrieval before implementation and record its topic,
     SDK, query fingerprint, and source. For non-trivial capabilities, verify
     both behavior and the implementation signature (import, type, method,
     parameters, return value, and SDK/API level). The query must cover the
     page's key uncertain or version-sensitive UI/state/layout needs; unrelated
     evidence alone does not satisfy the gate.
     Interactive ArkUI Tracks must record the three focused evidence scopes:
     `components`, `state`, and `signatures`.
   - For UI impact, follow the UI checkpoint only at the required impact level.
   - Record `ui_checkpoint.source_revision` and snapshot after user approval.
    - Immediately after install/launch and the initial screenshot, use the
      interactive `question` tool to ask whether automated device interactions
      are approved. Record the answer before lint or any click, typing, filter,
      or delete action. Do not interact before an `approved` decision.
   - Compare the foreground layout with the source revision and record
     `matched` or `blocked` using `record_runtime_evidence.py`; do not run CRUD
     interactions while runtime evidence is blocked.
   - Before any screenshot, run `prepare_artifacts.py` and use only
     `artifacts/snapshots/<task-id>.png`; never fall back to the project root.

5. **Boundary Verification**
   - Run `verification_gate.py --phase-boundary` once before the boundary
     commands. It must return `GATE_PASS`; use its cache decisions rather than
     repeating unchanged work.
   - The gate marks the boundary `gate_passed`; after actual build/sign/device
     evidence, set it to `passed` before post-verification.
   - Ensure one complete build/sign/device pass exists for an
     application-changing phase.
   - Run long commands through `compact_command.py`; retain full output in
     `artifacts/logs/` and use only its compact result in the conversation.
   - Reuse a successful unchanged UI checkpoint; otherwise run the boundary
     pass.
    - Use `lint_cache.py` before lint and pass the project root to
      `devecocli check lint --format json`; a zero-file result is not a source
      validation pass unless the project genuinely has no lintable files.
   - Use `context_cache.py` and `evidence_cache.py` before rereading context or repeating API retrieval.
   - Record the cache command result in the phase log. Do not claim a cache
     optimization was applied without an actual `REUSE_*`, `SKIP_*`, or
     `FETCH_*` result.
   - Repeat only after failure, source/package/signing change, or runtime/device
     impact.
   - After actual lint/build/device results are recorded, run
      `verification_gate.py --post-verification`; it must confirm a matching
      lint result and passed boundary before synchronization.
   - Record the actual boundary result with `record_boundary.py`; manual edits
     to `verification_boundary.status=passed` are invalid.
    - If a command times out, mark it `wrapper-exit-unconfirmed`, stop the
      current verification step, run `record_failure.py` before retry, and do
      not infer success from a later command's internal build.
    - Do not rerun build, run, screenshot, or layout after a successful
      unchanged checkpoint. Repeat only after source, packaging, signing,
      runtime, or device-impacting changes.
    - Use `incremental_verify.py` for application changes. It builds the
      affected module and uses `devecocli run --skip-build`; it does not claim
      file-only compilation when the toolchain dependency graph requires a
      module build.
   - After a structural ArkUI/ArkTS compile failure or more than one syntax
     error, reread the complete target file and replace it coherently; do not
     append fragments or duplicate components, roots, or properties.

  6. **Synchronization**
    - Update `SESSION_STATE.json` first with `state_update.py`.
    - Run `sync_phase.py` once to generate the summary and optionally mark the
      matching task. Set `next_action` with `state_update.py --next-action`
      before this step to avoid PowerShell quoting errors.
   - Run `validate_state.py`; an invalid state blocks the transition.
   - Run `bootstrap_summary.py` once to refresh `conductor/bootstrap.md`.
   - Run `sync_phase.py` only while `current_phase=synchronization` and
     `phase_status=in_progress`; it must complete the phase, write
     `synchronization_record`, set `track_status=verified`, and set
     `next_phase=handover` before handover.
    - Always pass the exact `--task-id`; when synchronizing TASKS, also pass
      `--tasks-file` when needed. Summary paths have safe defaults.
      Synchronization must update an existing checkbox
      idempotently and must not append a second completion line.
   - Keep a completed phase on `current_phase`; start `next_phase` in a separate
     update.

  7. **Handover**
    - Do not run script `--help` during normal handover. Use the fixed command
      signatures in `conductor-dev/SKILL.md`.
   - Run `verification_gate.py --handover` before the handover report. It must
     return `GATE_PASS` before setting `track_status: handed_over`.
   - Report status, boundary result, UI decision, blockers, deferred work, and
     artifact paths from the phase summary.
   - Do not print the full learning log, command transcript, or repeated history.
   - Before handover, run `clean_ai_workflow.py AI_WORKFLOW.md` and remove all
     unfinished template placeholders.
   - If the user already requested pause, record pause without opening another next-step question.
   - Ask for the next project action only after recording handover.
   - Complete handover explicitly: set `current_phase: handover`,
     `phase_status: in_progress`, then after the report set
     `phase_status: completed`, `last_completed_phase: handover`,
     `track_status: handed_over`, and `next_phase: null`.

8. **UI Regression Minimum**
    - For CRUD Tracks, validate add, complete, filter, and delete. Validate
      persistence only when the confirmed brief includes persistence; otherwise
      record `out_of_scope` instead of falsely reporting a pass.
   - Use `record_acceptance.py` for each path. If an out-of-plan file such as a
     bundle configuration must change, record and obtain approval with
     `record_scope_change.py` before editing it.

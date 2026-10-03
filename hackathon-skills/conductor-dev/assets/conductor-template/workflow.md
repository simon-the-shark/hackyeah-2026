# Project Workflow

This file is the project-facing summary. Detailed policy lives in the installed
`conductor-dev` references and is loaded only when needed.

For a continuing project, read `conductor/bootstrap.md` first. Use compact
command wrappers for build, lint, and device operations; retain full output in
`artifacts/logs/` and show only the one-line result.

## Lifecycle

1. Define the Track and record risk, profile, kind, and UI impact.
2. Record scope, acceptance criteria, non-goals, architecture decisions, and
   verification in the Track plan.
3. For `low + lean`, keep Work Plan Approval as a separate explicit
   confirmation; only shorten the recommendation and plan text. Keep separate
   recommendation and plan decisions for strict or higher-risk work.
4. Implement in phases using focused compile/checks.
5. For UI impact, use the build/install/launch/screenshot/user approval loop.
6. At an application-changing phase boundary, ensure one complete
   build/sign/device pass exists. Reuse a successful unchanged UI checkpoint.
7. Synchronize `SESSION_STATE.json` once, then run `sync_phase.py` to derive the
   phase summary and optionally update the matching task checkbox.
8. Run `validate_state.py` before handover. Handover only after verification and
   synchronization.

Use `state_update.py` for state changes and `bootstrap_summary.py` once at phase
sync. Do not patch `SESSION_STATE.json` by appending fields.

## Verification

Use `references/execution-policy.md`. Do not repeat a complete pass after short
diagnostics. Repeat it only after failure, source change, packaging/signing
change, or possible runtime/device impact. If no signing profile exists, record
`signing: not_configured`; an unavailable required device blocks completion.

Use `lint_cache.py` before lint. Skip an unchanged zero-file result until the
tool version, configuration fingerprint, or target fingerprint changes.
Use `context_cache.py` before rereading phase files and `evidence_cache.py` before
repeating an API search. Cache hits are not new verification work.

## Learning and Communication

Record only consequential failures and reusable tool limitations. Show only new
learning entries. Send updates at implementation, compile, device validation,
phase transition, synchronization, and around long-running commands. Batch
short reads and checks.

## State

- `SESSION_STATE.json` is the operational source of truth.
- `TASKS.md` is the backlog and acceptance list.
- The Track plan contains scope and decisions.
- The phase summary contains the final phase result.
- `learning.md` contains consequential lessons and known limitations.
- `AI_WORKFLOW.md` is updated with new tools or decisions at phase sync, not by
  repeating unchanged tool descriptions every task.

When a phase is complete, keep `current_phase` on it, set
`last_completed_phase` to it, and set `next_phase` only as an intention. Start
the next phase with a separate `in_progress` update. A completed phase is not a
completed Track.

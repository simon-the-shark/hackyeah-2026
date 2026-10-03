# Conductor State and Synchronization

Load `execution-policy.md` for risk and verification, and `context-policy.md`
for context and specialist loading. This file defines ownership only.

## State Ownership

- `SESSION_STATE.json`: one operational source of truth, including phase,
  Track, profile, UI impact, verification boundary, caches, blockers, and next
  action.
- `TASKS.md`: backlog and acceptance checkboxes only.
- Track plan: scope, architecture, decisions, and non-goals.
- Phase summary: generated once by `sync_phase.py`.
- `learning.md`: consequential lessons and reusable tool limitations only.

## Synchronization

1. Update `SESSION_STATE.json`.
2. Run `sync_phase.py` once to generate the phase summary and optionally mark a
   matching task.
3. Run `validate_state.py`.
4. Update only secondary artifacts required by acceptance criteria.

Do not copy the same completion narrative into multiple files. A completed
phase keeps `current_phase` and `last_completed_phase` on that phase; starting
`next_phase` requires a separate state update. Handover requires completed
verification and synchronization.

## Safety

Tasks must respect product constraints and public-safety rules. The user remains
the final approver for scope, UI, and handover.

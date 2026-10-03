# Conductor Context Policy

Read only the context needed for the current phase. Do not reread the full
Conductor Skill, all workflow files, or all specialist skills at every phase.

## Default Context Set

Choose the smallest context set that satisfies the workflow profile. `quick`
loads the target file and the one relevant configuration file; `standard` adds
the active Track and selected specialist; `strict` adds the full verification
state and evidence artifacts.

- Initialization: `SESSION_STATE.json`, `TASKS.md` if present, and the active
  Track plan.
- Product discovery: `product.md` and only the project files needed to answer
  the unresolved product question.
- Strategy: active Track plan, relevant architecture reference, and selected
  specialist delegation.
- Execution: active Track plan, changed files, and the selected implementation
  skill.
- Verification: `SESSION_STATE.json`, boundary result, and `ohos-app-dev`.
- Synchronization: `SESSION_STATE.json`, `sync_phase.py`, and the single phase
  summary.
- Handover: phase summary and `SESSION_STATE.json`; do not reread the full
  history.

Record a `context_fingerprint` and `loaded_context` list in session state when
the session is long-lived. If the fingerprint is unchanged, reuse the context.
Reload only after a phase change, relevant file change, tool/version change, or
user request.

Run `context_cache.py` with the phase and file list before rereading a phase
context, then repeat it with `--record` after loading that context. The script
returns exit code `10` for `REUSE_CONTEXT`.

## Specialist Loading

Select `required_skills` in the Track plan before loading specialists:

- L1 UI: ArkUI implementation + `ohos-app-dev`.
- L2 UI: L1 plus ArkTS retrieval only for uncertain APIs.
- L3 architecture: MVVM, ArkUI, ArkTS retrieval, and `ohos-app-dev`.
- V1/V2 migration: migration skill only for an explicit migration Track.

Do not inspect or load optional specialists until the Track requires them.
For `quick`, use ArkUI implementation alone for known components and run the
retriever only when the API signature or ArkTS restriction is uncertain.
After each Skill load, run `record_skill_usage.py` with `--skill`. Before
execution, the validator requires `required_skills` to be a subset of
`loaded_skills`.

## Evidence Cache

Cache API evidence by API/topic, SDK version, and query fingerprint in
`SESSION_STATE.json`. Reuse the cited document and section within the Track.
Show at most three search results, then read only the selected result.
Use `evidence_cache.py` before searching and record the selected document,
section, source kind, and one-line summary after retrieval. Its cache hit exits
with `10` and prints `USE_CACHED_EVIDENCE`.
Use `devecocli_docs_bridge.py` for both search and read. Never pass raw
`devecocli docs read` output into the model context; only translated English
`ready_context` is reusable context.
For non-trivial APIs, the evidence summary must cover both behavior and the
implementation signature: module/import, type, method, parameters, return
value, and SDK/API level. Do not treat a related but different topic as proof
of the call site.
For interactive ArkUI Tracks, record three focused scopes: `components`,
`state`, and `signatures`. This catches missing V1 state or callback-signature
research without requiring every basic UI primitive to be inventoried.
Append the cited source path or document ID to `api_evidence_sources`; an ArkTS
retrieval Track cannot enter execution without one.

## Product Questions

- Clear direction requires a problem or opportunity, primary user, and intended
  outcome. Only then skip opportunity cards and ask missing brief questions.
- An app name, category, feature fragment, or desired output alone is vague.
  Use bounded discovery with at most 3-5 opportunity cards and 1-6 questions
  per round, and wait for the user's explicit choice or custom definition.
- For discrete choices, use the interactive `question` tool so the client can
  render selectable options. If it is unavailable or dismissed, use a Markdown
  table with stable option IDs, short trade-offs, and an explicit selection
  request, then wait; do not silently choose a default.
- In `quick`, ask one bounded confirmation containing the missing brief fields
  and the minimal work plan instead of opening separate discovery and strategy
  rounds. Require only problem, desired outcome, MVP, and acceptance criteria;
  collect the full brief for standard and strict work.
- Always render bounded choices with the interactive `question` tool when it is
  available. A textual list is not an equivalent fallback unless the tool call
  failed or was dismissed.

## Architecture Routing

- Do not load MVVM for a one-state, one-page Quick Track.
- For Standard UI Tracks with three or more stateful interactions,
  persistence, multiple pages, shared state, or explicit architecture concerns,
  load `hmos-arkui-mvvm-pattern` before ArkUI implementation.
- Strict UI Tracks with persistence, multiple state owners, or multi-page flow
  require the MVVM review unless the Track records a reasoned exception.
- Never silently fill product audience, problem, MVP, visual direction,
  non-goals, platform capability, or acceptance criteria.
- Before Track creation, the confirmed brief must also contain core flow,
  target device, data behavior, and explicit non-goals. Product direction
  selection is not product brief confirmation.
- Low + lean: keep Work Plan Approval explicit; only shorten the recommendation
  text and the plan presentation.
- Record `ui_checkpoint.source_revision` and `ui_checkpoint.snapshot` after UI
  approval. Reuse the approval while that source revision is unchanged.
- Record AI workflow entries with `ai_workflow.py` only when the tool, decision,
  failure, or validation evidence is new. Repeated skill/tool descriptions are
  skipped by fingerprint.

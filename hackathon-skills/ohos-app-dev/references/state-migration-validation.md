# State-Management Migration Validation

Use this reference only when a Conductor handoff declares an explicit V1/V2 migration.
Do not turn ordinary feature development into an incidental state-management migration.

## Preflight

Confirm from the migration handoff:

- current state-management version
- target state-management version
- migration inventory and batch
- accepted architecture decision, if any
- SDK/API level and API evidence
- rollback checkpoint
- regression matrix

Scan the affected module for both V1 and V2 indicators. Report mixed files and unresolved
decorators before running device validation.

## Batch Checks

For each batch, verify the relevant mappings rather than performing a text replacement:

- `@State` to `@Local` or `@Param @Once` according to initialization ownership
- `@Prop` to `@Param` with valid defaults or `@Require`
- `@Link` to `@Param` plus an explicit parent event path
- `@Observed`/`@ObjectLink` to `@ObservedV2`/`@Trace` for nested observation
- `@Provide`/`@Consume` to `@Provider`/`@Consumer` with matching aliases
- `@Watch` to `@Monitor`
- `ForEach`/`LazyForEach` to `Repeat` only when the target API and behavior require it
- application-level storage only after its lifecycle and persistence behavior are confirmed

Use `hmos-arkts-knowledge-retriever` when a mapping, import, or minimum API version is
unclear. Do not assume that a migration example is valid for every SDK. After source
changes, run the complete `ohos-app-dev` verification gates and use the active project's
build command as the final compiler authority.

## Regression Matrix

Record each applicable item as `pass`, `fail`, or `blocked`:

- local state mutation refreshes the UI
- nested object mutation refreshes the UI
- parent-to-child updates remain correct
- child-to-parent events update the source of truth
- provider/consumer state resolves the expected alias
- list insert, delete, update, and stable-key behavior remain correct
- application-level state has the expected scope
- persisted state restores after relaunch
- animation state changes still take effect

Compile success is necessary but not sufficient for migration completion.

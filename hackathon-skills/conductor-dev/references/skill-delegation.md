# Skill Delegation

Conductor coordinates specialist skills; it does not duplicate their implementation
knowledge or toolchain commands.

## Complexity Routing

### L1: Local UI Change

Examples: styling, spacing, one component property, or one simple event.

- Use `hmos-arkui-develop-skill` for the `.ets` change.
- Use `ohos-app-dev` for lint/build and UI validation when applicable.
- Do not invoke MVVM or API retrieval unless an API is genuinely uncertain.

### L2: Page Interaction

Examples: a page with a list, form, several UI states, or a non-trivial interaction.

- Use `hmos-arkui-develop-skill` for component and state implementation.
- Use `hmos-arkts-knowledge-retriever` for uncertain, version-sensitive, or complex ArkTS APIs.
- Use `ohos-app-dev` for the verification loop.
- Invoke `hmos-arkui-mvvm-pattern` when state ownership or component boundaries are unclear.

### L3: Architecture or Business State

Examples: persistence, networking, repositories, ViewModels, shared state, navigation
architecture, or a V1/V2 state-management migration.

- Invoke `hmos-arkui-mvvm-pattern` before changing structure or state ownership.
- Record and obtain acceptance for the architecture decision.
- Use `hmos-arkui-develop-skill` to implement the accepted `.ets` and project changes.
- Use `hmos-arkts-knowledge-retriever` for API, import, and SDK evidence.
- Use `ohos-app-dev` for lint, build, device, runtime, and UI verification.

### M1/M2/M3: State-Management Migration

Use this route only for an explicit V1-to-V2 request, confirmed V1/V2 mixing, or a
product requirement that has accepted V2 as a target. Ordinary feature work must keep
the project's current state-management version.

- Detect the current state-management version, inventory decorators and
  application-level state, and record a migration plan before source changes.
- For simultaneous architecture work, invoke `hmos-arkui-mvvm-pattern` only after the
  target state-management version is selected; its architecture must use the target
  version's decorators and data-flow rules.
- Use `hmos-arkts-knowledge-retriever` for version-sensitive V2 APIs, import paths,
  `Repeat`, application storage, persistence, and any migration example that conflicts
  with the active SDK.
- Use `hmos-arkui-develop-skill` for the actual source changes.
- Use `ohos-app-dev` after each migration batch for lint, build, device regression, and
  UI evidence.

Migration order should normally be: inventory and checkpoint, leaf components, data
objects, parent/child state flow, page state, application-level state, then navigation
or shared state. Do not perform a blind repository-wide search-and-replace.

## Handoff Contract

Before verification, the implementation phase records:

- `changedFiles`
- `targetModule`
- `targetSdkVersion` and `compatibleSdkVersion`
- `stateManagementVersion`
- `architectureDecision`
- `apiEvidencePath` when non-basic APIs are used
- `userPaths`
- `knownRisks`
- `migrationMode` (`none`, `planned`, or `active`)
- `currentStateManagementVersion`
- `targetStateManagementVersion`
- `migrationInventoryPath` when migrating
- `migrationRegressionMatrixPath` when migrating
- `rollbackCheckpoint`

The verification phase records:

- lint result and exit code
- build success marker and exit code
- selected device name
- install and launch result
- each user path result
- screenshot and log paths
- warnings and blockers

Recommended artifact locations:

```text
artifacts/logs/<track-id>-handoff.md
artifacts/logs/<track-id>-api-evidence.md
artifacts/logs/<track-id>-migration-inventory.md
artifacts/logs/<track-id>-migration-matrix.md
artifacts/snapshots/<task-id>.png
```

## Fallbacks

`hmos-arkui-scenario-development` is optional. If it is unavailable, use the local
ArkUI references and `hmos-arkts-knowledge-retriever` for uncertain APIs. If the retriever
is unavailable, report the missing evidence skill and use the project's documented official
platform references plus compile verification as the fallback. Never block a Track solely
because the optional scenario specialist is missing.

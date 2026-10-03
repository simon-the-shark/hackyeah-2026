# ArkUI Validation

This reference defines the boundary between ArkUI implementation and the app inner loop.

## Before Verification

Read the implementation handoff when available and confirm:

- changed `.ets` files and target module
- `targetSdkVersion` and `compatibleSdkVersion`
- V1 or V2 state-management choice
- accepted architecture decision
- API evidence for non-basic or version-sensitive APIs
- expected user paths and known risks

If the handoff is missing, inspect the project context and report the missing acceptance
information instead of inventing it.

## Fast ArkUI Checks

Use the implementation skill's detailed rules for fixes. During verification, check for
obvious regressions in:

- mixed V1/V2 decorators
- unstable `ForEach` keys
- invalid component nesting
- side effects or I/O in `build()`
- incorrect UIContext usage
- missing empty, loading, or error states when in scope
- import paths that do not match the current SDK or project convention

These checks supplement, but do not replace, lint, build, and device validation.

## API Failure Routing

For an API/import/signature/version failure:

1. Capture the first actionable diagnostic.
2. Check the local ArkUI quick references.
3. Use `hmos-arkts-knowledge-retriever` when evidence is missing or conflicting.
4. Record the selected import, API level, and source in API evidence.
5. Return the source fix to `hmos-arkui-develop-skill`.

`@kit.*` is not a universal replacement rule. `@ohos.*` must not be mechanically
rewritten without checking the active SDK, API level, official documentation, and the
project's existing convention.

## UI Evidence

Record every planned path as one of:

- `pass`: observed expected behavior
- `fail`: observed incorrect behavior
- `blocked`: prerequisite unavailable, such as no device

Attach screenshots for UI changes and logs for runtime failures. A build or launch pass
does not prove that the user path passed.

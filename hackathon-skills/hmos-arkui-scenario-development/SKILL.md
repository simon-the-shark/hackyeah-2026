---
name: hmos-arkui-scenario-development
description: >-
  HarmonyOS/ArkUI scenario-based development skill for implementing,
  troubleshooting, and validating ArkUI (.ets) features. It routes requests
  through four phases (REQ, DEV, FIX, VAL) and four primary scenes: ARKUI-01
  ArkUI basic syntax; ARKUI-02 UI framework and page logic; ARKUI-03 state
  management; and ARKUI-04 compilation and runtime. It does not cover native
  development unrelated to ArkUI, non-HarmonyOS platforms, or CI/CD.
metadata:
  version: 1.0.0
  keywords:
    - ArkUI
    - HarmonyOS
    - ArkTS
    - .ets
    - declarative UI
    - scenario development
    - REQ
    - DEV
    - FIX
    - VAL
    - conditional rendering
    - V1 state management
    - V2 state management
    - component state synchronization
    - '@State'
    - '@Link'
    - '@Local'
    - '@Param'
    - '@Monitor'
    - '@Watch'
    - V1/V2 mixing
    - visibility switching
    - expand and collapse
    - custom component
    - '@Builder'
    - '@BuilderParam'
    - AttributeModifier
    - '@Reusable'
    - LazyForEach
    - Repeat
    - component reuse
    - gesture
    - gesture conflict
    - nested scrolling
    - drag
    - pinch zoom
    - PanGesture
    - PinchGesture
    - responseRegion
    - hitTestBehavior
    - state management
    - route navigation
    - page navigation
    - Navigation
    - NavDestination
    - route interception
    - split view
    - compilation error
    - build failure
    - runtime exception
    - crash
    - blank screen
    - ArkTS restriction
    - page construction
    - Column
    - Tabs
    - WaterFlow
    - dialog
    - bindSheet
    - CustomDialog
    - Toast
    - half-modal
    - animation
    - transition
    - animateTo
    - TransitionEffect
    - geometryTransition
    - shared-element animation
    - frame animation
    - focus
    - focus navigation
    - focusable
    - requestFocus
    - focusBox
    - nextFocus
    - responsive layout
    - breakpoint adaptation
    - FrameNode
    - DrawModifier
    - ContentModifier
    - BuilderNode
    - XComponent
    - custom drawing
    - advanced dialog
    - levelOrder
    - ComponentContent
    - layout selection
    - RelativeContainer
    - GridRow
    - image display
    - ImageAnimator
    - frame sequence
    - scroll list
    - waterfall layout
    - grouped sticky header
    - rich text
    - RichEditor
    - SymbolGlyph
---

# ArkUI Scenario Development

## Skill Definition

| Field | Content |
| --- | --- |
| `skill_id` | `arkui-scenario-development` |
| `skill_name` | `ArkUI Scenario Development` |
| `one_line_purpose` | Covers ArkUI basic syntax, UI framework logic, state management, compilation and runtime. Uses route documents for interaction, focus, navigation, page construction, V1/V2 state management, component synchronization, dialogs, menus, animation, custom components, layouts, images, lists, and text. |
| `not_in_scope` | Native development unrelated to ArkUI, non-HarmonyOS development, and CI/CD configuration. |
| `primary_outputs` | `primary_scene`, `implementation_notes`, `code_touchpoints`, `verification_matrix` |

## Core Constraints

- Handle only ArkUI / ArkTS `.ets` pages, components, interactions, state, navigation, dialogs, animation, layout, images, lists, text, compilation, and runtime tasks.
- Do not handle unrelated native system capabilities, back-end APIs, databases, CI/CD, release workflows, or non-HarmonyOS development. Classify requests limited to those areas as `not_in_scope`.
- When `ARKUI-02` or `ARKUI-03` is matched, read its route document and complete the secondary routing. If several secondary scenes match, record and read all of them.
- Before presenting a solution or code, provide the routing result, phase, matched scenes, and resource paths to be read. Do not skip routing and go directly to implementation.
- Base the solution or code on the matched resource documents, including their APIs, component structure, callbacks, lifecycle rules, and verification points. Explicitly state any uncovered boundary.

## Execution Steps

Every ArkUI request must follow these steps in order. Do not write code before completing them.

### Step 1: Determine the Route

Use the decision tree and output:

```yaml
active_phases: [REQ / DEV / FIX / VAL]
primary_phase: <primary phase>
primary_scene: <primary scene ID, such as ARKUI-02>
secondary_scenes: [<related scene IDs>]
route_reason: <brief routing reason>
next_scene_refs: [<primary and related resource paths>]
```

Rules:

- Include every `resource_refs` entry for `secondary_scenes` in `next_scene_refs`.
- Find primary scene resources from the scene index.
- Resolve `resource_ref`, `resource_refs`, and `resource_files` in secondary ROUTE documents.

### Step 2: Read All Scene References

Use the Read tool to read every file in `next_scene_refs`. Do not replace document-specific guidance with assumptions.

Read in this order:

1. Primary scene reference documents.
2. Related scene reference documents.
3. Cascaded route documents. If a reference is a ROUTE document, continue through its scene index until all leaf documents have been read.

Do not skip a referenced file, assume a file is empty from its name, or replace a documented API pattern with prior knowledge.

### Step 3: Confirm the Route

Before implementation, output:

```markdown
## Route Confirmation

**Routing result**:
- primary_phase: ...
- primary_scene: ...
- secondary_scenes: [...]

**Documents read**:
1. [file path] - [one-sentence summary]
2. [file path] - [one-sentence summary]

**Implementation points**:
- [API, pattern, or constraint extracted from the documents]
```

### Step 4: Implement

Implement according to the constraints, API usage, callbacks, lifecycle rules, and configuration formats in the scene documents.

- Use the documented API patterns; do not replace them with undocumented alternatives.
- When a document provides a complete code example, adapt that example instead of rewriting it from scratch.
- When several examples exist, choose the one that best matches the request.

## Phase Labels

| Label | Phase | Focus |
| --- | --- | --- |
| `REQ` | Requirements and design | Scene recognition, interaction design, state-management selection, animation selection, and page-flow design |
| `DEV` | Development | ArkUI implementation, component usage, state management, gesture handling, animation APIs, and route configuration |
| `FIX` | Troubleshooting | Compilation errors, runtime exceptions, failed animations, state desynchronization, navigation failures, and broken interactions |
| `VAL` | Functional validation | UI rendering, interaction events, state management, animation effects, and page-flow validation |

## Unified Output Fields

- `REQ`: `device_constraints`, `capability_boundary`, `acceptance_focus`
- `DEV`: `code_touchpoints`, `reuse_resources`, `implementation_notes`, `integration_risks`
- `FIX`: `problem_profile`, `root_cause_hypothesis`, `fix_plan`, `regression_watchlist`
- `VAL`: `verification_matrix`, `evidence_requirements`, `pass_criteria`, `residual_risks`

## Field Definitions

- `device_constraints`: Constraints caused by device type, screen size, system version, or similar environment differences.
- `capability_boundary`: The API versions, device types, and system states where the plan is valid, plus cases requiring fallback or extra handling.
- `acceptance_focus`: UI behavior, interaction behavior, and animation effects that must receive special attention during acceptance.
- The fields listed for a phase are required after the corresponding scene is matched. Output is determined by the phase, not separately by each scene.

## Scenario Decision Tree

### Step 1: Determine the Phase

Decide whether the user describes an existing implementation with an incorrect result.

- `FIX`: An existing implementation produces an error, crash, blank screen, failed animation, desynchronized state, failed navigation, unresponsive gesture, or missing dialog; the user explicitly requests troubleshooting or fixing; or the prompt includes an API/code sample and an abnormal result.
- `DEV`: The user describes a new feature without an existing abnormal result, using signals such as "implement", "development plan", or "build". A design constraint such as "must not be covered" is not the same as an existing obstruction.
- `REQ`: The user asks for requirements analysis, evaluation, or solution selection.

### Step 2: Match Primary Scenes

Match all primary scenes in parallel. Use `metadata.keywords`, each scene's `intent_signals`, the user's prompt, code, error, screenshot, and context.

- Strong signals such as API names, decorators, component names, and error symptoms take priority over generic words.
- Check `applies_when` for every candidate.
- Check `not_applies_when` and move excluded candidates to a more suitable scene or to `secondary_scenes`.
- A scene that matches only `intent_signals` but not `applies_when` cannot be `primary_scene`.
- `primary_scene` is the strongest scene satisfying the signals, applicability, and current phase.
- `secondary_scenes` capture dependencies, related behavior, troubleshooting prerequisites, and validation supplements. Multiple applicable scenes may be retained.

### Step 3: Apply Phase Decisions

Read the matching scene's `REQ`, `DEV`, `FIX`, or `VAL` decisions according to `primary_phase`:

- `REQ` clarifies scope and acceptance priorities.
- `DEV` determines the implementation path and code skeleton.
- `FIX` identifies diagnostic checkpoints and regression risks.
- `VAL` generates the validation matrix and evidence requirements.
- If the decisions do not fully cover the request, keep the matched scene and explicitly state the uncovered boundary.

### Step 4: Resolve Resources

Add every primary and secondary `resource_refs` entry to `next_scene_refs`. Expand every ROUTE reference through its own decision tree. If no scene matches, classify the request as `not_in_scope`; do not skip field-based routing and implement directly.

## Scene Index

### `ARKUI-01` ArkUI Basic Syntax

```yaml
scene_id: ARKUI-01
scene_name: ArkUI Basic Syntax
resource_refs:
  - ./references/arkui-basic/ROUTE.md
intent_signals:
  - declarative UI / conditional rendering / visibility switching / expand and collapse
  - custom components / @Component / @ComponentV2 / @Builder / @LocalBuilder / @BuilderParam
  - AttributeModifier / @Reusable / @ReusableV2 / LazyForEach / Repeat / virtualScroll / UI slots / style reuse / component reuse
applies_when:
  - The request concerns ArkUI's declarative paradigm, component definitions, build(), decorators, or basic syntax.
  - The request concerns if rendering, dynamic visibility, expand/collapse, or login-state switching.
  - The request concerns @Builder, @BuilderParam, @LocalBuilder, AttributeModifier, @Reusable, @ReusableV2, LazyForEach, Repeat, reuseId, or reuse.
not_applies_when:
  - The core request is page structure, layout, navigation, interaction, dialogs, animation, images, lists, or text (`ARKUI-02`).
  - The core request is state transfer, synchronization, observation, or V1/V2 mixing (`ARKUI-03`).
  - The core request is a compilation/runtime error, blank screen, crash, or SDK compatibility issue (`ARKUI-04`).
```

### `ARKUI-02` UI Framework and Page Logic

```yaml
scene_id: ARKUI-02
scene_name: UI Framework and Page Logic
resource_refs:
  - ./references/arkui-02-route.md
intent_signals:
  - gestures / keyboard / touch / stylus / focus / focusable / requestFocus / nextFocus / focus box
  - navigation / Navigation / Router / page stack / dialogs / menus / Toast / Popup / Sheet / Dialog / animation / transitions / animateTo / TransitionEffect / geometryTransition
  - Column / Row / Stack / Flex / RelativeContainer / GridRow / Tabs / List / Grid / WaterFlow / ArcList / Scroll / Swiper / page skeleton / responsive layout / breakpoints / FrameNode / Modifier / RenderNode / BuilderNode / XComponent / Image / ImageAnimator / Text / TextInput / RichEditor / SymbolGlyph
applies_when:
  - The request builds pages, flows, interactions, temporary interfaces, or animations using ArkUI components and framework capabilities.
  - The request handles navigation, gestures, focus, dialogs, menus, animation transitions, layouts, images, lists, text, custom nodes, or page skeletons.
not_applies_when:
  - The request only confirms basic syntax, conditional rendering, Builder, or basic reuse (`ARKUI-01`).
  - The main issue is state decorators, state synchronization, or V1/V2 mixing (`ARKUI-03`).
  - The main issue is compilation/runtime failure rather than UI logic (`ARKUI-04`).
```

### `ARKUI-03` State Management

```yaml
scene_id: ARKUI-03
scene_name: State Management
resource_refs:
  - ./references/arkui-03-route.md
intent_signals:
  - @State / @Prop / @Link / @Provide / @Consume / @Watch / @Track / @ObjectLink / @Observe
  - @Local / @Param / @Event / @Monitor / @Provider / @Consumer / @Computed / @ObservedV2 / @Trace
  - AppStorage / AppStorageV2 / state management / component synchronization / application state / V1/V2 mixing
applies_when:
  - The request passes or shares state between components.
  - The request uses V1 or V2 state management, state observation, computed state, two-way binding, state-driven animation, component reuse, freezing, or loop rendering.
  - The request explicitly concerns V1/V2 mixing or using V2 components with V1 components, or vice versa.
not_applies_when:
  - The request is only layout, navigation, interaction, dialogs, animation, focus, images, lists, or text (`ARKUI-02`).
  - The request is only basic syntax, Builder, conditional rendering, or basic reuse (`ARKUI-01`).
  - The issue is a compilation/runtime failure whose root cause is not yet tied to state management; start with `ARKUI-04`.
```

### `ARKUI-04` Compilation and Runtime

```yaml
scene_id: ARKUI-04
scene_name: Compilation and Runtime
resource_refs:
  - ./references/compilation-runtime-scenario-development.md
intent_signals:
  - compilation error / build failure / ArkTS type error / import / export / module path
  - runtime exception / blank screen / crash / abnormal lifecycle / resource-load failure
  - hvigor / oh-package.json5 / module.json5 / SDK compatibility / API compatibility
applies_when:
  - The request troubleshoots ArkTS compilation, build, dependency, module, or SDK/API compatibility problems.
  - The request troubleshoots runtime exceptions, blank screens, crashes, lifecycle issues, or resource loading failures.
  - The request checks whether an ArkUI pattern is constrained by language, compilation, runtime, or version rules.
not_applies_when:
  - The issue is explicitly a UI page, interaction, navigation, dialog, animation, focus, layout, image, list, or text implementation issue (`ARKUI-02`).
  - The issue is explicitly a state decorator, state synchronization, or V1/V2 mixing issue (`ARKUI-03`).
  - The request only asks about basic ArkUI syntax or reuse (`ARKUI-01`).
```

## Additional Guidance

- For detailed implementation decisions, continue into the matched scene's `decisions` section and reference documents.
- Do not mix V1 and V2 decorators in the same component without an explicit requirement and documented bridge strategy.
- When a root cause crosses scene boundaries, retain the original scene and add the related scene to `secondary_scenes`.
- Always report unresolved API/version boundaries instead of inventing unsupported code.

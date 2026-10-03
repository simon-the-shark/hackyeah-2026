# V2 MVVM Development Scenario and Solution

## Introduction

V2 uses `@ComponentV2`, `@Local`, `@Param`, `@Event`, `@ObservedV2`, `@Trace`, `@Computed`, `@Monitor`, `@Type`, `PersistenceV2`, and `Repeat` for data-driven updates, deep observation, persistence, and strict one-way data flow.

**Notes**
- This document applies only to V2 state management. Do not mix V1 decorators.
- If the project uses V1 state variables, see [mvvm-scenario-development_v1.md](./mvvm-scenario-development_v1.md).
- MVVM layering is independent of the state-management version.

## V2 MVVM Scenario: Todo Application

Model loads raw JSON, ViewModel manages state and business logic, and View renders the UI. `@Param` provides read-only data and `@Event` sends mutations upward. `PersistenceV2` restores state after restart, `@Computed` derives counts, and `Repeat` renders lists efficiently.

| MVVM layer | V2 decorators | Responsibility |
|---|---|---|
| View page | `@Entry` + `@ComponentV2` + `@Local` | Bind state and assemble the page |
| Business View | `@Param` + `@Event` | Read parent data and report actions |
| Shared View | None | Stateless presentation |
| ViewModel | `@ObservedV2` + `@Trace` | Deep observable state |
| Computed state | `@Computed` | Cached derived values |
| Monitor | `@Monitor` | Observe changes and old/new values |
| Persistence | `PersistenceV2.connect` | Restore state across restarts |
| Nested serialization | `@Type` | Serialize nested classes |
| List rendering | `Repeat` | Efficient component reuse |
| Model | Ordinary class | Raw data and data access |

**Scenario ID:** MVVM_SCENE_V2

**Complete assets:** `../assets/V2MVVM`

### Data Flow

1. Page connects to persisted state; empty state loads JSON through Model.
2. Parent passes ViewModel data with `@Param`; child reports actions with `@Event`.
3. ViewModel methods update `@Trace` properties and arrays.
4. `@Computed` recalculates derived counts and `Repeat` updates changed list items.

### View Responsibilities

Use `@Param` for read-only ViewModel references, `@Event` for mutations, and `@Local` for private input state. Keep all business operations in ViewModel methods. Use `@Builder` for reusable UI structures.

### Recommended Structure

```text
src/main/ets/
├── model/       # TaskModel.ets and TaskListModel.ets
├── pages/       # TodoListPage.ets
├── view/        # TitleView, ListView, and BottomView
└── viewmodel/   # TaskViewModel.ets and TaskListViewModel.ets
```

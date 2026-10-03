# V1 MVVM Development Scenario and Solution

## Introduction

In V1, MVVM uses `@Component`, `@State`, `@Prop`, `@Link`, `@ObjectLink`, `@Observed`, and `@Track` for View/ViewModel binding and data-driven updates.

**Notes**
- This document applies only to V1 state management. Use the V1 decorator set with `@Component`; do not mix V2 decorators.
- If the project uses V2 state variables, see [mvvm-scenario-development_V2.md](./mvvm-scenario-development_V2.md).
- MVVM layering is independent of the state-management version; V1 and V2 differ in observation and synchronization mechanisms.

## V1 MVVM Scenario: Todo Application

Separate Model, View, and ViewModel. Model provides raw data and loading, ViewModel manages page state and business logic, and View renders UI and handles interaction. View accesses Model only through ViewModel.

| MVVM layer | V1 decorators | Responsibility |
|---|---|---|
| View page | `@Entry` + `@State` | Bind ViewModel and assemble the page |
| Business View | `@Link` / `@ObjectLink` | Synchronize with ViewModel and invoke its methods |
| Shared View | None | Stateless presentation |
| ViewModel | `@Observed` + `@Track` | Observable state and precise property updates |
| ViewModel array | `@Observed extends Array` | Observable `push` and `splice` |
| Model | Ordinary class | Raw data and data access |

**Scenario ID:** MVVM_SCENE_V1

**Complete assets:** `../assets/V1MVVM`

### Data Flow

1. Page load calls `ViewModel.loadTasks()`, which calls `Model.loadTasks()` and converts records to ViewModel objects.
2. Select-all uses `@Link`, calls `chooseAll()`, and updates each item.
3. Item actions use `@ObjectLink` and call ViewModel methods.
4. `@Track` refreshes only UI that reads the changed property.

### Model and ViewModel Responsibilities

Use ordinary Model classes for raw structures and JSON loading. Use `@Observed` ViewModels with `@Track` properties for observable UI state. Subclass `Array` with `@Observed` when V1 array mutations must be observed.

### View Responsibilities

Shared components remain stateless. Business components receive ViewModel references with `@Link` or `@ObjectLink`, call ViewModel methods from event handlers, and do not access Model objects directly. Page components use `@State` to bind the ViewModel and call loading methods from `aboutToAppear`.

### Recommended Structure

```text
src/ets/
├── model/       # ThingModel.ets and TodoListModel.ets
├── pages/       # Index.ets
├── view/        # AllChooseComponent, ThingComponent, TodoComponent, TodoListComponent
└── viewmodel/   # ThingViewModel.ets and TodoListViewModel.ets
```

# MVVM Refactoring Workflow: Existing Project

Use this when existing code must be refactored to MVVM. **Proceed page by page and verify unchanged behavior after each Page.**

## 0. Determine Refactoring Order

Order from lowest to highest risk:

```
1. Pure display page (read-only, no interaction) → safest
2. Simple form page (has submission, no complex state)
3. List page (has additions, deletions, and edits; more complex state)
4. Multiple tabs / nested navigation page (cross-component shared state)
```

## 1. Scan the Current State

Identify MVVM violations in the target page:

| Check | How to inspect |
|--------|---------|
| Page contains business logic | Page struct contains data processing, API calls, or state calculations |
| View directly accesses Model | View file imports the model/ directory |
| State management is tangled | The same data is managed by `@State` in multiple places |
| Component responsibilities are unclear | One struct handles data retrieval, business calculations, and UI rendering |

Compare each item with [anti-patterns.md](references/anti-patterns.md).

## 2. Extract the ViewModel

Remove state and logic from Page/View and create a ViewModel class:

```
Code in the original Page:
├─ @State xxx → move to ViewModel and add an observation decorator
├─ Business methods (data processing, calculations) → move to ViewModel
├─ API / database calls → move to Repository (Model layer)
└─ Pure UI state (such as selected tabs) → keep in Page/View
```

**Order of operations**:
1. Create the ViewModel file and declare the class and properties (without decorators)
2. Move the Page's `@State` variables and business methods into it
3. Add observation decorators (`@Trace`/`@Observed`) to ViewModel properties
4. Have the Page hold the ViewModel instance and call its methods

## 3. Separate the Model

Use the [code file principles](#code-file-principles) to determine ownership for code in ViewModel/View:

```
Code in the ViewModel:
├─ http.createHttp().request(...) → move to Repository
├─ preferences.get(...)          → move to Repository
├─ Data structure definitions (interface/class) → move to Model files
├─ Pure algorithms and system-capability wrappers → move to util/
└─ Pure business logic (filtering, sorting, calculations) → keep in ViewModel
```

## 4. Reorganize the View

Reduce the Page to a pure assembly role:

```
Refactored Page:
├─ Create the ViewModel instance (@Local/@State)
├─ Call the ViewModel initialization method in aboutToAppear
└─ Do only layout and child-component assembly in build()

Refactored View:
├─ Receive ViewModel data through @Param/@Prop
├─ Pass user actions upward through @Event/callbacks
└─ Do not import Model files directly
```

## 5. Verify Page by Page

Verify immediately after refactoring each page:

1. Call `check_ets_files` for static checks on modified `.ets` files; fix errors until it passes
2. When necessary, call `build_project` for full build verification
3. Check data-flow compliance item by item:

| Verification | Method |
|--------|------|
| Behavior unchanged | Manually test every page interaction |
| Data-flow compliance | View does not directly access Model; events pass through ViewModel |
| Decorator pairing | V1/V2 are not mixed |
| No redundant state | Each piece of data is managed in one place |

Proceed to the next page only after verification passes.

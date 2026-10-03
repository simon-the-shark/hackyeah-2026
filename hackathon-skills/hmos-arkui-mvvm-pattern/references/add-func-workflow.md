# MVVM Implementation Workflow: New Feature

Use this when building a new page or module from scratch.

## 0. Identify State Categories

Use the [state variable principles](#state-variable-principles) decision tree to determine ownership for each variable.

## 1. Define the Model

Use the [code file principles](#code-file-principles) to determine ownership for each piece of code. The Model contains only pure data structures and data-access logic.

Note: this model must not contain decorators such as `@Observed` or any state-management content; it should contain only reusable pure business logic.

```
model/
├── UserModel.ets          Entity: pure data structure, no decorators
├── TaskModel.ets          Entity: interface or class
└── UserRepository.ets     Repository: encapsulates data-source access
    ├── fetchUser()        Network request
    ├── saveLocal()        Local storage
    └── parseResponse()    Data conversion
```

## 2. Create the ViewModel

**Each ViewModel corresponds to one UI concern**, not necessarily one page, and not one ViewModel for everything:

```
viewmodel/
├── LoginViewModel.ets     Login form state + validation logic
├── AuthViewModel.ets      Global authentication state (singleton, shared across pages)
└── CartViewModel.ets      Cart state + operation logic
```

| Division principle | Example |
|----------|------|
| One page has one primary ViewModel | LoginPage → LoginViewModel |
| Cross-page shared state is a singleton ViewModel | Login state → AuthViewModel |
| A complex component may have its own ViewModel | Address picker → AddressPickerViewModel |
| Do not put all logic into one "god ViewModel" | ✗ AppViewModel manages everything |

**What the ViewModel contains**:

```
├── UI state properties (drive rendering)     isChecked, loadState, taskList
├── UI logic methods (input validation)       validate(), updateInput()
├── Coordination methods (call Model, update state) loadTasks(), login()
└── Excludes                                  UI component references, direct system API calls
```

Use a `LoadState` enum plus separate data fields for **asynchronous data state**:

```typescript
// ✓ The loadState enum makes stages mutually exclusive; separate data fields preserve @Trace granularity
export enum LoadState {
  Idle = 'idle',
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
}

@Trace loadState: LoadState = LoadState.Idle
@Trace taskList: TaskModel[] = []
@Trace errorMessage: string = ''
```

Reason: `@Trace` tracks properties independently, so separate fields provide finer rendering granularity than a nested object.

| Step | V2 | V1 |
|------|----|----|
| Class decorator | `@ObservedV2` | `@Observed` |
| Property observation | `@Trace` | Automatic first-level / `@Track` for precision |
| State monitoring | `@Monitor` | `@Watch` |
| Computed property | `@Computed` | Manual getter |

## 3. Implement the View

| Step | V2 | V1 |
|------|----|----|
| Component decorator | `@ComponentV2` | `@Component` |
| Receive data | `@Param` | `@Prop` (one-way) / `@Link` (two-way) |
| Output events | `@Event` | `@Link` or callback |

The View depends only on the ViewModel and remains minimal.

## 4. Assemble the Page

The Page is the entry point, creates the ViewModel instance, and passes it to the View. The Page contains no business logic.

## 5. Build Verification

After implementation, always compile to find introduced errors:

1. Call `check_ets_files` for static checks on modified `.ets` files
2. If errors occur, fix them and check again until all pass
3. When necessary, call `build_project` for full build verification

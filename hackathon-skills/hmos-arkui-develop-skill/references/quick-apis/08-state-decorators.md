## 8. State Management Decorators


> **Component index**: `V1 decorators`, `V1 global state APIs`, `V2 decorators (API 12+)`, `V2 global state APIs`

### V1 Decorators

| Decorator | Category | Type | Description |
|--------|---------|-------------|------|
| **@State** | Component state | Object/class/string/number/boolean | Observes first-level property changes and triggers UI refresh |
| **@Prop** | One-way parent-to-child | Same as @State | One-way parent transfer with a local child copy |
| **@Link** | Two-way parent-child | Same as @State | Two-way synchronization; pass with `$variable` |
| **@Observed** | Class decorator | class | Observes nested property changes in class instances |
| **@ObjectLink** | Nested object | Class instance decorated with @Observed | Enables nested observation with @Observed |
| **@Provide / @Consume** | Across levels | Same as @State | Ancestor provides; descendants consume |
| **@Watch** | Variable observation | Appended after another decorator | `@Watch('onChanged')` callback on change |
| **@Builder** | UI reuse | Function | Declarative UI description function. Refresh behavior depends on parameter passing (see below) |
| **@BuilderParam** | UI slot | @Builder function | Receives external UI; its type must match the supplied @Builder |
| **@LocalBuilder** | Local UI | Function | Does not track external dependency changes; prefer @LocalBuilder over @Builder in @ComponentV2 |

**@Builder parameter passing quick reference** (see `common-mistakes/12-builder-params.md` for a complete incorrect-usage comparison):

| Passing method | Call form | Does a state-variable change refresh? | Limitation |
|---------|---------|-------------------|------|
| Pass by value (default) | `builder(this.label)` or `builder(label: string)` | ❌ No refresh | Simple-type parameters are passed by value by default |
| Pass by reference | `builder({ paramA1: this.label })` single-argument object literal | ✅ Refreshes | Works only with one object-literal argument; multiple arguments do not refresh |
| Pass by callback (API 20+) | `builder(UIUtils.makeBinding(() => this.x, setter))` | ✅ Refreshes and can be modified inside the Builder | A SetterCallback is required to write back |

> ⚠️ Common pitfalls: passing a state variable by value does not refresh / two or more arguments do not refresh / changing an argument inside @Builder reports 140109 / passing an entire object to a built-in component inside @Builder does not refresh.
| **@Extend** | Style extension | Component type | `@Extend(Text) function myStyle() {}` |
| **@Styles** | Common style | No arguments | `@Styles function myStyles() {}` |
| **@StateStyles** | Polymorphic style | — | {normal, pressed, disabled, focused, selected} |
| **@AnimatableExtend** | Animation extension | Animatable property | Custom animatable extension |
| **@Reusable** | Component reuse | @Component | Implement `aboutToReuse` |
| **@Require** | Required parameter | Variable | Marks a parameter as required |

### V1 Global State APIs

| API | Signature | Description |
|-----|----------|------|
| **AppStorage** | `.setOrCreate(key, value)` `.get(key)` `.set(key)` `.delete(key)` | Application-level global state |
| **@StorageLink** | `@StorageLink('key') var: type` | Two-way synchronization with AppStorage |
| **@StorageProp** | `@StorageProp('key') var: type` | One-way synchronization with AppStorage |
| **LocalStorage** | `new LocalStorage()` `.setOrCreate()` `.get()` | Page/module-level state |
| **@LocalStorageLink** | `@LocalStorageLink('key') var: type` | Two-way synchronization with LocalStorage |
| **@LocalStorageProp** | `@LocalStorageProp('key') var: type` | One-way synchronization with LocalStorage |
| **PersistentStorage** | `.persistProp('key', default)` `.deleteProp()` | Persistent storage |
| **Environment** | `.envProp('key', value)` | Environment variable |

### V2 Decorators (API 12+)

| Decorator | Category | Description |
|--------|---------|------|
| **@Local** | Component state | Replaces @State |
| **@Param** | Parent-to-child passing | Replaces @Prop/@Link |
| **@Once** | Appended to @Param | Synchronizes only once during initialization |
| **@Event** | Child-to-parent callback | `@Event onValueChange: (val) => void` |
| **@Provider / @Consumer** | Across levels | V2 version |
| **@Monitor** | Property observation | `@Monitor('p1','p2') onPChange(mon: IMonitor) {}` |
| **@SyncMonitor** | Synchronous observation | Synchronous version |
| **@Computed** | Computed property | `@Computed get name(): string {}` |
| **@ObservedV2** | Class decorator | Deep observation in V2 |
| **@Trace** | Property tracking | `@Trace name: string = ''` |
| **@Type** | Type marker | Serialization type |
| **@ReusableV2** | Component reuse | V2 version |
| **@Binding** | Two-way binding | Two-way binding in V2 |

### V2 Global State APIs

| API | Signature | Description |
|-----|------|------|
| **AppStorageV2** | `.connect(this, 'key', type?)` | Application-level state in V2 |
| **PersistenceV2** | `.connect(this, 'key', type?)` | Persistence in V2 |
| **makeObserved** | `makeObserved(target)` | Makes an object observable |
| **canBeObserved** | `canBeObserved(target)` | Checks whether an object is observable |
| **getTarget** | `getTarget(proxy)` | Gets the original object from a Proxy |
| **addMonitor / clearMonitor** | `addMonitor(obj, prop, cb)` / `clearMonitor(id)` | Dynamic observation |

---

## 3. State Management V1 Decorator Constraints

### @State
- Observes only **first-level** changes (assignment, array item insertion/removal, and Map/Set API calls)
- **Deep property changes** in nested objects are not observed; use @Observed/@ObjectLink
- `push/splice` on a **nested array property** of an @State object (such as `project.tasks`) is not observed; the array must be an `@Observed class extends Array` and a child must receive that array instance through @ObjectLink
- **Aggregate values** such as completed count or total progress do not automatically observe child property changes; recompute them in a callback
- Does not support undefined or null

### @Prop
- **One-way synchronization**; local changes can be overwritten by parent updates
- May be initialized locally or externally
- A variable decorated with @Prop locally **copies the data source**

### @Link
- **Must be initialized externally**; **local initialization is forbidden**
- **Two-way synchronization** with the data source
- Can only be initialized by a V1 state variable

### @ObjectLink
- **No local initialization**; the value must come from the parent
- **Do not assign the whole value** (`this.objLink = ...`); only properties may be changed (`this.objLink.a = ...`)
- Before API version 19, the type **must** be an @Observed class instance
- API version 19+ supports complex types, but nested observation still requires @Observed
- **Simple types** (number, string, boolean) are unsupported; use @Prop

### @Observed
- Decorates a class
- In nested scenarios, **non-simple properties also require @Observed** or changes are not observed

### @Provide / @Consume
- @Consume **cannot be initialized externally**
- @Provide may be initialized externally or locally

### @StorageLink / @StorageProp / @LocalStorageLink / @LocalStorageProp
- **Cannot be initialized externally**; automatically bind to AppStorage / LocalStorage

### @Watch
- Never modify **the watched variable itself** in an @Watch callback; this causes an infinite loop

### @Builder
- **Do not define state variables** or lifecycle functions inside @Builder
- Parameter types **cannot** be undefined, null, or expressions returning them
- **By-value state parameters do not refresh**: `builder(this.label)` does not refresh Builder UI when label changes
- **By-reference refresh requires one object-literal parameter**: `builder({ paramA1: this.label })`; use `$$` for nested parameter conventions, but `$$` is not a language keyword
- **Parameter types must be declared classes/interfaces**; do not use inline object-literal types such as `$$: { x: T }` (10605040)
- **Two or more parameters do not refresh**; combine them into one object parameter
- **Do not modify Builder parameters**; use `MutableBinding` (API20+) and a SetterCallback when modification is required
- Passing a whole object to a custom component inside @Builder does not refresh; pass simple properties instead
- **Do not call @Builder outside UI statements**; call it directly or pass a method reference
- **Do not call @Builder inside @Watch callbacks**; this causes UI refresh errors
- Define a global @Builder globally when it does not depend on component state

### @BuilderParam
- Used as a placeholder and may be initialized externally

### @Extend
- **Global definitions only** (cannot be defined inside a component)
- **Available only in the current file**; export is unsupported (use AttributeModifier to export)
- **Cannot be combined with @Styles**

### @Styles
- **Parameters are unsupported**
- **Business logic statements are unsupported**
- Supports only **common attributes** (not private attributes such as Button fontColor)
- export is unsupported

### @Require
- Means external initialization is required and conflicts with private
- **Do not** decorate @State/@Prop/@Provide/@BuilderParam/regular members with both @Require and private

### @AnimatableExtend
- Decorated function parameters **only allow** number, string, Color, and their unions
- Maximum animation duration in cards is **1000ms**

### wrapBuilder
- The type parameter must **exactly match** the @Builder function signature

## Common Errors

- **Omitting state variable type annotations**: ArkUI decorators require every state variable to declare a type
  - ❌ `@State count = 0` → ✅ `@State count: number = 0`
  - ❌ `@State list = []` → ✅ `@State list: Array<string> = []`

---

## 12. @Builder Parameter Passing Errors

AI often writes @Builder code with incorrect parameter passing, causing **UI not to refresh** or **parameters to be mismatched**. @Builder has three parameter-passing modes, and choosing the wrong mode is the most frequent root cause.

### Parameter-Passing Quick Reference

| Passing mode | Call form | Does a state change refresh? | Use case |
|---------|---------|-------------------|---------|
| Pass by value (default) | `builder(this.label)` or `builder(label: string)` | ❌ No | Parameter does not depend on state, or renders only once initially |
| Pass by reference | `builder({ paramA1: this.label })` single-parameter object literal | ✅ Yes | Parameter is state and must refresh with changes |
| Pass by callback (API 20+) | `builder(UIUtils.makeBinding(() => this.x, setter))` | ✅ Yes, and it can be modified inside Builder | Input must be modified inside Builder and returned to the caller |

### Error 1: Passing a State Variable by Value Does Not Refresh the UI

❌ Incorrect usage
```typescript
@Builder
function overBuilderByValue(paramA1: string) {  // Primitive type = pass by value
  Text(`UseStateVarByValue: ${paramA1}`)
}

@Entry
@Component
struct ParameterValue {
  @State label: string = 'Hello';
  build() {
    Column() {
      overBuilderByValue(this.label)  // ❌ Text in Builder does not refresh when label changes
      Button('change').onClick(() => { this.label = 'ArkUI'; })
    }
  }
}
```

✅ Correct usage (change to pass by reference: one parameter + object literal)
```typescript
class Tmp { paramA1: string = '' }

@Builder
function overBuilderByReference(params: Tmp) {  // Object type + one parameter
  Text(`UseStateVarByReference: ${params.paramA1}`)
}

@Entry
@Component
struct ParameterReference {
  @State label: string = 'Hello';
  build() {
    Column() {
      overBuilderByReference({ paramA1: this.label })  // ✅ Refreshes when label changes
      Button('change').onClick(() => { this.label = 'ArkUI'; })
    }
  }
}
```

> **Root cause**: When passed by value, @Builder receives a copy of the state value. No dependency is established, so a state change does not re-render Builder.

### Error 2: Two or More Parameters Do Not Refresh, Even with Object Literals

❌ Incorrect usage
```typescript
class GlobalTmp { strValue: string = 'Hello' }
class SecondTmp { numValue: number = 0 }

@Builder
function overBuilder(param: GlobalTmp, num: SecondTmp) {  // Two parameters
  Text(`strValue: ${param.strValue}`)
  Text(`num: ${num.numValue}`)
}
// Call: overBuilder({ strValue: this.strParam.strValue }, { numValue: this.numParam.numValue })  // ❌ Does not refresh
```

✅ Correct usage (merge into one object parameter)
```typescript
class GlobalTmp {
  strValue: string = 'Hello';
  numValue: number = 0;
}

@Builder
function overBuilder(param: GlobalTmp) {  // One parameter
  Text(`strValue: ${param.strValue}`)
  Text(`num: ${param.numValue}`)
}
// Call: overBuilder({ strValue: this.objParam.strValue, numValue: this.objParam.numValue })  // ✅ Refreshes
```

> **Root cause**: Pass-by-reference triggers dynamic rendering only when **one parameter is passed as an object literal**; multiple parameters, or mixing pass-by-value and pass-by-reference, does not refresh.

### Error 3: Creating a Custom Component in @Builder and Passing the Whole Object Does Not Refresh

❌ Incorrect usage
```typescript
class Tmp { name: string = ''; age: number = 0 }

@Builder
function parentBuilder(params: Tmp) {
  Column() {
    Text(`parent===${params.name}===${params.age}`)
    HelloComponent({ info: params })  // ❌ Whole object passed; child does not refresh when name/age changes
  }
}

@Component
struct HelloComponent {
  @Prop info: Tmp = new Tmp();
  build() { Text(`child===${this.info.name}===${this.info.age}`) }
}
```

✅ Correct usage (pass primitive properties to the child component)
```typescript
@Builder
function parentBuilder(params: Tmp) {
  Column() {
    Text(`parent===${params.name}===${params.age}`)
    HelloComponent({ childName: params.name, childAge: params.age })  // ✅ Split into primitive properties; refreshes
  }
}

@Component
struct HelloComponent {
  @Prop childName: string = '';
  @Prop childAge: number = 0;
  build() { Text(`child===${this.childName}===${this.childAge}`) }
}
```

> **Root cause**: Passing the whole object to a custom component created in @Builder is not pass-by-reference, so the child @Prop/@Link cannot receive changes. Splitting it into primitive properties lets each property refresh independently.

### Error 4: Modifying an Input in @Builder Does Not Refresh and Reports 140109

❌ Incorrect usage
```typescript
@Builder
function myGlobalBuilder(value: string) {
  Text(`value: ${value}`)
    .onClick(() => {
      value = 'change';  // ❌ Primitive passed by value; modification does not refresh
    })
}

interface TempMod { paramA: string }

@Builder
function overBuilder(param: TempMod) {
  Button(`${param.paramA}`)
    .onClick(() => {
      param.paramA = 'Yes';  // ❌ Object passed by reference; property modification fails at runtime (140109 from API 23)
    })
}
```

✅ Correct usage 1 (modify the state variable in the caller's event callback, not the Builder input)
```typescript
@Builder
function overBuilder(param: TempMod) {
  Button(`${param.paramA}`)  // Do not modify inside Builder; the reference dependency refreshes it
}
// Caller:
// overBuilder({ paramA: this.label })
// Button('change').onClick(() => { this.label = 'ArkUI'; })
```

✅ Correct usage 2 (modify inside Builder and return it with MutableBinding, API 20+)
```typescript
import { UIUtils, MutableBinding } from '@kit.ArkUI';

@Builder
function myGlobalBuilder(str: MutableBinding<string>) {
  Text(`value: ${str.value}`)
    .onClick(() => {
      str.value = 'change';  // ✅ Modification is returned to the caller
    })
}
// Call:
myGlobalBuilder(UIUtils.makeBinding<string>(
  () => this.message,
  (val: string) => { this.message = val; }  // SetterCallback is required or runtime failure occurs
))
```

> **Root cause**: @Builder must not modify parameter values or properties. Primitive modifications have no effect (silent no-refresh); modifying an object property throws a runtime error and returns 140109 from API 23. To modify inside Builder, use MutableBinding and pass SetterCallback.

### Error 5: Refresh Problems After Assigning an @Builder Method to a Variable or Array

❌ Incorrect usage
```typescript
@Builder myImages() { Column() { Image($r('app.media.startIcon')) } }
@Builder myImages2() { Column() { Image($r('app.media.startIcon')) } }

private bgList: Array<CustomBuilder> = [this.myImages(), this.myImages2()];  // ❌ Called outside a UI statement
@State bgBuilder: CustomBuilder = this.myImages();  // ❌ Refresh problems after assignment to a variable
```

✅ Correct usage (call directly or pass a method reference)
```typescript
Text('2').background(this.myImages)    // ✅ Pass a method reference
Text('3').background(this.myImages())  // ✅ Call directly
```

> **Root cause**: After an @Builder method is assigned to a variable or array, it cannot be used reliably in UI methods and nodes display incorrectly during refresh. Call it directly or pass it as a method reference.

### Error 6: Calling @Builder Inside an @Watch Callback Causes Refresh Problems

❌ Incorrect usage
```typescript
@Provide @Watch('provideWatch') content: string = 'hello';

@Builder watchBuilder(content: string) { Row() { Text(`${content}`) } }

provideWatch() {
  this.watchBuilder(this.content);  // ❌ Calling @Builder inside @Watch causes UI errors
}
```

✅ Correct usage (@Watch handles logic only; call @Builder in build)
```typescript
provideWatch() {
  console.info('content changed');  // ✅ Logic only
}

build() {
  Column() {
    this.watchBuilder(this.content);  // ✅ Call in build
  }
}
```

**Root cause summary**: AI treats @Builder like an ordinary function and does not understand the refresh differences and restrictions of its three parameter-passing modes. Key rules: **to refresh state -> pass a single object literal by reference; do not modify inputs inside Builder; do not call Builder methods outside UI statements; do not call Builder inside @Watch**. See Section 3, the @Builder entry in `quick-rules/03-state-v1.md`, for the complete rules.

### Error 7: Missing Tuple Brackets in wrapBuilder / WrappedBuilder Generics

Use `wrapBuilder` to pass a global @Builder across components. The generic **must be the tuple array type `[T]`**; omitting `[]` reports **10505001**.

❌ Incorrect usage
```typescript
interface CardData { text: string }
@Builder
function CardBuilder($$: CardData) { Text($$.text) }

const wrapper: WrappedBuilder<CardData> = wrapBuilder(CardBuilder)  // ❌ Generic is missing []; CardData does not satisfy the Object[] constraint
// Error: Type 'CardData' does not satisfy the constraint 'Object[]'
// Calling wrapper.builder({text:item}) also has a type mismatch: Argument of type '[{ text: string; }]' is not assignable to parameter of type 'CardData'
```

✅ Correct usage (write the generic as tuple `[CardData]`)
```typescript
interface CardData { text: string }

@Builder
function CardBuilder($$: CardData) { Text($$.text) }

const wrapper: WrappedBuilder<[CardData]> = wrapBuilder(CardBuilder)  // ✅ Tuple generic

@Entry
@Component
struct CardListPage {
  private items: string[] = ['A', 'B', 'C']
  build() {
    Column({ space: 12 }) {
      ForEach(this.items, (item: string) => {
        wrapper.builder({ text: item })   // ✅ Call builder method with the first arg
      }, (item: string) => item)
    }
  }
}
```

> **Root cause**: The SDK defines `declare class WrappedBuilder<Args extends Object[]>` and `declare function wrapBuilder<Args extends Object[]>(...)`; the generic constraint is an array (tuple). AI tends to write `WrappedBuilder<T>` and omit `[]`. The correct form is `WrappedBuilder<[T]>`, called as `wrapper.builder(arg)` (builder method signature `(...args: Args) => void`).

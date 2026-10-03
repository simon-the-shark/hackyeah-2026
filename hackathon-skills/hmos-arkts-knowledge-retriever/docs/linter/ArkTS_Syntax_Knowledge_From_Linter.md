# ArkTS Syntax Constraint Summary
> Based on`ArkTSLinter_1_1`Rule implementation, supporting rule tags, and a set of minimal examples.> This article organizes the ArkTS language constraints implicit in the linter into a natural language summary, focusing on "what is allowed, what is prohibited, and exceptions under what conditions" rather than explaining the source code implementation process.
This article is an engineering summary based on the current implementation. It is not equivalent to the full text of the official language specification, nor does it cover UI ArkTS. For scenarios such as multi-file modules, shared modules and TS/ETS interoperability, this article uses the rule source code as the main basis; for pure non-UI single files`.ets`Scenarios, appendix examples available`arkts-cli`Do a recurrence check.
## 1. Overview
from`ArkTSLinter_1_1`Looking at the set of rules, ArkTS is not a simple TypeScript alias, but a restricted language subset built on the TypeScript syntax surface. Its core tendencies can be summarized as:
- Pursue explicit, static, and decidable type expressions.- Visibly compressed JavaScript's dynamic object model.- Reduce reliance on complex inference, structure type compatibility and runtime reflection capabilities.- pass`Sendable`, shared module and taskpool rules, making concurrency and shared data part of the language constraints.
Therefore, the "grammar knowledge points" in this article include three categories of content:
-Pure grammatical restrictions: Certain types of grammatical structures are not directly supported.- Type system restrictions: the syntax surface is writable, but the type semantics are tightened.- Running model limits: around`Sendable`, static constraints on shared modules and concurrent functions.
## 2. Rule reading method
The rules in this linter should not be interpreted as "absolute prohibitions". From the perspective of rule attributes, there are at least four intensities:
- Error level prohibition: if it occurs, it is deemed to be inconsistent with ArkTS syntax or semantic requirements.- Warning level restriction: The language still considers this writing method to be unsatisfactory or not recommended, but retains compatibility space.- Conditionally allowed: a grammatical construct is not completely disabled, but relaxed in a few contexts.- Migration rules: rules with`migratable`Attribute, indicating that it may be skipped in non-strict migration mode, but still belongs to ArkTS from the perspective of language specifications. The writing method is not recommended or supported.
This article defaults to error-level rules as the main specification in subsequent chapters, and explicitly notes warnings and condition relaxations.
This article uses the following fixed caliber for evidence sources:
- Rule source code: directly from `Problems.ts`, `CookBookMsg.ts`, and `TypeScriptLinter.ts` implementations or rule tags. - Sample verification: available from the minimal `.ets` samples in `examples/` with `arkts-cli`. - Derivation note: a conservative generalization of multiple rules used to explain boundaries; it should not be considered stronger normative text than the implementation.
## 3. Declaration and scope
### 3.1 Variable declaration
Rule definition:
- Variable declarations must use `let` or `const`; `var` cannot be used.
- Variable declaration does not support destructuring forms, including object destructuring and array destructuring.- Variables without type annotations and without initializers are considered illegal because this leaves type determination to implicit inference.- If the variable inference result falls to`any`or`unknown`, nor does it meet the type requirements of ArkTS.- Definite assignment assertions on ordinary variables`!`Considered a warning level restriction.
Allowed boundaries:
- has an explicit type, or has an explicit initializer and the inferred result does not fall into`any` / `unknown`When , the type annotation can be omitted.- `catch`Exception variables in clauses are special cases. The linter does not treat "Omitted exception variable type" as an error due to TypeScript's constraints on the location itself.
Not allowed to write:
```ts
var x = 1
let { a } = obj
let y!
let z
```

Allowed examples:
```ts
let count = 1
const label: string = "ok"
```

Example not allowed:
```ts
var x = 1
let [a, b] = [1, 2]
```

evidence:
- Rule source code: `arkts-no-var`, `arkts-no-destruct-decls`, `arkts-no-any-unknown`, `arkts-no-definite-assignment`
- Sample verification: `examples/allow_typed_object_literal_ok.ets`, `examples/forbid_var_fail.ets`, `examples/forbid_destructuring_decl_fail.ets`

### 3.2 Parameter declaration
Rule definition:
- Parameters do not support destructuring. - Constructor parameter properties are not supported; `public`, `private`, `protected`, and `readonly` cannot be written directly in the parameter position to declare members. - If the parameter type is omitted and inference falls to `any` / `unknown`, it likewise fails ArkTS's explicit type requirements.
Allowed boundaries:
- The type can be omitted for ordinary parameters, provided the inference result is stable and does not involve `any` / `unknown`.

### 3.3 Function declaration and function value
Rule definition:
- Local function declarations are not supported. Function declarations should be at the source top level or in a namespace module block. - Function expressions are not supported; prefer arrow functions. - Generator functions and `yield` expressions are not supported. - `this` is not allowed in a standalone function body.
- A function that lacks an explicit return type and whose return value relies on complex call inference is considered to have limited return type inference.
Allowed boundaries:
- Arrow functions themselves are allowed.- Return types do not always have to be written explicitly; they are considered unqualified only if the inferred result is unreliable, inexpressible, or the signature itself lacks sufficient information.
Not allowed to write:
```ts
function outer() {
  function inner() {}
}

const f = function () {}
function* gen() {}
```

Allowed examples:
```ts
let inc = (x: number): number => {
  return x + 1
}
```

Example not allowed:
```ts
function outer(): number {
  function inner(): number {
    return 1
  }
  return inner()
}
```

evidence:
- Rule source code: `arkts-no-func-expressions`, `arkts-no-nested-funcs`, `arkts-no-generators`, `arkts-no-standalone-this`, `arkts-no-implicit-return-types`
- Sample verification: `examples/allow_arrow_function_ok.ets`, `examples/forbid_nested_function_fail.ets`

### 3.4 Class declaration
Rule definition:
- Class expressions are not supported, classes should use regular class declarations.- Only one static code block is allowed in a class.- private`#identifier`The form is not supported.- Class member names must not have repeated meanings, including common identifiers and private names before they are removed`#`subsequent conflict.- Methods are not allowed to be reassigned.- You cannot treat a function as an open object and then add attributes.
Allowed boundaries:
- Classes as values ​​do not always report an error, it is a warning-level restriction; ArkTS tends to treat classes as types and constructors rather than ordinary object values.- Some dynamic or library type contexts relax the "class value usage" check, but this is not regular ArkTS style.
### 3.5 Interfaces, enumerations and namespaces
Rule definition:
- Interface merging is not supported, and enumeration merging is not supported.- Interfaces cannot inherit from classes.- When an interface inherits multiple parent interfaces, if the attribute types with the same name are inconsistent, it will be considered illegal.- Namespaces cannot be used as ordinary objects.- Only declarative members are allowed inside the namespace; neither ordinary statements nor empty semicolons should appear.- The abbreviation ambient module, module name with wildcard characters, and UMD form are not supported.
Additional instructions:
- ArkTS's attitude towards namespaces is closer to "historical compatibility syntax" than to the recommended way of organizing modules.
### 3.6 Unique naming
Rule definition:
- Declarations of types, namespaces, classes, functions, import names, etc. must be unique.- The linter explicitly does not accept the use of TypeScript declaration merging to resolve duplicate names.
## 4. Expressions and statements
### 4.1 Object literal
Rule definition:
- An object literal cannot appear freely without context; it should correspond to an explicitly declared class or interface type.- Object literals cannot be used directly as type declarations.- Object literal property names should default to identifiers.
Allowed boundaries:
- exist`Record`, dynamic objects, library types, etc., numeric literal property names can be relaxed.- Certain struct initialization scenarios allow object literal initialization.
Special restrictions:
- If an object literal matches multiple candidate targets simultaneously in a union type context, and these candidates belong to the static ArkTS type system, it will be treated as an ambiguous object literal.- exist`Sendable`In the target type context, object literal initialization will directly trigger sendable rule errors.
Example:
```ts
interface Point {
  x: number
  y: number
}

const p: Point = { x: 1, y: 2 }
```

```ts
// Not allowed
const obj = { x: 1, y: 2 }
type T = { x: number }
```

Boundary example:
```ts
interface Point {
  x: number
  y: number
}

let ok: Point = { x: 1, y: 2 }
```

```ts
let bad = { x: 1, y: 2 }
```

evidence:
- Rule source code: `arkts-no-untyped-obj-literals`, `arkts-no-obj-literals-as-types`, `arkts-identifiers-as-prop-names`, `arkts-no-ambiguity-obj-literal`
- Sample verification: `examples/allow_typed_object_literal_ok.ets`, `examples/forbid_object_literal_no_context_fail.ets`

### 4.2 Array literal
Rule definition:
- Array literals must consist of inferable elements.- If an object literal without context appears in an array element, the entire array will be considered illegal.
Allowed boundaries:
- If the array element already has a context type and the assignment relationship can be determined, part of the type writing is allowed to be omitted.- If the array target type is`Sendable`, still cannot be initialized directly with array literals.
Allowed examples:
```ts
let values: number[] = [1, 2, 3]
let first: number = values[0]
```

Example not allowed:
```ts
let bad = [{ x: 1 }, { y: 2 }]
```

evidence:
- Rule source code:`arkts-no-noninferrable-arr-literals`
- Sample verification:`examples/allow_array_element_access_ok.ets`
- Note: Mixing context-free object literals into arrays shares the same constraint logic with object literal rules. The appendix does not provide an independent minimal example yet.
### 4.3 Attribute access and element access
Rule definition:
- Computed attribute names are restricted overall.- Replacing ordinary field access with index access is discouraged.- Index signatures are not supported as a whole and are only allowed in a few special contexts.
Element access allows bounds:
- Element access is allowed on arrays, tuples, strings, `Record`, `Map`, enumerations, certain built-in objects, and certain library types. - Other ordinary class instances, interface instances, or structured objects cannot use index access as a regular field access mechanism.
Computed property name boundaries:
- Not all computed attribute names on ordinary objects are prohibited, but they need to meet the condition of "can be statically determined to be a legal attribute name".- `Sendable`class and`Sendable`In interfaces, computed attribute names are not allowed in principle.- right`@arkts.collections.d.ets`Neutralize`Symbol.iterator`A relevant minority of collections state that specialized exemptions exist.
Allowed examples:
```ts
let values: number[] = [1, 2, 3]
let first: number = values[0]
```

```ts
let scores: Record<number, string> = {
  1: "one",
  2: "two"
}
console.log(scores[1])
```

Example not allowed:
```ts
class Point {
  x: number = 1
}

let p: Point = new Point()
let bad = p["x"]
```

evidence:
- Rule source code: `arkts-identifiers-as-prop-names`, `arkts-no-props-by-index`, `arkts-no-indexed-signatures`, `arkts-sendable-computed-prop-name`
- Sample verification: `examples/allow_array_element_access_ok.ets`, `examples/allow_record_numeric_key_ok.ets`, `examples/forbid_object_index_access_fail.ets`

### 4.4 Assignment and structure operations
Rule definition:
- Destructuring assignment is not supported.- `delete`The operation is not supported.- The comma operator is only allowed in`for`Loop initialization and increment position.- Object expansion is not supported.- Unwinding elements is only allowed when an array or array-derived type is expanded into an array literal or call argument position.-Prototype chain modification and`prototype`Assignment is not supported.- Methods cannot be rebound in assignment statements.
Example not allowed:
```ts
class Point {
  x: number = 1
}

let p: Point = new Point()
delete p.x
```

evidence:
- Rule source code: `arkts-no-destruct-assignment`, `arkts-no-delete`, `arkts-no-comma-outside-loops`, `arkts-no-spread`, `arkts-no-prototype-assignment`, `arkts-no-method-reassignment`
- Sample verification:`examples/forbid_delete_fail.ets`

### 4.5 Operators
Rule definition:
- The `in` operator is not supported. - `instanceof` is only partially supported. - Unary `+`, `-`, and `~` accept only numeric types. - `typeof` is allowed only in expression contexts, not as a type query. - `is` type predicates are not supported.
`instanceof`The boundaries of:
- The left operand must be a reference type.- The left operand cannot be of primitive type.- The left operand cannot use the type name as a value to participate in judgment.- `this instanceof X`is retained as an acceptable scenario.
Allowed examples:
```ts
let x: number = 1
let kind: string = typeof x
```

Example not allowed:
```ts
class Point {
  x: number = 1
}

type PointCtor = typeof Point
```

```ts
class Point {
  x: number = 1
}

let p: Point = new Point()
let ok = "x" in p
```

evidence:
- Rule source code: `arkts-no-in`, `arkts-instanceof-ref-types`, `arkts-no-polymorphic-unops`, `arkts-no-type-query`, `arkts-no-is`
- Sample verification: `examples/allow_typeof_expression_ok.ets`, `examples/forbid_type_query_fail.ets`, `examples/forbid_in_fail.ets`

### 4.6 Control flow statements
Rule definition:
- `for...in`Not supported.- `with`Not supported.- `throw`Arbitrary values ​​cannot be thrown, the thrown expression must be`Error`System class or interface instance.- `catch`Clause does not support explicit exception type annotation.
### 4.7 Meta-Attributes, JSX and Error Suppression
Rule definition:
- `new.target` is not supported. - JSX is not supported, including ordinary and self-closing JSX elements. - Directives that disable type checking are not allowed, including `@ts-nocheck`, `@ts-ignore`, and `@ts-expect-error`.

Additional instructions:
- This shows that ArkTS not only limits the syntax itself, but also limits the means of "bypassing the type system".
## 5. Type system
### 5.1 Basic restricted types
Rule definition:
- `any`and`unknown`Not accepted.- `symbol`Type not accepted, overwhelmingly`Symbol`API is not accepted either.- `this`Type not supported.- `ESObject`It is a restricted type and cannot be used anywhere.
`ESObject`The boundaries of:
- In variables, properties, parameters, function types, partial return types, partial`as`Assertions and other boundary positions may be tolerated.- But the object literal is initialized directly`ESObject`, or put`ESObject`Widely propagated into the static type space, a warning will be triggered.
### 5.2 Advanced type expressions
Rule definition:
- Condition type is not supported.- Mapping type not supported.- Cross type is not supported.- Index access type not supported.- Object literal types are not supported.- Call signature is not supported.- Constructed signatures are not supported.
A breakdown of the constructed signature:
- A constructor signature in a type literal reports `ConstructorType`.
- A constructor signature in an interface reports `ConstructorIface`.
- The constructor type node itself does not support writing.
### 5.3 Structure type compatibility
Rule definition:
- ArkTS does not accept generalized structural type compatible models.- When an assignment relies primarily on "member shape similarity" rather than explicitly declaring the relationship, the linter treats it as a structural type risk.
Specification meaning:
- ArkTS prefers nominal relationships, explicitly declared relationships, or more predictable compatible relationships.- This is obviously different from TypeScript's "assignment as long as the structure is compatible".
### 5.4 Type assertion
Rule definition:
- Only `as T` syntax is accepted; angle-bracket assertions are not accepted. - `as const` is not supported. - Some assertions from primitive types to boxed object types are illegal, such as `number as Number` and `boolean as Boolean`.

`Sendable`Related assertion boundaries:
- Asserting non-sendable data to a sendable type is not allowed.- Asserting a non-sendable function as sendable function type aliasing is not allowed.
Example not allowed:
```ts
let pair = [1, 2] as const
```

evidence:
- Rule source code: `arkts-as-casts`, `arkts-no-as-const`, `arkts-sendable-as-expr`, `arkts-sendable-function-as-expr`
- Sample verification:`examples/forbid_as_const_fail.ets`

### 5.5 Generics
Rule definition:
- Generic call if the type parameter is omitted and the compiler infers the type parameter.`unknown`, an error will be triggered.- ArkTS does not prohibit generic inference completely, but prohibits "inadequate and unacceptable" inference.
### 5.6 Return type inference
Rule definition:
- Return type inference is not completely disabled, but is severely restricted.- Method signatures, environment declarations, and function bodyless declarations that lack return types are usually directly regarded as incomplete.- When a function's return value depends on another function call without an explicit return type, the return type inference of the current function is considered unreliable.
Allowed boundaries:
- Simple, stable return values ​​that do not require further inference across functions may still be accepted.- Arrow functions allow more room for inference in certain library type contexts.
### 5.7 Tool Type
Rule definition:
- Several standard utility types are directly restricted, including `Awaited`, `Pick`, `Omit`, `Exclude`, `Extract`, `NonNullable`, `Parameters`, `ReturnType`, `InstanceType`, and `ThisType`. - `Partial<T>` may be relaxed only when `T` is a class or interface; otherwise it remains unsupported.
## 6. Object-oriented and object model
### 6.1 Inheritance and Implementation
Rule definition:
- `implements`Class types cannot be written in the clause, only interfaces.- Interfaces cannot inherit from classes.
Specification meaning:
- ArkTS does not allow reuse of "class instance shapes" as interface protocols via TypeScript.
### 6.2 Classes, namespaces, and enumerations as values
Rule definition:
- Namespaces cannot be used as object values.- Classes used as object values ​​are subject to warning level restrictions.
Difference description:
- Namespaces as values ​​are an explicit error in ArkTS.- Classes as values ​​are closer to the "keep compatible but discouraged" status, which may be relaxed especially in dynamic or library type contexts.
### 6.3 Function objects and reflective calls
Rule definition:
- `Function.apply`and`Function.call`Not supported.- `Function.bind`It is a warning level restriction.- Declaring properties on function objects is not supported.
Specification meaning:
- ArkTS discourages treating functions as values ​​with mutable object behavior, and discourages reflective rewriting of call semantics through function objects.
Boundary example:
```ts
let inc = (x: number): number => x + 1
```

```ts
let inc = (x: number): number => x + 1
let bound = inc.bind(undefined, 1)
```

evidence:
- Rule source code: `arkts-no-func-apply-call`, `arkts-no-func-bind`, `arkts-no-func-props`
- Sample verification:`examples/warn_function_bind_warn.ets`
- Remark:`Function.bind`This is a warning-level limitation in the current implementation; minimal examples may be accompanied by other errors.
## 7. Modules and import and export
### 7.1 Basic import and export
Rule definition:
- `import`Must be at the front of the file and cannot appear after other declarations or statements.- `import =`and`require`Import assignment of the form is not supported.- `export =`Not supported.- import assertion is not supported.
dynamic`import()`The boundaries of:
- The current implementation does not include dynamic`import()`itself as a core prohibition.- But once the second parameter object appears`assert`, the import assertion error will still be triggered.
Example description:
```ts
import { foo } from "./foo"
```

```ts
// Not allowed
const x = 1
import { foo } from "./foo"
```

```ts
// Not allowed
import data from "./a.json" assert { type: "json" }
```

evidence:
- Rule source code: `arkts-no-misplaced-imports`, `arkts-no-require`, `arkts-no-export-assignment`, `arkts-no-import-assertions`
- Note: These examples involve a multi-file module context, and this article uses the rule source code as the main basis; the appendix does not provide single-file independent examples.
### 7.2 Special module form
Rule definition:
- shorthand ambient module is not supported.- Wildcard characters in module names are not supported.- UMD module definitions are not supported.
### 7.3 TS/ETS interoperability
Rule definition:
- When importing from ETS to TS, only import is allowed`Sendable`class and`Sendable`interface.- TS files cannot re-export ETS entities.- namespace import from ETS to TS is not supported.- Side-effect import from ETS to TS is not supported.
## 8. Standard library and limited built-in capabilities
### 8.1 Restricted Standard Library API
Rule definition:
- `eval` is not supported. - Many dynamic metaprogramming APIs on `Object` are restricted, including `assign`, `create`, `defineProperty`, `freeze`, `seal`, and `setPrototypeOf`. - APIs on `Reflect` related to reflection, prototypes, and property descriptors are restricted. - APIs on `ProxyHandler` corresponding to proxy traps are restricted. - Use of `Symbol` / `SymbolConstructor` is generally restricted.
### 8.2 `Symbol`the boundary of
Rule definition:
- `symbol`The type itself is not supported.- `Symbol()`Related APIs are basically not supported.
Allowed boundaries:
- `Symbol.iterator`Special allow lists exist.- There is a special handling for iterator computed properties in some collection declaration files.
## 9. `Sendable`rule
`Sendable`Not a single syntax point, but a set of static rules around "shareable, concurrent delivery of data."
### 9.1 What can be considered sendable
From a rule abstraction point of view, the following types can enter the sendable determination:
- Basic primitive types and their null value forms.- `@Sendable`kind.- `@arkts.lang.d.ets`middle`lang.ISendable`System interfaces and their derived types.- `@Sendable`function.- `@Sendable`Function type alias.- A union type in which all members are sendable.- `const enum`Considered allowed in certain sendable / shareable scenarios.
### 9.2 `@Sendable`Decorator
Rule definition:
- `@Sendable` can only be used for `class`, `function`, and `typeAlias`.
- If used in other declaration positions, an error will be reported directly.- `@Sendable`Entities cannot have other non-sendable decorators attached to them.
Version threshold:
- when`compatibleSdkVersion`Prior to API 12 beta3, sendable functions and sendable type alias were still considered unavailable.
### 9.3 `Sendable`kind
Rule definition:
- Non-sendable classes cannot inherit or implement sendable types. - A sendable class can implement an interface, but it can inherit only from a sendable class. - The inheritance target must be a real sendable class entity, not a local variable or opaque intermediate value. - Sendable class fields must have explicit types. - Their types must be sendable. - Definite-assignment assertions `!` are not allowed in sendable classes.
- Computed property names are not allowed in sendable classes.- Objects of sendable type cannot be initialized directly by object literals or array literals.
Allowed examples:
```ts
@Sendable
class Box {
  value: number

  constructor(value: number) {
    this.value = value
  }
}
```

Example not allowed:
```ts
@Sendable
class Box {
  value = 1
}
```

evidence:
- Rule source code: `arkts-sendable-class-inheritance`, `arkts-sendable-prop-types`, `arkts-sendable-definite-assignment`, `arkts-sendable-generic-types`, `arkts-sendable-obj-init`, `arkts-sendable-explicit-field-type`
- Sample verification: `examples/allow_sendable_class_ok.ets`, `examples/forbid_sendable_missing_field_type_fail.ets`

### 9.4 `Sendable`interface
Rule definition:
- The attribute type of the sendable interface must be of sendable type.- If a property type refers to a type alias with a non-sendable generic argument, a warning is generated.- The sendable interface also does not allow computed property names.
### 9.5 `Sendable`Generics
Rule definition:
- Generic arguments of type sendable must all be of type sendable.- If the default type of a sendable type parameter is not a sendable type, it is not legal.- This check applies to both type references and`new`Type arguments on expressions.
### 9.6 `Sendable`closure capture
Rule definition:
- In sendable classes and sendable functions, only imported variables are allowed to be captured.- Closure capture of local variables, functions, classes, interfaces, enumerations, namespaces, parameters, etc. outside the same file are restricted.
Allowed boundaries:
- Exported top-level declarations, top-level sendable entities,`const enum`Special relaxations exist for members.- The property name part in property access will not be treated as a closure capture object.
### 9.7 `Sendable`Functions and type aliases
Rule definition:
- `@Sendable` functions may have only the `@Sendable` decorator. - If a group of overloads is considered sendable as a whole, every related overload declaration must explicitly use `@Sendable`.
- sendable functions do not allow arbitrary access to function object properties.- `@Sendable`Type aliases can only be declared as function types.- The right-hand side of an assignment for a sendable function type alias must be a sendable function or a sendable function type alias object.- Non-sendable functions cannot be passed`as`Assertions are converted to sendable function types.
## 10. shared module and concurrent functions
### 10.1 shared module

Identification method:
- The file appears after the import statement and at the position of the first non-import statement`"use shared"`When used as a literal, it is treated as a shared module.
Import rules:
- Shared module does not allow side effects to be imported, that is, it cannot be written without`importClause`of bare import.
Export rules:
- A shared module may export only shareable entities. - Shareable is slightly broader than sendable and allows primitive literal types and `const enum`.
- `export * from ...`Not allowed.- `type alias`If the export is not shareable, it may be downgraded to a warning instead of an error.
Example description:
```ts
"use shared"

export const VERSION: string = "1.0"
```

```ts
"use shared"

import "./side-effect-only"
```

```ts
"use shared"

export * from "./other"
```

evidence:
- Rule source code: `arkts-no-side-effects-imports`, `arkts-shared-module-exports`, `arkts-shared-module-no-wildcard-export`
- Note: These examples rely on the layout of multi-file modules. This article uses the rule source code as the main basis; the appendix does not provide single-file independent examples.
### 10.2 taskpool and concurrent functions
Rule definition:
- The functions passed to the taskpool related API must be ordinary functions with`@Concurrent`Decorator.- Rules apply not only to calling expressions, but also to partial task object construction scenarios.
Specification meaning:
- ArkTS does not accept the "callable value can safely enter the concurrent execution framework" model, and requires explicit concurrency marking.
## 11. Rule strength description
### 11.1 Error level rules
The following types of rules should be understood as default error level limits:
- `any` / `unknown`
- Condition type, mapping type, intersection type, index access type- `var`
- Destructuring declarations, destructuring assignments, and destructuring parameters - `delete`, `in`, `for...in`, and `with`
- `throw`any value- `JSX`
- `new.target`
- `Function.apply` / `Function.call`
- `import =`, `export =`, and import assertions
- Sendable inheritance, properties, generics, closure capture and other core rules
### 11.2 warning level rules
The following rules are explicitly marked warning in the implementation:
- Ordinary deterministic assignment assertion`DefiniteAssignment`
- `globalThis`
- `Function.bind`
- Class as object value`ClassAsObject`
- `ESObject`Usage restrictions- Shared modules are not shareable`type alias`Export- Problems with certain type alias parameters in sendable scenarios`SendablePropTypeWarning`

warning example:
```ts
let g = globalThis
```

evidence:
- Rule source code: `arkts-no-definite-assignment`, `arkts-no-globalthis`, `arkts-no-func-bind`, `arkts-no-classes-as-obj`, `arkts-limited-esobj`, `arkts-shared-module-exports`, `arkts-sendable-prop-types`
- Sample verification:`examples/warn_global_this_warn.ets`
- Note: a warning does not prevent `Syntax Check: OK`.

### 11.3 Conditional Allowance Rules
The following structures are not simply "total ban":
- Object literals are available with explicit contextual types and in struct initialization. - Numeric property names may be relaxed in `Record`, dynamic-object, and library-type contexts. - Element access is available for arrays, tuples, strings, `Record`, `Map`, and enumerations. - `typeof` is allowed in expression contexts but not as a type query. - Stable generic inference is allowed; inference to `unknown` is not. - Dynamic `import()` is not directly rejected, but its `assert` option is not allowed.
### 11.4 Migration rules
The following rules apply`migratable`Attributes should be understood as "still restricted in specifications, but may be relaxed in migration mode":
- Numeric or string literal attribute name- private`#identifier`
- Duplicate naming- `var`
- Parameter properties- Index field access- Function expressions, class expressions- `as`type assertion- Destructuring assignment, destructuring statement- `catch`type annotation- `throw`Improper type- local functions- Return type inference is restricted
## 12. Appendix A: Rule Tag Index
| Category | Representative tag | Description || --- | --- | --- |
| Statement |`arkts-no-var`| Prohibited`var` |
| Statement |`arkts-no-destruct-decls`| Destructuring variable declarations is prohibited || Statement |`arkts-no-destruct-params`| Destructuring parameters is prohibited || Statement |`arkts-no-ctor-prop-decls`| Disable construction parameter attributes || Statement |`arkts-no-private-identifiers`| No private`#identifier` |
| Statement |`arkts-unique-names`| Claim name must be unique || Statement |`arkts-no-decl-merging`| Prohibited merging of statements || function |`arkts-no-func-expressions`| Disable function expressions || function |`arkts-no-class-literals`| Disallow class expressions || function |`arkts-no-nested-funcs`| Local function declaration is prohibited || function |`arkts-no-generators`| Disable generators and`yield` |
| function |`arkts-no-standalone-this`| Prohibited in independent functions`this` |
| function |`arkts-no-implicit-return-types`| Return type inference restricted || function |`arkts-no-definite-assignment`| Definite assignment assertions on ordinary variables are warning-level restrictions || function |`arkts-no-func-props`| Declaring properties on function objects is prohibited || Object |`arkts-no-untyped-obj-literals`| Object literals must have an explicit context type || Object |`arkts-no-noninferrable-arr-literals`| Array literal elements must be inferred || Object |`arkts-no-obj-literals-as-types`| Object literal types are prohibited || Object |`arkts-no-ambiguity-obj-literal`| disallow ambiguous object literals || Object |`arkts-no-classes-as-obj`| Classes as object values ​​fall under warning level restrictions || Properties |`arkts-identifiers-as-prop-names`| Attribute name should be an identifier || Properties |`arkts-no-props-by-index`| Ordinary fields are prohibited from accessing by index || Properties |`arkts-no-indexed-signatures`| Disable index signatures || Properties |`arkts-no-method-reassignment`| Disable method rebinding || Properties |`arkts-no-multiple-static-blocks`| A class only allows at most one static code block || Properties |`arkts-no-spread`| Unfolding only allows arrays or array-derived types || Properties |`arkts-no-prototype-assignment`| ban prototype chain or`prototype`Assignment || namespace |`arkts-no-ns-as-obj`| Namespace cannot be used as an object value || namespace |`arkts-no-ns-statements`| Non-declarative statements are prohibited in namespaces || Operator |`arkts-no-delete`| Prohibited`delete` |
| Operator |`arkts-no-in`| Prohibited`in` |
| Operator |`arkts-instanceof-ref-types` | `instanceof`Only partially supported || Operator |`arkts-no-polymorphic-unops`| Unary arithmetic only supports numeric types || Operator |`arkts-no-comma-outside-loops`| The comma operator is only allowed in`for`Looping || Operator |`arkts-no-is`| Prohibited`is`type predicate || Type |`arkts-no-any-unknown`| Prohibited`any` / `unknown` |
| Type |`arkts-no-symbol`| Restrictions`symbol`and`Symbol` |
| Type |`arkts-no-typing-with-this`| Prohibited`this`Type || Type |`arkts-no-conditional-types`| Prohibition condition type || Type |`arkts-no-mapped-types`| Forbidden mapping types || Type |`arkts-no-intersection-types`| Cross type prohibited || Type |`arkts-no-aliases-by-index`| Disallowed index access types || Type |`arkts-no-call-signatures`| Disable calling signature || Type |`arkts-no-ctor-signatures-type`| Disallow construction signatures in type literals || Type |`arkts-no-ctor-signatures-iface`| Disable interface construction signature || Type |`arkts-no-ctor-signatures-funcs`| Disallow constructor type nodes || Type |`arkts-no-utility-types`| Limit standard tool types || Type |`arkts-no-structural-typing`| Structure type compatibility is prohibited || Type |`arkts-no-inferred-generic-params`| Restrict generic parameter inference || Type |`arkts-strict-typing`| Enforce strict type checking || Assertion |`arkts-as-casts`| Accept only`as T` |
| Assertion |`arkts-no-as-const`| Prohibited`as const` |
| Assertion |`arkts-sendable-as-expr`| Disable assertion of non-sendable data as sendable || Module |`arkts-no-misplaced-imports` | `import`Must be preceded || Module |`arkts-no-require`| Prohibited`require`/`import =` |
| Module |`arkts-no-export-assignment`| Prohibited`export =` |
| Module |`arkts-no-import-assertions`| prohibit import assertion || Module |`arkts-no-special-imports`| No special`import type`form || Module |`arkts-no-special-exports`| No special`export type`form || Module |`arkts-no-ambient-decls`| Disable shorthand ambient module || Module |`arkts-no-module-wildcards`| Disable module name wildcards || Module |`arkts-no-umd`| UMD prohibited || Module |`arkts-no-ts-deps`| Reliance on TypeScript code is prohibited || Module |`arkts-no-ts-import-ets`| TS only allows sendable classes and interfaces when importing ETS || Module |`arkts-no-ts-sendable-type-inheritance`| The use of sendable types in inheritance or implementation clauses is prohibited in TS || Module |`arkts-no-dts-sendable-type-export`| Export of sendable classes and interfaces is prohibited in sdk ts files || Module |`arkts-no-ts-re-export-ets`| Re-export of ETS entities is prohibited in TS || Module |`arkts-no-namespace-import-in-ts-import-ets`| TS disable namespace import when importing from ETS || Standard Library |`arkts-limited-stdlib`| Limit dynamic standard library API || Standard Library |`arkts-limited-esobj`| Restrictions`ESObject` |
| function object |`arkts-no-func-apply-call`| Prohibited`Function.apply` / `call` |
| function object |`arkts-no-func-bind`| Restrictions`Function.bind` |
| JSX | `arkts-no-jsx`| Disable JSX || Meta attributes |`arkts-no-new-target`| Prohibited`new.target` |
| Type checking |`arkts-strict-typing-required`| Prohibited`@ts-ignore`Isoinhibition Notes || Statement |`arkts-no-destruct-assignment`| Destructuring assignment is prohibited || Statement |`arkts-no-for-in`| Prohibited`for...in` |
| Statement |`arkts-no-with`| Prohibited`with` |
| Statement |`arkts-no-types-in-catch`| Prohibited`catch`Clause explicit type annotation || Statement |`arkts-limited-throw` | `throw`Cannot throw arbitrary values ​​|| enum |`arkts-no-enum-mixed-types`| Initialization of enumeration members must be compile-time expressions of the same type || enum |`arkts-no-enum-merging`| Disable enumeration merging || Inheritance |`arkts-implements-only-iface` | `implements`Only interfaces can be written in the clause || Inheritance |`arkts-extends-only-class`| Interfaces cannot inherit from classes || Inheritance |`arkts-no-extend-same-prop`| Incompatible members with the same name are prohibited during multiple interface inheritance || Sendable | `arkts-sendable-class-inheritance`| sendable inheritance restricted || Sendable | `arkts-sendable-prop-types`| sendable attribute type must be sendable || Sendable | `arkts-sendable-definite-assignment`| Forbidden in sendable class`!` |
| Sendable | `arkts-sendable-generic-types`| sendable Generic arguments must be sendable || Sendable | `arkts-sendable-imported-variables`| The sendable class only allows capturing imported variables || Sendable | `arkts-sendable-class-decorator`| sendable classes only allow`@Sendable` |
| Sendable | `arkts-sendable-obj-init`| Sendable types prohibit literal initialization || Sendable | `arkts-sendable-computed-prop-name`| The sendable type prohibits calculation of property names || Sendable | `arkts-sendable-decorator-limited` | `@Sendable`Can only be used with class/function/typeAlias ​​|| Sendable | `arkts-sendable-beta-compatible`| sendable function/typeAlias ​​is not available before API 12 beta3 || Sendable function |`arkts-sendable-function-imported-variables`| sendable functions only allow capturing imported variables || Sendable function |`arkts-sendable-function-decorator`| sendable functions only allow`@Sendable` |
| Sendable function |`arkts-sendable-function-overload-decorator`| Every declaration of a sendable overloaded function must be explicit`@Sendable` |
| Sendable function |`arkts-sendable-function-property`| Restrict sendable function attribute access || Sendable function |`arkts-sendable-function-as-expr`| Disable assertion of non-sendable functions as sendable type alias || Sendable alias |`arkts-sendable-typealias-decorator`| sendable type alias only allowed`@Sendable` |
| Sendable alias |`arkts-sendable-typeAlias-declaration`| sendable type alias can only be function type || Sendable assignment |`arkts-sendable-function-assignment`| sendable function type assignment is restricted || shared module | `arkts-no-side-effects-imports`| Shared modules prohibit side-effect imports || shared module | `arkts-shared-module-exports`| Shared modules can only export shareable entities || shared module | `arkts-shared-module-no-wildcard-export`| Shared modules are prohibited`export *` |
| Concurrency |`arkts-taskpool-concurrent-function-args`| taskpool parameter must be`@Concurrent`Ordinary functions |
## 13. Appendix B: Quick check on grammatical construction
- Declarations: `var`, destructuring declarations, parameter properties, local functions, class expressions, function expressions, and duplicate names. - Type expressions: `any`, `unknown`, `symbol`, `this` types, conditional types, mapped types, intersection types, indexed-access types, object-literal types, call signatures, constructor signatures, and restricted utility types. - Operators: `delete`, `in`, partial `instanceof`, unary `+/-/~`, type-query `typeof`, and `is`.
- Statements: `for...in`, `with`, restricted `throw`, and typed `catch`.
- Modules: leading `import`; prohibited `require`, `import =`, `export =`, import assertions, ambient modules, and UMD.
- Object model: Attribute names must be statically decipherable, index access is limited, prototype rewriting is limited, and reflective invocation of function objects is limited.- Concurrency and sharing:`Sendable`, shared module, taskpool concurrent function.
## 14. Appendix C: Samples and Reproduction Methods
The following examples can be used to reproduce the single-file scenario in which the "sample verification" conclusion has been given in this article:
| sample file | expected | represents a diagnosis or result || --- | --- | --- |
| `examples/allow_typed_object_literal_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/allow_array_element_access_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/allow_typeof_expression_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/allow_arrow_function_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/allow_sendable_class_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/allow_record_numeric_key_ok.ets`| Allow |`Syntax Check: OK` |
| `examples/forbid_var_fail.ets`| Report an error |`arkts-no-var` |
| `examples/forbid_destructuring_decl_fail.ets`| Report an error |`arkts-no-destruct-decls` |
| `examples/forbid_object_literal_no_context_fail.ets`| Report an error |`arkts-no-untyped-obj-literals` |
| `examples/forbid_object_index_access_fail.ets`| Report an error |`arkts-no-props-by-index` |
| `examples/forbid_type_query_fail.ets`| Report an error |`arkts-no-type-query` |
| `examples/forbid_nested_function_fail.ets`| Report an error |`arkts-no-nested-funcs` |
| `examples/forbid_as_const_fail.ets`| Report an error |`arkts-no-as-const` |
| `examples/forbid_delete_fail.ets`| Report an error |`arkts-no-delete` |
| `examples/forbid_in_fail.ets`| Report an error |`arkts-no-in` |
| `examples/forbid_sendable_missing_field_type_fail.ets`| Report an error |`arkts-sendable-explicit-field-type` |
| `examples/warn_global_this_warn.ets` | warning | `arkts-no-globalthis`, overall still`Syntax Check: OK` |
| `examples/warn_function_bind_warn.ets`| warning | hit`arkts-no-func-bind`, and may be accompanied by other errors |
General reproduction command:
```bash
node ./arkts-cli/bin/arkts-cli.js \
  --input third_party/typescript/src/linter/ArkTSLinter_1_1/examples/<file>.ets \
  --out-dir <tmp-dir>
```

illustrate:
- `arkts-cli`Currently only covers pure non-UI`.ets`Single file scenario.- Multi-file module, shared module and TS/ETS interoperability rules are mainly based on the rule source code and are not within the scope of single-file reproduction in this appendix.
## 15. Conclusion
If you only look at the language boundaries reflected by this set of linters, the core of ArkTS is not to be "as compatible as possible with TypeScript", but to retain a data model in the TypeScript syntax shell that is more controllable, static, and more suitable for concurrency and cross-module sharing.
It encourages:
- explicit type- Clarify inheritance relationship- Class and interface modeling- Conservative object usage- Controlled concurrent data flow
This article is intended to be used as a summary of rules, an index of examples, and a quick reference to engineering practices under current implementations; it should not replace the official language specification, SDK documentation, or implementation notes for future releases.
It compresses:
- Dynamic object shaping- Structural types are freely compatible- runtime reflection- Turn off the type system with comments- Omit specifications based on complex inferences
If further refinement continues, the most valuable next step is not to continue to expand the prohibited items, but to make a "list of recommended forward writing methods in ArkTS" and list the acceptable functions, classes, objects, modules and`Sendable`Design patterns are sorted out forward.

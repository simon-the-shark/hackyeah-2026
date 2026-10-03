## 3. Mixing V1/V2 State Management

AI often mixes V1 and V2 decorators in the same component.

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| `@ComponentV2` with `@State` | @ComponentV2 can use only V2 decorators (@Local/@Param, etc.) | Rule 1: custom component constraints; Rule 5: V1/V2 mixing constraints |
| `@Component` with `@Local` | @Component can use only V1 decorators | Rule 1: custom component constraints; Rule 5: V1/V2 mixing constraints |
| `@State` decorating a property in an `@ObservedV2` class | V1 decorators cannot be used with @ObservedV2 | Rule 5: V1/V2 mixing constraints |
| Passing values across V1/V2 without calling `enableV2Compatibility` | V1→V2 or V2→V1 values require a compatibility bridge | Rule 5: V1/V2 mixing constraints |

**Root cause**: AI does not understand the strict boundary between V1 and V2, producing mixed code that looks reasonable but fails to compile.

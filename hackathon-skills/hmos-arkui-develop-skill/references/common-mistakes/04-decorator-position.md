## 4. Decorators Used in the Wrong Position

AI often confuses what decorators should decorate.

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| `@State` decorating a component parameter | @State decorates only internal component variables; use @Prop/@Param for parameters | Rule 3: V1 state decorators; Rule 4: V2 state decorators |
| `@Local` decorating a component parameter | @Local is for internal component initialization; use @Param for parameters | Rule 4: V2 state decorators |
| `@Prop` decorating an internal component variable | @Prop decorates only component parameters | Rule 3: V1 state decorators |
| `@Param` decorating an internal component variable | @Param decorates only component parameters | Rule 4: V2 state decorators |
| Local initialization of `@Link`: `@Link count: number = 0` | @Link forbids local initialization and must be supplied externally | Rule 3: V1 state decorators |
| Local initialization of `@ObjectLink` | @ObjectLink forbids local initialization | Rule 3: V1 state decorators |
| `@ObjectLink` decorating a primitive type | @ObjectLink does not support number/string/boolean | Rule 3: V1 state decorators |
| External initialization of `@Consume` | @Consume cannot be initialized externally | Rule 3: V1 state decorators |

**Root cause**: AI treats decorators as generic "reactive markers" and does not understand initialization direction or positional constraints.

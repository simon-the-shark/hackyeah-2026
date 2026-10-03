## 10. Omitted State Variable Types

| ❌ Common AI error | ✅ Correct form | Rule section |
|--------------|-----------|---------|
| `@State count = 0` | `@State count: number = 0` | Rule 3: V1 state decorators |
| `@Local name = ''` | `@Local name: string = ''` | Rule 4: V2 state decorators |
| `@State list = []` | `@State list: Array<string> = []` | Rule 3: V1 state decorators |

**Root cause**: AI tends to omit type annotations, but ArkUI decorators require every state variable to declare a type.

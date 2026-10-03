## 2. build() Function Constraints

| Rule | Description |
|------|------|
| @Entry root must be a container | The build() root of an @Entry component is **required and unique**, **must be a container**, and ForEach **cannot be the root** |
| @Component root may be non-container | The build() root of an @Component is **required and unique** and may be non-container, but ForEach **cannot be the root** |
| No local declarations | **Do not declare local variables** in build() (for example, `let num = 1`) |
| No console.info | **Do not use** console.info directly in build() (it is allowed inside methods or functions) |
| No local scopes | **Do not create local scopes** `{ ... }` in build() |
| No calls to non-@Builder methods | **Do not call methods without @Builder** in build(); system component parameters may use TS method return values |
| No switch syntax | **Do not use switch** in build(); use if |
| No ternary expressions | **Do not use ternary expressions** (`? :`) in build(); use if components |
| **Do not mutate state directly** | **Do not mutate state variables** in build() or @Builder methods because this can cause render loops. This includes mutations in @Builder/@Extend/@Styles, calls to state-changing functions while computing parameters, and calling sort() before filter() on the current array |
| sort/filter trap | sort() mutates the original array in `this.arr.sort().filter(...)`; use `this.arr.filter(...).sort()` |

## Common Errors

- **`this.counter += 1` mutates state in build()**: this causes a render loop; put state changes in event callbacks
- **`this.arr.sort().filter(...)`**: sort() mutates the original array and triggers a state change; use `this.arr.filter(...).sort()`

---

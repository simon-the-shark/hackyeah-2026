## 5. Invalid Operations Inside build()

AI often writes code in build() that does not belong there.

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| `let temp = compute()` declares a local variable | Local variables cannot be declared in build() | Rule 2: build() constraints |
| `console.info(...)` logs output | console.info is not allowed in build() | Rule 2: build() constraints |
| `switch (type) { case ... }` | switch is not allowed in build(); use if instead | Rule 2: build() constraints |
| `flag ? textA : textB` ternary expression | Ternary expressions are not allowed in build(); use if instead | Rule 2: build() constraints |
| Calling a non-@Builder method to generate UI | build() may call only methods decorated with @Builder | Rule 2: build() constraints |
| `this.counter += 1` directly changes a state variable | Changing state in build() causes recursive rendering | Rule 2: build() constraints |
| `this.arr.sort().filter(...)` | sort() mutates the original array, causing recursive rendering on state change | Rule 2: build() constraints |

**Root cause**: AI writes build() like an ordinary function and does not understand declarative UI rendering constraints.

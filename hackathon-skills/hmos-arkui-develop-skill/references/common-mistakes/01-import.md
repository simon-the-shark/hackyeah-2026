## 1. Import Paths and Module Errors

One of the most common AI errors, with a very high occurrence rate.

| ❌ Common AI error | ✅ Correct form | Rule section |
|--------------|-----------|---------|
| `import router from '@ohos.router'` | `import { router } from '@kit.ArkUI'` | Rule 20: module import constraints |
| `import promptAction from '@ohos.promptAction'` | `import { PromptAction } from '@kit.ArkUI'` or through UIContext | Rule 20: module import constraints |
| Inventing a nonexistent import path or symbol | Confirm through retrieval; do not invent from memory | Rule 20: module import constraints |

**Root cause**: AI training data contains legacy `@ohos.*` imports, or guesses kit ownership from memory. Always retrieve and confirm import paths before generating code.

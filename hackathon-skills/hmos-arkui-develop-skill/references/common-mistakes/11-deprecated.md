## 11. Use of Deprecated APIs

| ❌ Common AI error | ✅ Correct replacement | Rule section |
|--------------|-----------|---------|
| `CustomDialogController` | `promptAction.openCustomDialog` | Rule 10: dialog and sheet constraints |
| `pageTransition` | Navigation transition / Modal transition | Rule 8: animation constraints |
| `@ohos.*` imports | `@kit.*` imports | Rule 20: module import constraints |
| `@Component` + `static {}` static block | Static blocks do not execute in V1 (warning from API 22) | Rule 1: custom component constraints |

**Root cause**: AI training data contains legacy examples and does not know that these APIs are deprecated.

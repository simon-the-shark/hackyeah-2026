## 23. Deprecated Interface Constraints

### 23.1 Replacement Rules
| Rule | Description |
|------|-------------|
| **Do not use CustomDialogController** | Not recommended from API version 12; use `promptAction.openCustomDialog` |
| **Do not use pageTransition** | Use Navigation or Modal transitions |
| **Do not import `@ohos.*` paths** | Legacy paths are deprecated; use `@kit.*` |
| **Do not use `static {}` in @Component** | V1 static blocks do not execute (warning from API 22) |

### Common Errors
| Wrong | Correct replacement |
|-------|---------------------|
| `CustomDialogController` | `promptAction.openCustomDialog` |
| `pageTransition` | Navigation / Modal transition |
| `@Component` + `static {}` | Use `@ComponentV2` or remove the static block |

---

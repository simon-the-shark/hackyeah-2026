## 20. Module Import Constraints

### 20.1 Import Rules
| Rule | Description |
|------|-------------|
| **Do not import `@ohos.*` paths** | They are legacy paths; **use `@kit.*`** |
| **Do not invent imports from memory** | Module paths and exports must come from search results |
| **Do not omit required imports** | Every external type/function/enum needs a declaration |
| **Do not import unused modules** | Remove unused imports |
| **Do not import from the wrong kit** | Each API belongs to one kit |

### 20.2 Kit Import Quick Reference
Use the following mapping to choose imports from the functionality used by the code.

#### @kit.ArkUI (core UI kit)
`UIContext`, `window`, `BuilderNode`, `FrameNode`, `NodeController`, `ComponentContent`, `NodeContent`, `NodeRenderState`, `LengthMetrics`, `ColorMetrics`, `matrix4`, `curves`, `router`, `PromptAction`, `ImageModifier`, `KeyboardAvoidMode`, `Font`, `uiObserver`, `UIUtils`, `Theme`, `ThemeControl`, `CustomColors`, `CustomTheme`, `CircleShape`, `RectShape`, `EllipseShape`, `PathShape`, `Binding`

#### @kit.AbilityKit (application model kit)
`UIAbility`, `AbilityConstant`, `Want`, `common`, `Configuration`, `ConfigurationConstant`, `bundleManager`

#### @kit.BasicServicesKit (basic services kit)
`BusinessError`, `request`, `commonEventManager`

#### Other kits
| Kit | Symbols | Use |
|-----|---------|-----|
| `@kit.ArkData` | `unifiedDataChannel`, `uniformTypeDescriptor` | Drag data transfer (UTD) |
| `@kit.ImageKit` | `image` | Image processing |
| `@kit.InputKit` | `pointer`, `IntentionCode` | Cursor and input devices |
| `@kit.ArkGraphics2D` | `uiEffect` | Blur and graphics |
| `@kit.CoreFileKit` | `fileIo` | File I/O |
| `@kit.ArkTS` | `buffer` | Binary buffers |
| `@kit.PerformanceAnalysisKit` | `hilog` | Logging |

### 20.3 Common Import Errors
| Wrong | Correct |
|-------|---------|
| `import router from '@ohos.router'` | `import { router } from '@kit.ArkUI'` |
| `import window from '@ohos.window'` | `import { window } from '@kit.ArkUI'` |
| `import promptAction from '@ohos.promptAction'` | `import { PromptAction } from '@kit.ArkUI'` |
| `import { BusinessError } from '@ohos.base'` | `import { BusinessError } from '@kit.BasicServicesKit'` |
| `import { UIAbility } from '@kit.ArkUI'` | `import { UIAbility } from '@kit.AbilityKit'` |
| `import { hilog } from '@kit.ArkUI'` | `import { hilog } from '@kit.PerformanceAnalysisKit'` |
| `import { image } from '@kit.ArkUI'` | `import { image } from '@kit.ImageKit'` |

### 20.4 Built-ins That Do Not Need Imports
ArkTS global built-ins include basic components, common attributes, basic enums, decorators, global UI methods, dialog components, and `LocalStorage`/`PersistentStorage`/`AppStorage`.

## Common Errors
- Inventing import paths or exports from memory.
- Omitting an external type/function/enum import.
- Importing an unused module.
- Root cause: legacy `@ohos.*` examples remain common in training data; prefer `@kit.*`.

---

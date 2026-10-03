## 19. UIContext Replacements for Global Interfaces

In the Stage model, one ArkTS engine can run multiple ArkUI instances. Global interfaces infer the current UI context from the call chain, and asynchronous or non-UI interfaces can break tracking. **Do not call the following global interfaces directly; obtain replacements through `UIContext`.**

> Obtain UIContext with `this.getUIContext()` inside a custom component or `windowClass.getUIContext()` through a window object.

### Direct global interfaces and UIContext replacements
| Direct global interface | UIContext replacement | Description |
|---|---|---|
| `@ohos.animator` | `uiContext.createAnimator()` | Custom animation controller |
| `@ohos.arkui.componentSnapshot` | `uiContext.getComponentSnapshot()` | Component snapshot |
| `@ohos.arkui.componentUtils` | `uiContext.getComponentUtils()` | Component utilities |
| `@ohos.arkui.dragController` | `uiContext.getDragController()` | Drag controller |
| `@ohos.arkui.inspector` | `uiContext.getUIInspector()` | Component layout callback |
| `@ohos.arkui.observer` | `uiContext.getUIObserver()` | Passive observation |
| `@ohos.font` | `uiContext.getFont()` | Custom fonts |
| `@ohos.measure` | `uiContext.getMeasureUtil()` | Text measurement |
| `@ohos.mediaquery` | `uiContext.getMediaQuery()` | Media queries |
| `@ohos.promptAction` | `uiContext.getPromptAction()` | Dialogs and prompts |
| `@ohos.router` | `uiContext.getRouter()` | Page routing |
| `AlertDialog` | `uiContext.showAlertDialog()` | Alert dialog |
| `ActionSheet` | `uiContext.showActionSheet()` | List selection dialog |
| `DatePickerDialog` | `uiContext.showDatePickerDialog()` | Date picker dialog |
| `TimePickerDialog` | `uiContext.showTimePickerDialog()` | Time picker dialog |
| `TextPickerDialog` | `uiContext.showTextPickerDialog()` | Text picker dialog |
| `ContextMenu` | `uiContext.getContextMenuController()` | Menu control |
| `vp2px` / `px2vp` / `fp2px` / `px2fp` / `lpx2px` / `px2lpx` | `uiContext.vp2px()` etc. | Pixel conversion |
| `focusControl` | `uiContext.getFocusController()` | Focus control |
| `cursorControl` | `uiContext.getCursorControl()` | Cursor control |
| `getContext` | `uiContext.getHostContext()` | Current Ability context |
| `LocalStorage.getShared` | `uiContext.getSharedLocalStorage()` | Ability-shared storage |
| `animateTo` | `uiContext.animateTo()` | Explicit animation |
| `CalendarPickerDialog` | `uiContext.runScopedTask(() => CalendarPickerDialog.show())` | Calendar picker |
| `animateToImmediately` | Unsupported | No UIContext replacement |

### Correct usage
```ts
this.getUIContext().getPromptAction().showToast({ message: 'Hello' });
this.getUIContext().getRouter().pushUrl({ url: 'pages/Second' });
this.getUIContext().showAlertDialog({ title: 'Title', message: 'Content' });
let px = this.getUIContext().vp2px(20);
```

## Common Errors
- Direct global calls such as `AlertDialog.show()`, `router.pushUrl()`, `promptAction.showToast()`, `vp2px()`, and `animateTo()` can fail in multi-instance scenarios.
- Root cause: training examples frequently use global calls even though they can lose UI context tracking.

---

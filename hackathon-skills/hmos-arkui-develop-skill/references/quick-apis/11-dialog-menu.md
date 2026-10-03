## 11. Dialogs, Menus, and Modals


> **Component index**: `Dialog APIs`, `Menus`, `Popup`, `Modals`

### Dialog APIs

| API | Signature | Core parameters |
|-----|------|---------|
| **AlertDialog** | `AlertDialog.show(options)` | `{title?, message, alignment?, primaryButton?, secondaryButton?, buttons?[]}` |
| **ActionSheet** | `ActionSheet.show(options)` | `{title, message?, confirm, cancel?, sheets: SheetInfo[]}` |
| **CustomDialog** | `new CustomDialogController(options)` | `{builder, alignment?, autoCancel?, customStyle?}`; call `.open()` `.close()` |
| **Toast** | `promptAction.showToast({message, duration?, bottom?})` | `{message, duration?, bottom?, showMode?}` |
| **DatePickerDialog** | `DatePickerDialog.show(options)` | `{start?, end?, selected?, lunar?, onDateAccept?: (value: Date) => void, onDateChange?: (value: Date) => void}` |
| **TimePickerDialog** | `TimePickerDialog.show(options)` | `{selected?, useMilitaryTime?, onAccept?: (value: TimePickerResult) => void}` |
| **TextPickerDialog** | `TextPickerDialog.show(options)` | `{range, selected?, onAccept?: (value: TextPickerResult) => void}` |
| **CalendarPickerDialog** | `CalendarPickerDialog.show(options)` | `{selected?, onAccept?: (value: Date) => void, onCancel?, onChange?: (value: Date) => void}` |

**AlertDialog button structure:**

> **Button structure**: `{ value: string, action?: () => void, enabled?: boolean, defaultFocus?: boolean, style?: DialogButtonStyle }`
> ⚠️ Use `value`, not `text` (AI often writes text incorrectly).

- Each element in AlertDialog's primaryButton/secondaryButton and buttons array uses **`value`**, not `text`: `{ value: 'OK', action: () => {} }`
- ActionSheet's option list uses **`sheets`**, not `buttons`; each option uses **`title`**, not `text`: `{ title: 'Option', icon?, action }`
- The confirm field also uses the `{ value, action }` format.

### CustomDialogController Usage (Two Steps)

Step 1: Define the dialog component with the @CustomDialog decorator
```typescript
@CustomDialog
struct MyDialog {
  controller: CustomDialogController
  
  build() {
    Column() {
      Text('Dialog content')
      Button('Close')
        .onClick(() => { this.controller.close() })
    }
  }
}
```

Step 2: Create and invoke the controller in the parent component
```typescript
@Component
struct Parent {
  dialogController: CustomDialogController = new CustomDialogController({
    builder: MyDialog(),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: false
  })
  
  build() {
    Button('Open dialog')
      .onClick(() => { this.dialogController.open() })
  }
}
```

> **Note**: CustomDialogController only works when defined and assigned inside an @Component/@ComponentV2 struct. The controller must be declared as a property in the @CustomDialog component before close() can be called.

### Menus

| Component/Method | Signature | Core parameters |
|-----------|------|---------|
| **MenuItem** | `MenuItem(options)` | `{value, icon?, startIcon?, endIcon?, selected?, onChange?}` |
| **MenuItemGroup** | `MenuItemGroup(options)` | `{header?, footer?}` |
| **.bindMenu** | `.bindMenu(content: MenuElement[] \| CustomBuilder)` | Bind a menu |
| **.bindContextMenu** | `.bindContextMenu(content, responseType)` | Context/long-press menu; responseType: `ResponseType.LongPress` / `ResponseType.RightClick` |

### Popup

| Method | Signature | Core parameters |
|------|------|---------|
| **.bindPopup** | `.bindPopup(show: boolean, options)` | `{message, placement?, offset?, showInSubWindow?, mask?, onStateChange?}` |

> **bindPopup callback note:** The `onStateChange` callback parameter is an **object**, `{ isVisible: boolean }`, not a raw boolean. Correct usage: `onStateChange: (event: PopupStateEvent) => { this.show = event.isVisible }`

### Modals

| Method | Signature | Core parameters |
|------|------|---------|
| **.bindSheet** | `.bindSheet($$isShow, builder, options?)` | options: `{detents?, height?, preferType?, dragBar?, backgroundColor?, blurStyle?, title?, showInSubWindow?, enableOutsideInteractive?, onWillDismiss?, onWillAppear?, onAppear?, onWillDisappear?, onDisappear?}`. Note: there is no `sheetSize` field; use `detents` or `height`. |
| **.bindContentCover** | `.bindContentCover(isShow, builder, options?)` | `{modalTransition?}` |

> **⚠️ The $$ two-way binding is required**: the first argument must use `$$this.showXxx`, not `this.showXxx`. The panel closes when `showXxx = false` only with $$ binding.

---

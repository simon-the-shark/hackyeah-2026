## 10. Dialog and Sheet Constraints

| Rule | Description |
|------|-------------|
| Multiple dialogs | Stack newest first and dismiss from top to bottom |
| System dialogs block custom dialogs | Non-system dialog APIs are blocked while a system dialog is visible |
| Avoid background dialogs | Do not show dialogs while the app is not foregrounded |
| bindSheet onWillDismiss | Every close action must call `dismiss()` |
| bindSheet UIExtension limit | A UIExtension inside a sheet cannot start another sheet/dialog |
| CustomDialogController | Not recommended from API version 12; use promptAction.openCustomDialog |
| AlertDialog buttons | Use `value` + `action`; there is no `text` field |
| bindSheet height | Use `SheetSize.MEDIUM` or `SheetSize.LARGE`; `HALF` does not exist |

### AlertDialog.show Minimum Template
The buttons fields are `value` and `action`, and both are required.

### bindSheet Minimum Template
Use `SheetSize.MEDIUM` for half screen or `SheetSize.LARGE` for near full screen.

---

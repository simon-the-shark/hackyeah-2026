## 2. Global APIs Not Called Through UIContext

AI tends to use global APIs directly and ignore the UIContext requirement.

| ❌ Common AI error | ✅ Correct form | Rule section |
|--------------|-----------|---------|
| `AlertDialog.show({ ... })` | `this.getUIContext().showAlertDialog({ ... })` | Rule 19: replace global APIs with UIContext |
| `router.pushUrl({ url: '...' })` | `this.getUIContext().getRouter().pushUrl({ url: '...' })` | Rule 19: replace global APIs with UIContext |
| `promptAction.showToast({ ... })` | `this.getUIContext().getPromptAction().showToast({ ... })` | Rule 19: replace global APIs with UIContext |
| `let px = vp2px(20)` | `let px = this.getUIContext().vp2px(20)` | Rule 19: replace global APIs with UIContext |
| `animateTo({ ... }, () => { ... })` | `this.getUIContext().animateTo({ ... }, () => { ... })` | Rule 19: replace global APIs with UIContext |

**Root cause**: AI training data contains many examples that call global APIs directly. They may be syntactically valid but fail in multi-instance scenarios.

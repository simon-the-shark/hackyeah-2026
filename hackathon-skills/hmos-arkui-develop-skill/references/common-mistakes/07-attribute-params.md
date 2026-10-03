## 7. Attribute and API Parameter Misuse

One of the easiest errors for AI to make: guessing parameter names, types, order, or enum values from memory instead of checking the documentation.

### 7.1 Invented or Confused Parameter Names

| ❌ Common AI error | ✅ Correct form | Explanation |
|--------------|-----------|------|
| `.backgroundColor('#ff0000')` written as `.bgColor('#ff0000')` | `.backgroundColor('#ff0000')` | Invented a nonexistent property name |
| `.onClick((event: ClickEvent) => ...)` written as `.onClick((event: GestureEvent) => ...)` | Parameter type is `ClickEvent` | Confused the event callback parameter type |
| `.borderRadius(8)` written as `.radius(8)` | `.borderRadius(8)` | Used a nonexistent abbreviation |
| `.fontSize(16)` written as `.textSize(16)` | `.fontSize(16)` | Invented a nonexistent property name |
| `List({ space: 10 })` written as `List({ gap: 10 })` | `space` parameter | Confused the parameter name |
| `Text('').fontColor(Color.Red)` written as `Text('').textColor(Color.Red)` | `.fontColor()` | Invented a nonexistent property name |

### 7.2 Invalid Enum Values

| ❌ Common AI error | ✅ Correct form | Explanation |
|--------------|-----------|------|
| `.textAlign('center')` | `.textAlign(TextAlign.Center)` | Replaced an enum value with a string |
| `.flexAlign('start')` | `.flexAlign(FlexAlign.Start)` | Incorrect enum-value capitalization |
| `.fontWeight('bold')` | `.fontWeight(FontWeight.Bold)` | Replaced an enum value with a string |
| `.displayMode(ButtonMode.NORMAL)` | Use another approach when `ButtonMode` does not exist | Invented a nonexistent enum |

### 7.3 Invalid Parameter Types and Order

| ❌ Common AI error | ✅ Correct form | Explanation |
|--------------|-----------|------|
| `.margin(10, 20, 10, 20)` | `.margin({ top: 10, right: 20, bottom: 10, left: 20 })` | Invalid four-value margin form |
| `.padding(10, 20)` | `.padding({ top: 10, right: 20 })` | padding does not support the multi-argument shorthand |
| `.width('100%')` written as `.width('match_parent')` | `.width('100%')` | Borrowed Android syntax |
| `.height('wrap_content')` | `.height('auto')` or omit it | Borrowed Android syntax |
| `animateTo({ duration: 300, curve: 'ease' })` | `animateTo({ duration: 300, curve: Curve.Ease })` | curve must be an enum |

### 7.4 Attributes Assigned to the Wrong Component

| ❌ Common AI error | ✅ Correct form | Explanation |
|--------------|-----------|------|
| Use `.textOverflow()` on `Image` | `.textOverflow()` is supported only by `Text` | Attribute does not belong to this component |
| Use `.objectFit()` on `Text` | `.objectFit()` is supported only by `Image` and other media components | Attribute does not belong to this component |
| Set `.fontColor()` directly on `Button` | Set Button text through a child component or `ButtonStyle` | Button text styling works differently |
| Write private component attributes in `@Styles` | `@Styles` supports only common attributes (Rule 11: style and theme constraints) | @Styles restriction |

**Root cause**: AI guesses API signatures from memory without retrieval. ArkUI attribute names, parameter types, and enum values differ significantly from other frameworks (React Native, Flutter, Android) and are easy to confuse. When an attribute or parameter is uncertain, **the knowledge base must be consulted**.

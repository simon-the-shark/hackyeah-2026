## 4. Selector Components


> **Component index**: `DatePicker`, `TimePicker`, `TextPicker`, `PatternLock`, `Stepper / StepperItem quick reference`

### DatePicker

Date picker.

**Constructor:** `DatePicker(options?: DatePickerOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| start | Date | No | 1970-1-1 | Start date |
| end | Date | No | 2100-12-31 | End date |
| selected | Date | No | Current date | Selected date |
| lunar | boolean | No | false | Lunar calendar |

**Properties and methods:** `.lunar(boolean)`

**Events:** `.onDateChange(callback)` `.onDateAccept(callback)`

---

### TimePicker

Time picker.

**Constructor:** `TimePicker(options?: TimePickerOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| selected | Date | No | Current time | Selected time |
| useMilitaryTime | boolean | No | true | 24-hour format |

**Events:** `.onChange(callback)`

---

### TextPicker

Text picker.

**Constructor:** `TextPicker(options?: TextPickerOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| range | string[] \| Resource | No | — | Data range |
| selected | number | No | 0 | Selected index |
| value | string | No | — | Selected value |

**Properties and methods:** `.canLoop(boolean)` `.defaultPickerItemHeight(number)`

**Events:** `.onChange(callback)` `.onAccept(callback)`

---

### PatternLock

Pattern password lock.

**Constructor:** `PatternLock(options?: PatternLockOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| controller | PatternLockController | No | — | Controller |
| sideLength | number | No | 300vp | Side length |
| circleRadius | number | No | 14vp | Circle radius |
| regularColor | ResourceColor | No | #FF182431 | Regular color |
| selectedColor | ResourceColor | No | #FF182431 | Selected color |
| activeColor | ResourceColor | No | #FF182431 | Active color |
| pathColor | ResourceColor | No | #FF317AF7 | Path color |

**Properties and methods:** `.autoReset(boolean)` `.challengeResult(PatternLockChallengeResult)`

**Events:** `.onPatternComplete(callback: (input: number[]) => void)`

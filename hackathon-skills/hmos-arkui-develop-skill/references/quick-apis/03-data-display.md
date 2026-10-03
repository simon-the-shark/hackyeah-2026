## 3. Data Display Components


> **Component index**: `Gauge`, `DataPanel`, `QRCode`, `CalendarPicker / TextClock / TextTimer quick reference`

### Gauge

Gauge component.

**Constructor:** `Gauge(options: GaugeOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| value | number | Yes | — | Current value |
| min | number | No | 0 | Minimum value |
| max | number | No | 100 | Maximum value |

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .value | `.value(value: number)` | — | Current value |
| .startAngle | `.startAngle(value: number)` | 0 | Start angle |
| .endAngle | `.endAngle(value: number)` | 360 | End angle |
| .colors | `.colors(value: Array)` | — | Color segments |
| .strokeWidth | `.strokeWidth(value: Length)` | 4vp | Stroke width |
| .description | `.description(value: CustomBuilder)` | — | Description area |
| .trackShadow | `.trackShadow(value: ShadowOptions)` | — | Track shadow |
| .indicator | `.indicator(value: GaugeIndicatorOptions)` | — | Indicator |

---

### DataPanel

Data panel.

**Constructor:** `DataPanel(options: DataPanelOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| values | number[] | Yes | — | Data values (up to 9 items) |
| max | number | No | 100 | Maximum value |
| type | DataPanelType | No | Circle | Type (Line/Circle) |

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .closeEffect | `.closeEffect(value: boolean)` | false | Disable effects |
| .valueColors | `.valueColors(value: Array\<ResourceColor \| LinearGradient\>)` | — | Data colors |
| .trackBackgroundColor | `.trackBackgroundColor(value: ResourceColor)` | — | Track background color |
| .strokeWidth | `.strokeWidth(value: Length)` | 24vp | Stroke width |
| .trackShadow | `.trackShadow(value: ShadowOptions)` | — | Track shadow |

---

### QRCode

QR code component.

**Constructor:** `QRCode(value: string)`

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .color | `.color(value: ResourceColor)` | Black | QR code color |
| .backgroundColor | `.backgroundColor(value: ResourceColor)` | White | Background color |
| .contentOpacity | `.contentOpacity(value: number)` | 1.0 | Content opacity |

---

### CalendarPicker / TextClock / TextTimer Quick Reference

| Component | Constructor Signature | Core Methods | Core Events |
|------|---------|---------|---------|
| **CalendarPicker** | `CalendarPicker(options?: CalendarPickerOptions)` | `.selectedDate(Date)` `.edgeAlign(CalendarAlign)` `.startDate(Date)` `.endDate(Date)` | `.onDateChange(callback)` |
| **TextClock** | `TextClock(options?: {timeZoneOffset?, is24Hour?})` | `.format(string)` | `.onDateChange(callback)` |
| **TextTimer** | `TextTimer(options?: {isCountDown?, count?, controller?})` | `.format(string)` `.fontColor()` `.fontSize()` | `.onTimer(callback)` |

---

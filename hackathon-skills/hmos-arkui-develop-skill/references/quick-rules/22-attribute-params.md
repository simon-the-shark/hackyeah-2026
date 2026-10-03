## 22. Attribute and API Parameter Constraints

### 22.1 Attribute Naming
| Rule | Description |
|------|-------------|
| **Do not invent attributes** | Search the knowledge base when uncertain |
| **Do not use abbreviated attributes** | Use full names such as `.backgroundColor()`, `.borderRadius()`, and `.fontSize()` |
| **Match attributes to components** | `.textOverflow()` is for Text; `.objectFit()` is for Image and similar media components |
| **Set Button text style through children** | Button text does not directly support `.fontColor()` |
| **@Styles supports common attributes only** | Component-private attributes are unsupported |

### 22.2 Enum Values
Use enums rather than strings, preserve exact case, and search before using an uncertain enum.

### 22.3 Parameter Format
Use object syntax for margin/padding; pass Row/Column space to the constructor; center Stack with `alignContent`; do not use Flex space; do not borrow Android `match_parent`/`wrap_content`; use enum `Curve.Ease` for animateTo.

### 22.4 Component Constructors
Badge requires style; Badge count and value are exclusive; Select receives a SelectOption array; bindPopup requires show and options; WaterFlow has no controller; RichEditor requires one; overlay requires CustomBuilder; Scroll receives an instance; ListItemGroup has no divider attribute.

### 22.5 Callback Parameters
Use exact callback types: `ClickEvent`, `PlaybackInfo`, `PreparedInfo`, `PopupStateEvent`, and array access such as `result.index[0]`. `curves.springCurve` requires four parameters. AlertDialog uses `value`; ActionSheet uses `sheets`.

### 22.6 Resource Names
Do not guess system symbol names. Prefer verified hex colors when system colors are unavailable. `MediaQuery` uses an uppercase Q.

### 22.7 Global Types That Need No Import
`SwiperController`, `LazyForEach`, `ForEach`, and basic dialog callback types are globally available.

### 22.8 Nonexistent APIs
Do not use `WaterFlowController`, `StarStyle`, `SnapAlign`, `SnapPagination`, `curves.easeInOut()`, `keyframeAnimateTo()`, `LengthMetrics.vp()`, or `GradientDirection.BottomRight`.

### Common Errors
Use `.backgroundColor()`, `.borderRadius()`, `.fontSize()`, `.fontColor()`, `List({ space: 10 })`, typed enum values, `PlaybackInfo`/`PreparedInfo`, and verified resource names.

---

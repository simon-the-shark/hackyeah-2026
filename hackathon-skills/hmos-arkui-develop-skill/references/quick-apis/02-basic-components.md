# 2. Basic Components

This quick reference lists common ArkUI content, input, selection, and feedback components.

## Text Content

| Component | Constructor | Common APIs |
|---|---|---|
| `Text` | `Text(content?, options?)` | `fontColor`, `fontSize`, `fontWeight`, `fontStyle`, `fontFamily`, `textAlign`, `textOverflow`, `maxLines`, `lineHeight`, `textShadow`, `textSelectable`, `textCase`, and `onCopy`. |
| `Span` | `Span(value)` | `fontColor`, `fontSize`, `fontWeight`, `fontStyle`, `fontFamily`, `decoration`, `letterSpacing`, `textCase`, `lineHeight`, and `textShadow`. |
| `ImageSpan` | `ImageSpan(value)` | `verticalAlign`, `objectFit`, `alt`, `onComplete`, and `onError`. |
| `SymbolSpan` | `SymbolSpan(resource)` | Symbol color, size, weight, rendering strategy, and effect strategy. |
| `SymbolGlyph` | `SymbolGlyph(resource?)` | `symbolEffect`, color, size, and weight. |

## TextInput and TextArea

`TextInput(options?: TextInputOptions)` accepts `placeholder`, `text`, and `controller`. Common methods include `type`, `placeholderColor`, `placeholderFont`, `enterKeyType`, `caretColor`, `maxLength`, `fontColor`, `fontSize`, `fontStyle`, `fontWeight`, `fontFamily`, `showPasswordIcon`, `copyOption`, `textAlign`, `inputFilter`, `style`, `showUnderline`, `showCounter`, `enableKeyboardOnFocus`, and `selectionMenuHidden`.

Events include `onChange`, `onSubmit`, `onEditChange`, `onCopy`, `onCut`, and `onPaste`.

`TextArea(options?: TextAreaOptions)` exposes the same text styling and editing APIs, plus `barState` for its scroll bar.

## Button

`Button(options?: ButtonOptions)`, `Button(label?, options?)`, or `Button()` creates a button. Options include `type`, `stateEffect`, `buttonStyle`, `controlSize`, and `role`. Common methods are `fontSize`, `fontColor`, `fontWeight`, `fontStyle`, `fontFamily`, `labelStyle`, `contentModifier`, and `minFontScale` or `maxFontScale`.

## Image

`Image(src: PixelMap | ResourceStr | DrawableDescriptor)` displays an image. Common methods include `alt`, `objectFit`, `objectRepeat`, `interpolation`, `renderMode`, `sourceSize`, `fillColor`, `autoResize`, `syncLoad`, `colorFilter`, `autoPlay`, `resizable`, `copyOption`, `fitOriginalSize`, `matchTextDirection`, `imageMatrix`, and `enableAnalyzer`.

## Selection and Progress

| Component | Constructor | Main options and events |
|---|---|---|
| `Slider` | `Slider(options?)` | `value`, `min`, `max`, `step`, `style`, `direction`, `reverse`, colors, `showSteps`, `showTips`, and `onChange`. |
| `Toggle` | `Toggle(options)` | `type`, `isOn`, `selectedColor`, `switchPointColor`, `switchStyle`, and `onChange`. |
| `Radio` | `Radio({ value, group, ... })` | `checked`, `radioStyle`, and `onChange`. |
| `Checkbox` | `Checkbox(options?)` | `select`, `selectedColor`, `unselectedColor`, `mark`, `shape`, and `onChange`. |
| `CheckboxGroup` | `CheckboxGroup(options?)` | `selectAll`, colors, `mark`, `checkboxShape`, and `onChange`. |
| `Select` | `Select(options: SelectOption[])` | Options contain `value`, optional `icon`, and optional `symbolIcon`; use `selected`, `value`, styling methods, `space`, and `onSelect`. |

`Progress({ value, total?, type? })` displays a progress bar. Use `value`, `color`, `style`, and `backgroundColor` to configure it.

`Rating(options?)` supports `rating`, `indicator`, `stars`, `stepSize`, `starStyle`, and `onChange`.

`LoadingProgress()` supports `color` and `enableLoading`.

## Search and RichEditor

`Search(options?)` accepts `value`, `placeholder`, `icon`, and `controller`. Common methods include `searchButton`, placeholder and text styling, `searchIcon`, `cancelButton`, `caretStyle`, and `selectedBackgroundColor`. Events include `onSubmit`, `onChange`, `onCopy`, and `onCut`.

`RichEditor({ controller })` supports text styling and `onReady` and `onChange` events. Create a controller with `new RichEditorController()` when one is not supplied.

## Utility Components

| Component | Constructor | Main APIs |
|---|---|---|
| `Divider` | `Divider()` | `vertical`, `color`, `strokeWidth`, and `lineCap`. |
| `Blank` | `Blank(min?)` | `color`. |
| `Marquee` | `Marquee({ start, step?, loop?, fromStart?, src })` | Text styling, `allowScale`, and lifecycle events. |
| `ImageAnimator` | `ImageAnimator()` | `images`, `state`, `duration`, `reverse`, `fillMode`, `iterations`, and lifecycle events. |
| `ToolBarItem` | `ToolBarItem(options?)` | Optional `placement`, `content`, `icon`, and `action`. |
| `overlay` | `.overlay(builder, options?)` | Attaches a custom builder to a component. |

# Text component text presentation case Set

# Functional points typically use scene comparison

Text components Typical use scenario Core competencies Not applicable
|---------|------------|---------|-----------|
|Text article body display, trade names, description text | Multi-style only text presentation | User input, rich text editor |
| TextInput | Registration Form, Search Box, Login Input | Single Line Text Input+ Type Keyboard | Multiline Input, Rich Text Editor |
| RichEditor | Forum Poster, Document Editor | Rich Text Editor ( Style + Picture) | Read-only presentation |
|SymbolGlyph |SymbolGlyph Setup Icon, State Icon |System Level Icon + Activation | Custom Icon, Normal Picture |
| MutableStyledString | Search Results Highlight Highlight | Dynamic Text Highlight / Division Style | Read Only Show (to match Text) |
|Text + Span + ImageSpan | Promotion Paper, Commodity Tags, Text | Text + Picture Companion | Edit scene |

---

# Scene I: Presentation of news articles in support of custom styles and super-long omissions

**Scene Example Description**: In News Read App, the text of the article is displayed in multiple paragraphs, supports custom font sizes/line spacing/word spacing, automatically wraps text over long and displays ellipses at the end, and supports the roll-up/closure of the full text.

** Solution**: Use the Text component to display ellipses when using font size by fontSize, lineHeight setting line spacing, letterSpacing setting spacing, textOverFlow matching maxLines settings exceeding.

• Alternative components
|---------|------------|
| TextInput | is an input component for user input text only
| RichEditor | is an editable component with only read-only display of the body of the article

```typescript
/ / Expand/ Collect Status must be declared with @state, otherwise maxLines and button file files will not respond to refreshing
@State isExpanded: boolean = false;

// Title: Large font + Crude + Custom Line High
Text(this.articleTitle)
  .fontSize(22).fontWeight(FontWeight.Bold)
  .lineHeight(32).letterSpacing(1)

/ / Body: Hyperlong ellipses + Expand/ Collapse
Text(this.articleContent)
  .fontSize(16).lineHeight(28).letterSpacing(0.5)
  .maxLines(this.isExpanded ? 100 : 3)
  .textOverflow({ overflow: TextOverflow.Ellipsis })

Button.
  .onClick(() => { this.isExpanded = !this.isExpanded; })

/ / Decoration Line Style
Text
  .decoration({ type: TextDecorationType.LineThrough, color: '#e74c3c' })
```

# Text Key API

| Properties | Role | Example |
|------|-----|------|
`fontSize` | Font Size `.fontSize(16)` |
`fontWeight` | fine font  `Normal` / `Medium` / `Bold` |
`fontStyle`| font style  `Normal`/`Italic`|
`lineHeight` `.lineHeight(28)`
`letterSpacing` | Spacing `.letterSpacing(0.5)` |
`maxLines`| Maximum number of rows |XKEEP1ZX|
`textOverflow` | Spill processing  `Ellipsis`/`Clip`|
`textAlign` | alignment  `Start`/ `Center`/ `End`|

# TextOverflow

Equation values Behaviour
|--------|------|
Z `TextOverflow.Ellipsis` | The excess is shown in ellipses
`TextOverflow.Clip` ZEX ZEX
`TextOverflow.None` zirconium does not process spills

# TextDecoration Type

Equation values, effects, effects.
|--------|------|
`Underline`
`LineThrough` ZERO
`Overline`
`None`

---

# scene two: multiple input types of user registration form, each pulling the corresponding keyboard

** Example description of scene **: User registration page, containing multiple input boxes such as user name (single text), password (cipher mode mask), mailbox (mail box keyboard), mobile phone number (digit keyboard), each type of keyboard and real-time form validation.

** Solution**: Real-time validation using TextInput components, type setting different input types, placeholdt text by placeholdholder settings, onChange backup.

• Alternative components
|---------|------------|
| TextArea | Registration Form is all single-line input, TextArea is a multi-line input box
| RichEditor | For rich text editing, only plain text for form entry

```typescript
/ / Username: Normal
TextInput({text: this.username, placeholder: 'Please enter username'})
  .type(InputType.Normal).maxLength(20)
  .onChange((value: string) => { this.username = value; })

/ Password: Password mode mask
TextInput({text: this.password, placeholder: 'Please enter password'})
  .type(InputType.Password)
  .onChange((value: string) => { this.password = value; })

// Mailbox: Mailbox keyboard
TextInput({text: this.email, placeholder: 'Please enter the mailbox'})
  .type(InputType.Email)
  .onChange((value: string) => { this.email = value; })

Cell phone number: Digital keyboard
TextInput({text: this.phone, placeholder: 'Please enter cell phone'})
  .type(InputType.Number).maxLength(11)
  .onChange((value: string) => { this.phone = value; })
```

# InputType count

| | | | Keyboard Type |
|--------|---------|---------|
`Normal` | Normal Text Keyboard | Username, nickname, address
`Password`| Password Keyboard (shield display) | Password, Authentication Code
`Email`| Mailbox Keyboard (with @ symbol) | Mailbox Address
`Number` | Digital keyboard | Cell number, amount, authentication code |
`PhoneNumber` | phone keyboard | phone number |

---

# Scene III: The Forum Post page supports rich text editors such as thicker, italics, colour, etc.

** Example description of the scene**: Poster/Comment page of the community forum App. Users need to enter text and insert emoticons to support the setting of bold, italics, colour, etc. for selected text, and to mix the text.

** Solution**: Use the RichEditor component to set up subsequent input styles (grain/in italics/colour/ character) via RichEditorController setTypingStyle to support editing, such as revocation/rework.

• Alternative components
|---------|------------|
|Text + Span | only displays a graph mix and does not support user interactive editing
|TextArea| only supports text input and cannot insert pictures and settings

```typescript
/ / Toolbar Style Status must be managed with @State to ensure that buttons are switched to synchronize with subsequent input styles
@State isBold: boolean = false;
@State isItalic: boolean = false;
@State currentColor: string = '#000000';

controller: RichEditorController = new RichEditorController();

private applyTypingStyle(): void {
  this.controller.setTypingStyle({
    fontWeight: this.isBold ? FontWeight.Bold : FontWeight.Normal,
    fontStyle: this.isItalic ? FontStyle.Italic : FontStyle.Normal,
    decoration: { type: this.isUnderline ? TextDecorationType.Underline : TextDecorationType.None },
    fontColor: this.currentColor
  });
}

/ Toolbar button
Button('B').onClick(() => { this.isBold = !this.isBold; this.applyTypingStyle(); })
Button('I').onClick(() => { this.isItalic = !this.isItalic; this.applyTypingStyle(); })

Colour Selection
ForEach(this.colors, (color: string) => {
  Circle().width(28).height(28).fill(color)
    .onClick(() => { this.currentColor = color; this.applyTypingStyle(); })
})

// Rich Text Editing Area
RichEditor({ controller: this.controller })
.placeholder
  .width('100%').height(240)
```

---

# scene IV: System Settings Page WiFi/Bluetooth switches use system icons and enablers

**Scene Example Description**: On the System Settings page, a switch button such as WiFi/Bluetooth/flight mode/positioning uses the system pre-set Symbol icon, with a system-level dynamic transition when clicking on the switch.

** Solution**: Use the SymbolGlyph component, refer to the system preset symbol resource, set colours by fontColor, setting renderingStrategy, symbolEffect set system level dynamics.

• Alternative components
|---------|------------|
|Image | system-scale and multi-chromosomal power without Symbol icons
| Icon Font | SymbolGlyph integrates with system symbol library depth to support multi-layer colour configuration

```typescript
/ / Switch status arrays and kinetic triggers (@state to ensure color and kinetic response updates)
@State items: Array<{ symbol: ResourceStr, enabled: boolean }> = [
  { symbol: $r('sys.symbol.ohos_wifi'), enabled: true },
  { symbol: $r('sys.symbol.bluetooth'), enabled: true },
  { symbol: $r('sys.symbol.airplane'), enabled: false },
  { symbol: $r('sys.symbol.location_north_up_right'), enabled: true }
];
@State triggerValues: number[] = [0, 0, 0, 0];

ForEach(this.items, (item: { symbol: ResourceStr, enabled: boolean }, index: number) => {
  SymbolGlyph(item.symbol)
    .fontSize(28)
    .fontColor(item.enabled ? ['#1890ff'] : ['#999999'])
    .renderingStrategy(SymbolRenderingStrategy.SINGLE)
    .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER), this.triggerValues[index])
    .onClick(() => {
      this.items[index].enabled = !this.items[index].enabled;
This.triggerValues [index]++; /// Incremental Trigger Driver Bounce Dynamics
    })
}, (item: { symbol: ResourceStr, enabled: boolean }, index: number) => index.toString())
```

# SymbolGlyph

| | | | | |
|---------|--------|------|
| SymbolRenderingStrategy | `SINGLE` / `MULTIPLE_OPACITY` / `MULTIPLE_PALETTE` | Rendering Policy
|SymbolEffectStrategy |`NONE` /`HIERARCHICAL`|active policy
|EffectScope |`LAYER`/ `WHOLE`|View range

# # Common system Symbol resource

| Resource name | Icon |
|--------|------|
| `sys.symbol.ohos_wifi` | WiFi |
`sys.symbol.bluetooth`
`sys.symbol.airplane`
`sys.symbol.location_north_up_right`
`sys.symbol.sound`
`sys.symbol.brightness` | Brightness
`sys.symbol.battery` | Battery
`sys.symbol.bell` Notification
`sys.symbol.moon`

---

# scene five: matching keyword highlight in search result list

**Scene example description**: In the search result list, the part of the trade name that matches the search keyword requires a high-profile display (e.g. a search for a "cell phone" and a change in the word "cell phone" in the result), and different keywords in the same paragraph may use different high-light colors.

** Solution**: Build property string using MutableStyledString, use replaceStyle for text ranges matching keywords, set different colours and bolds, and set to the Text Component by TextController.setStyledString.

• Alternative components
|---------|------------|
| Span sub-component | Dynamic fusion multiple Span code long and difficult to maintain under complex high-profile scenes
| RichEditor | The search results are read-only and do not require editorial skills

```typescript
/ Predefined keyword colour
const KEYWORD_STYLES = [
{keyword: 'cell phone', color: '#e74c3c'},
{keyword: 'WOW', color: '#2980b9 '},
  // ...
];

// Build Highlight Properties String
private buildHighlight(text: string): MutableStyledString {
  const styled = new MutableStyledString(text);
/ / ... find keyword locations and create character position keyword mapping
// Set Highlight Styles for Match Range
  styled.replaceStyle({
    start: rangeStart, length: length,
    styledKey: StyledStringKey.FONT,
    styledValue: new TextStyle({ fontColor: color, fontWeight: FontWeight.Bold })
  });
  return styled;
}

/ Must call Controller.setStyledString() sets MutableStyledString to TextController,
/ / Otherwise the attribute string cannot render to the Text component (stop skipping this step directly using MutableStyledString)
private updateHighlight(text: string): void {
  this.controller.setStyledString(this.buildHighlight(text));
}

/ / Call when about ToAppear or search result data update
// aboutToAppear(): void { this.updateHighlight(this.searchText); }

/ / Use TextController to set attribute string
Text(undefined, { controller: this.controller })
  .fontSize(16).fontWeight(FontWeight.Medium)
```

# Styled StringKey Count

Quantum count value Quantifiable properties Quantification
|--------|----------|
| `FONT` | fontColor, fontWeight, fontSize, fontStyle |
`BACKGROUND_COLOR` | Background Colour
`DECORATION` ZEX ZEX ZEX ZEX ZEX
`LINE_HEIGHT`
`FONT_FAMILY`

---

# Scene VI: Embedded icons and pictures in the Commodity Details Page Promotions

**Scene exposition**: In the Commodity Details page, the promotion case "Treasure on a time-limit of $50" needs to include promotional icons, small images of the gift in the middle of the text, images and text in the same line.

** Solution**: Use Text component, use Span to display text clips in subcomponents, ImageSpan to insert line pictures, and set vertical alignment of pictures with text by verticalAlign.

• Alternative components
|---------|------------|
|Image | is a stand-alone image component that cannot be embedded in text stream to mix text with text
| RichEditor | Commodity Details Page is read-only and does not require editing

```typescript
/ Core promotional file: graph mix
Text() {
  ImageSpan($r('sys.media.ohos_ic_public_clock'))
    .width(18).height(18)
    .verticalAlign(ImageSpanAlignment.CENTER)
Span
    .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
Span('50 minus)
    .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFE066')
/ / / / . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
}
.backgroundColor('#E74C3C').borderRadius(8).padding(12)

/ / Promotion label: multiple icons + text Fuck. Line
Text() {
  ImageSpan($r('sys.media.ohos_ic_public_sound'))
    .width(14).height(14).verticalAlign(ImageSpanAlignment.CENTER)
Span('full decrease').fontSize(12).fontColor('#E74C3C')
    .backgroundColor('#FDEAEA').borderRadius(4)
/ /...more labels
}
```

# ImageSpanAlignment

Quantum count, alignment,
|--------|---------|
`TOP` |Photo and text top pair
`CENTER` ZiO ZiZiZi
`BOTTOM` | Aligns the bottom with the bottom of the text
`BASELINE` | Pictures aligned to text baseline

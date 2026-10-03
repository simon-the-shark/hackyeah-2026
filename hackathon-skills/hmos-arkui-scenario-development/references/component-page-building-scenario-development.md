# Component Build Basic Page Case Set

---

# Layout component builds a page frame

# Functional points typically use scene comparison

| Layout component | Typical use scenario | Core competencies | Not applicable
|---------|------------|---------|-----------|
| Column / Row | Settings Settings vertically, horizontally, horizontally, | simple linearly, | line breaks, stacking, 2D positioning |
|Stack List + Suspended Button, Video + Control Bar, Picture + Angular Marker |Streave over +N9M
Left, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, fourth, fifth, fifth, fourth, fourth, fifth, fourth, fourth, fifth, fifth, fifth, fifth, fourth, fourth, fifth, fifth, fifth, fourth, fifth, fifth, fifth, fourth, fifth, fourth, fifth, fourth, fifth, fifth, fourth, fifth, fifth, fifth, fifth, fifth, fifth, fifth, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, third, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second, second,
| RelativeContainer | Social dynamics cards, complex forms, dashboards | flat anchor location | simple linear organization
| GridRow / GridCol | Multi-Equip, Responsive Card | Adjusting Columns to the Wideness Dynamics of Equipment | Fixed Row Grid |
|DynamicLayout |File Manager View Switch (List/ Grid/ Fall Stream) |Talk to layout and maintain status with data source | Page Sign Switch, Condition Render
| Tabs| News Channel Switch, Commodity Classification Page Signs | Multi-Category View Switch Not Destroy | Page Navigation Jump |

---

# scene I: set the page settings vertically, with each in icon + title + switch horizontally

**Scene Example Description**: Set a page with multiple settings (WiFi, Bluetooth, Display, Sound, etc.) vertically, with each setting item icon + Title + Switch button horizontally.

**Solution**: Outer Column Arrange Settings, each setting item Row sets the equidistance between the icon and the title through space properties, and the switch button pushes the Blank component to the right.

| Alternatives | Reasons for impropriety |
|---------|------------|
|Stack (Stack) | Setup is a linear arrangement between items and does not require stacking
RelativeContainer

```typescript
/ / Outer Column Vertically Align All Settings, Space
Column({ space: 12 }) {
/ / Set Item 1: WLAN - Right Toggle Switch
  Row() {
    Text('📶').fontSize(24).width(40)
Text('WLAN'). FontSize(16). playoutWeight(1) / / Fill the middle gap and push Toggle to Right Side
    Toggle({ type: ToggleType.Switch, isOn: this.wifiEnabled })
      .selectedColor('#007DFF')
      .onChange((isOn: boolean) => { this.wifiEnabled = isOn; })
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })

/ / Set Item 2: Bluetooth - Right Toggle Switch
  Row() {
    Text('🔵').fontSize(24).width(40)
Text('Bluetooth').fontSize(16).playoutWeight(1)
    Toggle({ type: ToggleType.Switch, isOn: this.bluetoothEnabled })
      .selectedColor('#007DFF')
      .onChange((isOn: boolean) => { this.bluetoothEnabled = isOn; })
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })

/ / Set Division 3: Brightness - Right Text Subtext (non-switch scene, need to distinguish between content types)
  Row() {
    Text('🔆').fontSize(24).width(40)
Text('light').fontSize(16).playoutWeight(1)
    Text(`${this.brightness}%`).fontSize(14).fontColor('#999')
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })
}
```

# Key API #

| Properties | Role | Example |
|------|-----|------|
`space` | subcomponent spacing  `Column({ space: 10 })` |
`layoutWeight` | Proportional distribution of remaining space |XKEEP1ZX |
`Blank()` | takes over the rest of the space  Z push the back component to the right  Z
`justifyContent` ZEX ZEKEP 1ZX / `SpaceBetween` ZE
`alignItems` | Cross-axis Alignment |XKEEP1ZX |

Prohibition of writing

• Prohibition of writing
|---------|------|
| Column space | space uniformly manages line spacing with hard-coded line spacing of margin; hard-coded margin maintenance is difficult and easily inconsistent
| Absolute Positioning Nail Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle Toggle
@ Toggle does not bind @state status variable | Click on switch not to respond, state not to update  @
| Toggle scene

---

# scene two: the long list page has a "return top" button on top of the list

**Scene Example Description**: The long list page has suspended the "return top" button at the bottom right corner of the page, always overwhelms the list content and the button position remains unchanged when the list scrolls.

**Solution**: Using the Stack layer stacking, List component as a bottom full screen, suspended Button as an upper layer component, set to Bottomend at the lower right corner through a signContent.

| Alternatives | Reasons for impropriety |
|---------|------------|
| RelativeContainer | Suspended buttons need to be located in the corner of the container, and the Stack alignment is more intuitive
| Linear Layout (Column/Row) | Buttons need to be covered above the list and not next to the list

```typescript
Stack({ alignContent: Alignment.BottomEnd }) {
/ Bottom: Long list
  List({ scroller: this.scroller }) {
    ForEach(this.items, (item: string, index: number) => {
      ListItem() {
        Row() {
          Text(`#${index + 1}`).fontSize(14).fontColor('#999').width(40)
          Text(item).fontSize(16).layoutWeight(1)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 })
      }
    })
  }
  .width('100%').height('100%')
  .onScrollIndex((index: number) => { this.showBackButton = index > 3; })

/ Top layer: suspended to top button
Button.
    .fontSize(14).fontColor(Color.White)
    .backgroundColor('#007DFF').borderRadius(24)
    .margin({ right: 16, bottom: 16 })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 2 })
    .onClick(() => { this.scroller.scrollToIndex(0); })
}
.clip(true)
```

# alignContant

Quantum count, alignment, alignment.
|--------|---------|
`Alignment.TopStart` | Top left corner  Z
`Alignment.Top` ZO ZO ZO ZO ZO
`Alignment.TopEnd` | Top right corner  Z
`Alignment.Start` | Centre Left
`Alignment.Center`
`Alignment.End` | Centre right side |
`Alignment.BottomStart` | Bottom left corner  Z
`Alignment.Bottom` | Centred below
`Alignment.BottomEnd` | Bottom right corner  Z

---

# scene III: Search page historical search phrase labels adjust to width and automatically break lines

**Scene example description**: In the search page, the user history search term is displayed as a label, the width of the label corresponds to the length of the text, and the line is automatically replaced by the next line after the line is full.

** Solution**: using the Flex layout, setting direction to Row, wrap to start line breaks, each tab setting flexShrink to 0 to prevent compression.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Linear layout Row | Row does not support automatic line breaks, too many labels spill out or are compressed
| Grid | Grid is a 2D layout in a fixed row that does not allow for the self-adaptation of labels of varying widths

```typescript
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
  ForEach(this.searchHistory, (tag: string) => {
    Text(tag)
      .fontSize(14).fontColor('#333')
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor('#F1F3F5').borderRadius(16)
. flexShrink(0) / Key: prevent label compression
      .margin({ right: 10, bottom: 10 })
  })
}
```

# # Flex Key Count

| | | | | |
|---------|--------|------|
|FlexDirect |`Row` /`Column` / `RowReverse` / `ColumnReverse`|
|Flexwrap |XKEEP0ZX /`Wrap` /`WrapReverse`|
|FlexAlign |`Start` / `Center` / `End` / `SpaceBetween` / `SpaceAround` / `SpaceEvenly` |System
| ItemAlign | `Start` / `Center` / `End` / `Stretch` / `Baseline` |

---

Scene IV: Complex positioning of elements such as images, user names, text, buttons, etc. in social dynamics cards

** Example description of scenes**: Social App dynamic cards with complex positions such as head (top left), user name (right side), release time (under user name), text (cross line), acclaim/comment/sharing button ( even distribution at the bottom) if 3-4 layers of packages are required to influence long list performance using the Row/Column nest.

** Solution**: using RelativeContainer to position the elements against the anchor points of the containers and bros, flatten the layout structure to reduce the embedded layer.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Linear layout (Column/Row) | elements have a two-dimensional positioning relationship. Row/Column nested layers are too deep (3-4 floor) |
The stacks, the stacks, the tacks, the elements are not overstretched, but are scheduled.

```typescript
RelativeContainer() {
// Header - Top left corner, anchor container left
  Stack() { Text('👤').fontSize(28) }
    .width(48).height(48).borderRadius(24)
    .alignRules({ left: { anchor: '__container__', align: HorizontalAlign.Start } })
    .id('avatar')

/ username - anchored header right
Text ('Zhang Sanfeng').fontSize (16).fontWeight (FontWeight.Medium)
    .alignRules({ left: { anchor: 'avatar', align: HorizontalAlign.End } })
    .margin({ left: 12, top: 4 }).id('username')

/ Focus Button - Top right corner of the anchor container (top + right while anchoring  container  )
Button.
    .fontSize(12).fontColor(Color.White)
    .backgroundColor('#007DFF').borderRadius(14)
    .height(28).padding({ left: 12, right: 12 })
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    })
    .margin({ top: 8, right: 0 })
    .id('followBtn')

/ / Release time - anchor under user name
Text('2 hours ago'). FontSize(12). FontColor('#999')
    .alignRules({
      left: { anchor: 'avatar', align: HorizontalAlign.End },
      top: { anchor: 'username', align: VerticalAlign.Bottom }
    }).id('postTime')

/ Body - Port and right anchor containers full width below the time of release
Text.
    .alignRules({
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      top: { anchor: 'postTime', align: VerticalAlign.Bottom },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    }).id('content')

// Pointing/ Comment/Sharing - anchor below the partition line
  Row() { Text('❤️'); Text(` ${this.likeCount}`) }
    .alignRules({
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      top: { anchor: 'divider', align: VerticalAlign.Bottom }
    })
    .chainMode(Axis.Horizontal, ChainStyle.SPREAD_INSIDE)
    .id('likeBtn')
/ / /... comments, sharing buttons similar
}
```

# alignrules anchor rules

|anchor value
|-------------|------|
`'__container__'` | relative to the parent container
`Against another subcontent of the same size
|top + right while anchoring `__container__` | position to the top right corner of the container (e. g. focus button)

| align (horizontal)
|-------------------|------|
`HorizontalAlign.Start` | anchors the left edge of the target
`HorizontalAlign.Center` | anchor target center  Z
`HorizontalAlign.End` ZeroZX Zero Zero Zero Zero

|align value (vertical)
|-------------------|------|
`VerticalAlign.Top` anchors the upper edge of the target
`VerticalAlign.Center` | anchor target center  Z
`VerticalAlign.Bottom` ZeroZX Zero Zero

# CainMode Chain Layouts

| Equivalent values
|--------|---------|
`ChainStyle.SPREAD_INSIDE` ZEX ZEX ZEX ZEX ZEX ZEX ZEZEX ZEZEX ZEX ZEZEX ZEZEX ZEZEX ZEX ZEZEX ZEZEX ZEXEX ZEXEZEX ZEZEX ZEZEX ZEZEX ZEXEZEX ZEQIQUIDED ZEQUIPMENT ZEQUIPMENTS ZEQUIPMENTS AND EQUIPMENTS
`ChainStyle.SPREAD` | Equal distribution of all elements (with initial and end spacing)
Z `ChainStyle.PACKED` | All elements are organized and distributed in the middle

---

scene five: the list of electricians shows different columns on different devices

**Scene example description**: Electrician App page, mobile end displays 2 column commodity grids, tablet end displays 4 column commodity grids, 2in1 device end displays 6 column commodity grids with the same content but the number of columns changes with the width of the device.

** Solution**: Using GridRow to define grid packagings (default 12 grids), GridCol sub-components set different grid ratios under different breakpoints by span properties to achieve self-adaptation columns.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Grid component | Grid is a 2-D grid in fixed rows and cannot adjust the number of columns to the device's width dynamics
|Flex layout |Flex is suitable for one-dimensional organization and line break, which does not allow precise control of column proportions under different devices

```typescript
GridRow({
  columns: 12,
  breakpoints: {
    value: ['100vp', '200vp', '300vp'],
    reference: BreakpointsReference.WindowSize
  }
}) {
  ForEach(this.products, (product: Product) => {
    GridCol({
      xs: { span: 6 },
      sm: { span: 6 },
      md: { span: 3 },
      lg: { span: 2 }
    }) {
      Column() {
        Stack() { Text(product.emoji).fontSize(40) }
          .width('100%').aspectRatio(1)
          .backgroundColor(product.color).borderRadius(8)
        Text(product.name).fontSize(13).maxLines(1)
        Text(product.price).fontSize(14).fontColor('#E53935')
      }
      .padding(8).backgroundColor(Color.White).borderRadius(8)
    }
  })
}
```

## # grid computing speed check (12 grid system)

| Target column | span value |
|---------|---------|
1 column 12
2 rows 6
3 rows 4
4 Columns 3
6 Columns 2
|12 Row 1

---

# scene six: file manager to switch and maintain status between list/gap/fall stream view

**Scene Example Description**: In the File Manager App, the user clicks the Switch button, the file list moves between the "List View (Single Columns)" "More Columns" "Site Streams" (Six Columns)" and the current selected file and scroll position is not lost.

** Solution**: using layout algorithms such as the DynamicLayout component, which incorporates the ColumnLayout Algorithm (list), Grid Layout Algorithm (grid), can also customize CustomLayouAlgorinthm (e.g. waterfall flow) and automatically maintain the state of the sub-components at the time of conversion.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Rendering (if/else) | Switching different components destroys reconstruction, loses the selected status and scroll position
| Tabs | Tabs is a page-marking switch that does not fit into multiple layouts of the same data source

```typescript
import {
  ColumnLayoutAlgorithm, CustomLayoutAlgorithm, DynamicLayout,
  GridLayoutAlgorithm, LayoutAlgorithm, LayoutConstraint, LengthMetrics
} from '@kit.ArkUI';

// Custom Falls Flow Layout algorithm
class WaterfallLayout extends CustomLayoutAlgorithm {
  onMeasure(self: FrameNode, constraint: LayoutConstraint): void {
/ ... measure the width of each column and place the subcomponent in the shortest column
  }
  onLayout(self: FrameNode, position: LayoutPosition): void {
/ / ... set the position of each sub-component according to the measurement results
  }
}

@Local algorithm: LayoutAlgorithm = new ColumnLayoutAlgorithm({ space: LengthMetrics.vp(5) });

private switchLayout(mode: number): void {
  if (mode === 0) {
    this.algorithm = new ColumnLayoutAlgorithm({ space: LengthMetrics.vp(5) });
  } else if (mode === 1) {
    this.algorithm = new GridLayoutAlgorithm({
      columnsTemplate: '1fr 1fr 1fr',
      rowsGap: LengthMetrics.vp(10), columnsGap: LengthMetrics.vp(10)
    });
  } else {
    this.algorithm = new WaterfallLayout();
  }
}

/ / Use DynamicLayout - sub-components to maintain state on layout switching
DynamicLayout(this.algorithm) {
  ForEach(this.files, (file: FileItem, index: number) => {
    this.buildFileCard(file, index)
  })
}
```

# DynamicLayout layout algorithm count

| Algorithmic type | Description of key parameters |
|--------|------|---------|
`ColumnLayoutAlgorithm` | Single / Multi-column Linear |XKEEP1ZX |
`GridLayoutAlgorithm` | Grid Arrange  `{ columnsTemplate: '1fr 1fr 1fr', rowsGap, columnsGap }` |
`RowLayoutAlgorithm` | Single-line horizontal `{ space: LengthMetrics.vp(5) }` |
`CustomLayoutAlgorithm` | Custom layout (e.g. waterfall current) `onMeasure` + `onLayout` |

---

# Scene VII: The top page of News App to switch to the corresponding channel content

**Scene description**: News App has multiple classification pages at the top of the front page, such as "Recommended/hot spots/technology/recreation/sport", user click pages to switch to the content of the news list of the corresponding channel, and page signs support slide to see more categories.

**Solution**: Using the Tabs component, each TabContent corresponds to a classified news list, toggle through TabsController control pages, and index binds the program to cut pages in both directions.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Navigation | Navigation is used for page-level navigation jumps, page-mark switching is the view exchange on the same page
| Conditional Rendering (if/else) | The loaded list data will be lost at each switch; Tabs loaded TabContent will not destroy |

```typescript
Tabs({ barPosition: BarPosition.Start, controller: this.tabsController, index: this.currentIndex }) {
TabContent() {This.buildNewsList(this.recommendNews)}.tabBar('Recommended')
TabContent() {This.build NewsList(this.hotNews)}.tabBar('hotspot')
TabContent() {This.build NewsList(this.techNews)}.tabBar('tech')
/...more channels
}
.scrollable / / content area supports right and left slide switch
.barHeight(44)
.onChange((index: number) => { this.currentIndex = index; })
```

# # Tabs Key Count

| | | | | |
|---------|--------|------|
BarPosition | `Start` / `End` | page signer position (top/ bottom) |
Scrollable BarModeOptions | `Fixed` / `Scrollable` / `Marquee` page signer mode

---

# Scheduling speed check

| Layout component | Arranged | Core competencies | Typical scenes | Critical limitations |
|---------|---------|---------|---------|---------|
**Column / Row** Linear  ** Single-direction | Simple vertical/horizontal | Settings Page, Form, Navigation Bar  ** Non-supportive line break, non-supportive 2D positioning |
**Stack** Scramble over  ** sub-assemble over +9M
**Flex**  **Flex + line break  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **
**RelativeContainer** anchor relative position  ** flattensing complex 2D layouts | social cards, complex forms, dashboards ** id, anchoring complex rules  **
**GridRow / GridCol** Responsive grids  ** Adjustment columns based on equipment width dynamics  ** List of electrician goods, multi-equipment fit  ** Based on fixed grid numbers (12/24), non-pixel level precision |
** **DynamicLayout**  ** Toggle conversion | Toggle different layouts with data sources | File Manager View Switch | Need@ObservedV2 and @CompentV2|
**Tabs** Page Switch  ** Multi-Category View Switch has been loaded without destruction  ** News Channel, Commodity Catalogue Tab  ** is a View Switch non-page jump |


---

# Roll component list presentation

# Functional points typically use scene comparison

| Scroll component | Typical use scenario | Core competencies | Non-appliance scenario |
|---------|------------|---------|-----------|
|List +ListItemGroup |ListListPressBox, Left Slide List, Set List | Group + Suction + Slide Operation + Drag-Land Sort | Multi-Line Grid, Unarranged |
| ArcList | Smart watch arc menu, wearable device settings list | Circle screen fit + dynamic scaling | Cell phone line list |
High grids such as Grid + GridItem photo albums of nine palaces, applied mazes, photo choosers, | fixed liners, etc.
| WaterFlow + FlowItem | Commodity Refined Falls, Pinterest Flows, Small Red Book Information Flows, etc.

---

# scene I: the address book grouped by initials, headlines suffocated, left slide deleted

** Example description of scene**: In the address book App, contact groups are grouped by initials (A/B/C...), each group header is shown on top, and the list supports the name search filter, left slide deletion.

** Solution**: Using the List component, sub-components are the ListItemGroup (grouping), setting the sticky properties to get group headers to the top, swipeaction to the left slide button.

• Alternative components
|---------|------------|
A two-dimensional layout that does not require a grid is shown in a single column of the address book.
| WaterFlow | Address Book List Item Aligns Highly, does not require a misarranged waterfall

```typescript
List({ space: 0 }) {
  ForEach(this.getFilteredGroups(), (group: ContactGroup) => {
    ListItemGroup({ header: this.groupHeader(group.letter) }) {
      ForEach(group.contacts, (contact: Contact) => {
        ListItem() {
          Row() {
/ Image
            Column() { Text(contact.avatar) }
              .width(44).height(44).borderRadius(22)
/ Name + Cell phone number
            Column() {
              Text(contact.name).fontSize(16)
              Text(contact.phone).fontSize(12).fontColor('#999')
            }.layoutWeight(1)
          }
          .width('100%').height(64).padding({ left: 16, right: 16 })
        }
        .swipeAction({ end: this.deleteButton(contact.name) })
      })
    }
  })
}
.sticky (StickyStyle. Header)/ / Group Header
.divider({ strokeWidth: 0.5, color: '#f0f0f0', startMargin: 72 })
```

# List Key API

| Properties | Role | Example |
|------|-----|------|
`sticky`| Group Header Suction Top
`ListItemGroup` | Group Container `ListItemGroup({ header: builder })` |
`swipeAction` | Slide Operation Button `{ end: builder }` / `{ start: builder, end: builder }` |
`divider` | Partition Line  `{ strokeWidth, color, startMargin }` |
`onReachEnd` | Scroll back to bottom | to load more |
`EditMode`| Drag sorting mode  ZListItem long by drag sorting

# StickyStyle Count

Equation values Behaviour
|--------|------|
`Header`| Group Header Suction Top
`Footer` | Bottom of group inhalation
`None`

---

# scene II: Smart Table Circle Screen menu items arranged along arcs, with the largest centre items

**Scene Example Description**: On a circle table of smart watches, set menu entries arranged along a circle arc, the list items automatically shrink as they approach the upper and lower edges of the circle screen, and the list items in the middle are the most prominent.

** Solution**: Using ArcList component, sub-component ArcListItem, the list item automatically zooms in distance from the center of the screen, setting the list item initially displayed through the Index setting.

• Alternative components
|---------|------------|
|List | is a list of straight lines that does not fit the arc of a circle screen interactively
| Grid | is a two-dimensional grid layout that does not support arc organization and dynamic scaling effect

```typescript
ArcList({ initialIndex: 0 }) {
  ForEach(this.menuItems, (item: ArcMenuItem) => {
    ArcListItem() {
/ / / list item content, automatically scaled according to location
      // ...
    }
  })
}
```

> NOTE: ArcList's main fit circle screen device (smart handwatch) can use the List + scale/opacy animation simulation to simulate similar effects.

---

# Scene III: Chat photos of nine palaces, three squares of equal width per line

** Example description of scene**: In the micro-mail chat interface, the user sends a nine-gauge of nine photos, three squares of equal width per line, with fixed spacing.

** Solution**: Use Grid component to set the number of columns (e. g. `'1fr 1fr 1fr'` three columns) using columnsTemplate,rowsGap/columnsGap settings space.

• Alternative components
|---------|------------|
|List | is a single-column linear arrangement that does not allow multiple-column grids
♪ WaterFlow ♪
| GridRow/GridCol | for a responsive layout, the nine palaces are a fixed-wing structure

```typescript
Grid() {
  ForEach(this.photos, (photo: PhotoItem) => {
    GridItem() {
      Image(photo.url)
.objectFit (ImageFit.Cover) / Key: prevent photo distortion
.aspectRatio(1) / / Fixed width ratio to ensure a clean grid
.onClick(() => {this.openPhotoPreview(photo.url);})/ click on preview
    }
  })
}
...columnsTemplate('1fr 1fr') / / 3 columns, etc. width
.rowsGap(8).columnsGap(8)
.padding({ left: 16, right: 16 })
```

# columnsTemplate syntax

| Syntax:
|------|------|------|
`1fr` | Proportional distribution |XKEEP1ZX = 3 %
Z `100vp` | Fixed width  Z `'100vp 1fr 1fr'` = First column fixed + second column parity
`auto` |According to content |XKEEP1ZX = First column by content, next column is full of |

## Layout rules for different number of photos

| Photos | columnsTemplate | layout effect
|--------|----------------|---------|
|1 | dynamic tangent `'1fr'` or GridItem cross 3 rows | single large picture fills the whole line
2-3 Chang ZXKEP0ZX Line, left empty
|4  `'1fr 1fr 1fr'` |2x2 |(Left empty) |
5-6 Chang ZXKEP0ZX 2 Line Order
|7-9 x XKEEP0ZX | 3 x 3 x 3 Complete 9

> Note: A photograph may be conditioned to a single large chart, or GridItem cross 3 columns (`.columnStart(0).columnEnd(2)`).

---

# scene IV: Commodity recommended waterfalls, cards at varying heights

** Example description of scene **: Commodity-recommended home page of Small Book/Pinterest App, each of which has the same width but different height (due to different lengths of picture and description), with the new card automatically placed below the current minimum column, creating a faulty waterfall effect.

** Solution**: Sets the number of columns by using the WaterFlow component, using the ColumnsTemplate, with the subnode FlowItem automatically placed in the smallest column of the current total height.

• Alternative components
|---------|------------|
| Grid | Grid cannot achieve different heights of error by being tall
|List | is a single column equal to the width of a high ranking, which does not allow for multiple columns of high waterfalls.

```typescript
WaterFlow() {
  ForEach(this.products, (product: ProductCard) => {
    FlowItem() {
      Column() {
/ / Photo area: Different heights, creating a misdirection
        Stack() {
          Column().height(product.height - 80)
            .backgroundColor(product.color)
          Text(product.icon).fontSize(40)
        }
/ Commodity information
        Column() {
          Text(product.name).maxLines(2)
          Text(product.price).fontColor('#e74c3c')
        }.padding(10)
      }
      .height(product.height)
      .backgroundColor(Color.White).borderRadius(10)
    }
  })
}
...columnsTemplate('1fr 1fr')// Double Falls Stream
.columnsGap(8).rowsGap(8)
.onReachend()=>{/* Load more*/}
```

# Falls stream vs grid core difference #

♪ Bang, bang, bang ♪
|------|------------|-------------------|
♪ High, high, high, high ♪
| Arranged | Filling new entries in a row order Automatically short columns
| Applied scenes | Photo albums of nine palaces, fixed grids | Commodity recommendations, Pinterest |
GridItem FlowItem

---

# Scroll component spacing table

| Component | Form | Core competencies | Typical scenes | Critical limitations |
|------|---------|---------|---------|---------|
**List**  **System Linear | Group +Snaptop + Slide Operation + Drag-Low Sort  **List, Message List, Settings  **Systems only, not multiple columns |
**ArcList** Arc Arrange  ** Circle Screen Fit + Dynamic Scale  ** Smart Watch menu  ** Main Fit for Circle Screen Device  **
**Grid**  ** multi-column high  ** fixed-line grid layout  ** photo albums of nine palaces, applied mazes  ** high, each line high, does not support error  **
**WaterFlow**  ** Multiple columns are not high  ** Automatically short + misarranged  ** Commodity Recommendations, Pinterest  ** Unprecisely controlling position of the column

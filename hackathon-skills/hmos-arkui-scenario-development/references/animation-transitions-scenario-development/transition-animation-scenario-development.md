# Animation case series

# Apply scene

* Reissued for technical reasons.
|---|---|---|
|B page A↔B toggle  Z`TransitionEffect.OPACITY.combine(translate)` + `move(Edge)` | lighter than Navigation; A Fade left + B Slide right into |
| Slide hands back  `PanGesture` + `translate({x})` + Threshold judgement | Requires real-time handback; then release/ eject by offset
| Bottom drawer/operator panel + Condition Render + `TransitionEffect.translate({y})` + Mask | Simplicit scheme; Mask click closes
| Group List Expand Collapse | Two-stage transitions: Container `OPACITY` + Line Level `delay` Intersect | Container Controls the overall rhythm, Line Level Interlaces
|XKEEP0ZX ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ ZZZ ZZ Z Z Z Z Z Z Z Z  Z Z Z Z  Z  Z  Z  Z  Z   Z  Z   Z  Z   Z      Z  Z   Z                 Z    Z  Z     Z    Z  Z    Z  

# Core Animation API Enumeration Reference

# TranstionEffect Static Properties and Methods

| Properties/methods
|---|---|---|
`TransitionEffect.OPACITY` | Translucency (1:0:1) |Fadeout, bottom drawer
Z `TransitionEffect.IDENTITY` | no-turn effects
| `TransitionEffect.opacity(value)`| Custom transparency threshold | Mode transition from semi-transparent |
`TransitionEffect.translate(offset)` ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX
Z `TransitionEffect.scale(scale)` | Zoom Field Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom Zoom in Zoom In Zoom In Zoom In
Z `TransitionEffect.move(edge)` | slides into/ out of specified edges | B page slides into (END) right, slides out of (START) | left on exit
`.combine(effect)` | Combining two rotation effects
`.animation(params)` | Additional animated parameters | Setup curation/curve/deray |

# TranstionEdge Edge #

| | |
|---|---|---|
Z `TransitionEdge.TOP` | Slided into/out of top | Drawdown Notification Bar |
Z `TransitionEdge.BOTTOM` | slides into/out of the bottom | bottom panel pops into the bottom |
`TransitionEdge.START` | Slides/ Slides (usually left) from the start
`TransitionEdge.END` | slides in/out from the end (usually right) | New page slides in | right

# # Curve numeric count value (repeated animation)

| | |
|---|---|---|
Quick Start, Slow End Zi Zi Zi Zi
Z `Curve.EaseInOut` | Slow-Quick-Slow, two-end slow motion | List page fading/ fading
`Curve.Sharp` ZEX ZEX ZEX ZEX

## curves module spring curve function (commonly used for rerun animation)

| Function | Parameter | Description | Typical scene |
|---|---|---|---|
Z`curves.springMotion()` |`(response?, dampingFraction?)` | spring motion curve | page slips, bottom drawer pops up, folds up |
`curves.springMotion(0.6, 0.9)` | response=0.6, damping=0.9 | Moderate elasticity | Collapse, Page Switch

# TransportEffect.imation parameters

| Parameter | Type | Description |
|---|---|---|
`duration` | number number | animation duration (ms)
`curve` Curve
`delay` | number number | animation delay (ms)|

---

# scene 1: Page slide

**Scene description:** Simulate page switching, click the button to fade the current page to the left, and the new page slides from the right to form the A→B page jump transition.

** Solution:** Fade left with **`TransitionEffect.OPACITY.combine(translate)`** + **XKEEP1ZX Slide right** ** ** `curves.springMotion()` flex curve**

Step 1: Page A exit

```ts
if (!showPageB) {
Column(){/* Page A content*/}
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: 400, curve: curves.springMotion() })
        .combine(TransitionEffect.translate({ x: -100 }))
    )
}
```

Step 2: Page B enters the switch

```ts
if (showPageB) {
Column(){/* Page B content*/}
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: 400, curve: curves.springMotion() })
        .combine(TransitionEffect.move(TransitionEdge.END))
    )
}
```

Step 3: Trigger switch

```ts
Button('toggle'). onClick() = {
  this.showPageB = !this.showPageB
})
```

---

Scene 2: Slid back

** scene description:** Simulate iOS handside slipback, move the top page and right hand if the finger drags from the left edge of the screen to the right, slides above the threshold and exits automatically, without exceeding the bullet in place.

** Solution:** Drag ** With **`PanGesture` Horizontal** + **`translate({x: offsetX})` Counterhand** ** ** Free Hand Judge Diversion > 150px exit** ** ** `TransitionEffect` Exit Animation**

Step 1: PanGesture

```ts
.gesture(
  PanGesture({ direction: PanDirection.Horizontal })
    .onActionUpdate((event) => {
      this.offsetX = event.offsetX
    })
    .onActionEnd((event) => {
      if (this.offsetX > 150) {
// Slide long enough, exit
        animateTo({ duration: 250, curve: Curve.EaseOut, onFinish }, () => {
          this.offsetX = 300
        })
      } else {
/ Eject
        animateTo({ duration: 250 }, () => { this.offsetX = 0 })
      }
    })
)
```

Step 2: Exiting the switch

```ts
.transition(
  TransitionEffect.OPACITY
    .animation({ duration: 250, curve: curves.springMotion() })
    .combine(TransitionEffect.move(TransitionEdge.START))
)
.translate({ x: this.offsetX })
```

---

scene 3: Bottom drawer

** scene description: ** Simulates the bottom operating panel, clicks the button and pops out a semi-transparent mask from the bottom of the screen + the content panel, clicks the mask or closes the button and slips out of the back panel.

** Solution:** Use ** Render ** + `TransitionEffect.OPACITY.combine(translate({y:400}))`** ** `curves.springMotion()` elastic curve** ** ** ** semi-transparent mask click off**

Step 1: Mask + Drawer Layout

```ts
Stack() {
Column(){/ * Main content*/}

  if (this.showDrawer) {
/ Translucent Mask
    Column().width('100%').height('100%')
      .backgroundColor('rgba(0,0,0,0.4)')
      .onClick(() => { this.showDrawer = false })

/ Bottom drawer
Column() {/* drawer content*/}
      .width('100%')
      .height(400)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .transition(
        TransitionEffect.OPACITY
          .animation({ duration: 350, curve: curves.springMotion() })
          .combine(TransitionEffect.translate({ y: 400 }))
      )
  }
}.justifyContent(FlexAlign.End)
```

---

Scene 4: Expand Collapse

**Scene description:** Simulates the list of grouping pages, each with an icon + title + arrow. Rotates an arrow with a 180-degree display when clicking on the group header, the sub-option packaging is diluted as a whole, the internal rows are staggered from the left; click again to fold. The card is cropped using `clip(true)`, and the extension does not spill over the corner boundary.

** Solution:** Launch ** ** **  **  ** X X X X X X X X  **  **  **  **  **  **  **  **  **  **  **  **  **  ** **  **  **  **  ** ** ** ** ** ** ** ** Z Z X X X

Step 1: Data definitions

```ts
interface GroupItem {
  title: string
  icon: string
  items: string[]
}

// Example data
private groups: GroupItem[] = [
{title: 'Personal information', icon: '👤, 'items: ['heading set', 'nickname modified', 'personal profile', 'gender set']},
{title: 'notification settings', icon: '🔔, 'items: [ 'message sent', 'mail sent ', 'sMS sent ', 'sMS sent ', 'quiet silent time'],
  /* ... */
]
@State expandedItems: boolean[] = [false, false, false, false]
```

### Step 2: Group title lines (in icon + arrow rotation + click extension)

```ts
Row() {
  Text(group.icon).fontSize(20).margin({ right: 10 })
  Text(group.title).fontSize(16).layoutWeight(1)

/ / Arrow: Rotate 180° on expansion, use hidden expression to ensure smooth transition
  Text('▼')
    .fontSize(12).fontColor('#999999')
    .rotate({ angle: this.expandedItems[index] ? 180 : 0 })
    .animation({ duration: 250, curve: Curve.EaseInOut })
}
.width('100%').height(52)
.padding({ left: 16, right: 16 })
.onClick(() => {
/ / Change status with animateTo package to trigger springMotion elastic animation
  this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion(0.6, 0.9) }, () => {
    this.expandedItems[index] = !this.expandedItems[index]
  })
})
```

## # Step 3: Subpackage + Line two-step stagger field

```ts
if (this.expandedItems[index]) {
/ / tw container level transfer: overall OPACITY fades out and controls folding speed
  Column() {
    ForEach(group.items, (subItem: string, subIndex: number) => {
      Row() {
        Text(subItem).fontSize(14).fontColor('#666666').layoutWeight(1)
        Text('›').fontSize(16).fontColor('#cccccc')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
/ / Wing line transfer: slide from left -30px into + transparency, deray achieve staggered entry Field
      .transition(
        TransitionEffect.OPACITY
          .animation({
            duration: 300,
            curve: curves.springMotion(0.6, 0.9),
Delay: 30 * subIndex / / Line 0, delay 30 ms in line 1, incrementally
          })
          .combine(TransitionEffect.translate({ x: -30 }))
      )
    })
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 200, curve: Curve.EaseOut })
  )
}
```

## # Step 4: Card container cropping (prevent spills)

```ts
Column() {
* Title line Step 2 */
Step 3 */
}
.width('100%')
.backgroundColor(Color.White)
.borderRadius(12)
.clip(true) / / key: shearing content in circle range Internal
.shadow({ radius: 2, color: '#1a000000', offsetY: 1 })
```

Key points:
- ** Two-stage transfer superheave**: container `Column` mounted ZXXKEEP1ZX (200ms EaseOut) controls the overall fading out, and `Row` mounted ZXXKEEP3ZX (300m SpringMotion) from the left to the left
- ** `delay: 30 * subIndex`**: sub-items are indexed to delay entry, creating a waterfall from top to bottom; folding is equally reverse-line exit
- **Arrow `.animation()` Concealed Animation**: Arrow Rotation is not placed in `animateTo`, but monitors `.animation()` Properties for `rotate` Changes, playing in parallel with ZXXKEEP4ZX-activated animation
-**`clip(true)`**: clip must be used when the card is set as a round corner, otherwise the sub-item will slide from ZXXKEEP1ZX beyond the circle boundary
- ** `springMotion(0.6, 0.9)`**: Response parameter 0.6 + blocker parameter 0.9, efficacy medium not to bounce too much, suitable for a list extension hand

---

# Scenario 5: Photospace Palace Rotation

** scene description: ** Photo album browsing page, ** The number of ceremonial grids is smaller and narrow, the number of ceremonial grids is automatically increased to take full advantage of the wide screen space, and the image is condensed and the number of column smooth transitions are rotated.

** Solution:** Use **`GridRow` breakpoint system `{ sm, md, lg, xl }` Auto-adaptation columns** ** **`GridCol({ span: 1 })` Both width** ** ** `.aspectRatio(1)` square thumbnails**

Step 1: Data definitions

```ts
class PhotoItem {
  id: number = 0
  label: string = ''
  colors: string[] = []

  constructor(id: number, label: string, colors: string[]) {
    this.id = id
    this.label = label
    this.colors = colors
  }
}
```

Step 2: GridRow + GridCol Breakpoint Fits to the Palace

```ts
Scroll() {
  GridRow({ columns: { sm: 3, md: 4, lg: 5, xl: 6 }, gutter: 4 }) {
    ForEach(this.photos, (photo: PhotoItem, index: number) => {
      GridCol({ span: 1 }) {
        Stack() {
          Column() {}
            .width('100%').height('100%')
            .linearGradient({ angle: 135, colors: [[photo.colors[0], 0], [photo.colors[1], 1]] })
          Text(`${index + 1}`)
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
        }
        .aspectRatio(1)
        .borderRadius(4)
        .clip(true)
      }
    })
  }
  .width('100%')
  .padding(8)
}
```

Key points:
- `GridRow({ columns: { sm: 3, md: 4, lg: 5, xl: 6 } })` Breakpoint System automatically matches the number of columns according to the width of the screen, without the need to monitor changes in direction manually
- Breakpoint threshold: sm < 520vp, md 520-844vp, lg > 844vp, automatically toggle breakpoints and rearrange
- `GridCol({ span: 1 })`, 1 column for each thumbnail, `gutter: 4` control spacing
- `.aspectRatio(1)` ensures that the thumbnails are squared, rotated and sized to fit the image
- `module.json5` needs to configure `"orientation": "auto_rotation"`

---

scene 6: trade details rotate

**Scene description: ** Estimator ' s Commodity Details Page, stand-up is a single-column scroll layout (Commodity Large Chart + Price Information + Detail Description + User Evaluation + Bottom Operator Bar), automatically switch to the left- and right-column on screen (Left Large Commodity Chart + Right Details + Right Bottom Operations Bar) and down-and-out smooth transition on rotation.

** Solution:** Use **`mediaquery` audio orientation changes** + **`TransitionEffect.OPACITY.combine(scale)` zoom out** ** ** **`curves.springMotion()` elastic transition** ** ** ** vertical `Scroll` single column / wide screen `Row` column** ** public `@Builder` component reuse**

### Step 1: Data definition and Builder declaration

```ts
/ Commodity data model
class Product { /* name, price, description, reviews[] ... */ }
class ReviewItem { /* user, rating, content, date ... */ }

/ / Draw public @Builder, vertical/blank sharing to avoid code repetition
@Builder ProfInfoBuilder(){/* Commodity Name + Price + Label + Description */}
@Builder ReviewListBuilder(){/ *ForEach Render */}
@Builder ActionBarBuilder(){/* Join Shopping Car + Buy */ }
```

Step 2: mediaquery

```ts
import mediaquery from '@ohos.mediaquery'

@Entry
@Component
struct Scene6ProductDetail {
  @State isPortrait: boolean = true
  private listener?: mediaquery.MediaQueryListener

  aboutToAppear() {
    this.listener = mediaquery.matchMediaSync('(orientation: landscape)')
    this.isPortrait = !this.listener.matches
    this.listener.on('change', (result) => {
      animateTo({ duration: 350, curve: curves.springMotion() }, () => {
        this.isPortrait = !result.matches
      })
    })
  }

  aboutToDisappear() {
    this.listener?.off('change')
  }
}
```

## # Step 3: Stand-alone layout

```ts
@Builder
PortraitLayout() {
  Column() {
    Scroll() {
      Column() {
* Commodity megagraph*/
/ * Commodity information
* User evaluation
      }
    }.layoutWeight(1)

* Bottom Bar
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 300, curve: curves.springMotion() })
.compine (TranstionEffect.scale({x: 0.96, y: 0.96),) / / slightly reduced Out
  )
}
```

Step 4: Double-bar layout across screen

```ts
@Builder
LandscapeLayout() {
  Row() {
* Large left graph*/

    Column() {
      Scroll() {
        Column() {
/ * Commodity information
* User evaluation
        }
      }.layoutWeight(1)

* Bottom Bar
    }.layoutWeight(1)
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 300, curve: curves.springMotion() })
.compine (TranstionEffect.scale({x: 1.04, y: 1.04}))/ / slightly magnify Enter
  )
}
```

Step 5: Rotation transition assembly

```ts
build() {
  if (this.isPortrait) {
    this.PortraitLayout()
  } else {
    this.LandscapeLayout()
  }
}
```

Key points:
- `mediaquery.matchMediaSync('(orientation: landscape)')` hearing vertical switch, `.on('change')` echoes through `animateTo` package ZXXXKEEP3ZX to trigger a remix animation
- `scale({ x: 0.96, y: 0.96 })` slightly reduced dilution, `scale({ x: 1.04, y: 1.04 })` slightly amplified dilution to form a "push" view Sensor.
- Commodity information, evaluation list, operating column extracted as `@Builder`, vertical/blank sharing of the same layout logic, avoiding code repetition
- `aboutToDisappear` Call `listener.off('change')` Release media query bugging to prevent memory leakage
- `module.json5` needs to configure `"orientation": "auto_rotation"` to support screen rotation

---

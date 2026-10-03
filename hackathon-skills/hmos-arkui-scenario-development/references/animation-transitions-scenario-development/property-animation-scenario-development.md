# Properties Animation Case Set

# Apply scene

* Reissued for technical reasons.
|---|---|---|
`animateTo` + `iterations:-1` + `delay` | Infinite Cycle + multilayer delay
| Sidebar/panel switch  `animateTo` Drive ZXXKEEP1ZX | Packaging Properties Association requires a visible closed package
| `translate({y})` + `clip(true)` + Upon the margin, the greater the margin, the longer the margin, the simulation of the true scroll beat |
`animateTo` Drive Width + `.animation()` Drive opacity + invisible hybrid drive, width and high-light sync transition |
X X X X X X Z Z Z Z Z Z Z Z Z Z Z Z Respond Response Response Response Response Response Response Response Response Response Response Response Response Response Response Z Z Z Z Z Z Z Z Z Z Z Response Response Response Response Response Z Z Z Z Z Z Z X Z X  X X X X X X X X X X X X X X        Z  Z  Z  Z  Z   Z  Z       Z    Z       Z    Z Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag Drag and Drag and Drag Drag Drag Drag and Drag and Drag and Drag and Drag and Drag and Drag and Drag, Suding, Sud Z
| `.overlay()` + `.animation()` hidden drive | scrolling back only to Boolean state, hidden animation automatic transition |
`keyframeAnimateTo` +`vibrator` | Multisection key frame precise control deviation direction

# Core Animation API Enumeration Reference

# animateTo parameter

| Parameter | Type | Description |
|---|---|---|
`duration` | number | animation duration (ms), default 1000 |
`curve` |Curve\ICurve\string|an animation curve, default `Curve.EaseInOut`|
`delay` | number | animation delay (ms), default 0 |
`iterations` | number number number number, 1 for unlimited loop, default 1 |
`playMode` |PlayMode| Animation mode, default `PlayMode.Normal`|
`finishCallback`()= void| Animation returned

# Curve enumerator value

| | |
|---|---|---|
Z `Curve.Linear` | linear, flat rate change | flat rate rotation, progress bar |
Z`Curve.Ease`|  Z Quick start, slow end | General transition |
`Curve.EaseIn` | slow start, faster end  Z element leave screen |
`Curve.EaseOut` | Quick start, slow end | element enter screen, vote PK |
Z `Curve.EaseInOut` | Slow-Quick-Slow, two-end slow motion | Universal transition, water ripple proliferation |
`Curve.FastOutSlowIn` | Standard Material Curve | Material Animation
`Curve.LinearOutSlowIn` |  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z
`Curve.FastOutLinearIn` X-ray, slow-on-off, Zero Element, Zero Element
`Curve.ExtremeDeceleration` Z0ZX Z0
`Curve.Sharp` |  Z  Z | | | | | |
`Curve.Rhythm` | rhythm curve | elastic rhythm effect  Z
`Curve.Smooth`| smooth curve | smooth transition  Z
`Curve.Friction` Z curve curve curve curve curve curve curve curve curve

## curves module spring curve function

| Function | Parameter | Description | Typical scene |
|---|---|---|---|
`curves.springMotion()` `(response?, dampingFraction?)` `(response?, dampingFraction?)` | Physical spring motion curves | loose-hand adsorption and elastic return
`curves.responsiveSpringMotion()` |`(response?, dampingFraction?)` | Responsive spring curves with delay and hand feeling | drag-and-hand, suspension ball movement  Z
`curves.interpolatingSpring()` |`(velocity, mass, stiffness, damping)` | Plug-in spring curve | Accurate control of the attribution of spring parameters
Z`curves.initCurve()` |`(curve: Curve)` | Initialization curve for `interpolate()` | Progress-scale map calculation

# PlayMode enumeration value

Equation values Description
|---|---|
`PlayMode.Normal`| is playing once (default) |
`PlayMode.Reverse`| Plays in reverse once
`PlayMode.Alternate` ZEX is playing back-to-back
`PlayMode.AlternateReverse` ZEX ZEX

---

# scene 1: Waterline effects

** Scene description:** Simulates the dilation effect of listening to music, clicks on buttons and produces continuous outward water waveprint animations and clicks again to immediately stop the return.

** Solution:** Use** `animateTo` + `iterations: -1` Infinite Cycle** **deley stagged two players of **scale + dual attribution**

## # Step 1: Defines the gill state variable

```ts
@State isListening: boolean = false
@State immediatelyOpacity: number = 0.8
@State immediatelyScaleX: number = 1
@State immediatelyScaleY: number = 1
@State delayOpacity: number = 0.8
@State delayScaleX: number = 1
@State delayScaleY: number = 1
```

Two layers each maintain both levels of opacy and scale.

Step 2: Start the thorium - two groups animateTo + delay staggered

```ts
/ First tier: start immediately
animateTo({
  duration: 1300,
  iterations: -1,
  curve: Curve.EaseInOut
}, () => {
  this.immediatelyOpacity = 0
  this.immediatelyScaleX = 6
  this.immediatelyScaleY = 6
})

/ Second floor: 200 ms delay start
animateTo({
  duration: 1300,
  iterations: -1,
  curve: Curve.EaseInOut,
  delay: 200
}, () => {
  this.delayOpacity = 0
  this.delayScaleX = 6
  this.delayScaleY = 6
})
```

Key points: `iterations: -1` achieves an unlimited cycle, and `delay: 200` staggers two layers of gills to produce water wave proliferation vision.

Step 3: Stop gill-dururation: 0

```ts
animateTo({ duration: 0 }, () => {
  this.immediatelyOpacity = 0.8
  this.immediatelyScaleX = 1
/... reset all states
})
```

Step 4: Layout - Stack superheavy 2 Layers

```ts
Stack() {
  Circle().width(96).height(96).fill(Color.White)
    .opacity(this.immediatelyOpacity)
    .scale({ x: this.immediatelyScaleX, y: this.immediatelyScaleY })
Circle() / / Second layer
    .opacity(this.delayOpacity)
    .scale({ x: this.delayScaleX, y: this.delayScaleY })
Button() / / Trigger button, zIndex: 1
}.width('100%').height('100%')
```

---

scene 2: sidebar faded Out

**Scene description:** Simulates the information panel, slides out of the list of members on the right side behind the side button, and clicks again to close.

** Solution:** Use **`SideBarContainer(Embed)` + `animateTo` Driver `showSideBar`** ** ** `Curve.Friction` friction curve** + ** content area opacity connection**

Step 1: Toggle Sidebar

```ts
switchTabBar() {
  animateTo({ duration: 500, curve: Curve.Friction }, () => {
    this.isShowSideBar = !this.isShowSideBar
  })
}
```

Step 2: Layout - SideBarContainer + Conditions

```ts
SideBarContainer(SideBarContainerType.Embed) {
/ / Sidebar
  Column() {
Text.
    List() { LazyForEach(this.memberArray, ...) }
  }
.opacity (this.isShowSideBar ? 1:0) / / Link transparency degrees

/ Main content area (includes switch buttons)
  Stack() {
Column(){/* Chat */ TextInput()}
Text (this.isShowSideBar ? '▶: '◀)/ Switch button
      .onClick(() => this.switchTabBar())
  }
  .alignContent(Alignment.End)
}
.sideBarPosition(SideBarPosition.End)
.showSideBar(this.isShowSideBar)
.showControlButton(false)
.sideBarWidth(200)
.autoHide(false)
```

Key points: Automatic indentation of content area in Embed mode, buttons on `Alignment.End` automatically follow the right edge of the content area, without additional transport.

---

Scene 3: Number rolling

**Scene description:** Replicate ticketing/inventory numbers, with multiple numbers rolling from bottom to bottom to new random values, the longer the number changes.

** Solution:** Use ** father-son component split** + ** dual ForEach horizontal/vertical rendering number** + **translate({y}) offset + crip(true) crop** + **animateTo margin

Step 0: Component disassembly

This scenario needs to be divided into two components with separate duties:

-** Sub-component (digital scroll area)**: for digital rendering and rolling animation logic, new state of listening via `@Prop @Watch`
-** Parent Component (Refresh Container)**: holding `isRefresh` state, package Refresh component to provide refreshment capability

```ts
/ Subcomponent: is listening to changes trigger animation
@Component
struct DigitalScrollDetail {
  @Prop @Watch('onDataRefresh') isRefresh: boolean = false
  @State scrollYList: number[] = []
  private currentData: number[] = new Array(7).fill(0)
  private preData: number[] = new Array(7).fill(0)
  private dataItem: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  onDataRefresh() {
    if (!this.isRefresh) {
      this.refreshData()
    }
  }
/ ... the remaining steps are achieved in sub-components
}

/ / Parent Component: Refresh Container
@Entry
@Component
struct DigitalScrollPage {
  @State isRefresh: boolean = false

  build() {
    Refresh({ refreshing: $$this.isRefresh }) {
/ / Page Contents
      DigitalScrollDetail({ isRefresh: this.isRefresh })
    }
    .onRefreshing(() => {
      setTimeout(() => { this.isRefresh = false }, 1000)
    })
  }
}
```

Key points: Sub-components listen to changes in parent component `@Prop @Watch('onDataRefresh')`. When Refresh's `onRefreshing` returned to set `isRefresh` to `false`, the ZXXKEEP5ZX of the sub-component was triggered and a digital animation started.

Step 1: Data structure and constant

```ts
private readonly ITEM_HEIGHT: number = 26
private readonly FONT_SIZE: number = 22
private readonly DURATION_TIME: number = 200
private readonly NUMBER_LEN: number = 7
percent = 3// 1,000-point interval

@state
Other Organiser
Private preData: number[] = new Array(7). fill(0) / Last number
private dataItem: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] / 0-9 fixed Group
```

Step 2: Initialization offset

`scrollYList` must be initialized when the component appears, otherwise all numbers stacked at y = 0 at the first rendering cannot be shown correctly.

```ts
aboutToAppear() {
  const initialData: number[] = []
  for (let i = 0; i < this.NUMBER_LEN; i++) {
    initialData.push(Math.floor(Math.random() * 10))
  }
  this.currentData = initialData
  this.preData = [...initialData]
/ Key: calculation of initial deviations based on initial figures
  this.scrollYList = initialData.map((v: number) => -v * this.ITEM_HEIGHT)
}
```

Key points: The `scrollYList` annual value must contain to `currentData`, and the definition of each = `- numerical value x ITEM HEIGHT '.

### Step 3: Generate random numbers and animate place by place

```ts
refreshData() {
  const tempArr: number[] = []
  for (let i = 0; i < this.NUMBER_LEN; i++) {
    tempArr.push(Math.floor(Math.random() * 10))
  }
  this.currentData = tempArr

  this.currentData.forEach((item: number, index: number) => {
/ /Recommended to use get UIContext()? .animateTo, abandonment To
    this.getUIContext()?.animateTo({
      duration: Math.abs(item - this.preData[index]) * this.DURATION_TIME,
      curve: Curve.LinearOutSlowIn,
      onFinish: () => {
This. preData = [...this.currentData] // Expand operator to create new arrays to ensure state update
      }
    }, () => {
      this.scrollYList[index] = -item * this.ITEM_HEIGHT
    })
  })
}
```

Key points:
The longer the margin is animated, the more the real number flies.
- `onFinish` only update `preData` without setting ZXXKEEP2ZX (father controlled Refresh status)
- `preData` grant to expand the operator with `[...this.currentData]` to ensure that ArkUI detects array reference changes

Step 4: Layout - Double ForEach + krip

```ts
Row() {
  ForEach(this.currentData, (item: number, index: number) => {
/ 1,000-point comma
    if ((this.NUMBER_LEN - index) % this.MILLENNIAL_LEN === 0 && index !== 0) {
      Text(',')
        .fontWeight(FontWeight.Bold)
        .fontSize(this.FONT_SIZE)
    }
    Column() {
      ForEach(this.dataItem, (subItem: number) => {
        Text(subItem.toString())
          .fontWeight(FontWeight.Bold)
          .fontSize(this.FONT_SIZE)
.head('100%') / Must fill the height of Column to ensure equal spacing of numbers
          .textAlign(TextAlign.Center)
.translate({y: this.scrollYList[index}}) / /translate must be on Text
      })
    }
    .height(this.ITEM_HEIGHT)
    .clip(true)
  })
}
```

Key points:
- **FONT SIZE must ≤ ITEM HEIGHT**, otherwise the character exceeds the crip cropping area, resulting in a break in the base of the number and a spill of the top to the adjacent area. Recommended FONT SIZE than ITEM HEIGHT Small 4px (e. g. 22 vs 26) to complete the font
- **Translate must be applied on every Text**, not on the outer layer Column. Column sets `clip(true)` to cut the spill of sub-elements relative to Column, translate on Text to get 0-9 numbers rolling correctly in the cropping area. clip tailors the flow of Column as opposed to the spill of the parent's container, if translate is placed on Column, the numerical scrolling effect is invalid
- Every Text has to set `.height('100%')` and `.textAlign(TextAlign.Center)`, otherwise the numbers are not evenly organized vertically
-0-9 Numerical Numeric Group Proposal defined as a private component field `private dataItem: number[]` to avoid hard encoding in templates

---

Scene 4: Vote PK

**Scene description: ** Synopsis of PK voting, with one half of the votes being held before the vote and one half of the votes being divided between the two parties, with a smooth transition in the width of the vote and a high-profile view of the party chosen.

** Solution:** Use **animateTo drive width as a percentage string** + **Curve.Easeout **

Step 1: state definition

```ts
@State leftWidth: string = '50%'
@State rightWidth: string = '50%'
@state identifiedoption: string = ' / / Record user select party (' left' |right' |)
```

> ** Key points: ** Draws `selectedOption` to distinguish the selected from the unselected. An empty string before the vote, which records after the vote the choice of the user, drives the difference between the brightness and the darkening style.

Step 2: Vote Animation - Width Transition + Record Selection

```ts
doVote(option: string) {
/ Record user selection
  animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
    this.leftWidth = (leftPercent).toFixed(0) + '%'
    this.rightWidth = (rightPercent).toFixed(0) + '%'
  })
}
```

> **Keypoint: ** `selectedOption` external grant in `animateTo` to synchronize high-light style changes with width animations. Selector `opacity: 1` (full highlight), unselected `opacity: 0.5` (darker liner) and the difference between the two sides is smoothed by ZXXKEEP4ZX.

## # Step 3: Layout — Flex 2 paragraphs Stack + Selection Highlight / Darken without Selection

```ts
Flex() {
  Stack() {
    Text(leftLabel).fontColor(Color.White)
  }
  .width(this.leftWidth)
  .backgroundColor('#ff6b6b')
  .opacity(this.selectedOption === '' ? 1 : (this.selectedOption === 'left' ? 1 : 0.5))
  .animation({ duration: 600, curve: Curve.EaseOut })

  Stack() {
    Text(rightLabel).fontColor(Color.White)
  }
  .width(this.rightWidth)
  .backgroundColor('#4ecdc4')
  .opacity(this.selectedOption === '' ? 1 : (this.selectedOption === 'right' ? 1 : 0.5))
  .animation({ duration: 600, curve: Curve.EaseOut })
}
```

> ** Key points:**
> - ** Level III opability logic**: `selectedOption === ''` before voting; `opacity: 1` after voting; `opacity: 1` (highlight), unelected ZXXKEEP3ZX (darking) to create visual contrasts to highlight user selection
> - ** `.animation()` Concealed Animation**: opacity changes via `.animation({ duration: 600 })` auto-filling, synchronized with the width transition, brightness and width changes Done.
> - Removed the original global `fillOpacity` and changed it to an independent opability and highlighted the differences

---

# Scene 5: Trapped and drawn

** Scenario description: ** Simulates the suspension of a floating ball in a passenger suit, suspends a floating window and moves with a hand when the finger drags, and automatically flexes it to the nearest left/right edge of the screen.

** Solution:** Use **`curves.responsiveSpringMotion()` Drag and Grab Hand** + **`curves.springMotion()` Unhand Sorb** ** ** **`.position()` Absolute Position + `onTouch` Event**

Step 1: onTouch drag hands

```ts
.onTouch((event) => {
  if (event.type === TouchType.Move) {
    animateTo({ curve: curves.responsiveSpringMotion() }, () => {
/ Update Edge. left/right/top
      this.edge = { top: newY, left: newX }
    })
  }
})
```

Step 2: Unhand to the nearest edge

```ts
if (event.type === TouchType.Up) {
  const snapX = currentX < containerWidth / 2 ? margin : containerWidth - windowWidth - margin
  animateTo({ curve: curves.springMotion() }, () => {
    this.edge = { top: clampY, left: snapX }
  })
}
```

Key points: `responsiveSpringMotion` provides elastic delay and hand, `springMotion` provides efficacious ejection.

---

scene 6: Gradient edge

** scene description:** Simulates the horizontal slide list of the recommended pages, which can scroll horizontally when the contents exceed the visual area, and when rolling to the start/end position, the corresponding edge gradients the hint to the boundary; when rolling to the middle position, both ends show more elements on both sides of the gradient mask tip, with a smooth transition in the mask.

** Solution:** Control left and right masks ** + ** `.overlay()` superimpose gradients** ** ** ** `linearGradient({ angle: 90 })` left and right ** ** ** ** `.animation()` hidden animation smooth transition** ** ** ** `Scroller` + `onReachStart/onReachEnd/onDidScroll` accurately detect rolling positions**

## # Step 0: constant definition and status initialization

```ts
const GRADIENT COLOR: string = '#fff5f5f5'// non-transparent version of background colour to form a mask
const GRADIENT DURATION: number = 220 / / Mask hidden animation duration (ms)

@state showStartFade: boolean = false // Whether to show left mask (initially in starting position, not shown)
@state showEndFade: boolean = true / / Whether to show the right mask (initially in the starting position, hint on right)
private scroller: Scroller = new Scroller()
```

Key points:
- Controls the left and right masks with two `boolean` states `showStartFade`/`showEndFade`, which are clearer and less error-prone than the direct operation of a gradual colour string
- Initial state: left not shown (already left, no more content) and right (right hint with content)

Step 1: Listen to the rolling state

Three echoes each to update the bourbon state of both sides, with clear logic and no conflict:

```ts
List({ scroller: this.scroller })
  .onReachStart(() => {
    this.showStartFade = false
    this.showEndFade = true
  })
  .onReachEnd(() => {
    this.showStartFade = true
    this.showEndFade = false
  })
  .onDidScroll(() => {
    if (!this.scroller.isAtStart() && !this.scroller.isAtEnd()) {
      this.showStartFade = true
      this.showEndFade = true
    }
  })
```

Key points:
- `onReachStart`: Roll to the leftmost side → Hide left (to the head), Show right (with content)
- `onReachEnd`: Roll to the right-handmost left display (in front) and hide (overhead)
- `onDidScroll`: Show at the middle position at both ends. Use `isAtStart()` / `isAtEnd()` to determine the boundary, more semantic than `currentOffset().xOffset !== 0` and in a different device direction
- `onDidScroll` must add border judgement, otherwise the setting of the `onReachStart`/`onReachEnd` will cause the mask to blink

Step 2: Gradient Mask

Encapsulate the overlay as `@Builder`, calculates the colour array through the Boolean state and maintains a clear code:

```ts
@Builder
fadingOverlay() {
  Column()
    .width('100%')
    .height('100%')
    .linearGradient({
Angle: 90, / / Must Set: 90° = Left Right, Do Not Set Default Up Down
      colors: [
        [this.showStartFade ? GRADIENT_COLOR : '#00000000', 0.0],
        ['#00000000', 0.15],
        ['#00000000', 0.85],
        [this.showEndFade ? GRADIENT_COLOR : '#00000000', 1.0]
      ]
    })
    .animation({ curve: Curve.Ease, duration: GRADIENT_DURATION })
    .hitTestBehavior(HitTestMode.Transparent)
}
```

`.overlay()` binding on List:

```ts
List({ scroller: this.scroller }) {
/... Listitem content
}
.listDirection(Axis.Horizontal)
.overlay(this.fadingOverlay())
.edgeEffect(EdgeEffect.None)
.scrollBar(BarState.Off)
.onReachStart(() = > {/* Step 1*/})
.onReachEnd(() = >/* Step 1*/})
.onDidScroll(() = >/* Step 1*/})
```

Key points:
- **Bur status colour map**: `showStartFade` is true with `GRADIENT_COLOR` (colour mask), false with `'#00000000'` (full transparency), right-end homogeneity. Avoided color exchange logic and reduced probability of error.
- ** The `angle: 90`**: `linearGradient` must be set with the default direction of upper and lower (angle: 180) and the failure to set will result in the mask appearing on the upper and lower edges rather than on the left and left edges. 90° = Right left
- Tie a mask with `.overlay()` instead of a Stack superimpose. Overlay is attached directly to List, size matching automatically
- ** must set `.edgeEffect(EdgeEffect.None)`**: the default spring effect will generate a echo at the boundary, resulting in `onReachStart/onReachEnd` being covered by `onDidScroll` immediately after the trigger, and the mask flashing
- `.animation()` to automatically generate 220ms of colour change due to Boolean's state switch, smooth transition, ZXXKEEP1ZX makes the mask unstoppable.
- Overlay Column needs `.width('100%')` and `.height('100%')` to cover the entire List area
- `0.15 ~ 0.85` is fully transparent and does not affect the normal display of list contents

---

scene 7: vibrating

**Scene description:** Simulates the login page, click a key login when the protocol is not ticked, and the cell phone produces vibration feedback while "read and tick the protocol" hints to the left and right.

** Solution:** Vibration with **`vibrator.startVibration` Hardware** + **`keyframeAnimateTo` Key frame vibrating** + ** `translateX` bit mobile painting**

Step 1: Trigger hardware vibration

```ts
import { vibrator } from '@kit.SensorServiceKit'

startVibrate() {
  try {
    vibrator.startVibration({
      type: 'time',
      duration: 600
    }, { id: 0, usage: 'alarm' }, (error) => { /* ... */ })
  } catch (err) { /* ... */ }
}
```

Step 2: Key frame vibrating animation

```ts
startAnimation() {
  this.translateX = 0
  this.getUIContext()?.keyframeAnimateTo({ iterations: 2 }, [
    {
      duration: 100,
      event: () => { this.translateX = 5 }
    },
    {
      duration: 100,
      event: () => { this.translateX = 0 }
    }
  ])
}
```

Key points: `iterations: 2` Diverse 2 Rounds (0:5:0:0:0:0:5:5:0) `keyframeAnimateTo` supports precise key frame control. `ohos.permission.VIBRATE` permissions are required.

---

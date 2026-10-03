# Frame Animation Cases

# Apply scene

* Reissued for technical reasons.
|---|---|---|
| Load/Respiration Animation | `createAnimator` + `onFrame` + `direction:'alternate'` | Need to calculate the index of active elements on a frame-by-frame basis; alternate autoreverse |
`AnimatorResult` + `delay` + `onFinish` chain | accurate control of the start and end of each segment triggers the next part
Shimmer |XKEEP0ZX +`linear` + Global ZXXKEEP2ZX | Uno Animator Drive All Part-Scanning Synchronize All Pages
`direction:'alternate'` + `onRepeat` Flip ZOX Up-Scanning Up-Down + Flip Decoration Element
| Complex roll-up/take-up | Double-way reuse `AnimatorResult` + Customization process function | 8+ property phased connection, `onFrame` frame by frame

# Core Animation API Enumeration Reference

No, no, no, no.

| Parameter | Type | Description |
|---|---|---|
`duration` | number | single animation duration (ms)|
`iterations` | number number number number, 1 for unlimited circulation
`begin` | number number animation start value
`end` number animated end value
`easing` | string | slow curve name
`delay` | number | animation delay (ms), default 0 |
`direction` | string | Animation direction, default `'normal'`|
`fill` | string | Animation fill mode, default `'none'`|

##Direct

| | |
|---|---|---|
`'normal'` | is playing (beginsend) | Loading animations, progress bars |
`'reverse'`| Reverse playback (end→begin)| Countdown time effect
`'alternate'` zirconium (begin)
`'alternate-reversed'` ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZOO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO

# # fill fill mode count values

| | |
|---|---|---|
Z `'none'` | do not fill, return to the initial value after the animation | One-time animation |
`'forwards'` ZEX ZEX ZEX ZEX ZEX ZEX
`'backwards'` | Displays the first frame during the delay while the animation is delayed
`'both'` ZiZiZiZi, apply both forwards and backwards ZiZiZi, and keep the initial frame completely.

# # eating a slow curve string value

| String Value | Description | Typical scene |
|---|---|---|
`'linear'` | linear velocity | |  Z
Z`'ease'`| Universal slow motion | Player Expand/Close
`'ease-in'`  Z slows in and leaves the element
`'ease-out'` ZeroZix Zero
`'ease-in-out'` | slow-in-out | universal transition |
`'friction'` ZZZZZZZZZZ Z Z Z Z Z Z Z Z Z Z Z Z
`'extreme-deceleration'` Z0ZX Z0
`'sharp'`|  Z  Z  Z  Z  Z  Z |
`'rhythm'` X X X X X X
`'smooth'`| smooth transition | smooth curve  Z

#ANIMATORResult Method

Methodology
|---|---|
`.play()`| Starts animation
`.cancel()` | Cancel animation and reset to initial state
`.finish()` Zulu completes the animation to final state
`.pause()`| Pause Animation
`.reset()` | Reset animation to initial state
Z `onFrame` Revert | Trigger per frame, parameter is the current frame value |
`onFinish`, back, back.
`onRepeat` echo | | Trigger every time you repeat

# # Curve numeric count value (commonly used in frame animation)

| | |
|---|---|---|
`Curve.LinearOutSlowIn` X-ray, slow out, slow down.
`Curve.Ease` ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX
`Curve.EaseInOut` | Slow-Quick-Slow | General Transition |

---

# scene 1: Load animated

** scene description: ** Three common Loding styles: 1 five dot jump up and down; 2 system circle progress rotation indicator; 3 pulse loops spreading from centre to centre breathing effect. Click the button to start three animations at the same time.

** Solution:** Use **`AnimatorResult(createAnimator)`** ** **`onFrame` Rewinding ** ** ** ** `direction:'alternate'` Reverse**

Step 1: Tilt - onFrame Calculate Active

```ts
const dotAnimator = createAnimator({
  duration: 2000,
  iterations: 1,
  begin: 0,
  end: 1
})
dotAnimator.onFrame = (progress) => {
  const cycleProgress = progress * 4 * 5  // 5 dots * 4 cycles
  const activeIndex = Math.floor(cycleProgress) % 5
  this.dotScales = Array.from({ length: 5 }, (_, i) => i === activeIndex ? 1.5 : 1)
  this.dotOpacities = Array.from({ length: 5 }, (_, i) => i === activeIndex ? 1 : 0.3)
}
```

Step 2: Pulse Circle - Direction

```ts
const pulseAnimator = createAnimator({
  duration: 1000,
  direction: 'alternate',
  iterations: 6,
  begin: 1,
  end: 1.5
})
pulseAnimator.onFrame = (value) => { this.pulseScale = value }
```

---

# Scene 2: Check successful

**Scene description:** Simulates the payment success page, clicks the button and appears in turn: Green circle pops up a chorus from the center of the circle and draws a chorus that spreads out, cucumbers the "pay success" text from the bottom to the bottom, with four animated line links.

** Solution:** Using **4 `AnimatorResult` serials delay + `onFinish` chain trigger** ** ** `easing:'friction'` eject** + ** proliferation **

Step 1: Green round bullets Out

```ts
createAnimator({ duration: 400, easing: 'friction', delay: 100, begin: 0, end: 1 })
.onFrame = (v) => { this.circleScale = v; this.circleOpacity = v }
```

Step 2: Deray 400ms

```ts
createAnimator({ duration: 300, easing: 'friction', delay: 400, begin: 0, end: 1 })
.onFrame = (v) => { this.checkScale = v; this.checkOpacity = v }
.onFinish=()=>{/* Trigger*/}
```

# # Step 3: Radium proliferation

```ts
createAnimator({ duration: 600, easing: 'ease-out', begin: 1, end: 1.5 })
.onFrame = (v) => { this.rippleScale = v; this.rippleOpacity = 2 - v }
```

Step 4: Move text up (delay,700ms)

```ts
createAnimator({ duration: 400, easing: 'ease-out', delay: 700, begin: 20, end: 0 })
.onFrame = (v) => { this.textOffsetY = v; this.textOpacity = 1 - v / 20 }
```

---

Scene 3: Bones screen Shimmer

** scene description:** mimics social feed stream loading position, with the data being loaded showing the grey skeleton space block (headage, title line, text line) with a scintillation effect from the left-to-right cycle through one high-light synchronization in each of the slots; after loading, the skeleton crosses into the actual content and the Shimmer sweep sync stops.

** Solution:** Use **`AnimatorResult` Unlimited Cycle ZXXKEEP1ZX Horizontal Sweeping Drive Global ZXXKEEP2ZX** ** ** `linearGradient` 5 Port Transparency Highlight Belt** ** ** ** Reusable ZXKEEP4Z** ** ** `.clip(true)` Shearing Out** ** ** ** `Stack` Cross-Drinking + Independent `fadeAnimator` **

Step 1: Shimmer Sweep Animation - cycle limitless

> Animated Engine Body. Creates `shimmerAnimator`, `onFrame` drive ZXXKEEP3ZX for sharing of all space blocks.

`showLoading()` Creates ZXXKEEP1ZX, `shimmerAnimator`, `begin/end` is -350/350 (over the left and right bounds of the width of the component) and `onFrame` assigns value to the global `shimmerTranslateX` for all occupied blocks to share. `cancel` Old Animators avoid supersing each call.

```ts
@State shimmerTranslateX: number = -350
@State skeletonOpacity: number = 1
@State contentOpacity: number = 0
private shimmerAnimator: AnimatorResult | undefined = undefined

showLoading() {
  if (this.shimmerAnimator) { this.shimmerAnimator.cancel(); }
  this.skeletonOpacity = 1;
  this.contentOpacity = 0;

  this.shimmerAnimator = this.getUIContext().createAnimator({
    duration: 1500, easing: 'linear', fill: 'forwards',
    iterations: -1, begin: -350, end: 350
  });
  this.shimmerAnimator.onFrame = (value: number) => {
    this.shimmerTranslateX = value;
  };
  this.shimmerAnimator.play();
}
```

Key points:
- `iterations: -1` Infinite Cycle +ZXXKEEP1ZX velocity to ensure that the high-light sweep is evenly speeded/ slow Sensor.
- `begin: -350, end: 350` exceeding the width of the component, which allows the high light to slide from the left side screen, and the right side screen to slip out, avoiding the sudden/sudden disappearance of the edges
- All occupied blocks share the same `shimmerTranslateX`, single-angle drive all occupied blocks of the entire page Move!
- Lieutenant General `aboutToDisappear` sets `shimmerAnimator` to `undefined` to prevent leakage of animators after page destruction

Step 2: Shimmer Highlight Belt - Reusable

> Pure UI layout. Defines the status variable of `@Builder shimmerLine/shimmerSquare`, which constructs a high-light belt, `.translate({ x })` binding step 1 with transparency of ZXKEEP1Z5. No animation logic.

Each skeletal piece is a `Stack` superheavy two layers: the grey base + the high-light gradient. The high PVKEEP1ZX (full transparency on both sides, and central translucent white) is used to follow and sweep through ZXXKEEP2ZX. Enveloped with two `shimmerLine` (reverse) and `shimmerSquare` (square/ circular) duplicates.

```ts
@Builder shimmerLine(width: Length, height: Length, radius: number) {
  Stack() {
/ / Grey Bottom
    Column().width(width).height(height).borderRadius(radius).backgroundColor('#e0e0e0')

/ / High-light gradient – 5 Plasma transparency to create a narrow line of high light
    Column()
      .width(width).height(height).borderRadius(radius)
      .linearGradient({
        angle: 90,
        colors: [
['#00ffffff', 0], // Full transparency
['#00ffffff', 0.35], / / Transition starting point
['#33ffffff', 0.5], / / Highlight Center (20% white)
['#00fffffff', 0.65], // / Transitional Endpoint
['#00ffffff', 1] // Full transparency
        ]
      })
.translate({x: this.shimmerTranslateX})// Follow Global Sweep Move!
  }
  .width(width).height(height)
.clip(true) // Cropping: the invisible part of the high light beyond the size of the bits
}
```

The skeletal configuration is composed of several `shimmerLine`/`shimmerSquare`:

```ts
Column() {
  Row() {
This.shimmerSquare(60,30) / / header position (round)
    Column() {
/ Title
This.shimmerLine(100, 12, 6) // Subheading
    }
  }
This.shimmerLine('90%', 16, 8) / / bodyline
  this.shimmerLine('75%', 16, 8)
  this.shimmerLine('85%', 16, 8)
  /* ... */
}
.opacity(this.skeletonOpacity)
```

Key points:
`0.35→0.5→0.65` in the gradient of the `0.35→0.5→0.65` is a narrow strip of high light of only 30% width, both sides of `0→0.35` and `0.65→1` are fully transparent, making the light look like a light belt instead of a whole face.
- `angle: 90` allows gradients horizontally (left to right) and horizontally sweeps with `translate({ x: shimmerTranslateX })`
- `.clip(true)` Crop Stack Boundaries: the upper part of the upper spectral layer that is beyond the size of the block during `translate` has been reduced to ensure that the light is visible only within the area of the slot
- `shimmerLine` and `shimmerSquare` only have different parameters (the latter is the same width) and the same Stack double-layer structure is used for all placeholder shapes

Step 3: Load Finish - Stop Shimmer + Cross-Drink [core]

> Animated Drive. First `cancel` destroys `shimmerAnimator` to stop sweeping and then create a single `fadeAnimator`, ZXXKEEP3ZX sync drive double-layer opacity changes to cross-blank.

`showContent()` First `cancel` and destroy ZXXKEEP2ZX (stop sweeping) and then create a single `fadeAnimator` driver `contentOpacity` from 0→1, `skeletonOpacity` from 1⁄0 to achieve cross-flining of the skeleton with the actual content. The skeleton layer and the actual content layer are superimposed in `Stack`, bound to each other 'opity.

```ts
showContent() {
/ Stop Shimmer Sweep
  if (this.shimmerAnimator) {
    this.shimmerAnimator.cancel();
    this.shimmerAnimator = undefined;
  }

/ / Cross-fade: One-time animator-driven double layer
  this.fadeAnimator = this.getUIContext().createAnimator({
    duration: 400, easing: 'ease-out', fill: 'forwards',
    iterations: 1, begin: 0, end: 1
  });
  this.fadeAnimator.onFrame = (value: number) => {
This. currentOpacity = value; / /real content 0 →1
Other Organiser
  };
  this.fadeAnimator.play();
}
```

`Stack` superheavy the layout upper cascading layer and the actual content layer bound by `Stack`

```ts
Stack() {
Column() {/* Bones block*/ }.opacity (this. skeletonOpacity)
Column(){* Real content (headprint, text, pictures)*/}.opability (this.contentOpacity)
}
```

Key points:
- `showContent` at the beginning of `cancel` + with `undefined` to completely destroy ZXXXKEEP3ZX to prevent visual disturbances caused by the high light during cross-defiction
- `fadeAnimator` uses `iterations: 1` to play one-time +`ease-out` curves, skeletal skeletal fast disappearing, real content smoothing Floating Current
- `onFrame` `contentOpacity = value` and `skeletonOpacity = 1 - value` are synchronized to update in the same echo to ensure that the two layers of transparency are always complementary (and equal to 1) and seamlessly intersect
- `Stack` superimposes two layers instead of `if/else` condition rendering: two layers are visible at the same time during the cross-deficient period and are complementary to each other, avoiding the transient flashing of the moment

---

Scene 4: Custom Scanning

**Scene description: ** Simplified Scanning interface, ** The center of the screen shows a square scanning frame, a blue scanning line up and down in the frame, a diamond light on top of the scanning line followed and scalded and respirated, and a decorated corner marked the identification area.

** Solution:** Use **`AnimatorResult` + `direction:'alternate'` Up and Down ** ** **`onRepeat` Flip Shadow** ** ** ** `.position()` Scanline/ Angular Positioning**

## # Step 1: Scan wire animation [core]

> Animated engine capital, `onFrame` frame-driven scanning line position and shade scaling, `onRepeat` flipping the diamond angle.

```ts
const scanAnimator = createAnimator({
  duration: 2000,
  direction: 'alternate',
  iterations: -1,
  begin: 0,
End: 100 / / SCAN ARAA Height
})
scanAnimator.onFrame = (value) => {
  const normalized = value / 100
  this.linePosition = SCAN_AREA * normalized
/ / Shadow Zooming: Zoom in first half and then back half
  this.shadowScale = normalized < 0.389
    ? 0.5 + normalized * 2
    : 0.5 + (1 - normalized) * 2
}
scanAnimator.onRepeat = () => {
  this.scanAngle = this.scanAngle === 0 ? 180 : 0
}
```

Step 2: Layout - Scan Box + Angular Marker + Scan Line [Support]

> Pure UI layout, `.position()` positioning element and binding the state variable for step 1.

```ts
Stack() {
/ / Quadrant
  Image($r('app.media.scan_corner')).position({ x: 0, y: 0 })
  // ...
// Scan Line
  Row().width('80%').height(2)
    .backgroundColor('#4facfe')
    .position({ x: '10%', y: this.linePosition })
/ Shading
  Text().width(60).height(60)
    .scale({ x: this.shadowScale, y: this.shadowScale })
    .rotate({ angle: this.scanAngle })
    .position({ x: '35%', y: this.linePosition - 30 })
}
.width(200).height(200)
.clip(true)
```

---

scene 5: Mini Player

** scene description: ** Analogous music player with a mini-player bar at the bottom of the page showing the cover and song name, clicked on the mini-player seamlessly spread the full-screen playback page (cover zoomed from the top left corner to the middle of the screen, the details page slipped from the bottom), drags down the details page to follow it in real time and then decides to bounce back or to close it completely on the basis of the location threshold.

**Solution:** Use **`AnimatorResult` for two-way reuse + Custom `expandCollapseAnimation(progress)` multi-relationship** ** ** Double Cover Layer Switch** ** ** Phase two-phase ** ** **`PanGesture.onActionUpdate` gesture real-time driver + `onActionEnd` + `animateTo` threshold **

Step 0: Page Environment and Constant System [core]

> Base number of animation distance depends on the page layout. BAR HEIGHT is the most critical constant - it determines the calculation of the three distance parameters of MiniDistanceToBottom/miniDistanceToTop/miniImgToDetailsPageImgDistance. The missing BAR HEIGHT will cause the entire distance system to shift and the animation trajectory does not match expectations.

** Page level (zIndex from low to high):**

|Index
|---|---|---|---|
|Recommended page 0 |Search + Banner + Songlist Grid
| Bottom Tabs |5 Home / Line / My |BAR HEIGHT(56) |
| Mini Player | Cover + Song Name + Play/ Next Music Control | MINI HEIGHT(56) |
| Details Page | 20 | Dark Background + Cover Zoom + Play Control + PanGesture | Full Screen |

** Total constant:**

| constant value | function | omission consequences |
|---|---|---|---|
|Mini HEIGHT | 56 | Mini player line high |
**BAR HEIGHT**  ** 56** ** base height of Tab bar** ** **ministanceToBottom offset, distance system collapse** **
| MINI IMG SIZE | 40| Mini Player Cover Size |
|DETAILS PAGE IMG SIZE | Cover Size for Details Page |
| MINI IMG MARGIN LEFT |12 Left margin of the cover | Horizontal deviation of the cover
| MINI IMG RADIGUS | 4 Covered Circle Angle | Mini/Details Unmatched Circle
|ANIMATION PROGRESS |0.3 |2-stage divide |
|backHeight initial value 800 | on AreaChange
|backWidth initial value 360 | on AreaChange

** Distance parameter calculation (bar HEIGHT effect):**

```
MiniDistanceToBottom = MINI HEIGHT + BAR HEIGHT // 56 + 56 = 112 (the sum of the two columns)
MiniDistanceToToToToToToToToToToToToToToToTo/ Expand Vertical Distance
MiniImgToDetailsPageImgDistance = end value of MiniDistanceToTop / /AnimatResult
MiniPlayery =backHeight - MINI HEIGHT - BAR HEIGHT// MiniPlayer hangs over Tabs
```

If `BAR_HEIGHT = 0`: MiniDistanceToBottom changes from 112 to 56, the mini player paste instead of hanging over Tabs, expands the distance of the base figure by approximately 56px, expands the cover and moves the trajectories up the detailed pages against expectations.

** The recommended page must have real content**, providing visual anchors for mini-players: Seach Component + Banner Chart + Songlist Grid. Scroll bottom padding is set to `MINI_HEIGHT + BAR_HEIGHT` to prevent content from being overshadowed by mini players and Tabs.

** A dark theme must be used on the detailed pages** (backgroundColor: `#1a1a2e`, text fontColor: `Color.White`/`'#cccccc'`). Dark background allows for a strong visual contrast between cover, white text and icons; light background (e.g. `#f5f5f5`) is weak and the cover is magnified with a significant loss in visual impact.

Step 1: Double Layer Layout - Stack Layer Collapse + Double Cover Switch [core]

> The entire structure of the animation. The two-covered cover policy (static cover + animated cover is interactively interactive) determines the state design of all subsequent animations.

Use `Stack` to superimpose the mini player (zIndex 10) and the details page (zIndex 20) on the page contents. The cover sheet follows a two-example **: The static cover (`miniImgOpacity` control) in the mini-player and the animated cover (`miniImgAnimateOpacity` control) in the detailed page are two separate ZXXKEEP3ZXs, which are dropped out and the latter faded and amplified, avoiding the simultaneous binding of two layout sets by the same element.

** The details page under the pullout state must be located outside the screen** (`position y = stackHeight + 100`), instead of relying on `opacity = 0` to hide. Because the details page of `zIndex(20)`, even if ZXKEP3ZX were involved in the hit test, would intercept `onClick` from the next mini player. After moving its physical position to the bottom of the screen, the two layers of the touch area no longer overlap and the interception is avoided.

```ts
@State miniPlayerOpacity: number = 1
@state MINIMgOpacity: number = 1/ / status cover in your player
@StatelineImgAnimateOpacity: number = 0/ / Animated cover page
@state MINImgofsetX: number = 0// cover horizontal offset (close to screen centre)
@state MiniImgofsetY: number = 0// cover vertical offset (drive, 0→disistance)
@stateminiImgofsetSize: number = 0// Cover Size Increase (07220px)
@State detailsPageOpacity: number = 0
@State detailsPagePositionY: number = 0
@state degrees
@State miniPlayerY: number = 0
@State miniChangeHeight: number = 0

/ about ToAppear: kick both floors off the screen before the front frame, wait on AreaChange until he gets his real size.
aboutToAppear() {
  this.detailsPagePositionY = 9999
  this.miniPlayerY = 9999
}

@Builder miniPlayer() {
  Row() {
Image(/* Cover*/)
      .width(MINI_IMG_SIZE).height(MINI_IMG_SIZE)
.opacity (this.miniImgOpacity) // Static cover: fading when expanding
      .margin({ left: MINI_IMG_MARGIN_LEFT + this.miniImgOffsetX + this.miniImgOffsetSize })
* * song name, control button, */
  }
. height (MINI HEIGHT + this.miniChangeHeight) / / height with contraction
  .opacity(this.miniPlayerOpacity)
  .position({ x: 0, y: this.miniPlayerY })
  .zIndex(10)
}

@Builder detailsPage() {
  Column() {
Row() {/*top navigator*/}.opacity (this.detailsPageTopOffice)
Image(/* Cover - Animated Copy */)
.width (MINI IMG SIZE + this.miniImgofsetSize) / Zoom in from 40px to 260px
      .height(MINI_IMG_SIZE + this.miniImgOffsetSize)
.opacity (this.miniImgAnimateOpacity) / /Drink while expanding
      .margin({ left: MINI_IMG_MARGIN_LEFT + this.miniImgOffsetX })
* Song information, play controls, etc. */
  }
  .opacity(this.detailsPageOpacity)
  .position({ x: 0, y: this.detailsPagePositionY })
  .zIndex(20)
}
```

`onAreaChange` returns to two layers after the first layout:

```ts
.onAreaChange((oldValue: Area, newValue: Area) => {
  this.stackHeight = newValue.height as number
  this.stackWidth = newValue.width as number
  if (!this.isExpand && !this.isAnimating) {
    this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT
This.detailsPagePositationY = this.stackHeight + 100 // Move the details page to 100px below the screen
  }
})
```

Key points:
- The two-covered plan policy is at the heart of the scene: static cover controlled by `miniImgOpacity` in place of the mini-player, animated cover covered by `miniImgAnimateOpacity` + `miniImgOffsetSize` + `miniImgOffsetX` drive for zooming and centering through opacy
- `miniImgOffsetSize` superimpose to `width`/`height` (`MINI_IMG_SIZE + offsetSize`) to achieve continuous Zoom-up from 40px to 260px
- `miniImgOffsetX` superimpose to `margin.left` to move cover gradually from the left edge to the center of the screen horizontal
- `onAreaChange` captures the real size of `stackHeight`/`stackWidth` at the first layout of the page for all subsequent position calculations
- **Signature details page located outside the screen** (`stackHeight + 100`): `zIndex(20)` details page even if ZXXKEEP2ZX is involved in the hit test will intercept the touching event of the mini-player if you stay in the visual area. Position to the bottom of the screen, two layers of touch area no longer overlap, without `hitTestBehavior` or condition rendering
- `aboutToAppear` sets two initial layers of `position` to `9999` (Face Screen) to avoid an error in position on the front frame before ZXXKEEP3ZX triggers
- **Recommended page Scroll bottom padding** set to `MINI_HEIGHT + BAR_HEIGHT` to prevent content from being overshadowed by mini players and Tabs
- ** Bottom Tabs ** (zIndex: 5, barHeight:BAR HEIGHT) must exist and the mini player is located above it rather than at the bottom; ignoring BAR HEIGHT will cause the total deviation from distance calculation
-**Dark theme for detailed pages** (`#1a1a2e`) strongly contrasts cover with white text, light theme is weak and cover amplification is not significant

Step 2: Multi-Intangible Animation Function - expandCollapse Animation [core]

> Animated algorithm core. Receives 0 →1 progress values, calls one time to synchronize the 8 + status variable and controls the alternation between two stages of disposition = 0.3.

This function receives a progress value of 011 and updates 8+ status variables in a single call. The core policy is two stages of `progress = 0.3` disposition: the first 30% mini-player fads out + details page up; and then 70% of the details page is fully visible + cover continues to zoom in.

```ts
private expandCollapseAnimation(progress: number) {
// Cover Size Increase: 0 → (260-40) = 220px
  this.miniImgOffsetSize = (DETAILS_IMG_SIZE - MINI_IMG_SIZE) * progress;
/ / Cover horizontal offset: close to the center of the screen
  this.miniImgOffsetX =
    ((this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2 - MINI_IMG_MARGIN_LEFT) * progress;

  if (progress < ANIMATION_PROGRESS) {   // ANIMATION_PROGRESS = 0.3
/ Stage 1: Mini player fading, detail pages remain invisible but move up
    this.detailsPageOpacity = 0;
    this.miniPlayerOpacity = 1 - progress / ANIMATION_PROGRESS;
    this.detailsPagePositionY = this.stackHeight - this.miniImgOffsetY - this.miniDistanceToBottom;
  } else {
/ Stage 2: Mini Player is completely hidden, detail pages appear and dominate
    this.miniPlayerOpacity = 0;
    this.detailsPageOpacity = 1;
    let detailsPageOffsetY = this.miniDistanceToTop * progress -
      (this.miniDistanceToTop - this.miniImgToDetailsPageImgDistance) * ANIMATION_PROGRESS *
      ((1 - ANIMATION_PROGRESS) - (progress - ANIMATION_PROGRESS)) / (1 - ANIMATION_PROGRESS);
    this.detailsPagePositionY = this.stackHeight - detailsPageOffsetY - this.miniDistanceToBottom;
  }
/ / Mini Player Location and Height Follow
  this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT - this.miniImgOffsetY;
  this.miniChangeHeight = this.miniImgOffsetY;

/ / Upside Navigator Bar for Details: Upon arrival of the top half of the screen Fade
  this.detailsPageTopOpacity =
    this.detailsPagePositionY <= this.stackHeight / 2
      ? 1 - this.detailsPagePositionY / (this.stackHeight / 2) : 0;
}
```

Key points:
- `miniImgOffsetY` is a global driver (a direct grant from animater or gesture), `expandCollapseAnimation` reads it instead of self-calculating, ensuring that the animators are in the same state as the two paths of the gesture
- Phase 1 (process < 0.3): `miniPlayerOpacity` from linear 1 to 0, `detailsPageOpacity` maintains 0 (detail pages are not visible but positions have moved up from the bottom of the screen) to avoid the early appearance of the detail pages creating visual palsy
- Phase 2 (process > = 0.3): `miniPlayerOpacity` lock 0, `detailsPageOpacity` Switch to 1 (detail page visible) and continue to move up to `y = 0` using a separate `detailsPageOffsetY` formula
- `detailsPageTopOpacity` only fades into the upper half of the screen when the details page enters, avoiding early visual interference from the navigation column
- Covered `offsetSize` and `offsetX` linear interpolation values across 0→1, unrelated to phase two, ensuring smooth expansion of the cover

Step 3: Two-way AmadorResult - Expand and reuse the same animator [core]

> Animated Drive Entry. Creates `AnimatorResult`, `onFrame` to call step 2 in the direction of `isExpand`, `doExpand()` / `doCollapse()` to calculate distance parameters and initiate animation. **doExpand and doCollapse have to be independent methods**, which differ substantially in the cover-tap switching strategy.

A single `AnimatorResult` created by `begin: 0, end: miniImgToDetailsPageImgDistance`, with `onFrame` distinguishing between directions by ZXXKEEP3ZX sign: progress is (0→1) in motion and reverse (1?0). `onFinish` locks in the end state according to orientation**.

```ts
private createAnimatorAndPlay() {
  if (this.animatorObject) { this.animatorObject.cancel(); }
  this.animatorObject = this.getUIContext().createAnimator({
    duration: 500, easing: 'ease', fill: 'forwards', iterations: 1,
    begin: 0, end: this.miniImgToDetailsPageImgDistance
  });

  this.animatorObject.onFrame = (value: number) => {
    if (!this.isExpand) {
      let progress: number = value / this.miniImgToDetailsPageImgDistance;
      this.miniImgOffsetY = value;
      this.expandCollapseAnimation(progress);
    } else {
      let progress: number = 1 - value / this.miniImgToDetailsPageImgDistance;
      this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance - value;
      this.expandCollapseAnimation(progress);
    }
  };

  this.animatorObject.onFinish = () => {
    this.isAnimating = false;
    if (!this.isExpand) {
      this.isExpand = true;
This.
This.miniPlayerOpacity = 0; / / Visible locking: the minibar must be hidden to expand completion
    } else {
      this.isExpand = false;
      this.resetExpandState();
    }
  };

  this.animatorObject.play();
}

private doExpand() {
  if (this.isAnimating || this.isExpand) return;
  this.miniDistanceToBottom = MINI_HEIGHT + BAR_HEIGHT;
  this.miniDistanceToTop = this.stackHeight - this.miniDistanceToBottom;
  this.miniImgToDetailsPageImgDistance = this.miniDistanceToTop;
This.miniImgOpacity = 0;// static cover Light Out
This.miniImgAnimateOpacity = 1;// Animated Cover Light Enter
  this.isAnimating = true;
  this.createAnimatorAndPlay();
}

private doCollapse() {
  if (this.isAnimating || !this.isExpand) return;
This.miniImgAnimateOpacity = 0; / / Animated cover fading (only one item!)
  this.isAnimating = true;
  this.createAnimatorAndPlay();
}
```

Key points:
- Animator: `isExpand` in `onFrame` determines the direction of progress, `isExpand` in `onFinish` determines the state lock (expand `isExpand=true` + `detailsPageOpacity=1` + `miniPlayerOpacity=0`; close `resetExpandState()`)
- **onFinish must have a visible end state* *: roll-out complete visible `detailsPageOpacity=1, miniPlayerOpacity=0` to ensure the accuracy of the animated endpoint; collect complete call `resetExpandState()` to reset all states (including ZXXKEEP2ZX)
- **doExpand() and doCollapse() cover transition strategy**: `miniImgOpacity=0` + `miniImgAnimateOpacity=1` (static cover fading, animated cover faded); only ZXXKEEP2ZX (animated cover fading), ** do not restore meiniImgOpacity=1** - static cover restored by resetExpandstate and should not appear prematurely during the collection of animations, otherwise the visual cover will "jump back" Column
- `miniImgToDetailsPageImgDistance` as an animator ZXXKEEP1ZX is equal to the vertical distance of the cover from the position of the mini to the position of the detailed page, which is used as the denominator for all aspects of calculations
- `isAnimating` Validation Lock: Animation is ongoing and new expansion/recycling requests are denied

## # Step 4: An interactive hand collection - PanGesture drive in real time + animateTo threshold judgement [Assisting]

> Interactive enhancement. Reliance on step 0-3 structures that have been put in place to add an interactive path of "real-time pull-down of gestures". ** The gesture phase has to distinguish between two stages**: process < 0.3 driven directly by mineImgofsetY, process > = 0.3 using miniDistanceToTop * process composite formula, consistent with the animation phase logic of step 2.

`PanGesture`: `onActionUpdate` binds the details page to map the drag-and-drop distance to the problem,** directly to the state variables* * (Non-recall to `expandCollapseAnimation` because the detail pages of the gesture phase are always visible, pacity is of different logic); `onActionEnd` determines the ejection or full recovery of the bullet based on the current position threshold.

```ts
.gesture(
  PanGesture()
    .onActionUpdate((event?: GestureEvent) => {
      if (this.isAnimating || !event) return
If (event.offsety > =0) {// allow infsety=0 (do not ignore zero offsets)
        let progress: number = 1 - event.offsetY / this.miniDistanceToTop;
        if (progress < 0) progress = 0;
/ / Update the status variable directly (without calling extandCollapseAmination, keep detailed pages visible)
        this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance * progress;
        this.miniImgOffsetSize = (DETAILS_IMG_SIZE - MINI_IMG_SIZE) * progress;
        this.miniImgOffsetX = ((this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2
          - MINI_IMG_MARGIN_LEFT) * progress;
        this.miniChangeHeight = this.miniImgOffsetY;
        this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT - this.miniImgOffsetY;

// The gesture phase must also distinguish between two stages, consistent with the logic of the animation phase of step 2
        if (progress < ANIMATION_PROGRESS) {
/ Phase 1: MiniPlayer Fades out, lined with mineImgofsetY direct driver position (following cover offset)
          this.miniPlayerOpacity = 1 - progress / ANIMATION_PROGRESS;
          this.detailsPagePositionY = this.stackHeight - this.miniImgOffsetY
            - this.miniDistanceToBottom;
        } else {
/ / Stage 2: Mini Player Hides, details pages move up with a composite formula
          this.miniPlayerOpacity = 0;
          this.detailsPagePositionY = this.stackHeight - this.miniDistanceToTop * progress
            - this.miniDistanceToBottom;
        }
This.
        if (this.detailsPagePositionY <= this.stackHeight / 2) {
          this.detailsPageTopOpacity = 1 - this.detailsPagePositionY / (this.stackHeight / 2);
        } else {
          this.detailsPageTopOpacity = 0;
        }
      }
    })
    .onActionEnd(() => {
      if (this.isAnimating) return;
      this.getUIContext().animateTo({
        duration: 200, curve: Curve.LinearOutSlowIn,
        onFinish: () => {
          if (this.detailsPagePositionY > this.stackHeight / 2) {
This.resetExpandstate(); // / Overline → Full close
          }
        }
      }, () => {
        if (this.detailsPagePositionY <= this.stackHeight / 2) {
/ / Bouncing back up: back to full expansion
          this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance;
          this.miniImgOffsetSize = DETAILS_IMG_SIZE - MINI_IMG_SIZE;
          this.miniImgOffsetX = (this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2
            - MINI_IMG_MARGIN_LEFT;
          this.detailsPageTopOpacity = 1;
          this.miniPlayerOpacity = 0;
          this.detailsPageOpacity = 1;
          this.detailsPagePositionY = 0;
          this.miniPlayerY = 0;
        } else {
/ / Retrieve mini-state: detailed page pushed back below screen to restore initial state
          this.miniImgOffsetY = 0;
          this.miniImgOffsetSize = 0;
          this.miniPlayerOpacity = 1;
          this.miniImgOffsetX = 0;
          this.detailsPageOpacity = 0;
          this.miniChangeHeight = 0;
          this.detailsPagePositionY = this.stackHeight;
          this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT;
        }
      });
    })
)
```

Key points:
- ** The gesture phase must distinguish between two stages**: progress < 0.3 `detailsPagePositionY = stackHeight - miniImgOffsetY - miniDistanceToBottom`; details > = 0.3 `detailsPagePositionY = stackHeight - miniDistanceToTop * progress - miniDistanceToBottom`; details pages moved up with a composite formula. Distinction can lead to a more detailed shift curve when the gesture drags, which is inconsistent with the logic of the animation phase
- `onActionUpdate` does not call `expandCollapseAnimation`, but is a direct operational status variable: the hand-to-hand drag detail page is always `detailsPageOpacity = 1` (user is looking at the details page), only ZXXKEEP3ZX is still following a two-stage strategy
-Progress direction: the larger `offsetY` (towed down), the smaller the progress (to 0 = collected), the less `event.offsetY < 0` (towed up);** allows `offsetY >= 0`** (with zero deviations), which is different from the severe neglect of `event.offsetY < 0` as determined during the animation phase
- `onActionEnd` with `this.getUIContext().animateTo()` instead of the global `animateTo()`
- `onActionEnd` has to calculate `miniImgOffsetX` (`stackWidth - MINI_IMG_SIZE - miniImgOffsetSize) / 2 - MINI_IMG_MARGIN_LEFT`) in the bounce-out branch, and this value cover horizontal position will not be correctly omitted
- Threshold judgement: `detailsPagePositionY > stackHeight / 2` (detailed pages in the lower half of the screen) closes; otherwise the bounce is fully expanded. Call `onFinish` to reset all status if `resetExpandState()` is determined to close
- Set `detailsPagePositionY` in the closing branch as `stackHeight` (under screen), in line with the initial positioning strategy of step 0, ensuring that the detailed post-receipt page does not remain in visible areas to intercept touch events

## # Step 5: Status machine and reset [support]

> Animated Endpoint Status Management. `resetExpandState()` must reset** all ** status variables (including `isAnimating=false`) and any omission will cause subsequent interaction anomalies.

** Complete status replacement list:**

```ts
private resetExpandState() {
  this.isExpand = false;
This.isAnimatizing = false; / / Unlock Interacting (missing will result in a state of locking, cannot be repeated)
This.miniImgOpacity = 1; / /static cover restored visible
This.miniImgAnimateOpacity = 0; / / Animated Cover Restore Hidden
This.miniImgofsetY = 0; / / Vertical offset to zero
This.miniImgofsetX = 0; / / Horizontal offset to zero
This.miniImgofsetSize = 0; /// Cover Size Increase = 0
This.miniPlayerOpacity = 1; / / Mini Player Resume Visible
This.miniChangeHeight = 0; /// Mini Player Height = 0
This.
This.detailsPagePositationY = this.stackHeight; / / Details Page Back Below Screen
This. detailsPageTopOffice = 1; /// Navigator Bar Opacity Reset
This. MiniPlayerY = this.backHeight - MINI HEIGHT - BAR HEIGHT;/ / MiniPlayer
}
```

**State flow chart:**

```
Initial -doExpand() - Zoom In Animation - onFinish - Zoom
  ↑                                                      │
DoCollapse()-----onFinish----resetExpandstate()------------------------------------------------------------------------------------------------------------------------------- ----------------------------- -------------------- --, --, -- --, --, --, --, --, --, -- --, --, --, --, --, --, --, --, --, --, --, --, --, --, --, --, --, --, --
  │                                                      │
└ - PanGesture Threshold →resetExpandSate() → Initial
```

Key points:
- `isAnimating = false` is the most easily missed reset item, which will cause the re-entry lock to become permanent and cannot be re-opened or removed
- `miniImgOpacity = 1` and `miniImgAnimateOpacity = 0` must recover in resetExpandstate, not early in doCollapse (for reasons see step 3 key points)
- `detailsPagePositionY = this.stackHeight` (rather than `stackHeight + 100`): Push the details page under the screen after closing and keep it visible, avoiding zIndex(20) intercepting touch

---

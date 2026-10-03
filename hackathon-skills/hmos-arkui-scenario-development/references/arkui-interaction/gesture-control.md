# Hand gesture incident response control and conflict management


# Hand-to-hand competition control API quick check and contrast

The key difference between the above-mentioned scenarios, which use the echoes of multiple "intervening gestures" is ** the range of gestures controlled (which nodes are covered) and the timing of the trigger**. The table below provides a summary comparison to facilitate the selection of types on demand:

| API configuration node, | controlled range of gestures, | trigger time, | intervention mode, | association scene, |
|-----|---------|------------------|---------|----------------------------------------------------------------------------|---------|
|XKEEP0ZX | father component  ** subcomponent**: determining which subnode the touching event is forwarded to compete | | XKEEP1ZX (`id` + `TouchTestStrategy`) | XKEEP4ZX|
** `onGestureCollectIntercept` | Current component  ** Current node and higher priority node**: All identifiers to be collected on the response chain | gesture collection phase ** Prior to collection ** ** Return `GestureCollectIntervention` (e.g. `DISCARD_LOWER_PRIORITY_SIBLINGS`) | XXKEEP3ZX |
** `shouldBuiltInRecognizerParallelWith`  ** Current component (required to have built-in gestures)  ** Positions inside the current node Parallel to subcomponents (responding chain of the same type)**
**XKEEP0ZX| Current component  ** Specified gesture identifier**: can be screened by type / component `id` / `isBuiltIn()`, overwhelming the entire response chain ** touch test **, pre-identification `recognizers` Called `recognizer.preventBegin()` | ZXKEEP5Z|
** `onGestureRecognizerJudgeBegin`| Current component  ** Current node (self)** whether or not to participate in gesture processing *Return to `GestureJudgeResult` |ZXKEP2ZX  *

# Select the elements

1. ** First read "Who cares about the competition"**:
- Just to decide which sub-point** was forwarded to `onChildTouchTest` (Paternity, positioning by `id`).
- Want to screen the gestures as a whole according to the range ** of the response chain** (current node/brother node/high priority node/low priority node level).
- Wants to have **XKEEP0ZX, usually used in conjunction with `onGestureRecognizerJudgeBegin`, with **XKEEP1Z.
- Trying to disable from the outside** a certain type of identifier** (e.g., the Pinch `onTouchTestDone` + `preventBegin()`) from the outside.
- Want to control whether the current node itself is involved in ** gesture processing (which combines the movement of gestures, such as offsets, scroll positions, etc.) →XKEEP0ZX before identification.

2. ** Look again at "What stage of intervention"**:
- `onChildTouchTest` / `onGestureCollectIntercept` / `shouldBuiltInRecognizerParallelWith` are in ** pre-collect/collect** — influence on "what gestures enter competition".
- `onTouchTestDone` is in ** after collection, before identification ** — remove the identifier "collected but do not want to be identified".
- `onGestureRecognizerJudgeBegin` is at ** identification determination ** - control identifier is closed and final determination given.

> Note: `onTouchTestDone` + `preventBegin()` supports from API version 20; `onChildTouchTest` supports from API version 11; ZXXKEEP3ZX supports from API version 26. Please confirm the target device API version before use.

## prevent Begin() compares the identifier level control with setEnabled()

`onTouchTestDone` and `onGestureRecognizerJudgeBegin` will both get `GestureRecognizer`, but the last two methods of "disable identifiers" `preventBegin()` are completely different from `setEnabled()` ** The combination will render the action ineffective and press the following table type:

| Method | Entry into force phase | Effect | Use of gesture type |
|------|---------|------|-------------|
** `recognizer.preventBegin()`  ** **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **
** `recognizer.setEnabled(boolean)` ** gesture ** recognition determination phase** (typically `onGestureRecognizerJudgeBegin` internal call)  ** ** do not prevent the gesture from participating in identification**, only control the execution of the ** signback function after successful identification**  ** only for roll-on ** |

> ** `preventBegin()` is not valid to call after sign recognition begins**: `onGestureRecognizerJudgeBegin` is in the identification determination phase and the identifier is in the identification process, at which point `preventBegin()` cannot be removed from the recognition. To "get a gesture completely unidentified," you have to call at an earlier stage of `onTouchTestDone`.

**Select speed:**
- Trying to completely remove a gesture from identification** after collection** (e.g. by disableing PdfView's Pinch `onTouchTestDone` + `preventBegin()`).
- Whether or not to control roll-backs at the time of the determination** (e.g., internal and external Scroll embedded roll-out) **XKEEP0ZX+`setEnabled()` (see SCENE-10).

# onTouchIntercept / HitTest Behavior / onGestureCollect Intercept

All three are often used for "float/cover conflict with bottom gestures", but apply different boundaries. In combination with the syntax and code context of the developers,** the following two rules apply:

** Rule one needs to be "based on the location of the area" or "based on the component of the given sign type"? ** - Distinguishing `onTouchIntercept` from `onGestureCollectIntercept`

- Conflict resolution** depends only on the area/position of the touchpoint ** (e.g., "Invisible in the interactive zone, out-of-area transmission"), and it does not matter what kind of gesture, which component of the hit `onTouchIntercept` returns the `HitTestMode` by coordinates at the earliest stage of the touch test (see SCENE-04).
- Conflict resolution** needs to be identified "Is there a component that binds the specified sign type"** (e.g. "Only when the float buttons -- it binds the click sign -- when it is in that position, otherwise released) and needs to be determined by the `getType()`+ component at `onGestureCollectIntercept` (see SCENE-06).

> Code Context Speeding: Only `displayX/displayY` is used in the program to compare `onTouchIntercept` with area coordinates; `recognizers`, `getType()`, `.id()`/`isHostBelongsTo()` `onGestureCollectIntercept` is required.

** Rule II provides solutions from the top level or changes sub-components? ** - Distinguishing `onGestureCollectIntercept` from `hitTestBehavior`

- It is hoped that** conflict resolution will be provided in one place only at the outer level, without changes to the bottom or sub-components** (the bottom is a tripartite/system component, or is not easily configured on a case-by-case basis) →XKEEP0ZX, and that once registered at the outer level will allow an overview of the entire response chain (see SCENE-06).
- **Subcomponents can and will be modified on a case-by-case basis** (containers with `HitTestMode.None` penetrating + interactive subcomponents with `HitTestMode.BLOCK_HIERARCHY` intercept) and `hitTestBehavior` by one stroke for all gestures (see ZXXKEEP3ZX, SCENE-03).

> Developer semantic simplifier: semantics are → `onGestureCollectIntercept`; semantics are → `hitTestBehavior` "For a subcomponent/container " and can directly alter target component `hitTestBehavior`.

---

# SCENE-01 Edge button to expand response hot zone

** Applicable scenario: ** Used when interactive components are on or near the edge of the screen. On mobile devices, user fingers touch the edge of the screen, often with inaccuracy, and can easily render the click invalid. `responseRegion` expands the response area to the outside of the screen to increase the success of the edge component without changing the visual layout. Examples include the sidebar switch button, the return button that hangs on the edge of the page, the operation button for the side slide menu, etc.

** Core mechanism: ** `responseRegion({ x, y, width, height })` defines the response rectangle with the upper left corner of the component as the point of origin. Sets the `x` to negative value to extend the response area to the left, and sets `width` to extend the response area to the right by greater than the actual width of the component. The visual components remain the same in size, but actually the clickable area is expanded.

# # Apply scene: sidebar toggle buttons to expand the hot zone

The sidebar switch button closes to the right edge of the screen, the button itself is small (24 x 48vp) and the user is vulnerable to error when clicking on the edge area on a mobile phone. `responseRegion` expands the hot zone around, ensuring that users click on the area near the button to trigger the switch.

** Steps to be taken:**

1. ** Declared Offset State**: Declared ZXKEP0ZX Drive Offset with `isShowSideBar`
2. ** Package animated closed package**: `animateTo({ duration: 300, curve: Curve.Friction }, () => { ... })` grant in switchout
3. **Sight transfer bound**: Image chain call `.offset({ x: this.sideBarBtnOffset })`
4. ** Expanded hit heat zone**: Image chain call `.responseRegion({ x: -12, y: -12, width: 48, height: 72 })` (`x`/`y` negative increase, `width`/`height` total size of the hot zone)

```typescript
@Component
export struct SideBarContentView {
  @Link isShowSideBar: boolean;
  @State sideBarBtnOffset: number = 0;

  switchTabBar() {
    animateTo({ duration: 300, curve: Curve.Friction }, () => {
      this.isShowSideBar = !this.isShowSideBar;
      if (this.isShowSideBar) {
This.sideBarbnOnfset = -240;// sidebar width
      } else {
        this.sideBarBtnOffset = 0;
      }
    })
  }

  build() {
    Stack() {
/ ... sidebar omitted

/ / 1 Sidebar Switch button: Arrow icon, close to right edge of the screen
      Image(this.isShowSideBar
        ? $r("sys.media.ohos_ic_public_arrow_right")
        : $r("sys.media.ohos_ic_public_arrow_left"))
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.switchTabBar();
        })
        .height(48)
        .width(24)
        .borderRadius({ topLeft: 12, bottomLeft: 12 })
        .offset({ x: this.sideBarBtnOffset })
/ / 2 resoneseRegion: Responsive hot zone with extended edge buttons
        .responseRegion({
x:-12, / / Expand 12vp left
y:-12, / / Up 12vp
Width: 48, / / Expand Right to 48vp (24 + Left 12 + Right 12)
Height: 72 / / Down to 72vp (old height 48 + up 12 + down 12)
        })
        .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    }
    .width('100%')
    .alignContent(Alignment.End)
  }
}
```

---

# SCENE-02 Selective Event Plugin

** Applicable scenario: ** Use when a container ** containing sub-components is covered by " Clickable bottoms"** and requires that "all gestures on sub-components (buttons/input boxes, etc.) are only responded to by sub-components and do not penetrate to the bottoms; point-container blank areas go through the bottoms". Typical are bullet-window masks, new hands, suspended operating panels, etc., which are prioritized in this scenario.

** Core mechanism:** Set up `hitTestBehavior(HitTestMode.None)` for the parent packaging so that it does not participate in the touch test and click events are passed to the lower component; and set `hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)` for the subcomponents in the container that require interaction to prevent the event from continuing to pass under the mask.

# That's what it takes #

1. ** Layer superimpose**: `Stack`
2. ** Monument penetration**: Monument `Column` Chain call `.hitTestBehavior(HitTestMode.None)`
3. ** Sub-component exclusive**: Momentum interactivity (e.g. Button) chain call `.hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)`
4. **Extension safety zone**: masked `Column` chain call `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])`
5. ** Mask Style**: mask `Column` Chain Call `.backgroundColor('rgba(0, 0, 0, 0.3)')`

```typescript
@Entry
@Component
struct BlockHierarchy {
  build() {
    Stack() {
/ / / / / / Undercovered components: receiving penetrating touch events
      Column()
        .onTouch(() => {
Console.info (`Click on Undercover component');
        })
        .height('100%')
        .width('100%');

/ / 2 full screen mask
      Column() {
/ 3 Embossed inner subcomponent: prevent event penetration
Button.
          .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
          .onTouch(() => {
Console.info (`Click on the inner part of the mask');
          });
      }
      .justifyContent(FlexAlign.Center)
.hitTest Behavior (HitTestMode.None) / / Monk itself does not intercept incidents
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('rgba(0, 0, 0, 0.3)')
      .height('100%')
      .width('100%');
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
    .width('100%');
  }
}
```

---

# SCENE-03 to prevent sub-components from triggering the parent's scroll

**Applicable scene: **The parent packagings are normally rolling when Scroll, List, etc. have specific sub-components in the scrollable packaging, hoping to touch the sub-component without triggering the parent packaging ' s rolling behaviour. For example, map cards, dragable sliders, canvas areas in a rolling list.

** Core mechanism:** Set up `hitTestBehavior(HitTestMode.Block)` for sub-components that need to stop rolling, which will block the touch testing of their parent component and prevent the rolling action of the parent container from being triggered.

# That's what it takes #

1. **Rolling structure**: parent packaging `Scroll() { Column() { ... } }` structure
2. ** Trapped parent packaging rolling**: `.hitTestBehavior(HitTestMode.Block)` on chain call to subcomponents that need to stop rolling

```typescript
@Entry
@Component
struct Block {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column()
          .height(400)
          .width('100%')
Scroll scrolling
        Column()
          .height(56)
          .width('100%')
          .backgroundColor('#F1F3F5')
          .hitTestBehavior(HitTestMode.Block)
        Column()
          .height(400)
          .width('100%')
      };
    }
    .width('100%')
    .height('100%');
  }
}
```

---

# SCENE-04 dynamic determines events during touch

**Applicable scene: **Application when a touch occurs before a decision on the transmissible event is made on the basis of the location dynamics of the touchpoint. For example, there is a specific interactive area within a container component, which is clicked on the lower layer and clicked on the blank area, or the same component requires different touch behaviour in different positions/states.

** Core mechanism: ** Use `onTouchIntercept` back to return different ZXXKEEP1ZX values in the early stages of touch testing based on the dynamic of contact point coordinates, input sources, etc., to determine whether or not the event is transmissible. The core capability, "Return by touch point dynamic `HitTestMode`" and the method of obtaining the coordinates of the interactive area is left to the operational parties by scene.

# That's what it takes #

1. **Stack layer superimplation**: bottom-placed operational components (e.g. TextArea), upper layer covered packagings
2. ** Tie on Touch Intercept**: register callbacks on upper packagings to read `event.touches[0].displayX/displayY` (relative application of window coordinates)
3. ** Determines whether the touchpoint is in the interactive area**: the range of the interactive area coordinates is entered by business scene (see code note), which is directly comparable to `displayX/displayY` with the baseline
4. **Return by region HitTestMode**: return to `HitTestMode.Default` (failure, upper level) and return to ZXXKEEP1ZX (exploitation to lower level)

```typescript
@Entry
@Component
struct HitTestModeDemo {
/ / Range of coordinates of the interactive area: value assigned by the business scene (see comment on Touch Intercept)
  private areaX: number = 0;
  private areaY: number = 0;
  private areaW: number = 0;
  private areaH: number = 0;

  build() {
    Stack() {
/ / / / / / / / / / / / / lower level of operational component: handles that penetrate through the receiving area
TextArea({placeholder: 'click on empty area to enter; click on interactive area to be handled from the top level'})
        .width('100%')
        .height('100%')
        .backgroundColor('#F1F3F5');

/ / 2 Upper Cover Container: OnTouchIntercept Dynamics Decisions Passage
      Column() {
/ / Interactive area: Sub-components that the upper layer wishes to handle on its own
        Column() {
Text (`interactive area'). FontSize (16)
        }
        .width(160)
        .height(80)
        .backgroundColor('#C7C7CC')
.hitTest Behavior (HitTestMode.Block) / / Interactive Area Consumption Touches to prevent event bubbles
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onTouchIntercept((event: TouchEvent) => {
        const touchX: number = event.touches[0].displayX;
        const touchY: number = event.touches[0].displayY;
/ / / / The coordinates of the interactive area (this.areaX/areaY/areaW/areeha) please assign values according to the business scene, in a common way:
/ / / on AreaChange Cache Interactive Area GlobalProsition.x/y and width/health (recommended by dynamic layout);
// · Direct use of coordinates constants when the layout is fixed;
// · Multiple interactive areas can be changed to arrays, with a single hit.
/ Note: displayX/displayY and globalPositation coordinates are directly comparable and do not require conversion.
        const inside: boolean =
          this.areaX <= touchX && touchX <= this.areaX + this.areaW &&
          this.areaY <= touchY && touchY <= this.areaY + this.areaH;
        return inside
♪ HitTestMode. Default / Area: Upper processing, non-transmission
: HitTestMode.Transparent; / / Outer Area: Passed to BottomArea
      });
    }
    .height('100%')
    .width('100%');
  }
}
```

---

# SCENE-05 Custom Slider Supports Clicking Slide Position # # # SCENE-05 # + Scrubbing Slide

**Applicable scene: **Used when custom Slider needs to quickly locate to the corresponding value by clicking on any position on the slider, and wants users to continue to drag sliders to fine tune without lifting their fingers. Common for "first-in-first-in-a-side" interaction in volume/light, progress bar jump, colour slider, self-defined positive-negative Slider (zero points in the middle, right-to-right, two-way) etc. This mode can also be extended to any scenario where the parent container responds by pressing + to drag the specified subcomponent by the same gesture relay, e.g. towed label axes, map scaling strips, etc.

** Core mechanism: ** After `contentModifier` has been fully self-defined Sliter content area, the touch logic of the original slider has been replaced, requiring self-reconstruction of the interactive link. Registers `onChildTouchTest` on the Content Root Container (Stack) and returns to a `TouchResult` object, assigns slider sub-components via `id` (to be declared id in advance through `.id('xxx')`) and tells the system through ZXXKEEP5ZX to forward this touchdown test** to Forward** for the slider to compete. This means that the `onTouch` (processing Down calculates and submits the initial value) of the root container and the `PanGesture` (processing follow-up drag) of the slider can be carried out in the same gesture without the need for the user to lift his finger and press again.

**Achieving thought: **The slide track is rendered with `linearGradient` (zero points in the middle and two negatives in the left and right) and the slider is a `Circle` with `PanGesture`. The root container `onTouch` handles the logic of clicking on the slide position, and `onChildTouchTest` forwards the subsequent drag event to the slider to achieve a continuous operation of "tick position and continue to drag to fine."

** Steps to be taken:**

1. ** Root container `onTouch` processing click location**: Value based on touch point x coordinates at `TouchType.Down` and submitted through `config.triggerChange(value, SliderChangeMode.Click)`.
2. ** Slide binding ZXKEEP0Z**: Slide ZXKEEP1Z by `.id('circle')` declaring ID and horizontally `PanGesture`, submitted in `onActionStart`/`onActionUpdate`/`onActionEnd`, respectively.
3. ** Root container `onChildTouchTest` forwarding event**: returns `{ strategy: TouchTestStrategy.FORWARD_COMPETITION, id: 'circle' }`, forwards the subsequent movement of the same gesture to the slider, enabling `PanGesture` to take over the drag without lifting its finger.

```typescript
@Component
export struct CustomSlider {
  @State sliderValue: number = 0;
  @State sliderWidth: number = 0;

  build() {
    Column({ space: 10 }) {
/ / / / / customise Slider content area with currentModifeer
      Slider({ value: $$this.sliderValue, min: -100, max: 100 })
        .contentModifier(new MySliderStyle(this.sliderWidth))
        .padding(20)
        .onSizeChange((oldSize, newSize) => {
// Width of Component - Padding*2 is the width of the slider
          this.sliderWidth = (newSize.width as number) - 40;
        });

      Text(`sliderValue:${this.sliderValue}`).fontSize(30);
    }
    .height('100%')
    .width('100%');
  }
}

class MySliderStyle implements ContentModifier<SliderConfiguration> {
  sliderWidth: number = 0;
  lastOffsetX: number = 0;
  constructor(sliderWidth: number) {
    this.sliderWidth = sliderWidth;
  }
  applyContent(): WrappedBuilder<[SliderConfiguration]> {
    return wrapBuilder(buildSlider);
  }
}

@Builder
function buildSlider(config: SliderConfiguration) {
  Stack() {
// Custom slider: "Slipper - Slided Part - Slided Track" achieved by gradient, with zero points in the middle
    Row()
      .width('100%')
      .height(8)
      .borderRadius(4)
      .linearGradient({
        angle: 90,
        colors: [
          [$r('sys.color.ohos_id_color_component_normal'),
            config.value <= 0 ? (0.5 - config.value / config.min / 2) : 0.5],
          [$r('sys.color.ohos_id_color_emphasize'), config.value <= 0 ? (0.5 - config.value / config.min / 2) : 0.5],
          [$r('sys.color.ohos_id_color_emphasize'), config.value >= 0 ? (0.5 + config.value / config.max / 2) : 0.5],
          [$r('sys.color.ohos_id_color_component_normal'),
            config.value >= 0 ? (0.5 + config.value / config.max / 2) : 0.5]
        ]
      });

/ 2 Custom slider: declare id and bind horizontal PanGesture
    Circle({ width: 20, height: 20 })
      .id('circle')
      .fill('#fff')
      .borderRadius('50%')
      .shadow({ radius: 10, color: Color.Gray })
      .offset({ x: config.value / config.max * ((config.contentModifier as MySliderStyle).sliderWidth / 2) })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal, distance: 1 })
          .onActionStart(() => {
            config.triggerChange(config.value, SliderChangeMode.Begin);
            (config.contentModifier as MySliderStyle).lastOffsetX = 0;
          })
          .onActionUpdate((even) => {
            config.value = config.value +
              Math.round((even.offsetX - (config.contentModifier as MySliderStyle).lastOffsetX) /
                (config.contentModifier as MySliderStyle).sliderWidth * 200);
            config.triggerChange(config.value, SliderChangeMode.Moving);
            (config.contentModifier as MySliderStyle).lastOffsetX = even.offsetX;
          })
          .onActionEnd(() => {
            config.triggerChange(config.value, SliderChangeMode.End);
          })
      );
  }
/ / 1 parent packaging on Touch: calculate and submit value based on x coordinates when clicking on slide
  .onTouch((even) => {
    if (even.type === TouchType.Down) {
      config.value = Math.round(even.touches[0].x / (config.contentModifier as MySliderStyle).sliderWidth * 200) - 100;
      config.triggerChange(config.value, SliderChangeMode.Click);
    }
  })
/ 3 on ChildTouchtest: forward the follow-up of the same gesture to the slider to achieve the goal of "suspension and drag."
  .onChildTouchTest(() => {
    return { strategy: TouchTestStrategy.FORWARD_COMPETITION, id: 'circle' };
  });
}
```

** Key points:**

1. ** `onChildTouchTest` and `onTouch` Divisional **: `onTouch` of the parent packagings handles the instant logic of "click or location" (`TouchType.Down`), and `onChildTouchTest` handles the distribution logic of "where to follow" in the same gesture.
2. ** `TouchTestStrategy.FORWARD_COMPETITION`**: indicates that the touch test** was forwarded to the designated subnode of `id` to compete. The `PanGesture` of the subnode (slides) can thus be activated without raising the user ' s hand and carry the drag event.
3. ** The target sub-component must state that the `.id('xxx')`**: `onChildTouchTest` returned the `id` field needs to be fully consistent with the ID declared by the sub-component through `.id()`, otherwise the event cannot be located at the target sub-point.
4. ** Distinguished from SCENE-04 `onTouchIntercept`**: `onTouchIntercept` returns ZXXKEEP3ZX, which determines whether to pass through the lower layer; ZXXKEEP4ZX returns `TouchResult` (with `id` + `strategy`), which determines which "incident is transmitted to which subpoint" and is suitable for the "father-synthetic" gesture rather than the "upper-strain penetrating" gesture.
5. **According to ZXKEEP0ZA custom content**: When systems components such as Slider are fully self-defined through `contentModifier`, the touch logic of the raw slider is replaced and the full interactive link of "click location + drag fine" must be rebuilt by ZXKEEP2Z+`PanGesture` + `onChildTouchTest`.

---

# SCENE-06 Short Video Transparency Float Approximation/System Monopoly

> ** Version Requirements: ** `onGestureCollectIntercept` is supported from API version 26 and please confirm that the target equipment is not less than that version before using this program; change to other programs for low-end devices.

** Applicable scenario: ** Desired** to be used in a uniform control of hand-porting conflicts from the outer layer (Float) without the need to modify the bottom or sub-components on a case-by-case basis**. Typical claims: An interactive sub-component (e.g., a button) within the touch float is only responsive to the sub-component and does not repeat the trigger with the bottom; the touch in the blank area of the float passes through the bottom. If `hitTestBehavior` is used, `HitTestMode` is to be installed on the packaging and on each interactive sub-component, respectively; if `onTouchIntercept` is to be modified, only `HitTestMode` can be returned by the thick particle of the touch point. `onGestureCollectIntercept` is registered only once in the outer layer, so that you can look at the entire response chain and choose the conflict resolution as needed. Typical scenario:

- ** Short video playpage**: Bottom floor is a vertical screen `Swiper(vertical)` (up-down-to-down video) + item click to switch to play/stop, upper floor is a right bottom transparent float (like/receipt/review button). Point buttons only trigger buttons and do not "double-trigger" video layer clicks; the transparency area outside points buttons penetrates to the video layer to switch to play/pause.
- ** Cross-Framework Mixed Page**: The ArkUI page embeds Surface (bottom) with ArkUI Transparency Operator Bar (button, Tab Switch, etc.) and needs to avoid the buttons clicking on Double Trigger.
- ** It is not appropriate to change the unified conflict management of the bottom/subcomponent**: the bottom is a tripartite/system component (e.g. Flutter/WebView Surface), it is not convenient to configure the signature properties on a case-by-case basis, and it is hoped that a unified decision on how to resolve the hand conflict will be made at a different level.

** Core mechanism:** Registered on transparent float containers `onGestureCollectIntercept`,** integrated from the outer layer of the entire response chain and unified choice of gesture conflict resolution without changes to bottom or sub-components**. The key is to re-introvert the semantics of `recognizers`: ** It's the "all bound" sign recognition on the touch position response chain** (a snapshot of which gestures are tied here)** instead of the one that is currently being triggered**. As a result, `recognizers` was used to read the type of gesture for each identifier, `isHostBelongsTo(uniqueId)` (residence of a node tree) or `getEventTargetInfo().getId()` (specific component id) to determine ** "What part of this position binds the gestures" ** ** This is ** situational awareness** and ** to choose a `GestureCollectIntervention` conflict resolution ** based on this dynamic (e.g., if a flop button was found to bind the click hand → back to `DISCARD_LOWER_PRIORITY_SIBLINGS`; otherwise back to ZXKEEP8Z).

> ** Can't "select different gesture conflict solutions for different types of gestures at the same touch point"**: because you have all the bound identifiers, not the one that triggers, you don't know whether to click or slide at the moment.

** Steps to be taken:**

1. **The bottom full screen interactive container (maintain as it is, without changing it)**: normal binding of clicks and slides is sufficient (e.g. stand-by `Swiper` cut video +item ZXKEEP1Zx cut/ Pause; for example, `Column` + `onClick`+ vertically to `PanGesture` demonstration).
** Transparent float container**: set `hitTestBehavior(HitTestMode.Transparent)` and declare ID through ZXXKEEP1ZX; internal buttons** normal binding of gestures** (e.g. `priorityGesture(TapGesture())`)**,** no additional configuration for conflict ** — this is the expression of this programme's "no modification of subcomponents".
3. **Unified outer layer control**: `onGestureCollectIntercept` is only registered on a transparent float container, passing through `recognizers` to determine "what part of the position is bound by the gestures" and to select the `GestureCollectIntervention` programme accordingly.

```typescript
@Entry
@Component
struct VideoFeedOverlay {
  build() {
    Stack() {
/ 1 Bottom fullscreen interactive packaging: click cut/stop, up-slash video (main as it is, without conflict-related changes)
      Column() {}
        .width('100%').height('100%')
        .backgroundColor('#202020')
.onClick(()=>{/* Toggle play/ pause*/})
        .gesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 10 })
.onAction(() = > { / *Slow Slash Video */})
        );

/ 2 Transparent Operating Floats: Registered here only on Gesture Collact Intercept
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column({ space: 18 }) {
/ / 3 buttons can be properly bound to gestures without additional configuration for conflict
Column() {Text('like'). FontSize(11). FontColor('#FF')}
            .width(56).height(72)
.priorityGesture (tapGesture().onAction(() = { /*  * * * /});
Column() {Text('repossession'). FontSize(11). FontColor('#FF')}
            .width(56).height(72)
.priorityGesture (TapGesture().onAction(()=>{/* Collection*/}));
        }
      }
.id ('overlay Node') / / on GestureCollect Intercept relies on id uniqueId
      .width('100%').height('100%')
      .padding({ right: 12, bottom: 96 })
.hitTest Behavior (HitTestMode.Transparent) / / /Float full transparency: space penetrates into the lower layer
/ 4 Common external control: select conflict resolution based on the determination of whether the position has a flotospheric component bound to the click hand
      .onGestureCollectIntercept((recognizers: Array<GestureRecognizer>) => {
/ recognizers are "all bound" identifiers (not currently triggered) for situational awareness.
        const overlayId: number | undefined =
          this.getUIContext().getFrameNodeById('overlayNode')?.getUniqueId();
        for (let i = 0; i < recognizers.length; i++) {
          const r: GestureRecognizer = recognizers[i];
// posture: there's a float button tied to the click sign, / select the "Drop low priority brother" option, and the button click wins here
          if (overlayId !== undefined &&
            r.getType() === GestureControl.GestureType.TAP_GESTURE &&
            r.isHostBelongsTo(overlayId)) {
            return GestureCollectIntervention.DISCARD_LOWER_PRIORITY_SIBLINGS;
          }
        }
// posture: position without float buttons to bind click gestures (e.g., blank transparency zones) maintain default collection and take events to the bottom
        return GestureCollectIntervention.CONTINUE;
      });
    }
    .width('100%').height('100%');
  }
}
```

---

# SCENE-07 Custom gestures conflict with system gestures

** Applicable scenario: ** When the system of components displays the same type of self-defined gestures as those of developers bound through `.gesture()`, the system gestures will give priority to the response, resulting in the custom gestures not being triggered. For example, long preview animations and customised LongPressGesture conflicts with the Image component, on-Click with custom TapGesture.

** Core mechanism: ** System gestures that bind the same type of event and custom gestures by the same component give priority to response. By replacing `priorityGesture` by `gesture` binding, customized gestures can take precedence over system gestures; by ZXXKEEP2ZX binding, both can respond.

# # Apply scene: Image long by hand was robbed by built-in animation Jim.

When `.gesture(LongPressGesture())` is added to the Image component, a long picture cannot trigger a self-defined echo, but rather animate the system in which the image is magnified. This is because the long animation (system gesture) of the Image component is in conflict with the LongPressGesture (auto-defined gesture), which gives priority to response.

** Steps to be taken:**

1. ** Problem repeated**: use of `.gesture()` to bind long hand gestures to detect animated by the system Jim.
2. **Priority of response to custom gestures**: change to `.priorityGesture()` binding, custom gestures take precedence over system gestures
3.** Both responses** (optional): use of `.parallelGesture()` binding, with custom and system gestures triggered

```typescript
/ 1 Problem code: use gesture binding, system gesture priority, custom gesture not trigger
@Entry
@Component
struct GestureConflictDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
....gesture(/ / / / / ❌ by animated by Image's inner length) Jim.
          LongPressGesture()
            .onAction(() => {
(a) Console.info (`Long-activated');
            })
        )
    }
  }
}
```

```typescript
/ 2 Solution I: priority of custom gestures
@Entry
@Component
struct PriorityGestureDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
.priorityGesture(/ / / / / custom gestures take precedence over system gestures
          LongPressGesture()
            .onAction(() => {
Console.info (`self-defined long-term trigger by gesture');
            })
        )
    }
  }
}
```

```typescript
/ 3 Solution II: ParallelGesture to trigger both
@Entry
@Component
struct ParallelGestureDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
...parallelGesture(/ / / / / customized gestures and system gestures both ring Response
          LongPressGesture()
            .onAction(() => {
Console.info (`self-defined long-term trigger by gesture');
            })
        )
    }
  }
}
```

---

# SCENE-08 Multi-touch-and-strike

** Applicable scenario: ** When there are multiple interactive components on a page, multiple components may respond to a gesture event at the same time, resulting in operational anomalies in a multi-finger-controlled context. For example, there are multiple buttons on a page, and when users click on different buttons with multiple fingers, all buttons trigger the click event, which may result in unexpected changes in status.

** Core mechanism: ** Sets the component exclusive event response through `monopolizeEvents(true)` properties. After setting, if the event on the component first responds, this interaction allows only the event response set on this component, and the event on the other part of the window will not respond until the finger leaves the screen.

# # Apply scene: modified page slider and toolbar multitouch conflict

On the pixmap page, the user selects the reconciliation (light, contrast, etc.) through the bottom toolbar, and after the selection pops up the Slider slider. In a multi-finger touch, the user may touch both the slider and the bottom toolbar button, leading to an error-trigger-bar switch during the slider drag, or to a slider when the toolbar clicks. There is a need to ensure that Sliter drags in a monopolistic event response to prevent conflict with the bottom toolbar.

** Steps to be taken:**

1. **Recognize components that need to be monopolized**: Slider sliders need to have monopolized events when dragging their parameters to avoid multi-touching conflicts with bottom toolbar buttons
2. ** Set-up monopolizeEvents**: Add `.monopolizeEvents(true)` to Slider component, other components do not sound while dragging sliders Response
3. **Certification behaviour**: bottom toolbar button does not respond to a click event before the finger leaves after the finger touches the slider

```typescript
@Entry
@Component
struct PhotoEditPage {
  @State currentTool: number = -1
  @State showSlider: boolean = false
  @State sliderValue: number = 50

  private tools: ToolItem[] = [
id: 0, name: 'Light', iconText: },
{id: 1, name: 'comparison', iconText:'◐,
♪ id: 2, name: 'Saturation', iconText:'💧,
    // ...
  ]

  @Builder
  SliderArea() {
    if (this.showSlider) {
      Column() {
        Row() {
          Text(this.tools[this.currentTool]?.name ?? '')
            .fontSize(14).fontColor(Color.White)
          Text(`${this.sliderValue}`)
            .fontSize(14).fontColor('#FFA500').margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 12 })

/ / 1 S Lider Settings MonopolizeEvents (true)
/ / Tow sliders to monopolize events to prevent multiple fingering of the bottom toolbar at the same time
        Slider({
          value: this.sliderValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet
        })
.monopolizeEvents(true) / Monopolize / Monopoly Event: The toolbar button does not ring when dragging the slider Response
          .width('85%')
          .trackColor('#333333')
          .selectedColor('#FFA500')
          .blockColor('#FFFFFF')
          .onChange((value: number) => {
            this.sliderValue = Math.round(value)
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      .backgroundColor('#1A1A1A')
    }
  }

  @Builder
  BottomToolBar() {
    Column() {
      Scroll() {
        Row({ space: 4 }) {
The bottom toolbar button for / / 2 did not set the monopolizeEvents
          ForEach(this.tools, (tool: ToolItem) => {
            Column() {
              Text(tool.iconText).fontSize(22)
              Text(tool.name).fontSize(10)
            }
            .width(56)
            .onClick(() => {
              this.currentTool = tool.id
              this.showSlider = true
              this.sliderValue = 50
            })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(80)
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
  }
}
```

---

# SCENE-09 dynamic control custom gestures Response

** Applicable scenario: ** During sign recognition, developers need to decide whether to respond to a gesture according to business logic dynamics. For example, suspension balls need to refuse to click on gestures, so that the click event can be passed up to the bottom-page component; control the validity of a particular gesture according to user privileges; or block certain gestures at a specific interactive stage.

** Core mechanism: ** Based on `onGestureRecognizerJudgeBegin` rectification method, determinations are made at the gesture recognition stage. The echo parameters include `BaseGestureEvent` and `GestureRecognizer`, and the developer can return `GestureJudgeResult.REJECT` to reject hand gesture response, `GestureJudgeResult.ACCEPT` to directly allow hand gesture response, or `GestureJudgeResult.CONTINUE` to continue the default sign recognition process.

# # Apply scene: Click on event after suspension

The suspension ball component binds three gestures of `GestureGroup(Exclusive)` polymer drag (PanGesture), LongPressGesture and TapGesture. User long toggle disabled/enabled with suspended float. When disabled, click gestures on a suspended ball need to be rejected so that the click event can penetrate the suspended ball to the bottom page content.

** Steps to be taken:**

1. **Standing group**: use of `GestureGroup(GestureMode.Exclusive, ...)` aggregate drag, long press, click gesture
2. ** Long toggle disabled **: Flip ZXKEEP0Zx sign back by long gesture
3. ** Add onGestureRecognizer Judge Begin**: a decision to reject a gesture based on the `isDisable` state and movement of the gesture type is made in the gesture determinations

```typescript
@Component
struct FloatingWindow {
  @State isDisable: boolean = false;

  build() {
    RelativeContainer() {
      Stack({ alignContent: Alignment.Center }) {
/... toolbar sub-items...

        Column() {
UI
        }
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            PanGesture()
.onActionStart(/* Drag Start */)
.onActionUpdate(/* drag and update to control suspension ball following finger */)
.onActionEnd(/* drag end, adsorb to screen edge*/),
            LongPressGesture()
              .onAction((event: GestureEvent) => {
/ / Long Toggle Disable/ Enable
                this.isDisable = !this.isDisable;
              }),
            TapGesture()
              .onAction((event: GestureEvent) => {
/ Click to Expand/ Collapse Toolbar
              })
          )
        )
/ Knowledge point: Ensure that clicks are passed up by refusing to click on gestures
         .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, recognizers: Array<GestureRecognizer>) => {
            if (current.getType() === GestureControl.GestureType.TAP_GESTURE) {
/ / Refuse click on gestures when disabled / component does not consume this touch / event continues to be distributed down to bottom page
               return this.isDisable ? GestureJudgeResult.REJECT : GestureJudgeResult.CONTINUE;
            }
/ PAN / LONG PRESS continues to default recognition / / / Drag and Long is completely undisposed
            return GestureJudgeResult.CONTINUE;
         })
      }
    }
  }
}
```

** Key points:**

**ArkUI gesture "only consumes"**: Basic components (e.g. `Column`/`Button`, List scrolling, Image length equal to internal gestures) and self-defined gestures followed in the same touch sequence "Competitor has only one winner" — one identifier identifies success and consumes the touch, and other **competitive ** identifiers on the chain are set as a failure/cancellation, so that multiple points of competition do not react at the same time (except for `parallelGesture`, which is tied in parallel).
** For penetration to be established, the bottom page must be "chained"**: `onGestureRecognizerJudgeBegin` only returns ZXXKEEP1ZX so that it is not enough to hit the ball — the rejected click is going to fall to the bottom page, which must be in the touch test chain. The suspension is therefore subject to `hitTestBehavior(HitTestMode.Transparent)`, which integrates the bottom page into the chain; and then ZXXKEEP3ZX, which takes the ball out of the click competition, allows the bottom page click identifier to win and consume (i.e. penetrating) in a " one-time" competition.
3. ** Drag/Long by why it is not affected**: Underground pages usually have only click type identifiers and no drag/Long by-Identifier. These two bands have only balls, which naturally win and consume (`PAN`/`LONG_PRESS` returns `CONTINUE` in return for constant return) and do not penetrate.

---

# SCENE-10 father component management sub-component gesture (handhold intercept enhanced)

**Applied scenario: **In case of a conflict of gestures in the embedded scrolling of the father-son component, the father component requires a gesture response from the intervention subcomponent. The typical scene is the embedded Scroll packaging, which needs to be determined according to the dynamics of the rolling position, whether the inner or the outer packaging. For example, the Scroll embedded inner layer, which needs to be rotated to the outer scroll after scrolling to the top/floor.

** Core mechanism:** Use of `shouldBuiltInRecognizerParallelWith` in hand intercept enhancement to collect hand recognitions requiring parallel processing, and of ZXXKEEP1ZX in back motion control sub-components and parent components.

## # Application scene: outer layer Scroll manages three-way rolling component gestures

**Applicable scene: **In the original Scroll container, a rolling list of embedded threes (e.g. Flutter/XCommpont customised Scrolls, cannot be achieved through a nested Scroll) needs to control the outer Scroll dynamic according to user interaction (e.g. click switch) whether or not it responds to a slide move and avoids a slide conflict with the inner Scrollable components.

** Core thinking:**

1. **Inner layer three-scrollable components**: XKEEP0ZX to provide handprint identifiers (for external parallel binding), `onClick` toggle `consumePanGesture` signpoint control for the need for a consumption slide handle
2. **Scroll**: Finds and creates parallel pan gesture recognition for the inner layer of Column through `shouldBuiltInRecognizerParallelWith`, and controls/disables the internal and external identifier by `onGestureRecognizerJudgeBegin`

** Steps to be taken:**

1. **Column binding PanGesture**: Add PanGesture to the inner layer, and add on-Click to the consumption marker
2. **Scroll Parallel binding**: PanGesture identifier for `shouldBuiltInRecognizerParallelWith` to find the inner layer of Column (note: no longer check `isBuiltIn()` because the PanGesture of Column is a custom gesture)
3. ** Control of movement **: Enable/ Disable internal and external identifiers in `onGestureRecognizerJudgeBegin` based on `consumePanGesture` status

```typescript
@Entry
@Component
struct GesturesConflictScene8 {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  private childRecognizer: GestureRecognizer = new GestureRecognizer();
  private currentRecognizer: GestureRecognizer = new GestureRecognizer();
  @State consumePanGesture: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
/ / 1 Outer Plasma Scroll Container
      Scroll(this.scroller) {
        Column() {
          Text('Scroll Area')
            .width('100%')
            .height(150)
            .backgroundColor(0xFFFFFF)
            .borderRadius(15)
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .margin({ top: 10 })

/ 2 Inner Layer Column Simulation Three Scrollable Component
          Column() {
Text
              .width('100%')
              .height(150)
              .backgroundColor(0xFFFFFF)
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .margin({ top: 10 })
            Column() {
              ForEach(this.arr, (item: number) => {
                Text(item.toString())
                  .width('100%')
                  .height(200)
                  .backgroundColor(0xFFFFFF)
                  .borderRadius(15)
                  .fontSize(20)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 10 })
              }, (item: string) => item)
            }
            .width('100%')
          }
          .id('innerColumn')
          .width('100%')
          .height(800)
/ / 3 Click to switch to consumption sliders
          .onClick(() => {
            this.consumePanGesture = !this.consumePanGesture;
          })
/ 4 Tie PanGesture provides a gesture recognition device for parallel binding on the outer layer
          .gesture(
            PanGesture({ fingers: 1 })
              .onActionStart(() => {
              })
              .onActionEnd(() => {
              })
          )
        }.width('100%')
      }
      .id('outerScroll')
      .height(600)
      .scrollBar(BarState.Off)
/ 5 PanGesture identifier for collecting the inner layer of Column
      .shouldBuiltInRecognizerParallelWith((current: GestureRecognizer, others: Array<GestureRecognizer>) => {
        for (let i = 0; i < others.length; i++) {
          let target = others[i].getEventTargetInfo();
          if (target) {
            if (target.getId() === 'innerColumn' &&
              others[i].getType() === GestureControl.GestureType.PAN_GESTURE) {
              this.currentRecognizer = current;
              this.childRecognizer = others[i];
              return others[i];
            }
          }
        }
        return undefined;
      })
/ 6 Control the directional route according to the signage of the inner component
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, recognizers: Array<GestureRecognizer>) => {
         if (this.consumePanGesture) {
This. childRecognizer.setEnabled(true) / / Inner Circulation
This.currentRecognizer.setEnabled(false)/ / Outer Response
         } else {
This. childRecognizer.setEnabled (false) / / inner layer does not consume gestures
This.currentRecognizer.setEnabled(true)/ / OuterScroll
         }
         return GestureJudgeResult.CONTINUE;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xF1F3F5)
    .padding(12)
  }
}
```

---

# SCENE-11 to prevent specific type of gesture recognition

**Applicable scenario:** Need to completely prevent specific types of gestures on a component from being identified. For example, the PdfView component incorporates a condensed and out-of-hand position, which requires operational ban on scaling (reading only, zooming down is not allowed) and, if there is a need to prevent some system-wide gestures from being triggered under certain conditions.

** Core mechanism: ** Intercepted by `onTouchTestDone`, after the touch test has been completed, before the signature recognition begins. Revert parameters include `TouchEvent` and `GestureRecognizer[]` arrays. Developers can go through the `recognizer.getType()` list to determine the type of gesture and call ZXXKEEP4ZX to prevent a specific ZIdentifier from reaching the recognition status.

Apply scene: PdfView disabled Fire!

PDF Kit provides a PDF document preview capability through the PdfView component, where page scaling is achieved through the built-in PinchGesture. Sometimes it is necessary to disable zooming functions (e.g., document review mode with a fixed width) in the business scene, and it is necessary to prevent PdfView from joining hands.

** Steps to be taken:**

1. **PdfView packaged in packagings**: packaged in PdfView, with a container like Stack, `onTouchTestDone`
2. **List of pass-through identifiers**: pass through `recognizers` arrays in return to determine the type of gestures by ZXXKEEP1ZX
3. ** Deter the target gesture**: Call `recognizer.preventBegin()` to prevent the squeezing of the gesture to a recognized state

```typescript
import { pdfService, pdfViewManager, PdfView } from '@kit.PDFKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'PDFView';

@Entry
@Component
struct PDFViewDemo {
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext();
    if (!context) {
      hilog.error(0x0000, TAG, 'Get context failed');
      return;
    }

    let dir: string = context.filesDir;
    let filePath: string = dir + '/pdf_reference.pdf';
    try {
      fileIo.accessSync(filePath);
      let content: Uint8Array = context.resourceManager.getRawFileContentSync('rawfile/pdf_reference.pdf');
      let fdSand =
        fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(fdSand.fd, content.buffer);
      fileIo.closeSync(fdSand.fd);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, `fs operation failed, error code: ${err.code}, error message: ${err.message}`);
    }

    (async () => {
      let loadResult: pdfService.ParseResult = await this.controller.loadDocument(filePath);
      if (loadResult === pdfService.ParseResult.PARSE_SUCCESS) {
        hilog.info(0x0000, TAG, 'PDF load successfully');
      }
    })();
  }

  build() {
    Row() {
      Stack() {
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_WIDTH,
          showScroll: true
        })
        .id('pdfview_app_view')
        .layoutWeight(1)
      }
/ 1 Set onTouchTestDone
      .onTouchTestDone((event, recognizers) => {
        for (let i = 0; i < recognizers.length; i++) {
          let recognizer = recognizers[i];
/ / / / / / Find a ciphered gesture identifier by type, call prevent Begin() to prevent its recognition
          if (recognizer.getType() == GestureControl.GestureType.PINCH_GESTURE) {
            recognizer.preventBegin();
          }
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
```
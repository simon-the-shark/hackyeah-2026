
# Handbanded scene

#ZXKEEP0ZpriorityGesture Overwrite sub-component gesture/system component internal gesture

** Applicable scenario: ** Use when custom gestures need to take precedence over sub-component gestures/system components to respond to gestures. For example, a slide gesture is embedded in components such as List and Grid, and if it is necessary to press the trigger window long rather than trigger the component default, `priorityGesture` should be used to raise the custom gesture priority above the part ' s inside.

** Distinction from parallelGesture: ** `parallelGesture` does not change priority, custom gestures compete in parallel with the internal signage of components; ZXXKEEP1ZX ensures that self-defined gestures respond first.

# # Apply scene: Show menus by picture long

** Steps to be taken:**

1. ** Declares that bullet windows are invisible* *: `@State showMenu: boolean = false`, sync to `onStateChange`
** BindPopup**: `.bindPopup(this.showMenu, { builder: this.popUpBuilder, onStateChange: ... })`, provided in `@Builder`
3. ** Mounting priorityGesture**: `.priorityGesture(GestureGroup(GestureMode.Exclusive, LongPressGesture().onAction(() => { this.showMenu = true })))`, giving long priority to sub-component/inline gestures

```typescript
@Component
struct GridImageView {
  @State blogItem: BlogData = new BlogData();
@state showMenu: Boolean = false; / // Control bullet windows hidden
  @State flowHeight: Length = 0;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

// Reusable components must update data by about ToReuse
  aboutToReuse(params: ESObject): void {
    this.blogItem = params.blogItem;
  }

  build() {
    Stack() {
      Image(this.blogItem.images[0])
        .sourceSize({ width: 100, height: 100 })
        .width(CommonConstants.FULL_WIDTH)
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
    }
    .borderRadius(12)
    .clip(true)
/ / / / / A bubble bullet window: driven by showMenu status
    .bindPopup(this.showMenu, {
bilder: This.popUpBuilder, / /Box Contents Construction Device
Placement: Placement.Top, / / Blast windows above components
Mask: {color: '#33 million'}, / / Semi-transparent mask
PopupColor: Color. Yellow, / / Yellow Background
enabledArrow: true, / / Show arrow pointing
ShowInSubWindow: false, // Not in Sub-window
      onStateChange: (e) => {
        if (!e.isVisible) {
This. showMenu = sync; / / / sync when the bullet window disappears
        }
      }
    })
Priority gesture: Long by trigger Window
    .priorityGesture(
      GestureGroup(GestureMode.Exclusive,
        LongPressGesture().onAction(() => {
          this.showMenu = true;
        })
      )
    )
  }

/ 3 Bullet window content: no interest button
  @Builder
  popUpBuilder() {
    Row({ space: 2 }) {
      Text($r('app.string.not_interested_button_text'))
    }
    .width(100)
    .height(50)
    .padding(5)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
/ / Remove this entry from the eventHub Notification page
      this.context.eventHub.emit(CommonConstants.EVENT_REMOVE_ITEM, this.blogItem)
      this.showMenu = false;
    })
  }
}
```

---

# SCENE-02 parallelGesture in parallel with the gesture/system component inside the subcomponent

** Applicable scenario: ** When the parent component ' s self-defined gesture is required to respond to the subcomponent (or system component built-in) gesture. For example, the bullet window/panette component contains a scrollable list, and the parent component is required to adjust the height of the bullet window by dragging and dragging the hand (down and up and up) while the sub-list still needs to be properly rolling and the two are not mutually exclusive.

** Distinction from PriorityGesture:** `priorityGesture` intercepts sub-component gestures and sub-components are unable to respond; ZXXKEEP1ZX allows the father component gestures to be triggered in parallel with sub-component gestures, coordinating each other ' s behaviour in a backsliding through a state mark.

# # Apply scene: comment on the height of the bullet window and the height of the shrunk content

** Steps to be taken:**

1. ** Split tow areas**: upper masked with `.gesture(PanGesture(...))` and bullet window mains with ZXXKEEP1ZX
2. **Paternity Link**: `@State isGesture` pass-on list via `@Link`. Write back at the top of the child list `true`; father gesture `onActionUpdate` First row ZXXKEEP4ZX
3. ** Calculate target height and tighten**: `curDialogHeight = initDialogHeight - event.offsetY`, less than 0, greater than the initial value
4. ** `onActionEnd` Decision Final**: height less than `COMMENT_DIALOG_MIN_HEIGHT` to ZXKEP2ZX or `recoveryDialog()` adsorption

```typescript
@Component
export struct CommentDialog {
  @LocalStorageProp('ndPageHeight') ndPageHeight: number = 0;
  @Link ndDialogHeight: number;
  private initDialogHeight: number = 0;
/ ** Whether or not to allow the parent component to respond by hand, the list is not disabled when scrolling at the top */
  @State isGesture: boolean = true;
  @State listScrollAble: boolean = true;

  build() {
    Column() {
/ / / / / / Up above the bullet window covered, with an independent gesture that does not affect the window area
      Column()
        .width('100%')
        .height(this.ndPageHeight - this.ndDialogHeight)
        .backgroundColor(Color.Transparent)
        .gesture(PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event) => {
            if (this.ndDialogHeight <= 0) { return; }
            const curDialogHeight = this.initDialogHeight - event.offsetY;
            if (curDialogHeight < 0) {
              this.ndDialogHeight = 0;
            } else if (curDialogHeight <= this.initDialogHeight) {
              this.ndDialogHeight = curDialogHeight;
            }
          })
          .onActionEnd(() => {
            if (this.ndDialogHeight < COMMENT_DIALOG_MIN_HEIGHT) {
              this.closeDialog();
            } else {
              this.recoveryDialog();
            }
          }))

/ 2 bullet window subject: sub-components containing scrollable comments
      Column() {
        Comment({
isGesture: this.isGesture, / / Subcomponent by @Link
          listScrollAble: this.listScrollAble,
        })
      }
      .width('100%')
      .height(this.ndDialogHeight)
      .backgroundColor(Color.White)
/ 3 parallelGesture: in parallel with the inner roll-on of the sublist Response
      .parallelGesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event) => {
/ / Based on isGesture signpoint: Fathers are allowed to handle drags when the list scrolls to top
            if (!this.isGesture || this.ndDialogHeight <= 0) { return; }
            const curDialogHeight = this.initDialogHeight - event.offsetY;
            if (curDialogHeight < 0) {
              this.ndDialogHeight = 0;
            } else if (curDialogHeight <= this.initDialogHeight) {
              this.ndDialogHeight = curDialogHeight;
            }
          })
          .onActionEnd(() => {
            if (!this.isGesture && this.ndDialogHeight === this.initDialogHeight) {
              return;
            }
            if (this.ndDialogHeight < COMMENT_DIALOG_MIN_HEIGHT) {
              this.closeDialog();
            } else {
              this.recoveryDialog();
            }
            this.listScrollAble = true;
          }),
GestureMask. Normal / 4 Use Normal mask without neglecting any subcomponent gestures
      )
    }
    .width('100%')
    .height('100%')
  }
}
```

---

# List of inner gesture components

System gestures (e.g. scroll, click, drag, etc.) are embedded in parts of ArkUI, and when the developers bind custom gestures for these components through `gesture` API, the custom gestures may conflict with the inner gestures. The following is a list of all components with built-in gestures, as well as a description of the type of gestures and the scene of the conflict within each component.

## # scroll container class component (inline Pan/Swipe slide)

The presence of vertical or lateral slides in such components is a high-prevalence scene of hand gesture conflict. The component provides `nestedScroll` properties to resolve embedded scrolling conflicts.

The control properties provided by the components
|------|---------|---------|------------------|
**List** Vertical Sliding Strength
**Grid**  **Little/Little Sliding Strengths  **List, custom gestures are slided and intercepted
**Scroll** longitudinal/horizontal slideshows  ** Embedded scroll containers clash with subcomponent slideshows  **XKEEP0ZX, `enableScrollInteraction`|
**Swiper** Left and Right Sliding Motion  ** Self-defined Left and Right Slide Conflicting Handprint  **XKEEP0ZX (disable slide toggle)  **
**WaterFlow**  ** Vertical Sliding Strength  ** Falls Flow Conflict with Custom Gesture  **XKEEP0ZX, `enableScrollInteraction` |
**Tabs** Left-and-Right Slid-Slid-Slid-Slid-Slid-Slid-Slid-Slid-Slip-Script-Scatter-Scrap-Scatter-Scrap-Scatter-Scrap-Scrap-Scatter-Scrap-Scrap-Scatter-Scrap-Scrap-Scatter-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Scrap-Screen-Screen-Screen

## # Media-type components (inline click/long press/shrump)

I'm sorry.
|------|---------|---------|
**Image** | Long Animation (Long-and-post-magnification) | Custom `LongPressGesture` Intercepted by animation by the built-in long, resulting in a long echo that does not trigger |
**Video**  ** Click (play/suspension), Slide (pacing drag), Double-finger scaling  ** Custom gestures conflict with play control gestures
**Web**  ** scroll, long press (text selection), click, double-finger scaling | Custom gestures conflict with the contents of the web page; `nestedScroll` interface is required for nested scrolling containers

## # Form interactive type component (inline click/traw gesture)

I'm sorry.
|------|---------|---------|
**Slider**  ** Drag (Slider Drag), Click (Trip)
**Rating**  ** Click on gestures (click on stars), slide hands (sliding stars)  ** Custom clicks/slides conflict with star-level selection  **
**Toggle**  ** Click on gestures (click to switch) | Customize `TapGesture` / `onClick` conflict with open concerns
**Checkbox**  ** Click on gestures (click toggle) | Customize `TapGesture` / `onClick` conflicted with the selection switch |
**Radio**  ** Click on gestures (click on selection)  ** Custom clicks on gestures in conflict with single-chosen switching
**Select**  ** Click gestures (click to expand the dropdown menu)  ** Custom clicks conflict with menus
**Search**  ** Click on gestures (click on search box focus) | Custom click and input focus conflict  **

# # Selecter type component (inline roller)

I'm sorry.
|------|---------|---------|
**DatePicker** Roll action (year/month/day roller selection)
** **TimePicker** | Roll action (time/roller selection) | Custom longitudinal slide conflict with rolling wheel
**TextPicker**  ** Roll-in (text roller selection)  ** Custom longitudinal slide and roller conflict  **

## # Navigation type component (inline slide)

I'm sorry.
|------|---------|---------|
**Navigation**  ** Right slide on edge back to hand gestures  ** Customized left/right slide moves conflict with system returns

# GestureGroup

# ZXKEEP0Z Sequence: There's a sequence between gestures

** Applicable scenario: ** When there is a clear order of call between multiple gestures, the last sign should be used when the last sign is successful. For example, drag long after confirmation of intent (ordering of icons, moving of cards), click after selection (photo editor), double click after long press (quick action) etc.

** Core mechanism: ** `GestureGroup(GestureMode.Sequence, GestureA, GestureB)` sequentially. GestureA succeeded before GestureB began to identify. If GestureA doesn't trigger or be cancelled, GestureB will not take effect. Just one last gesture on an actionend can respond.

# # Apply scene: long press and drag pictures

Users confirm their intent with the card first, their fingers are moved and the card animation is returned.

** Steps to be taken:**

1. **Priority binding**: use of `priorityGesture` to bind gesture groups, with priority given to the inner length of components such as Image
2. **Advanced drag mode in `onAction` (magnification + semi-transparent visual feedback)**
3. ** Post-sequence gesture (Pan)**: `distance: 0` set up to ensure that identification is made even without drag, thus triggering `onActionEnd` completion status reset as the last gesture.
4. ** Bottom reset (onCancel)**: Serial break `onCancel` replacement state when gestures are interrupted

```typescript
@Entry
@Component
struct LongPressDragDemo {
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State isDragging: boolean = false;
  @State cardScale: number = 1.0;
  @State cardOpacity: number = 1.0;

  build() {
    Column() {
      Column() {
        Image($r('app.media.startIcon'))
          .width(160)
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)

Text.
          .fontSize(16)
          .fontColor(Color.White)
          .margin({ top: 12 })
      }
      .width(200)
      .height(240)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FF2D73FF')
      .borderRadius(16)
      .shadow(this.isDragging
        ? { radius: 24, color: '#40000000', offsetX: 0, offsetY: 8 }
        : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
      .scale({ x: this.cardScale, y: this.cardScale })
      .opacity(this.cardOpacity)
      .translate({ x: this.offsetX, y: this.offsetY })
Step 1: PriorityGesture has priority over Image's inner long animated
      .priorityGesture(
        GestureGroup(GestureMode.Sequence,
Step 2: Precedence gestures - Long press entry drag mode
          LongPressGesture({ fingers: 1, repeat: false, duration: 300 })
            .onAction(() => {
              this.isDragging = true;
              this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                this.cardScale = 1.15;
                this.cardOpacity = 0.85;
              });
            }),
Step 3: Back-sequence gesture - dissertation: 0 to ensure access to identification,
// Reset status onActionEnd as last gesture
          PanGesture({ fingers: 1, direction: PanDirection.All, distance: 0 })
            .onActionUpdate((event: GestureEvent) => {
              if (!this.isDragging) return;
              this.offsetX = event.offsetX;
              this.offsetY = event.offsetY;
            })
            .onActionEnd(() => {
              this.resetDrag();
            })
        )
Step 4: Bottom - Reset state when sequence breaks
        .onCancel(() => {
          this.resetDrag();
        })
      )
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F1F3F5')
  }

  private resetDrag() {
    this.isDragging = false;
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.cardScale = 1.0;
      this.cardOpacity = 1.0;
    });
  }
}
```

---

# SCENE-02 Parallel Parallel gestures: multiple gestures are identified, different situations trigger different effects

** Applicable scenario:** When multiple gestures need to be identified and triggered in parallel. For example, long, which is not at the same time long is effective in parallel on the same component - short-trigger collection, medium-long-trigger sharing, long-trigger deletion, the longer the user holds hold, the higher the operational level of the trigger.

** Core mechanism:** `GestureGroup(GestureMode.Parallel, GestureA, GestureB, GestureC)` allows all gestures in the group to be identified at the same time and without hindrance. Each sign independently triggers its own `onAction`, and all triggers will execute `onActionEnd`.

# # Apply scene: different effects at different lengths

The user presses a button to trigger different levels as the pressure is increased: 0.5 seconds collection, 1.5 seconds sharing, 3.0 seconds deletion.

** Steps to be taken:**

1.** Parallel group**: using `GestureGroup(GestureMode.Parallel, ...)` to combine three different ZXXKEEP1ZX, which simultaneously begin to recognize
2. ** Hierarchy Trigger**: minimum (500 ms) gestures trigger `onAction` first, medium (1500 ms) and maximum (3000 ms) signal triggers sequentially over time
3. **Standing**: `onAction` by `if (this.pressLevel < N)`
4. ** Reset **: `onActionEnd` (Leave Hands) in the shortest long hand sign to zero and ensure that the next round starts at zero

```
/ State: records the highest level that is currently triggered
pressLevel = 0

/ / 1 GestureGroup (Paralel): 3 LongPressGestures At the same time
Component.gesture()
  GestureGroup(GestureMode.Parallel,
// 2,500 ms → Collection (first triggered)
    LongPressGesture({ duration: 500 })
      .onAction(() => {
        pressLevel = 1
Trigger Collection
      })
/ 5 Reset after release and the next round presses from zero
      .onActionEnd(() => {
        pressLevel = 0
      }),

/ 3 1500ms → Share
    LongPressGesture({ duration: 1500 })
      .onAction(() => {
If (press Level < 2) {/ / / 4 Status Progressive: Ensure level is raised only
          pressLevel = 2
Trigger Sharing
        }
      }),

/ / 4,300ms
    LongPressGesture({ duration: 3000 })
      .onAction(() => {
        if (pressLevel < 3) {
          pressLevel = 3
Trigger Delete
        }
      })
  )
)
```

---

# SCENE-03 Exclusive: mutually exclusive gestures

** Applicable scenario: ** When multiple gestures are tied to the same component, they should be used at the same time only to respond to one of them. For example, click on each other (click on jump, long click on pop-up menu), click on each other and double-click on each other (click on selection, double-click on).

** Core mechanism:** `GestureGroup(GestureMode.Exclusive, GestureA, GestureB)` allows for cross-references. The system is tried one by one in the order of parameters, and once a gesture has been successfully matched, the rest will no longer respond.

## # Apply scene: commercial card long by popup menu, click off menu

The user clicks a commodity picture to close an open operating menu, e.g., pops up " uninterested " with a long commercial picture, and both gestures retrace each other - only one at the same time.

** Steps to be taken:**

1. **Crust group**: use `GestureGroup(GestureMode.Exclusive, TapGesture, LongPressGesture)` to click and long grouping into mutually exclusive gestures
2. **parallelGesture binding**: use of `parallelGesture` instead of `gesture` to identify self-defined gestures in parallel with those inside components and to avoid being intercepted by system-set gestures
3. ** Click to close **: `TapGesture({ count: 1, fingers: 1 })`
4. **Long press `LongPressGesture({ repeat: true })` **: `onAction` setting `selectedProductId` to the current commodity id to trigger the menu overlay display

```typescript
@Component
export struct ProductCard {
  @Link itemList: Array<Product>;
  @Link selectedProductId: number;
  @State product: Product = /* ... */;

  build() {
    Stack() {
      Column() {
        Image(this.product.imageUrl)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 0 })
          .draggable(false)
/ 1/ ParallelGesture: unstoppable in parallel with the internal signage of the component
          .parallelGesture(
            GestureGroup(GestureMode.Exclusive,
/ / 2 Click - Close Operations Menu
              TapGesture({ count: 1, fingers: 1 })
                .onAction(() => {
                  this.selectedProductId = 0;
                }),
/ 3 Long Press - Popup Menu (repeat: true sustainable trigger)
              LongPressGesture({ repeat: true })
                .onAction(() => {
                  this.selectedProductId = this.product.id;
                })
            )
          )

/... commodity titles, prices, etc. UI omitted
      }
      .width('100%')
      .height(253)
      .backgroundColor(Color.White)
      .borderRadius(12)

/ / 4 Long Overlay Menu, displayed only when selected
      if (this.selectedProductId === this.product.id) {
        Stack() {
          Column()
            .width('100%')
            .height(253)
            .backgroundColor('#80000000')
            .borderRadius(12)
/... Operation button list omitted
        }
        .onClick(() => {
          this.selectedProductId = 0;
        })
      }
    }
  }
}
```

## # Attention: questions about the order of statements when clicking and double-clicking

When tied to `GestureMode.Exclusive` at the same time as a double-click,** a double-click sign must be declared before the click**, otherwise the double-click sign cannot respond.

** Reason: **Exclusive mode tries to match one by one in parameter order. If `TapGesture({ count: 1 })` is written in front, the system will immediately match the click to the sign at the first click, and the double click will never be recognized. Places `TapGesture({ count: 2 })` in front, the system will wait to decide whether to double-click or not, if not to click.

```typescript
/ / ✅ Correct: double-click in front, click behind
GestureGroup(GestureMode.Exclusive,
TapGesture({count: 2)/ Try double-click first
.onAction(()=>{/* Double-click logic*/},
TapGesture({count: 1})/ Try again
.onAction(()=>{/ * Click Logic*/})
)

/ / ❌ Error: Click before, double click will never ring Response
GestureGroup(GestureMode.Exclusive,
TapGesture({count: 1})/ / Click to immediately match, double-click to skip
...onAction(() = > {/ * Click Logic*/},
TapGesture({count: 2) / / Never
.onAction(()=>{/* Double-click logic*/})
)
```

** Side effects: ** This order of statements leads to a delay of approximately 300 ms in a hand-click response. Because the system has to wait some time (about 300ms) to confirm that the user will not make a second click before it can be judged to be a click and trigger the echo. This is the inevitable trade-off in the click/twice-butting scene.

** Substitution:** If 300ms delay is unacceptable, consideration may be given to:
- Only click, remove double-click gestures and replace double-click with other interactions (e.g. long press, button)
- Use `GestureMode.Parallel` to double-click and double-click for parallel recognition, and manually secure double-click and double-click for execution
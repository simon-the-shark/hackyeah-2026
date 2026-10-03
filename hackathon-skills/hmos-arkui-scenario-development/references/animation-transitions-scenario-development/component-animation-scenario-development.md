# Component Animation Cases

# Apply scene

* Reissued for technical reasons.
|---|---|---|
| `TransitionEffect.OPACITY.combine(translate)` + `delay: index * 80` | delay Incremental generation waterfall staggering ZXXKEEP2ZX increases elasticity
| List Item Drag and Drag Exchange + Slide Delete |`AttributeModifier` + `GestureGroup(Sequence)` + ZXXKEEP2ZX | The scale/ translate/shadow/opacity, Modifier Mode requires control of multiple items; sidedrop delete achieves | via swipeaction + two paragraphs animateTo
| Grid Delete Fill + Add Back to Location |`Grid.supportAnimation(true)` + `AttributeModifier` + `AttributeUpdater` + `componentUtils` | Remove Fade + Slide from Modifeier Manual Drive; Add BacktoPilot Attribut Updater + ComponentUtils Calculating Screen Coordinates achieve cross-area flight into |

# Core Animation API Enumeration Reference

# TranstionEffect Static Properties and Methods

| Properties/methods
|---|---|---|
Z `TransitionEffect.OPACITY` | Transparency transition (1 00 →1) | List entry/ dropout
Z `TransitionEffect.IDENTITY` | no-turn effects
|`TransitionEffect.opacity(value)`| Custom transparency threshold | Modular login 0.4 Transparency transition |
`TransitionEffect.translate(offset)` ZEZX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX
`TransitionEffect.scale(scale)` ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX
`TransitionEffect.rotate(angle)` | rotation field | card flip effect
`TransitionEffect.move(edge)` | Slide/ Slide From Specified Edges | Page B Slide From Right
`.combine(effect)` | Combining two rotation effects
`.animation(params)` | Attaches animated parameters to the rerun

## curves module spring curve function (component animation commonly used)

| Function | Parameter | Description | Typical scene |
|---|---|---|---|
`curves.springMotion()` `(response?, dampingFraction?)` `(response?, dampingFraction?)` | spring motion curve | List of flexible ejectives entering the field
Z`curves.interpolatingSpring()` |`(velocity, mass, stiffness, damping)` | Plug-in spring curve | Plug-out two-part flexed backs (large blocker + small blocker) |
`curves.initCurve()` | `(curve: Curve)` | Initialisation Curve ZXXKEEP2ZX Calculates Neighborage Zoom

##ConponentUtils module (Calculated cross-area coordinates)

| Function | Parameter | Description | Typical scene |
|---|---|---|---|
`componentUtils.getRectangleById(id)` |`(id: string)` | Get screen coordinates and dimensions through component id
| Returns the value `.screenOffset` | `{ x: number, y: number }` | Screen Coordinate (px) | for the upper left corner of the component calculates the difference of the screen coordinates between the two components
| Return value `.size` | `{ width: number, height: number }` | The width and height of the | component

# # Curve numeric count (assembly animation commonly used)

| | |
|---|---|---|
`Curve.Friction` curve curve curve curve curve curve curve curve curve curve curve curve curve curve curve curve Z Z curve curve Z curve curve curve curve curve curve curve curve curve curve curve curve curve curve curve curve
`Curve.Sharp` ZeroZiZiZiZiZi ZiZiZiZiXiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiXiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiXiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZ ZiZi
Z `Curve.ExtremeDeceleration` | Extreme deceleration Curve | Grid In Animation (Quick and Slow Landing)

---

# Scenario 1: List entry

** scene description:** imitation social App page refreshed, 12 list entries pop up from the bottom, click on the button, 80 ms at each interval, creating a waterfall staggered entry.

** Solution:** Use **`TransitionEffect.OPACITY.combine(translate({y:80}))`** ** **`delay: index * 80` intersection** ** ** ** `curves.springMotion()` elastic curve**

```ts
@State items: number[] = []

playStaggerAnimation() {
  this.items = []
  setTimeout(() => {
    this.items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }, 50)
}

List() {
  ForEach(this.items, (item, index) => {
    ListItem() {
Row(){/* List item content*/}
    }
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 80 }))
        .animation({ duration: 400, curve: curves.springMotion(), delay: index * 80 })
    )
  })
}
```

Key point: `if` enters the dump when `delay: index * 80` triggers `if` conditions. `delay: index * 80` produces an incremental waterfall effect of 80 ms.

---

# scene 2: List item exchange

** scene description:** mimics the order of payment of bank cards management/quick payment, floats (shades + zooms) long by the list item, drags up and down with the finger, drags with the neighbour ' s item condensing on the basis of the dynamic of distance, automatic exchange of position when above half the height of the adjacent item, and flexes the back of the two subsequent springs. Supports side-slide-out deletion buttons, and clicks the list item to the right and fades away.

** Solution:** Use **`AttributeModifier<ListItemAttribute>` encapsulation animation properties (scale/translate/opacity/shadow)** ** ** ** `GestureGroup(Sequence, LongPress + Pan)` handprint** ** ** ** ** `curves.initCurve(Curve.Sharp).interpolate()` ** ** ** ** ** `curves.interpolatingSpring` ** ** ** `ListItem.swipeAction` side slide deleted** + ** ** two paragraphs ZXXKEEP5ZX removed data)**

### Step 0: Control Class Definition + Constant + Status Management Prerequisite [Auxiliary]

> Pure data structure definition and control complete class definition, providing a typological basis for subsequent steps. ** This step cannot be omitted** - The absence of `@Observed` decorations or the use of `private` access modifiers will cause UI to modify control properties without reloading and drag to change animations completely invalid.

```ts
const ITEM_HEIGHT: number = 50;
const ANIMATE_DURATION: number = 300;

enum OperationStatus {
  IDLE,
  PRESSING,
  MOVING,
  DROPPING,
  DELETE
}

@Observed
export class ListExchangeCtrl<T> {
  private deductionData: Array<T> = [];
  private modifier: Array<ListItemModifier> = [];
State: OperationStatus = OperationStatus.IDLE; / / ⚠️ must public: @Observed only observe public property changes
  private dragRefOffset: number = 0;
Offsety: number = 0; / / / ⚠️ must public: as above

  initData(deductionData: Array<T>) {
    this.deductionData = deductionData;
    deductionData.forEach(() => {
      this.modifier.push(new ListItemModifier());
    })
  }

  getModifier(item: T): ListItemModifier {
    const index: number = this.deductionData.indexOf(item);
    return this.modifier[index];
  }

/ on LongPress / onMove / HandleDrop / ChangeItem
}

/ / ⚠️ Initialization must be called initData in aboutToAppear and cannot be used in the constructor:
/ Correct:
//   @State listExchangeCtrl: ListExchangeCtrl<ListInfo> = new ListExchangeCtrl();
//   aboutToAppear(): void { this.listExchangeCtrl.initData(this.appInfoList); }
/ Error:
//   @State listExchangeCtrl = new ListExchangeCtrl(this.appInfoList);
/ Reason: At the time of construction, @State has not yet completed the binding of the component tree, @Observed observation chain has not been set up, and it is not possible to create a @Observed.
/ / Subsequent animateTo modify the ctrl attribute cannot trigger UI heavy rendering.
```

Key points:
- ** `@Observed` Decorator cannot be omitted**: `@State`/`@Link` Only Depth property observation of `@Observed` cases. When this decorator is missing, `animateTo` modify the `offsetY`, `modifier[].scale` properties inside the ctrl do not trigger UI rendering, resulting in drag-to-shape animation completely invalid -- The cards don't move with their fingers, the neighbors don't shrink, the exchange doesn't happen.
- ** `state` and `offsetY` shall have public**: `@Observed` only observe public changes of properties, which do not trigger heavy rendering
-** Initialization using `initData()` method**: Call in `aboutToAppear` instead of tectonic transfer. The component tree was mounted at `aboutToAppear`, and the `@State`/`@Link` observation chain was established to ensure that subsequent `animateTo` changes the ctrl attribute correctly triggers UI heavy rendering
-** `@Link` binding mode**: Father component holds case ctrl through `@State` and sub-`ListExchange` component receives via `@Link`. `@Link` binds ctrl to the `@State` of the parent component, which, in conjunction with `@Observed`, forms a deep observation chain across the component to ensure that ctrl properties change triggers UI replicating
- `ITEM_HEIGHT` must match the actual height of the list item, influence the exchange threshold calculation and the neighbor ' s constriction scale mapping

Step 1: ListitemModifier - Encapsulate animation properties as responsive objects

Each list item corresponds to an example of `ListItemModifier` that maps properties to the component style through `applyNormalAttribute`. The controller changes the attribute value in `animateTo` to trigger the animation. Modifier needs to overwrite the full animation properties of drag and drag exchange and side slide to delete both scenarios.

```ts
export class ListItemModifier implements AttributeModifier<ListItemAttribute> {
  public hasShadow: boolean = false;
  public scale: number = 1;
  public offsetY: number = 0;
  public offsetX: number = 0;
  public opacity: number = 1;
  public isDeleted: boolean = false;

  applyNormalAttribute(instance: ListItemAttribute): void {
    if (this.hasShadow) {
      instance.shadow({
        radius: $r('app.integer.list_exchange_shadow_radius'),
        color: $r('app.color.list_exchange_box_shadow')
      });
      instance.zIndex(1);
      instance.opacity(0.5);
    } else {
      instance.opacity(this.opacity);
    }
    instance.translate({ x: this.offsetX, y: this.offsetY });
    instance.scale({ x: this.scale, y: this.scale });
  }
}
```

Key points:
- `hasShadow` sets the shadow + zIndex + opacity when `hasShadow` is `true`; `opacity` deletes independently without shadow Light Out
-`offsetY` Drive Drag Vertical Shift; ZXXKEEP1ZX Drive Slide Remove Horizontal Move
- `scale` drive long by magnification and neighbourhood contraction; `isDeleted` mark deleted status for controller judgement
-shadow radius/color with `$r()` resource Quote for theme adaptation and multilingual maintenance

Step 2: List bound Modifeier + GestureGroup Group gestures + sideways deleted

`ListExchangeCtrl` maintains a `ListItemModifier` for each data item (data array and Modiffer array 1:1 map) and tracks the interactive status with `OperationStatus` (IDLE/PRESSING/MOVING/DRUPING/DELETE). `ListItem` binds the `.attributeModifier()` to the Modifier, achieves the "Stand and Drag" line by `GestureGroup(Sequence)`, while ZXXKEEP6ZX supports side-sliding and remove buttons.

```ts
@Component
export struct ListExchange {
  @Link appInfoList: Object[];
  @Link listExchangeCtrl: ListExchangeCtrl<Object>;
  @BuilderParam deductionView: (listInfo: Object) => void;
  @State currentListItem: Object | undefined = undefined;
  @State isLongPress: boolean = false;

  build() {
    Column() {
      List() {
        ForEach(this.appInfoList, (item: Object, index: number) => {
          ListItem() {
            this.deductionView(item)
          }
          .id('list_exchange_' + index)
          .zIndex(this.currentListItem === item ? 2 : 1)
          .swipeAction({ end: this.defaultDeleteBuilder(item) })
          .transition(TransitionEffect.OPACITY)
          .attributeModifier(this.listExchangeCtrl.getModifier(item))
          .gesture(
            GestureGroup(GestureMode.Sequence,
              LongPressGesture()
                .onAction((event: GestureEvent) => {
                  this.currentListItem = item;
                  this.isLongPress = true;
                  this.listExchangeCtrl.onLongPress(item);
                }),
              PanGesture()
                .onActionUpdate((event: GestureEvent) => {
                  this.listExchangeCtrl.onMove(item, event.offsetY);
                })
                .onActionEnd((event: GestureEvent) => {
                  this.listExchangeCtrl.handleDrop(item);
                  this.isLongPress = false;
                })
            ).onCancel(() => {
              if (!this.isLongPress) {
                return;
              }
              this.listExchangeCtrl.handleDrop(item);
            }))
        }, (item: Object) => JSON.stringify(item))
      }
      .divider({ strokeWidth: '1px', color: 0xeaf0ef })
      .scrollBar(BarState.Off)
      .width('100%')
    }
  }

  @Builder
  defaultDeleteBuilder(item: Object) {
    Image($r("app.media.list_exchange_icon_delete"))
      .width($r('app.integer.list_exchange_icon_size'))
      .height($r('app.integer.list_exchange_icon_size'))
      .onClick(() => {
        this.listExchangeCtrl.deleteItem(item);
      })
  }
}
```

Key points:
- `GestureGroup(Sequence, LongPress, Pan)` Serial Group: The long press must be triggered before the drag phase is reached and error is avoided
- `.onCancel()` processing sign interruption: return directly when long pressed untriggered (`isLongPress === false`); return to `handleDrop` when entered towp to prevent drag items from remaining in the middle
- `isLongPress` Sign Position Distinguishing "not trigger long" and "enter drag" cancelled scenes
- `zIndex` Dynamic Switch: Draged `zIndex(2)` floats over other items
- `transition(TransitionEffect.OPACITY)` provides fade-out effects when adding or deleting arrays
- `.swipeAction({ end })` side slides out the remove button, click and call `deleteItem` to execute the removal of the animation
- `.id('list_exchange_' + index)` sets a unique identifier for each list item to facilitate UI testing and accessibility
- KeyGenerator for ForEach uses `JSON.stringify(item)` to make sure that the exchange is tracked correctly.

Step 3: Long by floating - animateTo drive shadow + size

When you press the trigger, `animateTo` changes the `hasShadow` and `scale` properties of Modifier to create a sense of suspension from the card.

```ts
onLongPress(item: T): void {
  const index: number = this.deductionData.indexOf(item);
  this.dragRefOffset = 0;
  animateTo({ curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION }, () => {
    this.state = OperationStatus.PRESSING;
    this.modifier[index].hasShadow = true;
    this.modifier[index].scale = 1.04;
  })
}
```

Key points:
- Use of `commonConstants.ANIMATE_DURATION` (300ms) instead of hard-coding time to facilitate global harmonization
- `OperationStatus.PRESSING` status tag for subsequent logical judgement on the current interactive phase

Step 4: Drag Off

There are three key logics in the drag: direct migration, contraction of neighbours, and super-middle exchange. `onMove` uses try/catch packages to prevent animated carcasses from abnormally causing death during drag.

```ts
onMove(item: T, offsetY: number): void {
  try {
    const index: number = this.deductionData.indexOf(item);
/ / 1. Directly update place shift (no animation, following finger)
    this.offsetY = offsetY - this.dragRefOffset;
    this.modifier[index].offsetY = this.offsetY;

/ 2. Neighbourhood contraction: ratio of contraction based on drag distance
    const direction: number = this.offsetY > 0 ? 1 : -1;
    const curveValue: ICurve = curves.initCurve(Curve.Sharp);
    const value: number = curveValue.interpolate(Math.abs(this.offsetY) / ITEM_HEIGHT);
    const shrinkScale: number = 1 - value / 10;
    if (index < this.modifier.length - 1) {
      this.modifier[index + 1].scale = direction > 0 ? shrinkScale : 1;
    }
    if (index > 0) {
      this.modifier[index - 1].scale = direction > 0 ? 1 : shrinkScale;
    }

// 3. More than half-height → animateTo exchange position
    if (Math.abs(this.offsetY) > ITEM_HEIGHT / 2) {
      if (index === 0 && direction === -1) { return; }
      if (index === this.deductionData.length - 1 && direction === 1) { return; }
      animateTo({ curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION }, () => {
        this.offsetY -= direction * ITEM_HEIGHT;
        this.dragRefOffset += direction * ITEM_HEIGHT;
        this.modifier[index].offsetY = this.offsetY;
        const target = index + direction;
        if (target !== -1 && target <= this.modifier.length) {
          this.changeItem(index, target);
        }
      })
    }
  } catch (err) {
    logger.error(`onMove err:${JSON.stringify(err)}`);
  }
}

// Synchronize data arrays and Modifier arrays
changeItem(index: number, newIndex: number): void {
  const tmpData = this.deductionData.splice(index, 1);
  this.deductionData.splice(newIndex, 0, tmpData[0]);
  const tmpModifier = this.modifier.splice(index, 1);
  this.modifier.splice(newIndex, 0, tmpModifier[0]);
}
```

Key points:
- `dragRefOffset` to aggregate exchanged offsets to ensure the correct calculation of time-to-time shifts after consecutive exchanges (`offsetY` fixes `ITEM_HEIGHT` after each exchange)
- `curves.initCurve(Curve.Sharp).interpolate()` used `curves.initCurve(Curve.Sharp).interpolate()` to map drag progress (0-1) to non-linear contraction ratio, ZXXKEEP1ZX to change faster in the front of contraction
- Maintenance of 1:1 map relationship during exchange by `splice` Synchronizing data arrays and Modifeier arrays
-Try/catch package whole `onMove` to prevent border abnormalities during tow leading to the death of animated cards; ZXXKEEP1ZX recording abnormalities to debug
- Exchange target `target = index + direction` Add `target !== -1 && target <= this.modifier.length` double border verification

Step 5: Flex back - two spring animations

Two `interpolatingSpring` spring animations were carried out after the release: first, the neighbour, then the drag itself. Use the try/catch package to prevent fate anomalies and `logger` to record key nodes for debugging.

```ts
handleDrop(item: T): void {
  logger.info(`handleDrop start`);
  try {
    const index: number = this.deductionData.indexOf(item);
    this.dragRefOffset = 0;
    this.offsetY = 0;

/ / Paragraph 1: Reconstituted neighbour scale
    animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
      this.state = OperationStatus.DROPPING;
      if (index < this.modifier.length - 1) {
        this.modifier[index + 1].scale = 1;
      }
      if (index > 0) {
        this.modifier[index - 1].scale = 1;
      }
    })

/ / Second paragraph: double-trawl
    animateTo({ curve: curves.interpolatingSpring(14, 1, 170, 17) }, () => {
      this.state = OperationStatus.IDLE;
      this.modifier[index].hasShadow = false;
      this.modifier[index].scale = 1;
      this.modifier[index].offsetY = 0;
    })
    logger.info(`handleDrop end`);
  } catch (err) {
    logger.error(`handleDrop err:${JSON.stringify(err)}`);
  }
}
```

Key points:
- The two springs use different parameters: `interpolatingSpring(0, 1, 400, 38)` blocker, low rebuff, suitable for the smooth re-entry of the neighbour; ZXXKEEP1ZX small, visible rebuff, suitable for the flexible return of the tow item itself
- Two `animateTo` sections, which trigger at the same time but have different Modifoier properties, visually form the level of "neighbors first, drag and drop." Sensor.
- `OperationStatus` state flow: PRESSING → DROPPING → IDLE, each animation sets a different state to extend the weight defence logic to the `state` field
- `logger.info` records `handleDrop start/end` key nodes for tracking the animated life cycle and chronology problems

## # Step 6: Slide Delete - Two passages animateTo slide out + remove data

Slides out of the delete button on the side of `ListItem.swipeAction({ end })`, clicks and then calls `deleteItem`. Deletes the animation in two segments: the first drive of thefsetX + position (slips to the right and fades out), and the second removes the item from the data/modifier array in `onFinish`, matching ZXKEEP3Z with the dropout of the list entry.

```ts
deleteItem(item: T): void {
  try {
    const index: number = this.deductionData.indexOf(item);
    this.dragRefOffset = 0;
/ / First paragraph: Slide out of animation
    animateTo({
      curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION, onFinish: () => {
/ / Second paragraph: Remove data + Modiffer array
        animateTo({
          curve: Curve.Friction, duration: 500, onFinish: () => {
            this.state = OperationStatus.IDLE;
          }
        }, () => {
          this.modifier.splice(index, 1);
          this.deductionData.splice(index, 1);
        })
      }
    }, () => {
      this.state = OperationStatus.DELETE;
This.modifier [index].offsetX = 150; / / Right Slide Out
= 0; //
    })
  } catch (err) {
    logger.error(`delete err:${JSON.stringify(err)}`);
  }
}
```

Key points:
- The first paragraph `animateTo` uses ZXXKEEP1Z300ms: `offsetX = 150` for `offsetX = 150` to slide out horizontally, and ZXXKEEP3ZX for `opacity = 0` to trigger both the visual effect of "slide out and disappear"
- `animateTo` in the first paragraph of `onFinish`: remove this item first from the Modifeier and data arrays `splice`, at which point ZXXKEEP3ZX automatically provides a fade-out transition for list exits
- `onFinish` chain calls to make sure the timing is correct: First slide out, then remove the data and trigger the exit, and finally restore ZXXKEEP1ZX to IDLE
-`this.dragRefOffset = 0` Reset drag-and-drop baseline offsets to prevent deletion and drag-and-drop again Stay.

---

# Scenario 3: grid elements swap

**Scene description:** Simulate desktop shortcut management, with red drop buttons on the top right corner of the icon after entering the edit mode, click to delete the next adjacent icon to fill the empty slot (peer left, line tail to first of the next row), while supporting long drag-and-drop reordering. The icon in the list below is recommended to be clicked to the end of the main grid and the animation based on `componentUtils` calculates the screen coordinates to move from area to area.

** Solution:** Compute cross-area screen coordinates** ** ** ** `Grid.editMode` + ZXKEEP1Z** ** ** `AttributeModifier<GridItemAttribute>` Driver Deletation** + ** `AttributeUpdater<ColumnAttribute>` Driver Added Flight Shift** + ** `componentUtils.getRectangleById`

Step 1: Data model + two sets of Modifuier + constant definition

Data items use `@Observed` decorations, which contain `visible` properties to control visibility. Delete the scene with `GridItemModifier implements AttributeModifier` and add the returned scene with `TranslateItemModifier extends AttributeUpdater` (accessible `attribute` properties to set the style directly). The definition of constant concentration facilitates global adjustment.

```ts
const DELETE_ANIMATION_DURATION: number = 200;
const ADD_ANIMATION_DURATION: number = 1000;
const GRID_ITEM_SIZE: number = 72;
const COLUMN_COUNT: number = 5;

@Observed
export class AppInfo {
  icon: ResourceStr = '';
  name: ResourceStr = '';
  visible: boolean = true;
  constructor(icon: ResourceStr = '', name: ResourceStr = '', visible: boolean = true) {
    this.icon = icon; this.name = name; this.visible = visible;
  }
}

@Observed
export class GridItemModifier implements AttributeModifier<GridItemAttribute> {
  public offsetX: number = 0;
  public offsetY: number = 0;
  public opacity: number = 1;

  applyNormalAttribute(instance: GridItemAttribute): void {
    instance.translate({ x: this.offsetX, y: this.offsetY });
    instance.opacity(this.opacity);
  }
}

@Observed
export class TranslateItemModifier extends AttributeUpdater<ColumnAttribute> {
  initializeModifier(instance: ColumnAttribute): void {
    instance.translate({ x: 0, y: 0 })
      .visibility(Visibility.Visible);
  }
}
```

Key points:
- Delete `AttributeModifier`: Automatically trigger animations with `applyNormalAttribute` response map properties, ZXXKEEP2ZX
- Add `AttributeUpdater`: The `attribute` attribute allows the `.translate()` / `.visibility()` to be called directly in the `animateTo` callback, without waiting for ZXXKEEP5ZX to be called again, suitable for the flight animation that needs to be calculated by precise screen coordinates
- `AppInfo.visible` to control the display/hidden of added items in the recommended list
- Constant concentration definition: `DELETE_ANIMATION_DURATION`, `ADD_ANIMATION_DURATION`, `GRID_ITEM_SIZE`, ZXXKEEP3ZX to avoid hard-coded dispersions

Step 2: Delete Animation - Deleted

`GridItemDeletionCtrl` holds a `GridItemModifier` for each grid item and tracks the deleted state with `DeletionStatus` (IDLE/START/FINISH). Deleting by `animateTo` simultaneously drives the deleted out and subsequent moves, after the animation has ended, reset Modifeier offsets → removed from the data/Modifeer array → to notify other components of `AppStorage.setOrCreate` status.

```ts
export enum DeletionStatus { IDLE, START, FINISH }

export class GridItemDeletionCtrl<T> {
  private modifier: GridItemModifier[] = [];
  private gridData: T[] = [];
  private status: DeletionStatus = DeletionStatus.IDLE;

  constructor(data: T[]) {
    this.gridData = data;
    data.forEach(() => { this.modifier.push(new GridItemModifier()); })
  }

  getModifier(item: T): GridItemModifier {
    const index: number = this.gridData.indexOf(item);
    if (index === -1) {
      return new GridItemModifier();
    }
    return this.modifier[index];
  }

  deleteGridItem(item: T, itemAreaWidth: number): void {
    const index: number = this.gridData.indexOf(item);
    animateTo({
      curve: Curve.Friction, duration: DELETE_ANIMATION_DURATION, onFinish: () => {
        this.modifier.forEach((item) => {
          item.offsetX = 0;
          item.offsetY = 0;
        })
        this.gridData.splice(index, 1);
        this.modifier.splice(index, 1);
        this.status = DeletionStatus.FINISH;
        AppStorage.setOrCreate('deletionStatus', this.status);
      }
    }, () => {
      this.modifier[index].opacity = 0;
      this.modifier.forEach((item: GridItemModifier, ind: number) => {
        if (index === this.gridData.length - 1) {
          this.status = DeletionStatus.START;
          return;
        }
        if (ind > index && ind % COLUMN_COUNT !== 0) {
          item.offsetX = -itemAreaWidth;
        } else if (ind > index && ind % COLUMN_COUNT === 0) {
          item.offsetX = itemAreaWidth * 4;
          item.offsetY = -GRID_ITEM_SIZE;
        }
      })
      this.status = DeletionStatus.START;
    })
  }
}
```

Key points:
- ZXKEEP0Z200ms produces a natural slowdown. Sensor.
-Participate shift of all items (`ind > index`) after deletion: Shift one `itemAreaWidth` to the left of the non-line first entry; Move four grids to the right of the line first item (`ind % COLUMN_COUNT === 0`) + Move one cell up and replace the line back to fill in
- `index === this.gridData.length - 1` is the last item, which does not require a shift in the neighbour position, which is removed only when it fades out
- `onFinish` to reset all modifier offsets (`offsetX/offsetY = 0`) and remove this from two arrays to ensure that there are no remnants
- `AppStorage.setOrCreate('deletionStatus', DeletionStatus.FINISH)` syncs the state to the global level, with the main component re-entry locking through ZXXKEEP1ZX listening changes
- return new instance when `getModifier` returns `index === -1` to prevent the corresponding Modifier from crashing after array exchange

### Step 3: Add an animation - cross-section to calculate screen coordinates

recommends that the icon in the list click and go to the end of the main grid. Animation requires the calculation of the screen coordinate margin "from the recommended list icon to the empty space at the end of the main grid" and the acquisition of `screenOffset` and `size` for components using `componentUtils.getRectangleById`, which is converted to VP by `px2vp` to drive `TranslateItemModifier.attribute.translate()`.

```ts
export enum AddStatus { IDLE, START, FINISH }

export class GridItemAddCtrl<T> {
  private modifier: TranslateItemModifier[] = [];
  private sortAppData: T[] = [];
  private status: AddStatus = AddStatus.IDLE;

  constructor(data: T[]) {
    this.sortAppData = data;
    data.forEach(() => { this.modifier.push(new TranslateItemModifier()); })
  }

  getModifier(item: T): TranslateItemModifier {
    const index: number = this.sortAppData.indexOf(item);
    if (index === -1) {
      return new TranslateItemModifier();
    }
    return this.modifier[index];
  }

  addGridItem(item: T, appInfoList: AppInfo[]): void {
    const index: number = this.sortAppData.indexOf(item);
    const appId: string = (item as AppInfo).name.toString();
    animateTo({
      curve: Curve.ExtremeDeceleration, duration: ADD_ANIMATION_DURATION, onFinish: () => {
        this.modifier[index].attribute?.visibility(Visibility.Hidden);
        this.modifier.forEach((item) => {
          item.attribute?.visibility(Visibility.Hidden).translate({ x: 0, y: 0 });
        })
        this.status = AddStatus.FINISH;
        AppStorage.setOrCreate('addStatus', this.status);
      }
    }, () => {
      let offsetX: number = 0;
      let offsetY: number = 0;
      this.modifier[index].attribute?.visibility(Visibility.Visible);
      const gridItemNumber: number = appInfoList.length;
      const homeAppIndex: number = gridItemNumber % COLUMN_COUNT;
      const componentInfo: componentUtils.ComponentInfo =
        componentUtils.getRectangleById(appId);
      offsetX = (homeAppIndex - index) * GRID_ITEM_SIZE;
      if (appInfoList.length === 0) {
        offsetY = FIRST_APP_SCREEN_OFFSET_Y - componentInfo.screenOffset.y;
        this.modifier[index].attribute?.translate({ x: offsetX, y: px2vp(offsetY) });
        this.status = AddStatus.START;
        return;
      }
      const lastAppComponentInfo: componentUtils.ComponentInfo =
        componentUtils.getRectangleById(`${appInfoList[appInfoList.length - 1].name.toString()}InHome`);
      if (homeAppIndex === 0) {
        offsetY = lastAppComponentInfo.screenOffset.y - componentInfo.screenOffset.y
          + lastAppComponentInfo.size.height;
      } else {
        offsetY = lastAppComponentInfo.screenOffset.y - componentInfo.screenOffset.y;
      }
      this.modifier[index].attribute?.translate({ x: offsetX, y: px2vp(offsetY) });
      this.status = AddStatus.START;
    })
  }
}
```

Key points:
- `AttributeUpdater.attribute` can call `.translate()` / `.visibility()` directly in `animateTo` return, complete the style set without waiting for ZXXKEEP4ZX to reschedule -- this is the key advantage of `AttributeUpdater` over `AttributeModifier`
- `componentUtils.getRectangleById(appId)` for the recommended list icon `screenOffset.y` (screen Y coordinates, in px); coordinates of the end item of the main grid are obtained through `getRectangleById('xxxInHome')`, the difference between which is the number of flight shifts
- `px2vp(offsetY)` converts the Px screen coordinates to VP units because the `translate` attribute accepts VP values
- `homeAppIndex = appInfoList.length % COLUMN_COUNT` calculates the index of empty places at the end of the main grid; `offsetX = (homeAppIndex - index) * GRID_ITEM_SIZE` calculates horizontal shifts
- When first added (`appInfoList.length === 0`) locates `FIRST_APP_SCREEN_OFFSET_Y` in the first column of the main grid using a fixed offset
- `Curve.ExtremeDeceleration` 1000ms have a slow-to-fast-to-drive effect in contrast to the deleted ZXXKEEP1Z200ms
- The `onFinish` medium of modifier to `Visibility.Hidden` and reset `translate`, recommend list items to be hidden after animated, main grid to add new items to normal rendering through data array `push`

### Step 4: Main Grid + Recommended List - Double Area Tie Modiifier

The main grid uses `Grid.editMode()` + ZXKEP1ZX for drag-and-drop sorting; the recommended list uses `Flex` + `TranslateItemModifier` for flight animation. The two areas are protected by sharing `isEdit` and `appInfoList` and by listening to `@StorageLink` ZXXXXKEEP9ZX/`addStatus`.

```ts
@Component
export struct GridExchangeComponent {
  @Provide isEdit: boolean = false;
  @Provide @Watch('monitoringData') appInfoList: AppInfo[] = APP_LIST_DATA;
  @Provide appNameList: Array<string> = [];
  @Provide GridItemDeletion: GridItemDeletionCtrl<AppInfo> =
    new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
  @Provide FirstGridItemAdd: GridItemAddCtrl<AppInfo> =
    new GridItemAddCtrl<AppInfo>(this.firstAppInfoList);
  @StorageLink('addStatus') addStatus: AddStatus = AddStatus.FINISH;
  @StorageLink('deletionStatus') deletionStatus: DeletionStatus = DeletionStatus.FINISH;
  private itemAreaWidth: number = 0;

  @Builder pixelMapBuilder() {
    IconWithNameView({ app: this.movedItem })
  }

  build() {
    Column() {
/ Main grid: delete + drag sort
      Column() {
        Grid() {
          ForEach(this.appInfoList, (item: AppInfo, index: number) => {
            GridItem() {
              IconWithNameView({ app: item })
            }
            .id(`${item.name.toString()}InHome`)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.itemAreaWidth = Number(newValue.width);
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.movedItem = this.appInfoList[index];
              }
            })
            .attributeModifier(this.GridItemDeletion.getModifier(item))
            .onClick(() => {
              if (!this.isEdit) { return; }
              if (this.deletionStatus === DeletionStatus.FINISH) {
                this.deletionStatus = DeletionStatus.IDLE;
                this.GridItemDeletion.deleteGridItem(item, this.itemAreaWidth);
                this.appNameList.splice(
                  this.appNameList.indexOf(JSON.stringify(item.name)), 1
                );
              }
            })
          }, (item: AppInfo) => JSON.stringify(item))
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .supportAnimation(true)
        .editMode(this.isEdit)
        .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
          return this.pixelMapBuilder();
        })
        .onItemDrop((event: ItemDragInfo, itemIndex: number,
          insertIndex: number, isSuccess: boolean) => {
          if (isSuccess && insertIndex < this.appInfoList.length) {
            this.changeIndex(itemIndex, insertIndex);
          }
        })
      }
      .id('gridContainer')

/ / Recommended List: Add Back In
      this.sortIconWithNameView({
        title: 'app.string.grid_exchange_first_title_message',
        appInfoList: this.firstAppInfoList,
        translateItemModifier: this.FirstGridItemAdd
      });
    }
  }

  @Builder sortIconWithNameView(data: SortIconWithNameView) {
    Column() {
      Text($r(data.title))
      Flex() {
        ForEach(data.appInfoList, (item: AppInfo) => {
          Stack() {
/ Hide to the Animation Layer
            this.translateIconWithNameView({
              app: item, homeAppNames: this.appNameList,
              translateItemModifier: data.translateItemModifier
            });
/ / Show a static layer (click to trigger flight)
            this.addedIconWithNameView({
              app: item, homeAppNames: this.appNameList
            });
          }
          .onClick(() => {
            if (!this.isEdit) { return; }
            if (this.appNameList.includes(JSON.stringify(item.name))) {
              promptAction.showToast({ message: $r('app.string.grid_exchange_repeat_app_message') });
              return;
            }
            if (this.addStatus === AddStatus.FINISH) {
              this.addStatus = AddStatus.IDLE;
              this.appNameList.push(JSON.stringify(item.name));
              data.translateItemModifier.addGridItem(item, this.appInfoList);
              setTimeout(() => { this.appInfoList.push(item); }, ADD_ANIMATION_DURATION);
            }
          })
        }, (item: AppInfo) => JSON.stringify(item))
      }
    }
  }

  @Builder translateIconWithNameView(data: TranslateItemWithNameViewMode) {
    Column() {
      this.appItemWithNameView({ app: data.app, homeAppNames: data.homeAppNames });
    }
    .attributeModifier(data.translateItemModifier.getModifier(data.app))
    .width($r('app.string.grid_exchange_grid_item_width'))
    .height($r('app.string.grid_exchange_grid_item_height'))
    .justifyContent(FlexAlign.Center)
  }

  changeIndex(itemIndex: number, insertIndex: number): void {
    this.appInfoList.splice(insertIndex, 0, this.appInfoList.splice(itemIndex, 1)[0]);
  }

  monitoringData(): void {
    this.GridItemDeletion = new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
  }
}

@Component
struct IconWithNameView {
  private app: AppInfo = new AppInfo();
  @Consume isEdit: boolean;

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(this.app.icon)
          .width($r('app.string.grid_exchange_icon_size'))
          .height($r('app.string.grid_exchange_icon_size'))
          .draggable(false)
        if (this.isEdit) {
          Image($r('app.media.ic_public_remove_filled'))
            .width($r('app.string.grid_exchange_remove_icon_size'))
            .height($r('app.string.grid_exchange_remove_icon_size'))
            .markAnchor({ x: '-40%', y: '40%' })
            .draggable(false)
        }
      }
      Text(this.app.name)
        .width($r('app.string.grid_exchange_app_name_width'))
        .fontSize($r('app.string.grid_exchange_app_name_font_size'))
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width($r('app.string.grid_exchange_grid_item_width'))
    .height($r('app.string.grid_exchange_grid_item_height'))
  }
}
```

Key points:
- **Grid**:
- `editMode(this.isEdit)` supports long drag; `supportAnimation(true)` allows non-trawl to generate bitmap drawings when drag sorting
- ZXKEEP0Z${item.name}Inhome`)` sets the only id for each grid item to get screen coordinates
- `onAreaChange` Get `itemAreaWidth` to calculate the neighbourhood distance when deleted
- `onTouch` Log ZXXKEEP1ZX for ZXXKEEP2ZX to build drag-and-drop float icon
- `deletionStatus === FINISH` as a protection lock: new deletion is allowed only after the last animation has been deleted
- `onItemDragStart` returns `@Builder` as a towed floss; splice exchange position in ZXXKEEP2ZX has been sorted
- Delete buttons render `@Consume isEdit` conditions and automatically appear/hidden when editing mode switching

-** Recommended List (Flex + Stack Layer)**:
- Collapse two sub-components in `Stack`: Bottom `translateIconWithNameView` (flying into animate layer, binding `TranslateItemModifier`)+ Upper `addedIconWithNameView` (static display layer)
- Check `appNameList` for re-entry and then check `addStatus === FINISH` for weight Enter
- `addGridItem` triggers animation, `setTimeout(ADD_ANIMATION_DURATION)` takes item push to `appInfoList` - Animation flies into visual position, data delayed grouping to ensure the correct timing of the main grid rendering
- `@Watch('monitoringData')` listens to `appInfoList` changes, recreate ZXXKEEP2ZX when data changes

Step 5: Edit Mode State Management - @Provide/ @Consume +StorageLink + Weight Enter

Edit mode involves state synchronization between multiple components: `isEdit` Control Delete buttons/Add buttons show, `deletionStatus`/`addStatus` Controls Delete/Add animate re-entry, ZXXKEEP3ZX Changes trigger Modifier reconstruction.

```ts
/ Status hierarchy:
@Provide isEdit: boolean = False; / / Cross Component Sharing: Control Edit Mode UI
@Provide@watch('monitoringData')appInfoList; / / Cross Component Sharing + Data Change Reconstruction Modifier
@StorageLink ('deletionstatus')
@StorageLink('addStatus')addStatus; / / global share: add weight-proof lock

/ Edit Mode Switch:
.onClick(() => {
  this.isEdit = !this.isEdit;
This.orginAppInfoList = [...this.appInfoList]; ///Saving raw data to cancel
  this.originalAppNameList = [...this.appNameList];
})

/ Unedited: Blast window confirmation / Revert data / Rebuild Modifeier
promptAction.showDialog({ /* ... */ })
  .then(data => {
If (data. index = 0) {/ / Cancel
      this.appInfoList = [...this.originAppInfoList];
      this.appNameList = [...this.originalAppNameList];
      this.GridItemDeletion = new GridItemDeletionCtrl(this.appInfoList);
      this.isEdit = false;
      this.isChange = false;
}else {// Save
      this.isEdit = false;
      this.isChange = false;
    }
  })

/ MonitoringData: Data Change Rebuild Modifeier Map
monitoringData(): void {
  this.isChange = true;
  this.GridItemDeletion = new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
}
```

Key points:
- ** Level III mechanism**:
- `@Provide/@Consume`: Share ZXXKEEP1ZX/`appInfoList`, sub-component `IconWithNameView` displayed through `@Consume isEdit` Control Delete button
- `@StorageLink`: Sharing of ZXKEEP1Z/`addStatus`, `GridItemDeletionCtrl` Updates state in `onFinish` through `AppStorage.setOrCreate`, main component through `@StorageLink` listening changes Enter
- `@Watch`: Listen to `appInfoList` Change Autorebuild ZXXKEEP2ZX, maintain data/Modifire1:1 map
- ** Responsive lock**: `deletionStatus === FINISH` / `addStatus === FINISH` as pre-check to state ZXXKEEP2ZX before an animation is allowed to be performed to prevent rapid and continuous hits leading to animated superheavy
- ** Unrecovered**: Save `originAppInfoList`/`originalAppNameList` when entering editing mode, when cancelled, and restore ZXXKEEP2ZX
- Whether `this.isChange` tag data have been modified, exit edit mode if not modified, popup confirmation dialogue box if modified


# Basic extension scene

# SCENE-01 Component Plant Dynamic Distribution scene

**Applied scene: **The same container needs to render a variety of UI variants based on `type` fields in the data (typically pure text / single / three / video four items, system notification / user message / red package / file in the message list, etc.) and does not need to modify the caller code if you want to add a new type. By sinking the image of the "type rendering logic" to a centrally registered plant, the caller is only responsible for taking out the constructor and executing it by type, with the addition of a line to the plant register.

** Core mechanism: ** `@Builder` of ArkUI is a function statement and cannot be stored or passed as a single equivalent; `wrapBuilder` packages the global `@Builder` as a storeable value of the `WrappedBuilder<[P]>` type, so that it can be placed in `Map`, passed as a parameter, and called on its `.builder(param)` trigger rendering at the time of running. This is the bottom of the plant model that can land in ArkUI.

** Selected decision tree:**

1. ** Will the number of variants continue to grow? ** Yes (operationally clearly add new types)
2. **Typologies are fixed and rarely change? ** Yes (e. g. fixed 2-3 and non-extension) `if/else` is sufficient and no plant is required
3. ** Is there a need to determine the rendering logic according to the dynamics of the running time data? ** Yes (e. g. service bottom type field) natural match of plant registration capacity

# # Apply scene: multiple types of news stream item list

To achieve a newslist containing 4 item variants, building the factory step by step as follows.

Step 1: Define a data model with type identification fields

The data model must contain an item of `type` field as a key to the factory search, while the remaining fields are based on the variable shared basic information and optional fields (e.g. video time `duration` is used only for video type):

```typescript
Source: entry/src/main/ets/model/NewsModel.ets

export enum NewsItemType {
  TEXT = 'text',
  SINGLE_IMAGE = 'singleImage',
  MULTI_IMAGE = 'multiImage',
  VIDEO = 'video'
}

export interface NewsItem {
  id: string;
type: NewsItemType; // factory search key
  title: string;
  source: string;
  time: string;
  images: ResourceStr[];
  commentCount: number;
Use only video type
}
```

Step 2: Prepare a global picture for each variant

`wrapBuilder` can only be packaged for the "global `@Builder` function" and cannot be used as an arrow function or as a class member method, so each variant is declared as top level `function` by norm. The function signature is unified to `(item: NewsItem) => void`, which allows the plant to store:

```typescript
@Builder
function NewsTextItemView(item: NewsItem) {
  // ...
}

@Builder
function NewsSingleImageView(item: NewsItem) {
  // ...
}

/ Three-chart view, video view, bottom view, similar structure, slightly

/ / WrapBuilder packaged as a 'one equivalent 'to be stored by the plant/ passed
export const newsTextBuilder: WrappedBuilder<[NewsItem]> = wrapBuilder(NewsTextItemView);
export const newsSingleImageBuilder: WrappedBuilder<[NewsItem]> = wrapBuilder(NewsSingleImageView);
export const newsMultiImageBuilder: WrappedBuilder<[NewsItem]> = wrapBuilder(NewsMultiImageView);
export const newsVideoBuilder: WrappedBuilder<[NewsItem]> = wrapBuilder(NewsVideoView);
export const newsDefaultBuilder: WrappedBuilder<[NewsItem]> = wrapBuilder(NewsUnknownView);
```

### # Step 3: Achieve a CommonFactory Category

The plant is based on a general type, decoupling with specific operations (news) - any `type → @Builder` scene can be reused. Core API: `register` chain registration, `setDefault` set the bottom, ZXXKEEP3ZX press key Query (failed fallback):

```typescript
export class ComponentFactory<K, P extends Object> {
  private readonly builders: Map<K, WrappedBuilder<[P]>> = new Map<K, WrappedBuilder<[P]>>();
  private fallback: WrappedBuilder<[P]> | undefined = undefined;
  private readonly namespace: string;

  constructor(namespace: string = 'default') {
    this.namespace = namespace;
  }

/ ** Register a constructor to return this support chain call*/
  register(key: K, builder: WrappedBuilder<[P]>): ComponentFactory<K, P> {
    if (this.builders.has(key)) {
      console.warn(`duplicate key "${String(key)}" will be overwritten`);
    }
    this.builders.set(key, builder);
    return this;
  }

/ ** Sets the bottom constructioner, returns when missed get (key) avoids rendering blanks */
  setDefault(builder: WrappedBuilder<[P]>): ComponentFactory<K, P> {
    this.fallback = builder;
    return this;
  }

/ ** Find by key; unfailing returns fallback (possibly undefined)*/
  get(key: K): WrappedBuilder<[P]> | undefined {
    const builder = this.builders.get(key);
    if (builder) {
      return builder;
    }
    return this.fallback;
  }

  has(key: K): boolean { return this.builders.has(key); }
  unregister(key: K): boolean { return this.builders.delete(key); }
  clear(): void { this.builders.clear(); this.fallback = undefined; }
  size(): number { return this.builders.size; }
}
```

#### Step 4: Construction of a single business plant and centralized registration of a variant

The business layer needs only an example of a single plant, a chain call for the registration of all variants, and a vertebrae (a downgrade display when the undefeated registration form is used to avoid a blank item). The time to register is selected when the module is loaded (top level statement) to ensure that the registration form is ready before the page built:

```typescript
import { ComponentFactory } from '../../factory/ComponentFactory';
import { NewsItem, NewsItemType } from '../../model/NewsModel';
import {
  newsDefaultBuilder,
  newsMultiImageBuilder,
  newsSingleImageBuilder,
  newsTextBuilder,
  newsVideoBuilder
} from './NewsItemBuilders';

/ ** Single case of newslist component factory*/
export const newsComponentFactory: ComponentFactory<NewsItemType, NewsItem> = new ComponentFactory<
  NewsItemType,
  NewsItem
>('News');

/ / When the module is loaded, centralize the registration: add only one new line here for the new type
newsComponentFactory
  .register(NewsItemType.TEXT, newsTextBuilder)
  .register(NewsItemType.SINGLE_IMAGE, newsSingleImageBuilder)
  .register(NewsItemType.MULTI_IMAGE, newsMultiImageBuilder)
  .register(NewsItemType.VIDEO, newsVideoBuilder)
  .setDefault(newsDefaultBuilder);
```

### # Step 5: Press type in caller component to remove and execute

The caller component is no longer distributed in `switch`, but removes `WrappedBuilder` from the plant and calls its ZXXKEEP2ZX to trigger the rendering. Key engineering elements:

- **separate `@Component` carrier distribution**: `WrappedBuilder.builder()` has to be called in the context of component `build()` to remove a single ZXXKEEP3ZX so that data changes can accurately trigger the build recalculation and distribution to the right variant
- **build() if in **: ArkTS requires that a single root node of the build() must be a packaging component, so `if (wrapped)` must be wrapped in a container such as `Column()`; `wrapped` may be requested in advance as a class member

```typescript
@Entry
@ComponentV2
struct NewsListPage {
  private newsList: NewsItem[] = mockNews();

  build() {
    Column() {
Text.
        .fontSize(18).fontWeight(FontWeight.Bold).width('100%').padding(16)

      List({ space: 8 }) {
        ForEach(this.newsList, (item: NewsItem) => {
          ListItem() {
            // ...
            newsComponentFactory.get(item.type)?.builder(item)
            // ...
          }
        }, (item: NewsItem) => item.id)
      }
      .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
    }
    .width('100%').height('100%')
  }
}
```

### # Step 6 (important): Let the plant build UI with the data # # dynamically refresh # # must be passed by reference

The `builder(item)` of Step 5 completes the "type distribution" but `WrappedBuilder.builder(param)` follows the parameter transfer rules for ArkUI `@Builder` - ** Default value transfer**. When the data properties are subsequently changed (e.g. `commentCount` auto-increase, `duration` update), the UI in @Builder will not be refreshed **. In order for the UI built by the component plant to be updated with the data dynamic, it must be changed to ** to pass by reference**.

**ArkUI `@Builder` Parameter Transmission Rules (official):**

@ Transfer mode | Trigger condition | Status variable/ property level changes refresh @Builder UI |
| --- | --- | --- |
** ** Value Transfer (Default)** ** Pass "The Whole Object Variable" such as `builder(this.item)` | ❌ Do not refresh (only the whole object** is renewed**)  **
** Passed by reference** | Passed only** one parameter** and this parameter is directly** object volume** | Refreshed |
♪ Passing back ♪

** Corrected**: data in ** Literary ** * To `.builder(...)`, a list of fields that need to be observed - each field becomes an "observation point" for continuous observation of the framework, and a change in the attribute class can accurately trigger a UI upgrade of the plant's construction. Note that the host component needs to have data with a state decorator (V1 `@State` / V2 `@Param`) to drive the bild recosting and re-distribution:

```typescript
/ NewsReuseableItem.ets (V1 Host Component)
@Reusable
@Component
export struct NewsReusableItem {
  @State item: NewsItem = createEmptyNewsItem();

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as NewsItem;
  }

  build() {
    Column() {
/ / ✅ Transfer by Reference: Unique Parameter + Object Volume, field by field list of fields that need to respond to changes
      newsComponentFactory.get(this.item.type)?.builder({
        id: this.item.id,
type: this.item. type, // plant search key
        title: this.item.title,
        source: this.item.source,
        time: this.item.time,
        images: this.item.images,
        commentCount: this.item.commentCount,
        duration: this.item.duration
      })
    }
  }
}
```

** Three easy-to-loop pits**:

**: The whole object is passed in value, and `this.item.commentCount`, a policy change of this type, does not reflect the plan UI.
** The transmission by reference takes effect only for "single parameter + object volume"**: if @Builder has multiple parameters (e.g. `builder(a, b)`), even if one of them is the object volume does not support refreshing by reference -- At this point, all fields are received in a single object volume, with only one parameter.
3. ** Do not mix values with references**: The cross-references to " Object Variables " and " Object Font Volume " in the same @Builder call directly result in dynamic rendering invalid. A single object word field can be used.

---

# SCENE-02 Custom layout container scene

**Applied scene: **In the system, packagings (Row/Column/Grid/WaterFlow, etc.) do not meet layout rules, typically, such as " double-column, albeit high, waterfall flows + cards can cross rows over columns + drag-squeezing reordering" and "Manual layout in accordance with operational rules" "As part of the measurement phase, reverses the size of the sub-components and returns to the height of the parent". At this time, a complete layout is to be completed in two phases, by measuring and measuring the sub-components of `onMeasureSize`, by `onPlaceChildren`, and by placing the sub-components of `onPlaceChildren`. `@ComponentV2`.

** Core mechanism:**

- ** `@BuilderParam` + Placed ZXXKEEP1ZX is the basis of the custom packaging**: the sub-tree that the packaging component receives from the caller `@BuilderParam builder`, itself `build()` only calls `this.builder()` and hangs the sub-tree in `this.builder()` — the packaging itself does not care about what the sub-component is, but is responsible for measuring and locating them in two circuits.
- **V2 Undirected Data Flow: Retrieval with `@Param` Received Size, `@Event` Reverse**: Unlike V1 Directly Write Global Storage with `@StorageLink`, V2 Medium Father Component by `@Param deviceCardHeight`
- ** The measurement phase (`onMeasureSize`) is of only size, not location**: the measurement of each subcomponent was triggered by `child.measure({})` and the results were deposited in `child.measureResult`; the return value of the recall determined the size of the container itself
- ** Place Phase (`onPlaceChildren`) Read ZXKEEP1Z **: Measurement results are readable at this stage in `child.measureResult.width / height`, calculate ZXXKEEP3ZX for each subcomponent with a custom algorithm and then adjust `child.layout({ x, y })` to position
-** Algorithms and Frame decomposition**: extract "location calculation" into a pure algorithm class (e.g. `RowPlanner`), "appliance position" into a fill class (e.g. `ColumnFiller`), custom layout backshows only for both, to facilitate single measurement and replacement

** Selected decision tree:**

1. ** Can it be solved in a system container? ** Yes
2. ** Is it necessary to calculate location based on the actual measurements of sub-components? ** Yes (e.g. short edge by column, line width by stream) `onMeasureSize` +`onPlaceChildren`
** Will the layout rules evolve with business? ** Yes (e.g. new card size, new addition) Line
4. ** Total share across pages? ** No `@Param + @Event` One-way Synchronization is sufficient; yes `@Local` is replaced by ZXXKEEP2ZX, where `Holder` is the class (ZXXKEEP5ZX for V2 only supports the class type and does not support the base type immediate)

# Apply scene: double falls drag card walls

A 1x2 / 2x2 mixed double-line card wall is achieved, and the card can be rearranged by drag and drag. Layout core: Each time a new card is inserted, the current shorter column is selected to be added, and the total height of the container follows the dynamics of the longest column.

! [Custrated Double Falls Flow] (.. . ./ ./assets/ Custom-layout.png)

Step 1: Define position Builder and container skeleton (V2)

V2 Critical differences between self-defined packagings and V1: replace `@Component` with `@ComponentV2`; the total external height is received through `@Param` (read-only) and reverse writing through `@Event` notification - instead of `@StorageLink` writing for global storage. The container still requires `result: SizeResult` members to store their own measurements for frame reading:

```typescript
@ComponentV2
struct CustomLayout {
/ V2: Current total height to receive parent component from @Param (read-only, subcomponent cannot be modified directly)
  @Param deviceCardHeight: number = 1;
/ V2: Inform parent after measuring new values using @Event 's total high change echo
  @Event onHeightChange: (height: number) => void = (height: number) => {};

  @LocalBuilder
  doNothingBuilder() {
  };

  @BuilderParam builder: () => void = this.doNothingBuilder;
  result: SizeResult = {
    width: 0,
    height: 0
  };

See next steps

  build() {
    this.builder()
  }
}
```

Step 2: onMeasureSize - Trigger sub-component measurements and output container sizes

The measurement phase must call each sub-component of `Measurable` on `measure({})`, otherwise the subsequent `measureResult` is empty and the placement phase is zero. The return value determines the packaging's own size - the width of the container in this case equals the width of the screen by the left and right margin, at a height driven by `@Param` injected by `deviceCardHeight`:

```typescript
onMeasureSize(selfLayoutInfo: GeometryInfo, children: Array<Measurable>, constraint: ConstraintSizeOptions) {
  children.forEach((child: Measurable) => {
// Must call measure trigger subcomponent measurements, otherwise measureresult is empty
    child.measure({})
  })
/ / The width of the card container component
  this.result.width = this.getDeviceCardViewWidth() - CardInfo.CARD_MARGIN_SCREEN * 2;
This.sult. head = this.deviceCardHeight; / / Read @Param Injection
  return this.result;
}
```

> **Keypoint: ** `child.measure({})` with reference to `ConstraintSizeOptions`, faxing `{}` to indicate that the subcomponent is freely measured by its own declared width (e.g. `width(this.midCardWidth)`); if the parent container is required to contain the subcomponent (e.g. to limit the maximum width) ZXXKEEP4ZX.

Step 3: An abstract layout algorithm - RowPlanner

Removes the column selection + coordinates from the dropback to a pure algorithm class, enters a number of measurements of the size of the subcomponent, and the output is the drop coordinate of each subcomponent. This example uses the greedy strategy of "two-column height array `colHeights`, choosing each of the current shorter columns". Algorithms decoupling with components, V1/V2 fully consistent:

```typescript
interface CardMetrics {
  width: number
  height: number
}

interface PlannableCard extends CardMetrics {
  child: Layoutable
}

interface Placement {
  child: Layoutable
  column: number
  x: number
  y: number
}

class RowPlanner {
  private colHeights: number[] = [0, 0]
  private colX: number[]
  private gap: number

  constructor(screenMargin: number, gap: number, cardMaxWidth: number) {
    this.gap = gap
/ x-column x-coordinate: Left column to left, right to middle of screen
    this.colX = [screenMargin, screenMargin + cardMaxWidth / 2 + gap / 2]
  }

  plan(cards: PlannableCard[]): Placement[] {
    const placements: Placement[] = []
    cards.forEach(card => {
/ / Greed: Select a column with a smaller overall current height to keep the two columns as balanced as possible
      const column = this.colHeights[0] <= this.colHeights[1] ? 0 : 1
      const y = this.colHeights[column]
      placements.push({ child: card.child, column, x: this.colX[column], y })
      this.colHeights[column] = y + card.height + this.gap
    })
    return placements
  }

  totalHeight(): number {
// Total container height = Long column height - end
    return Math.max(this.colHeights[0], this.colHeights[1]) - this.gap
  }
}
```

Step 4: OnPlaceCildren - Read measurements, algorithms, application position, event return Pass

The placement phase is a bridge to measure and render: the size of the `measure({})` output from `child.measureResult` is read out from `child.measureResult` 2. Finally, by `@Event onHeightChange`, the new general height is passed back to the key to the one-way data stream of the parent component, V2: the subcomponent does not write the global state directly, but the event allows the parent component to decide how to update:

```typescript
onPlaceChildren(selfLayoutInfo: GeometryInfo, children: Array<Layoutable>, constraint: ConstraintSizeOptions) {
  const maxWidth = Number.parseFloat(constraint.maxWidth?.toString() ?? '0')
  const cardMaxWidth = maxWidth - CardInfo.CARD_MARGIN_SCREEN * 2
  const planner = new RowPlanner(
    CardInfo.CARD_MARGIN_SCREEN,
    CardInfo.CARD_MARGIN,
    cardMaxWidth
  )
// 1. Collect the actual size of each subcomponent from measureResult
  const cards: PlannableCard[] = []
  children.forEach(child => {
    cards.push({
      child: child,
      width: child.measureResult.width,
      height: child.measureResult.height
    })
  })
// 2. Hand over algorithms to calculate the location of each subcomponent
  const placements = planner.plan(cards)
/ 3. Apply position: click child. playout to write x/y
  new ColumnFiller().apply(placements)
/ / 4.V2: Read new values in next frame onMeasureSize updated by @Event Resume New High by Parent
  this.onHeightChange(planner.totalHeight())
}

class ColumnFiller {
  apply(placements: Placement[]): void {
    placements.forEach(p => {
      p.child.layout({ x: p.x, y: p.y })
    })
  }
}
```

Step 5: Call the square component by @BuilderParam injection subtree (V2)

The caller is `@ComponentV2`, the list data is stated as `@Local`, and the height is written back as a local state sub-component. `deviceCardHeight` (Down-Down Data) and `onHeightChange` in the initialization parameters of `CustomLayout`. V2 is bound in both directions by this visible "Apargon + Event" pair to replace V1. All you have to do is to change the order of `deviceLists` arrays (`splice` material), and CustomLayout will automatically trigger `onMeasureSize`+`onPlaceChildren` reset:

```typescript
@Entry
@ComponentV2
struct DragGrid {
/ V2: Internal status used
  @Local deviceLists: DeviceCardItemEntity[] = []
/ V2: General height as local state, updated by @Event sub-components, driving the outer layer Column height
  @Local deviceCardHeight: number = 1;
// Card size constant (no change after initialization, use a regular member, not @Local)
  smallCardWidth: number = 0;
  smallCardHeight: number = 0;
  midCardWidth: number = 0;
  midCardHeight: number = 0;

  build() {
    Column() {
      Column() {
        CustomLayout({
/ Down: pass the current total high to the sub-component (corresponding to @Param deviceCardHeight)
          deviceCardHeight: this.deviceCardHeight,
/ Up: sub-components measure a new, high, back-to-back and update local status (corresponding to @Event on HighChange)
          onHeightChange: (height: number) => {
            this.deviceCardHeight = height;
          }
        }) {
          ForEach(this.deviceLists, (item: DeviceCardItemEntity, index: number) => {
            if (item) {
              Column() {
                DeviceCommonComponent({ itemEntity: item, deviceLists: this.deviceLists, index: index })
              }
/ / The dimensions of the subcomponent itself will be read to measureResult
              .height(item.cardSize === CardSize.SMALL_CARD ? this.smallCardHeight : this.midCardHeight)
              .width(item.cardSize === CardSize.SMALL_CARD ? this.smallCardWidth : this.midCardWidth)
            }
          }, (item: DeviceCardItemEntity) => `${item.id}-${item.cardSize}`)
        }
      }
      .width('100%')
.head(this.deviceCardHeight) // Follow @Localup, triggers the outer column height
    }
    .height('100%').width('100%')
  }
}
```

---

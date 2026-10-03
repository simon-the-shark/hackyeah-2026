# Share animated cases of elements

# Apply scene

* Reissued for technical reasons.
|---|---|---|
| Thumbnail `geometryTransition(id)` + `animateTo` | Automatic Plugin Positions and Dimensions of the System, Shortest Scheme
`geometryTransition` +`TransitionEffect.OPACITY` | Cover Sharing Elemental Transition + Detailed Page Dilution Overall
| Open fullscreen |XKEEP0ZX + `bindContentCover(NONE)` | Non-Image components with follow; disable system simulator animation to avoid interference |
| `NodeController` + `position/translate/height`|
`Navigation.customNavContentTransition` ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ ZZZZZZ ZZZZ ZZZ ZZ Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z   Z Z  Z  Z   Z Z Z Z Z Z  Z  Z    Z  Z    Z           Z                            

# Core Animation API Enumeration Reference

No, no, no, no.

| Parameter | Type | Description |
|---|---|---|
`id` | string | sharing element ID pair, two components of the same ID will create a transition relationship
Z `{ follow: true }` | object | component follows the shared element movement (for transition between non-Image components) |

# HometryTransion ID policy

| Strategy | Description | Applicable scene |
|---|---|---|
| Thumbnail condition empty  Z `ID = ''` (hidden) when hit, otherwise keep ID | pictures browsing, card turns |
| Detailed pages always hold | without conditions to keep id | all shared element scenes
| Dynamic setting ID | Unique grant on/off `geometryId` | One-scenes search

# # ModalTransion ModalTransion

| | |
|---|---|---|
`ModalTransition.DEFAULT` | Default rotation of the system
`ModalTransition.NONE`| Disable system animation | Share element one shot to the end  Z
`ModalTransition.ALPHA` | Transparency Fade Out

## curves module spring curve function (commonly shared elements)

| Function | Parameter | Description | Typical scene |
|---|---|---|---|
Z `curves.springMotion()` | `(response?, dampingFraction?)` | spring motion curve | image browsing up/down, card turns field |
`curves.interpolatingSpring()` |`(velocity, mass, stiffness, damping)` | Plug-in spring curve | one shot to search for and/or close the news cover

# TransportEffect Method (commonly used sharing elements)

| Methodology | Description
|---|---|---|
`TransitionEffect.OPACITY` | Transparency Reverse | Details page as a whole
`TransitionEffect.asymmetric(enter, exit)` | Asymmetrical turn-off | Return button enters delay, exits no delay |
`.animation(params)` | Additional animation parameters | Fades 200ms |

---

# Scene 1: Friends Picture Browse

**Scene description: **Scope image browsing, zooming in to full-screen large-scale preview after clicking on a small picture in a nine-gauge, re-diggling the thumbnail position.

** Solution:** Use **`geometryTransition` shared element transition** + **`animateTo` drive transition** + ** `curves.springMotion` elastic curve**

> ** Full Source:** `AnimationCases/entry/src/main/ets/pages/sharedanimation/ImageBrowsePage.ets`

Step 0: Data model and state variable

```ts
/ / Data Model (field omitted constructor)
class MomentPost { id: string; userName: string; avatarSrc: Resource; text: string; time: string; images: Resource[] }

@Entry
@Component
struct ImageBrowsePage {
@state showViewer: boolean = false/ / Viewer display
@StateViewerPostIndex: number = -1// Index of posts currently viewed
@StateViewerImageIndex: number = -1 / Index of pictures currently viewed

Private posts: MomentPost[] = [ / *] post data*/]
}
```

> ** Photo resources:** Non-square grid images such as JPG/PNG must be used (not SVG). Thumbnails are tailored to squares with `objectFit(Cover)` + `aspectRatio(1)`, and Viewer with `objectFit(Contain)` shows in full that `geometryTransition` inserts a value between the two - only when Cover and Contain differ when the picture itself is wide and high. `transitionanimation_image1~6.jpg`.

Step 1: Nine-Cyber Thumbnail -GometryTransion condition empty

Thumbnail used ** Condition ID**: When Viewer opens and hits the current picture, ID is empty (hiding the thumbnail), otherwise `moment_{postIndex}_{imgIndex}` is maintained. This allows a pair of pictures in Viewer to zoom from thumbnail position to full screen.

```ts
@Builder
momentItem(post: MomentPost, postIndex: number) {
  Row() {
/ Image
    Column() {
      Image(post.avatarSrc)
        .width(44)
        .height(44)
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
    }
    .margin({ top: 14 })

    Column() {
/ Username
      Text(post.userName)
        .fontSize(16)
        .fontColor('#576b95')
        .fontWeight(FontWeight.Medium)

/ text
      Text(post.text)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .margin({ top: 6 })

      GridRow({ columns: 3, gutter: { x: this.GRID_GAP, y: this.GRID_GAP } }) {
        ForEach(post.images, (img: Resource, imgIndex: number) => {
          GridCol() {
            Image(img)
              .width('100%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(2)
              .geometryTransition(this.showViewer &&
                this.viewerPostIndex === postIndex && this.viewerImageIndex === imgIndex ?
                '' : `moment_${postIndex}_${imgIndex}`)
              .onClick(() => { this.openViewer(postIndex, imgIndex) })
          }
        }, (img: Resource, imgIndex: number) => `${postIndex}_${imgIndex}`)
      }
      .width(this.GRID_WIDTH).margin({ top: 8 })

// Time, praise, forward
      Row() {
        Text(post.time)
          .fontSize(12)
          .fontColor('#999999')

        Blank()

        Row() {
          Text('♡')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ right: 16 })
          Text('⤴')
            .fontSize(16)
            .fontColor('#999999')
        }
      }
      .width('100%')
      .margin({ top: 8, bottom: 14 })
    }
    .layoutWeight(1)
    .margin({ left: 12 })
    .alignItems(HorizontalAlign.Start)
  }
  .width('100%')
  .alignItems(VerticalAlign.Top)
  .padding({ left: 16, right: 16 })
}
```

> ** Key points:**
> -ID must contain `postIndex` and `imgIndex` in two dimensions, ensuring cross-post image ID is the only one in the world.
> - ** do not add `{ follow: true }`**: Thumbnails and Viewer are all Image components, do not follow, and instead change transition behaviour.

## # Step 2: Fullscreen big picture preview - always keep ID

Viewer picture** always holds the corresponding ** ID without any conditions:

```ts
@Builder
imageViewer() {
  Image(this.posts[this.viewerPostIndex].images[this.viewerImageIndex])
    .width('100%')
    .height('100%')
    .objectFit(ImageFit.Contain)
    .backgroundColor('#0a0a0a')
    .id('viewer_image')
.geometryTransion (`moment_${this.viewerPostIndex}_${this.viewerImageIndex}`)// Always hold ID
    .onClick(() => {
      this.closeViewer()
    })
}
```

> ** Key points:**
> -Viewer Photo `geometryTransition` Use `moment_${this.viewerPostIndex}_${this.viewerImageIndex}`,** without any conditions* *- If the ID becomes empty when off, it will not be possible to match the thumbnails and lose the animation that narrows back to its place of origin.
> - Viewer must be a single-naked `Image`,** not Swiper package** (multiple Image with different IDs for confusion)**,** not add additional `@State`/ZXKEEP2Z** (disturbing time series for entry/exit matching).

Step 3: Open/ turn on Viewer — animateTo driver

```ts
private openViewer(postIndex: number, imgIndex: number) {
  this.viewerPostIndex = postIndex
  this.viewerImageIndex = imgIndex
  this.getUIContext()?.animateTo({ duration: 350, curve: curves.springMotion(0.6, 0.8) }, () => {
    this.showViewer = true
  })
}

private closeViewer() {
  this.getUIContext()?.animateTo({ duration: 350, curve: curves.springMotion(0.6, 0.8) }, () => {
    this.showViewer = false
  })
}
```

> ** Keypoint: ** Open and close with the same `curves.springMotion(0.6, 0.8)` elastic curve to ensure a positive/reverse animation style.

Step 4: Layout Structure - Stack

```ts
build() {
  Stack() {
    Column() {
/ / Navigation Bar
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#333333')
          .margin({ right: 8 })
Text.
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding({ left: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

List of posts
      List({ space: 0 }) {
        ForEach(this.posts, (post: MomentPost, postIndex: number) => {
          ListItem() {
            this.momentItem(post, postIndex)
          }
        }, (post: MomentPost) => post.id)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: '#eeeeee', startMargin: 76, endMargin: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)

/ Top level: Fullscreen Viewer
    if (this.showViewer && this.viewerPostIndex >= 0 && this.viewerImageIndex >= 0) {
      this.imageViewer()
    }
  }
  .width('100%')
  .height('100%')
}
```

# gometryTranstion ID Summary of the twinning rule

| Timing | Thumbnail ID | Viewer Picture ID | Effect
|---|---|---|---|
|Viewer off (initial)  Z`moment_X_Y` | does not exist | thumbnail normal display |
| Viewer Open  Z Match Item `''` (hidden), the rest of | `moment_X_Y` (always) | Match picture zoom from thumbnail position to fullscreen |
|Viewer closes | Match Recovers `moment_X_Y` | `moment_X_Y` (always held) | Picture shrinks back thumbnail position from fullscreen

---

# Scene 2: Turn the card to the bottom

**Scene description:** Equivalent Falls Flow, zoom in on the cover of the card after clicking on the waterfall flow card, to the full screen details page, and then back to the original card cover position.

** Solution:** Fade out using **`WaterFlow` Falls** + **`geometryTransition('cardImg_${index}')` Shared Element Transition** + ** **`curves.springMotion(0.6, 0.9)` flex curve** ** ** ** `TransitionEffect.OPACITY` Details Page** + ** `clip(true)` Cropping**

> ** Core principle: ** Card cover pegged to detailed page cover by the same `geometryTransition` ID. A thumbnail ID is empty when clicking on the card, and the cover of the detailed page takes over the shared elements, making the transition from the card position to a seamless zoom in on the full screen.

Step 0: Data model and state variable

```ts
import { curves } from '@kit.ArkUI'

/ Data model (id, Title, cont, userName, imageSrc, aviatorSrc, constructor omitted)
class CardItemData { /* ... */ }

@Entry
@Component
struct CardTransitionPage {
@state isDetailShow: boolean = false// Whether the details page is shown
@state selectedIndex: number = 0// Selected card index

Private datasource: CardItemData[ ] =[ /*card data*/]
}
```

Step 1: Waterfall Flow Cover -geometryTransion Condition ID

The card cover is ** condition ID**: id is empty when the card is selected and the details page is displayed, otherwise `cardImg_${index}` is maintained.

```ts
WaterFlow() {
  ForEach(this.dataSource, (item: CardItemData, index: number) => {
    FlowItem() {
      Column() {
        Image(item.imageSrc)
          .width('100%').objectFit(ImageFit.Cover)
          .geometryTransition(
            this.isDetailShow && this.selectedIndex === index ? '' : `cardImg_${index}`)
          .onClick(() => {
If (this.isDetailShow) return / / protection against repeated clicks
            this.selectedIndex = index
            this.getUIContext().animateTo({
              duration: 400, curve: curves.springMotion(0.6, 0.9)
            }, () => { this.isDetailShow = true })
          })

/... Title, Author Information (normal UI, omitted)
      }.backgroundColor(Color.White).borderRadius(8)
    }.width('100%')
  })
}
.columnsTemplate('1fr 1fr').columnsGap(8).rowsGap(8)
```

> ** Key points:**
> - `geometryTransition` on card cover
> - `if (this.isDetailShow) return` to prevent re-clicking to trigger animation anomalies when the details page is shown
> -`id('card_image_${index}')` for debugging position (not necessary)

### Step 2: Details Page Cover - Always hold ID

Detailed page cover sheet** always held** `cardImg_${this.selectedIndex}`, without conditions:

```ts
if (this.isDetailShow) {
  Scroll() {
    Column() {
/ / Navigator Bar (Return button on Click →animateTo SpringMotion → is DatailShow=face)
      // ...

/ Cover Map - Always Hold ID
      Image(this.dataSource[this.selectedIndex].imageSrc)
        .width('100%').objectFit(ImageFit.Cover)
.geometryTransion (`cardImg_${this.selectedIndex}`)// Always hold ID
        .clip(true)

/... Title, body text, author information (normal UI, omitted)
    }
  }
  .width('100%')
  .height('100%')
}
```

** Key points:** The list of posts must be constructed with `List` + `ListItem` + `.divider()`,** not with `Scroll` + `Column`,** otherwise the position of `geometryTransition` may be affected.

Key points:
- Detailed page cover sheet `geometryTransition` with `cardImg_${this.selectedIndex}`,** without conditions**
-** `.clip(true)`** Ensure that cover sheets do not spill over the details page boundary during the transition
-** `TransitionEffect.OPACITY`** To dilute the entire details page (navigation column, title, text) and only the cover sheet transitions the shared elements through `geometryTransition`
- Return button with the same `springMotion(0.6, 0.9)` curve as when it is opened

Step 3: Layout Structure - Stack Overlay

```ts
build() {
  Stack() {
/ Bottom: Waterfall Flow List
    Column({ space: 2 }) {
      WaterFlow() {
/ Card in Step 1
      }
      .columnsTemplate('1fr 1fr')
      // ...
    }

/ Top level: Detailed pages (conditional rendering)
    if (this.isDetailShow) {
Details in step 2 Page
    }
  }
  .width('100%')
  .height('100%')
}
```

# gometryTranstion ID Summary of the twinning rule

♪ Time, time ♪
|---|---|---|---|
| Details page closed (initial)  Z`cardImg_${index}` | does not exist | Falls flow card normal display
| Details Page Open | Selection `''` (hidden), the remainder |`cardImg_${selectedIndex}` (always) | Cover Map Magnify From Card Position to Full Screen
| Detailed Page Close | Resume Selection `cardImg_${index}` | `cardImg_${selectedIndex}` (always held) | Cover Map Down From Full Screen Back to Card Position

---

# Scene 3: A mirror search

** scene description:** Simulates the end of a search mirror, clicks the search box on the first page and zooms it seamlessly into a full-screen search page, enters the keyword and clicks the result back to the first page and narrows the search box back to its original location.

** Solution:** Use **`geometryTransition(id, {follow:true})`** ** ** `bindContentCover(modalTransition:NONE)`** ** ** ** `curves.interpolatingSpring` plug-in spring** ** ** ** ** `TransitionEffect.asymmetric` asymmetrical rollover**

### Step 0: state variable and durability

```ts
import { curves, promptAction } from '@kit.ArkUI'
import { inputMethod } from '@kit.IMEKit'

interface SearchItem {
  id: number
  name: string
  category: string
}

PersistentStorage.persistProp('searchHistoryData', '[]')

@Entry
@Component
struct GeometrySearchPage {
@state isSearchPageShow: boolean = false/ / Whether the search page should be displayed
@state teamryId: string = ' / /geometryTransation ID
@StatesearchText: string = '/ / Search PageValue
@state searchInput: string = '/ / Actual search word (separate from searchText to avoid frequent triggers)
@statesearchResults: SearchItem[] =[] / / Search results
@StorageLink ('searchHistoryData')searchHistoryData: string = '[] ' // Enduring search history
@state classifyIndex: number = -1// sort index
@StateCategoryName: string = '/ // Class name

  private allItems: SearchItem[] = [
{id: 1, name: 'Viral beat Animation', Category: 'Active'},
{id: 2, name: 'waterline effects', category: 'activation'},
{id: 6, name: 'Flex elastic layout', country: 'UI layout',
/... more data
  ]
Private SearchClassifyData: string[] = ['UI layout', 'activation', 'Trilateral library', 'Native', 'Performance Example', 'other']
}
```

> **Keypoint: ** `searchText` is separated from `searchInput` - `searchText` binds the Seach component to `value` (includes cursor position), ZXXKEEP4ZX is used for the actual search logic to avoid cursor beat.

Step 1: Homepage Search Box

```ts
"Search."
  .width('80%')
  .height(40)
  .backgroundColor('#E7E9E8')
  .borderRadius(20)
// Ban First Page Search Box Focused Keyboard
  .focusOnTouch(false)
  .focusable(false)
  .enableKeyboardOnFocus(false)
  .geometryTransition(this.geometryId, { follow: true })
  .transition(TransitionEffect.OPACITY.animation({
    duration: 200,
    curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1)
  }))
  .onClick(() => {
    this.onSearchClicked()
  })
  .bindContentCover(this.isSearchPageShow, this.searchPage(), {
ModalTranstion: ModalTransation. NONE, / / Core: Disable System Modular Animation
    onDisappear: () => {
This.onArrowcicked() / / Process system gesture returns
      this.searchText = ''
    }
  })
```

Key points:
- **`ModalTransition.NONE`** Disable system aerodynamics with only `geometryTransition` reserved for one shot at the end
- **`{follow: true}`** Let components follow the motion of shared elements
- `focusOnTouch(false)` + `focusable(false)` + `enableKeyboardOnFocus(false)` Triple Insurance prevents the head page search box from getting caught out of the keyboard
- `onDisappear` processing system signback to ensure state reset

Step 2: Search Page

```ts
@Builder
searchPage() {
  Column() {
    Row() {
/ Return button - asymmetric symmetrical transfer (entry delay: 150, exit without delay)
      Text('←').onClick(() => { this.onArrowClicked() })
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.opacity(0).animation({ duration: 200, delay: 150 }),
          TransitionEffect.opacity(0).animation({ duration: 200 }),
        ))

/ / Search Box - Match the First Page Search Box
"Search"
...defaultFocus(true) / / Auto-focused keyboard
.geometryTransion (this.geometryId, {follow: true})/ / Match the homepage search box
        .onChange((value: string) => {
          this.searchText = value; this.searchInput = value
          this.doSearch(value, this.categoryName)
        })
    }.margin({ top: 50 })

/ / Category Filter Area (Grid + toggle click logic, normal UI omitted)

/ / Search historical areas (visibility + asymmetric + slide/ slide)
    // .visibility(searchText.length === 0 && searchResults.length === 0 ? Visible : None)
    // .transition(TransitionEffect.asymmetric(...))

/ / Search result list (List + ForEach → onClick call onItemClicked)
    // .transition({ opacity: 0 })
  }
  .backgroundColor(Color.White)
.TransionEffect.opacity(0)) // / Modular Total Light Out
}
```

Key points:
- Search PageSearch uses **same **`geometryId`** to match the home page search box to create a shared element transition
-**ZXKEP0ZX** Auto-focused popup keyboard when the search page is open
- **Return button `asymmetric` Rotation**: Enter ZXXKEEP1ZX (waiting the completion of the search box) without delay
- Search historical areas for `visibility` + `TransitionEffect.asymmetric` + `translate({ y: 30 })` to slide/ slide out

## # Step 3: Open the search page - interpolating Spring

```ts
private onSearchClicked(): void {
This.geometryId = 'search '// Setup Match ID
  this.getUIContext()?.animateTo({
duration: 100, / / Very short (spring parameters control actual duration)
    curve: curves.interpolatingSpring(0, 1, 324, 38)  // stiffness=324, damping=38
  }, () => {
    this.isSearchPageShow = true
  })
}
```

Step 4: Close the search page - three closed paths

> ** Core principle: `this.geometryId = 'search'` must be set up for all closed paths to ensure that `geometryTransition` matches are effective and that the search box is reduced back to its original location. **

```ts
Path 1: Click to return arrow - Spring Animation + Full Reset
private onArrowClicked(): void {
  this.geometryId = 'search'
  this.getUIContext()?.animateTo({
    curve: curves.interpolatingSpring(0, 1, 342, 38)
  }, () => {
    this.searchResults = []
    this.isSearchPageShow = false
    this.classifyIndex = -1
    this.searchInput = ''
    this.categoryName = ''
    this.searchText = ''
  })
}

/ / Path 2: Click on search results - very short animation fast close + save search history
private onItemClicked(item: SearchItem): void {
/ / Save to search history (drive, 20 limits, PersistentStorage Endurance)
  let history = this.getHistoryList()
  const idx = history.indexOf(item.name)
  if (idx !== -1) history.splice(idx, 1)
  history.unshift(item.name)
  if (history.length > 20) history = history.slice(0, 20)
  this.saveHistory(history)

  this.geometryId = 'search'
  this.getUIContext()?.animateTo({
    curve: Curve.Ease,
duration: 20 / / very short time, quick to close
  }, () => {
    this.searchResults = []
    this.isSearchPageShow = false
  })
}

/ / Path 3: System gesture returns - bindContantCover on Disappear echo (configured in Step 1)
```

#GometryTransion

| Component
|---|---|---|
| Homepage Search Box  Z `this.geometryId, { follow: true }` | Source: Search Box Zoom Out
|Search |XKEEP0ZX | Target end: Search box zoom in
Z `bindContentCover` | `modalTransition: ModalTransition.NONE` | Disables system aerodynamics with geometry only
Z `animateTo` | `interpolatingSpring(0, 1, 324, 38)` | spring curved state change

The first page search box matches the search page Saarch with the same `geometryId`. When you open the search box, zoom in to the full-screen search page Saarch and close the search page Saarch down to the search box position. `ModalTransition.NONE` ensures that no system defaults up-slide animated animated the effects of a lens.

# Turn off the path comparison

| Close the path | Animated curve | special processing |
|---|---|---|---|
| Click to return arrow  `interpolatingSpring(0,1,342,38)` | spring self-determination | reset all search status
| Click on search results | `Curve.Ease` | 20ms | Save search history and quickly close up |
`interpolatingSpring(0,1,342,38)` Revert state

---

# Scenario 4: Card rollout details

** scene description: ** Simulates the commercial card roll-out, clicks on the card cover from the card position to the full screen details page, the cover node is reused between the card and the details page and returns the card.

** Solution:** Use **`NodeController` + `BuilderNode` cover node to retrieve location** ** ** ** **`getComponentUtils().getRectangleById()` ** ** ** `curves.springMotion(0.6,0.9)` ** ** ** `position` / `translate` / `height` attribute animation**

> ** Core principle: ** `NodeController` sealed `BuilderNode` node can be moved between different parent packagings (from card container to extended page packaging) to achieve ** true reuse of cover node** (rather than destruction reconstruction). `position` / `translate` / `height` Three Properties Animation, achieves the ultimate effect of the "card from the original to the full screen".

### # Step 0: Data model and Builder definition [Auxiliary]

> Pure data structure definition and basis, Builder, to provide a type basis for subsequent steps.

```ts
import { NodeController, BuilderNode, FrameNode, UIContext, curves } from '@kit.ArkUI'

/ Data model (id, coverSrc, title, source, time, period, tag, constructor omitted)
class FeedCard { /* ... */ }

interface CardNodeData {
  coverSrc: Resource
isExpand: boolean / / control cover size: expand 220vp / close 80vp
}

// Cover Map Builder — isExpand toggle size and round angle
@Builder
function cardCoverBuilder(data: CardNodeData) {
  Image(data.coverSrc)
    .width('100%')
    .height(data.isExpand ? 220 : 80)
    .objectFit(ImageFit.Cover)
    .borderRadius(data.isExpand ? 0 : 6)
    .syncLoad(true)
}
```

Step 1: Card NodeCtrl - NodeController Encapsulation [core]

> Core mechanism for the whole scene. Encapsulated `BuilderNode` achieves the relocation of nodes between different containers (`onRemove`/`makeNode`/`update`), which cannot be reused without it.

```ts
class RectResult {
  left: number = 0
  top: number = 0
  width: number = 0
  height: number = 0
}

class CardNodeCtrl extends NodeController {
  private node: BuilderNode<CardNodeData[]> | null = null
  private isRemove: boolean = false
  private data: CardNodeData | null = null
  private callback: Function | undefined = undefined

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.isRemove) return null
    if (this.node != null) return this.node.getFrameNode()
    return null
  }

  init(uiContext: UIContext, coverSrc: Resource, isExpand: boolean) {
If (this.node! = full) return / / avoid repetition initialization
    this.node = new BuilderNode(uiContext)
    this.data = { coverSrc: coverSrc, isExpand: isExpand }
    this.node.build(wrapBuilder<CardNodeData[]>(cardCoverBuilder), this.data)
  }

  update(isExpand: boolean) {
    if (this.node !== null && this.data !== null) {
      this.data.isExpand = isExpand
This.node.update(this.data) // Update BuilderNode Data Trigger Rendering
    }
  }

  setCallback(cb: Function | undefined) {
This. Callback = cb / / Callback (NodeContainer in card)
  }

  callCallback() {
    if (this.callback != undefined) this.callback()
  }

  onRemove() {
    this.isRemove = true
This.rebuild() // trigger makeNode returns NodeContainer disappears in the ulterior card
    this.isRemove = false
  }
}

/ / Global node map - Fetch NodeController via card ID
let gNodeMap: Map<string, CardNodeCtrl> = new Map()

function createCardNode(id: string): CardNodeCtrl {
  let node = new CardNodeCtrl()
  gNodeMap.set(id, node)
  return node
}

function getCardNode(id: string): CardNodeCtrl | undefined {
  return gNodeMap.get(id)
}
```

> ** Key points:**
> -`onRemove()` sent `makeNode` back through the `isRemove` sign ZXXKEEP2ZX to "remove" node from the card container, but the `BuilderNode` example itself is still alive and can be taken over by the `NodeContainer` extension page
> -`update(isExpand)` Update `BuilderNode` Data Switching Cover Map between 80vp ↔ 220vp
> - Global `gNodeMap` Ensures that the extended page can get the same `NodeController` example via card ID

Step 2: AnimationProps - Animation properties and location calculations [core]

> Expands the animation drive logic. `expandAnimation`/`collapseAnimation` Calculated bit transfer by `animateTo` + `springMotion` Driver `position`/`translate`/`height`

```ts
@Observed
class AnimationProps {
  isExpandPageShow: boolean = false
isEnabled: Boolean = true / / Disable interaction during animation
  curIndex: number = -1
  translateX: number = 0
  translateY: number = 0
PositionX: number = 0/ / Initial position (card position)
  positionY: number = 0
Changed Height: boolean = false / / control height toggle between fullscreen/card dimensions
private calculatedTranslateX: number = 0/ / Expand target
  private calculatedTranslateY: number = 0
  private uiContext: UIContext | null = null

  setUIContext(ctx: UIContext) {
    this.uiContext = ctx
  }

  expandAnimation(index: number) {
    if (index != undefined) this.curIndex = index
This.calculateData (index.tostrring()) / /Read where the card is on the screen
    this.isExpandPageShow = true
    this.uiContext?.animateTo({ curve: curves.springMotion(0.6, 0.9) }, () => {
This.translateX = this.calcutedTranslateX/ / Flat to Full Screen Source
      this.translateY = this.calculatedTranslateY
This. Changed Height = true // height 100% from card height
    })
  }

  collapseAnimation(onFinish: () => void) {
    this.uiContext?.animateTo({
      curve: curves.springMotion(0.6, 0.9),
      onFinish: onFinish
    }, () => {
This.translateX = 0 / / Twist Back to Card Location
      this.translateY = 0
This. Changed Height = size/ weight from 100% card height
    })
  }

  calculateData(key: string) {
    if (this.uiContext === null) return
/ / Get the card on the screen through key (ID)
    let clickedInfo = this.getRectInfoById(this.uiContext, key)
    let rootInfo = this.getRectInfoById(this.uiContext, 'rootStack')
/ position: Expand page initially at card position
    this.positionX = this.uiContext.px2vp(clickedInfo.left - rootInfo.left)
    this.positionY = this.uiContext.px2vp(clickedInfo.top - rootInfo.top)
/ / Translate: Expand animate bits (from card position full screen origin)
    this.calculatedTranslateX = this.uiContext.px2vp(rootInfo.left - clickedInfo.left)
    this.calculatedTranslateY = this.uiContext.px2vp(rootInfo.top - clickedInfo.top)
  }

  private getRectInfoById(ctx: UIContext, id: string): RectResult {
    let info = ctx.getComponentUtils().getRectangleById(id)
    let wGap = info.size.width * (1 - info.scale.x) / 2
    let hGap = info.size.height * (1 - info.scale.y) / 2
    let rst = new RectResult()
    rst.left = info.translate.x + info.windowOffset.x + wGap
    rst.top = info.translate.y + info.windowOffset.y + hGap
    rst.width = info.size.width - wGap * 2
    rst.height = info.size.height - hGap * 2
    return rst
  }
}
```

> **Keypoint: ** `position` and `translate` are used in conjunction - The spread page is initially positioned at card position through `position` and animation is moved to full screen original (0,0). `changedHeight` controls `height` toggle between the card height (~100vp) and 100%.

Step 3: List of cards - Click to trigger node migration [core]

> Expands animated trigger entry. `onClick` calls `onRemove()` to remove node from the card + calls `expandAnimation` to initiate animation.

```ts
@Component
struct CardItem {
  @Prop index: number = 0
  @Prop card: FeedCard | null = null
  @Link animationProps: AnimationProps
  @State nodeController: CardNodeCtrl | undefined = undefined

  aboutToAppear() {
    if (this.card != null) {
      let node = createCardNode(this.card.id)
      node.init(this.getUIContext(), this.card.coverSrc, false)
NodeContainer
        this.nodeController = getCardNode(this.card!.id)
      })
      this.nodeController = node
    }
  }

  build() {
    Row() {
      Stack() {
NodeContainer (this.nodeController)// Cover Node
      }
      .width(110).height(80)
/key for getting RectangleById positioning

/ ... Title, label, source, time (normal UI, omitted)
    }
    .onClick(() => {
This. NodeController? .onRemove()// Remove Nodes from Card
This.animationProps.isEnabled = false// Disable interactive
      this.animationProps.expandAnimation(this.index)
    })
  }
}
```

Step 4: Expand page - Take over node + Expand content [core]

> Node Migration Target End. `aboutToAppear` obtains the same NodeController + `update(true)` by `aboutToAppear` to expand the size to be achieved by binding the animation properties of Step 2.

```ts
@Component
struct ExpandPage {
  @Link animationProps: AnimationProps
  @Prop cards: FeedCard[] = []
  @State nodeController: CardNodeCtrl | undefined = undefined

  aboutToAppear() {
    let card = this.cards[this.animationProps.curIndex]
This. nodeController = getCardNode(card.id)/ /get the same NodeController
This.nodeController? .update(tru)// Switch to expanse (220vp)
  }

  build() {
    Column() {
/ / Navigator Bar (back button on Click → update(false) + CollapseAmination (onFinish))
      Row() {
        Text('‹').onClick(() => {
This.nodeController? .update(false) // Switch to collect dimension
          this.animationProps.collapseAnimation(() => {
This.nodeControllback? .callCallback()// NotifyNodeContainer
This. nodeController? .onRemove()// Remove Node From the Enlarged Page
            this.animationProps.isExpandPageShow = false
This.animationProps.isEnabled = true // resume interaction
          })
        })
      }

      Scroll() {
        Column() {
          Stack() {
NodeContainer (this.nodeController)/ / Example of the same node
          }.width('100%').height(220)

/... further title, author information, text (normal UI, omitted)
        }
      }.layoutWeight(1)
    }
Height (this.animationProps.changed Height? '100%':100) // Fullscreen ↔ card height
    .translate({ x: this.animationProps.translateX, y: this.animationProps.translateY })
    .position({ x: this.animationProps.positionX, y: this.animationProps.positionY })
    .transition(TransitionEffect.OPACITY)
  }
}
```

Step 5: Main Page Layout [Auxiliary]

> Pure Page Layout, Stack superimpose card list and extension page, binding `isExpandPageShow` condition rendering. No animation logic.

```ts
@Entry
@Component
struct CardExpandPage {
  @State animationProps: AnimationProps = new AnimationProps()

  aboutToAppear() { this.animationProps.setUIContext(this.getUIContext()) }

  build() {
    Stack() {
      Column() {
/... Navigator Bar + List
      }

      if (this.animationProps.isExpandPageShow) {
        ExpandPage({ animationProps: this.animationProps, cards: this.cards })
      }
    }
.key ('rootStack') / / For calculateData Positioning Source
.enabled (this.animationProps.isEnabled) / / Disable interaction during animation
  }
}
```

Summary of migration process

```
Card List Expand Page
┌─────────────┐            ┌─────────────────┐
│ NodeContainer│            │                 │
│ (node here) onRemove │
─ ─ → │ │ (node moved here)
NodeContainer
│             │            │  update(true)   │
│             │            │  height: 220vp  │
└─────────────┘            └─────────────────┘
                                ←── collapseAnimation(onFinish)
                                │
                                ↓ onRemove + callCallback
┌─────────────┐            ┌─────────────────┐
│ NodeContainer│  callback  │                 │
│ (node recovery)
│  update(false)│           │                 │
│  height: 80vp │           │                 │
└─────────────┘            └─────────────────┘
```

| Phase | Node Location | IsExpand | Cover Altitude | Expand Page Height | Expand Page Position |
|---|---|---|---|---|---|
♪ Original ♪
Click on the card, click on the card, expand on the page, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the card, click on the page, click on the card, click on the page, click on the page, click on the page.
| Opens the animation | Opens the page | 220vp | 100vp → 100% | card position via translate
| Expand finished | Expand page | true 220vp | 100% (0,0) |
| Click to return | open page | | 220vp | 80vp | 100% → 100vp | origin → location of the card
♪ When you're done ♪

---

Scene 5: News cover details

**Scene description: ** Simulates the News Feed flow, clicks on the card behind the news list and expands from the card position to the full screen news page, the list page fades simultaneously and returns the cover sheet back to the card position in the list.

** Solution:** Use **`Navigation.customNavContentTransition`** ** ** `CustomTransition` Monochrome Retrieval** ** ** ** `CoverNodeController` Cross-page Cover** ** ** ** `interpolatingSpring` + `scale/translate/clip`

> ** Distinguished from scene 5: ** scene 5 is a migration node between the Stack superscript layers on the same page; scene 6 is a migration node between the two NavDestination Navigation pages, which requires the coordination of the sharing and animation of nodes across pages through `customNavContentTransition` custom rotation animations.

### Step 0: Data model, tool class and route configuration [auxiliary]

> Pure data model definition, `ComponentAttrUtils` position acquisition tool class and **`route_map.json` route configuration** to provide data and route basis for subsequent steps.

> **  ** Key Configuration: `route_map.json` must exist**
>
> Use `Navigation.customNavContentTransition` for cross-page rotations. The echo parameter `NavContentInfo.name` needs to be obtained by the page name registered for `route_map.json`. If this profile is missing, `from.name`/ZXKEP4ZX will be an empty string, leading ZXXKEEP5ZX to return `false`, `customNavContentTransition` to return `undefined`, the system will use ** default level to slide into animation** (diversion effect) instead of the ** zoom + crop + offset group animation that we expect**.
>
> File Path: `entry/src/main/resources/base/profile/route_map.json`
>
> ```json
> {
>   "routerMap": [
>     {
>       "name": "NewsList",
>       "pageSourceFile": "src/main/ets/pages/sharedanimation/newsdetail/NewsListPage.ets",
>       "buildFunction": "NewsListBuilder"
>     },
>     {
>       "name": "NewsDetailContent",
>       "pageSourceFile": "src/main/ets/pages/sharedanimation/newsdetail/NewsDetailContent.ets",
>       "buildFunction": "NewsDetailBuilder"
>     }
>   ]
> }
> ```
>
> Every NavDestination page file must export the corresponding `@Builder` function:
> ```ts
> // NewsListPage.ets
> @Builder
> export function NewsListBuilder() {
>   NewsListPage()
> }
>
> // NewsDetailContent.ets
> @Builder
> export function NewsDetailBuilder() {
>   NewsDetailContent()
> }
> ```
>
> ** Consequences of missing `route_map.json`**: `customNavContentTransition` cannot match the page name, always returns `undefined`, trans-field animated to the system's default horizontal slide (diversion effect) and completely loses the zoom extension.

```ts
// NewsData.ets
export class NewsItem {
  id: string
  coverSrc: Resource
  avatarSrc: Resource
  title: string
  author: string
  time: string
  summary: string
  category: string
  // constructor...
}

export const NEWS_DATA: NewsItem[] = [
  new NewsItem('1', $r('app.media.transitionanimation_image1'), $r('app.media.transitionanimation_avator1'),
"Yunnan Da Lisi: poignant poignant in the sea, 'Traveling King', '2 hours ago', '...', 'Travel'),
/... more news data
]
```

```ts
/ ComponentAttrutils.ets - Component Location Acquisition Tool
import { UIContext } from '@kit.ArkUI'

export class RectInfoInPx {
  left: number = 0
  top: number = 0
  right: number = 0
  bottom: number = 0
  width: number = 0
  height: number = 0
}

export class ComponentAttrUtils {
  public static getRectInfoById(context: UIContext, id: string): RectInfoInPx {
    let componentInfo = context.getComponentUtils().getRectangleById(id)
    let rstRect = new RectInfoInPx()
    let widthScaleGap = componentInfo.size.width * (1 - componentInfo.scale.x) / 2
    let heightScaleGap = componentInfo.size.height * (1 - componentInfo.scale.y) / 2
    rstRect.left = componentInfo.translate.x + componentInfo.windowOffset.x + widthScaleGap
    rstRect.top = componentInfo.translate.y + componentInfo.windowOffset.y + heightScaleGap
    rstRect.right = componentInfo.translate.x + componentInfo.windowOffset.x + componentInfo.size.width - widthScaleGap
    rstRect.bottom = componentInfo.translate.y + componentInfo.windowOffset.y + componentInfo.size.height - heightScaleGap
    rstRect.width = rstRect.right - rstRect.left
    rstRect.height = rstRect.bottom - rstRect.top
    return rstRect
  }
}
```

Step 1: CustomTransion Individual - Call Back Registration across Pages [core]

> A dispatch hub across the page. The `CustomTransition` case is the one where `Map<pageId, AnimateCallback>` is stored and returned, and `Navigation.customNavContentTransition` uses it to find and trigger a truncated animation.

```ts
// CustomNavigationUtils.ets
export interface AnimateCallback {
  animation: ((isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void) | undefined
  timeout: number | undefined
}

const customTransitionMap: Map<number, AnimateCallback> = new Map()

export class CustomTransition {
  private constructor() {}
  static delegate: CustomTransition = new CustomTransition()
  static getInstance(): CustomTransition { return CustomTransition.delegate }

  registerNavParam(id: number,
    animationCallback: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void,
    timeout: number): void {
    if (customTransitionMap.has(id)) {
      let param = customTransitionMap.get(id)
      if (param != undefined) {
        param.animation = animationCallback
        param.timeout = timeout
        return
      }
    }
    customTransitionMap.set(id, { timeout: timeout, animation: animationCallback })
  }

  unRegisterNavParam(id: number): void {
    customTransitionMap.delete(id)
  }

  getAnimateParam(id: number): AnimateCallback {
    return {
      animation: customTransitionMap.get(id)?.animation,
      timeout: customTransitionMap.get(id)?.timeout,
    }
  }
}
```

> **Keypoint:** Single example of `CustomTransition` to store each NavDestination registered callback in `Map<pageId, AnimateCallback>`. `Navigation.customNavContentTransition` echoes `from.index` and `to.index` (place of page in NavPathStack).

Step 2: Cover NodeController - Share across page cover nodes [core]

> Share the cover of the cover node across the page. `NodeController` Envelope `BuilderNode`, which supports ZXXKEEP2ZX dynamically changing cover sizes to enable the node to be used across NavDestination.

```ts
// CoverNodeController.ets
import { NodeController, BuilderNode, FrameNode, UIContext } from '@kit.ArkUI'

interface CoverNodeData {
  imageSrc: Resource
  width: number | string
  height: number | string
  borderRadius: number
  objectFit: ImageFit
}

@Builder
function coverBuilder(data: CoverNodeData) {
  Image(data.imageSrc)
    .width(data.width)
    .height(data.height)
    .borderRadius(data.borderRadius)
    .objectFit(data.objectFit)
    .syncLoad(true)
}

export class CoverNodeController extends NodeController {
  private cardNode: BuilderNode<CoverNodeData[]> | null = null
  private isRemove: boolean = false
  private data: CoverNodeData | null = null

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.isRemove) return null
    if (this.cardNode != null) return this.cardNode.getFrameNode()
    return null
  }

  init(uiContext: UIContext, imageSrc: Resource, width: number | string, height: number | string,
       borderRadius: number, objectFit: ImageFit) {
    if (this.cardNode != null) return
    this.cardNode = new BuilderNode(uiContext)
    this.data = { imageSrc, width, height, borderRadius, objectFit }
    this.cardNode.build(wrapBuilder<CoverNodeData[]>(coverBuilder), this.data)
  }

  updateSize(width: number | string, height: number | string, borderRadius: number) {
    if (this.cardNode !== null && this.data !== null) {
      this.data.width = width
      this.data.height = height
      this.data.borderRadius = borderRadius
      this.cardNode.update(this.data)
    }
  }

  onRemove() {
    this.isRemove = true
    this.rebuild()
    this.isRemove = false
  }
}
```

Step 3: Animation Projects - Expand/Close Animation Calculator [core]

> Animated algorithm core. `doAnimation` calculates the scaling, offset, tailoring, using `interpolatingSpring` to enter the animation, ZXXKEEP2ZX to exit the animation.

```ts
// AnimationProperties.ets
import { curves, UIContext } from '@kit.ArkUI'
import { RectInfoInPx } from './ComponentAttrUtils'

@Observed
export class AnimationProperties {
  navDestinationBgColor: ResourceColor = Color.Transparent
  translateX: number = 0
  translateY: number = 0
scaleValue: number = 1// cover scale
cripWidth: Dimension = '100%'// shear width
clipHeight: Dimension = '100%'// Crop height
  showDetailContent: boolean = false
  private uiContext: UIContext

  constructor(uiContext: UIContext) {
    this.uiContext = uiContext
  }

  public doAnimation(
    cardItemInfoPx: RectInfoInPx,
    isPush: boolean,
    isExit: boolean,
    transitionProxy: NavigationTransitionProxy,
    prePageOnFinish: () => void
  ): void {
/ / Fetch Screen Size (by location of newsRoot container)
    let winRect = this.uiContext.getComponentUtils().getRectangleById('newsRoot')
    let winW = winRect.size.width
    let winH = winRect.size.height

/ / Calculate the scaling scale: to take the medium-larger width ratio
    let widthScaleRatio = cardItemInfoPx.width / winW
    let heightScaleRatio = cardItemInfoPx.height / winH
    let isUseWidthScale = widthScaleRatio > heightScaleRatio
    let initScale: number = isUseWidthScale ? widthScaleRatio : heightScaleRatio

/ / Calculating Initial Offset and Crop Dimensions
    let initTranslateX: number = 0
    let initTranslateY: number = 0
    let initClipWidth: Dimension = '100%'
    let initClipHeight: Dimension = '100%'

    if (isUseWidthScale) {
      initClipHeight = this.uiContext.px2vp(cardItemInfoPx.height / initScale)
      initTranslateX = this.uiContext.px2vp(cardItemInfoPx.left - (winW - cardItemInfoPx.width) / 2)
      initTranslateY = this.uiContext.px2vp(cardItemInfoPx.top) - initClipHeight * (1 - initScale) / 2
    } else {
      initClipWidth = this.uiContext.px2vp(cardItemInfoPx.width / initScale)
      initTranslateY = this.uiContext.px2vp(cardItemInfoPx.top - (winH - cardItemInfoPx.height) / 2)
      initTranslateX = this.uiContext.px2vp(cardItemInfoPx.left) - initClipWidth * (1 - initScale) / 2
    }

    if (isPush && !isExit) {
/ Enter animation: from card size to full screen
      this.scaleValue = initScale
      this.translateX = initTranslateX
      this.translateY = initTranslateY
      this.clipWidth = initClipWidth
      this.clipHeight = initClipHeight

      this.uiContext.animateTo({
        curve: curves.interpolatingSpring(0, 1, 328, 36),
        onFinish: () => { transitionProxy?.finishTransition() }
      }, () => {
        this.scaleValue = 1.0
        this.translateX = 0
        this.translateY = 0
        this.clipWidth = '100%'
        this.clipHeight = '100%'
This. showDetailContent = true / / Show details after rollout
      })

/ Background colour from transparency to non-transparent white
      this.uiContext.animateTo({
        duration: 100, curve: Curve.Sharp
      }, () => {
        this.navDestinationBgColor = '#00ffffff'
      })
    } else if (!isPush && isExit) {
/ / Exit Animation: Reduce card size back from fullscreen
      this.uiContext.animateTo({
        duration: 350, curve: Curve.EaseInOut,
        onFinish: () => {
          transitionProxy?.finishTransition()
          prePageOnFinish()
        }
      }, () => {
        this.scaleValue = initScale
        this.translateX = initTranslateX
        this.translateY = initTranslateY
        this.clipWidth = initClipWidth
        this.clipHeight = initClipHeight
This. showDetailContent = false / / Hide Details
      })

      this.uiContext.animateTo({
        duration: 200, delay: 150, curve: Curve.Friction
      }, () => {
        this.navDestinationBgColor = Color.Transparent
      })
    }
  }
}
```

> ** Key points:**
> - **Scalculations**: take the direction of the card ' s width to the screen ' s width to be used as the scaling benchmark to ensure that the cover sheet is fully filled
> - ** Offset correction formula**: `initTranslateY` and `initTranslateX` must be subtracted from `clipHeight/clipWidth * (1 - initScale) / 2`. This is because the scale zooms start at the centre, and the translate needs to compensate for the centre deviation resulting from the scalding, otherwise the cover sheet will deviate from the card position during the roll-up/recycling. The omission of this amendment will result in a vertical/horizontal shift of approximately half-screen distance of the cover sheet, with a severe collapse.
> - **Into animated by `interpolatingSpring`** (flexical expansion),** Exited by animated by `EaseInOut`** (sliding up)
> - ZXKEP0ZX controls the invisibility of text content for details only after full screen expansion
> - `navDestinationBgColor` Gradient from Transparency to Opaque White to prevent bottom content from coming out when you close

Step 4: NewsDetailPage - Navigation Host [Assisted]

> Navigation container configuration. Connect `customNavContentTransition` to CustomTransion for route judgement and back distribution. No animation calculation logic.

```ts
/ NewsDetailPage.ets — @Entry Page, Loading Navigation
@Entry
@Component
struct NewsDetailPage {
  private pageInfos: NavPathStack = new NavPathStack()
  private allowedFromPage: string[] = ['NewsList']
  private allowedToPage: string[] = ['NewsDetailContent']

  aboutToAppear(): void {
    this.pageInfos.pushPath({ name: 'NewsList' })
  }

/ / Allow custom transfer between NewsList ↔ NewsDetailContent only
  private isCustomTransitionEnabled(fromName: string, toName: string): boolean {
    if ((this.allowedFromPage.includes(fromName) && this.allowedToPage.includes(toName)) ||
      (this.allowedFromPage.includes(toName) && this.allowedToPage.includes(fromName))) {
      return true
    }
    return false
  }

  build() {
    Navigation(this.pageInfos)
      .hideNavBar(true)
      .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
        if (!from || !to || !from.name || !to.name) return undefined
        if (!this.isCustomTransitionEnabled(from.name, to.name)) return undefined

        let fromParam = CustomTransition.getInstance().getAnimateParam(from.index)
        let toParam = CustomTransition.getInstance().getAnimateParam(to.index)
        if (!fromParam.animation || !toParam.animation) return undefined

        let customAnimation: NavigationAnimatedTransition = {
          onTransitionEnd: (_isSuccess: boolean) => {},
          timeout: 2000,
          transition: (transitionProxy: NavigationTransitionProxy) => {
// from page execution of exit animation (list fades)
            if (fromParam.animation) {
              fromParam.animation(operation === NavigationOperation.PUSH, true, transitionProxy)
            }
// to page execution into animation (cover expanded)
            if (toParam.animation) {
              toParam.animation(operation === NavigationOperation.PUSH, false, transitionProxy)
            }
          }
        }
        return customAnimation
      })
  }
}
```

> ** Key points:**
> - The `customNavContentTransition` echo parameter ZXXKEEP1ZX / `to.index` is the index of the page in NavPathStack, which corresponds to the value of `context.pathStack.getAllPathName().length - 1` in `onReady`.
> - ** `route_map.json` must exist under `entry/src/main/resources/base/profile/` directory** (see step 0). The absence of this file results in `from.name`/ZXKEP3ZX being an empty string, `isCustomTransitionEnabled` returning `false`, `customNavContentTransition` returning ZXXKEEP7ZX, and the switch site degrading to the system's default horizontal slide animation (diversion effect).
> - `customNavContentTransition` returns three conditions to `undefined` must all be avoided: 1 ZXXKEEP2ZX 2 ZXXXXXXXXKEEP3ZX (requires ruute map.json) 3 `!fromParam.animation || !toParam.animation` (requires on Ready).

## # Step 5: NewsListPage — Animation registered on list page [Auxiliary]

> List Page UI + Register `listOpacity` Fadeback + Click to spin reference. The list itself is a normal list layout, animated only for the overall effect change.

```ts
// NewsListPage.ets
@Component
export struct NewsListPage {
  pageInfos: NavPathStack = new NavPathStack()
  pageId: number = -1
  @State listOpacity: number = 1

  private doFinishTransition(): void {}

  private registerCustomTransition(): void {
    CustomTransition.getInstance().registerNavParam(this.pageId,
      (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => {
/ / List pages only participate when push+exit(opity→0) and pop+ does not exit(opity→1)
        if (isPush && isExit) {
          this.getUIContext().animateTo({
            duration: 350, curve: Curve.EaseInOut,
            onFinish: () => { transitionProxy?.finishTransition() }
          }, () => { this.listOpacity = 0 })
        } else if (!isPush && !isExit) {
          this.getUIContext().animateTo({
            duration: 350, curve: Curve.EaseInOut,
            onFinish: () => { transitionProxy?.finishTransition() }
          }, () => { this.listOpacity = 1 })
        }
      }, 500)
  }

  build() {
    NavDestination() {
      Column() {
/... Navigation Bar
        List() {
          ForEach(NEWS_DATA, (item: NewsItem, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.summary)
                      .fontSize(13)
                      .fontColor('#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 6 })
                    Row() {
                      Image(item.avatarSrc)
                        .width(18).height(18).borderRadius(9).objectFit(ImageFit.Cover)
                      Text(item.author)
                        .fontSize(12).fontColor('#888888').margin({ left: 6 })
                      Text(item.category)
                        .fontSize(11).fontColor('#ff6b35')
                        .backgroundColor('#fff3ed').borderRadius(3)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                        .margin({ left: 10 })
                      Blank()
                      Text(item.time).fontSize(11).fontColor('#cccccc')
                    }
                    .margin({ top: 10 }).width('100%')
                  }
                  .layoutWeight(1).margin({ right: 12 }).alignItems(HorizontalAlign.Start)

                  Image(item.coverSrc)
                    .width(110).height(76).borderRadius(6)
.key (`card_${index}`) // For ComponentAttrutils
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
/ / Get card position + pass parameters to details Page
                  let cardItemInfo = ComponentAttrUtils.getRectInfoById(
                    this.getUIContext(), `card_${index}`)
                  let param: Record<string, Object> = {}
                  param['cardItemInfo'] = cardItemInfo
                  param['cardIndex'] = index
                  param['coverSrc'] = item.coverSrc
                  param['doDefaultTransition'] = () => { this.doFinishTransition() }
                  this.pageInfos.pushPath({ name: 'NewsDetailContent', param: param })
                })
              }
              .alignItems(HorizontalAlign.Start)
            }
          }, (item: NewsItem) => item.id)
        }
        .divider({ strokeWidth: 0.5, color: '#f0f0f0', startMargin: 16, endMargin: 16 })
.opacity (this. listOffice) / / List as a whole Out
      }
.key('newsRoot') / / for AIMSProperties to fetch screen dimensions
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.pageId = this.pageInfos.getAllPathName().length - 1
      this.registerCustomTransition()
    })
    .onDisAppear(() => { CustomTransition.getInstance().unRegisterNavParam(this.pageId) })
  }
}
```

> ** Key points:**
> - **registerCustomTransion must make a strict distinction between the sub-divisions**: `isPush && isExit` (fading list at push) and `!isPush && !isExit` (drop list at pop) and cannot be simplified to `isPush ? 0 : 1`. The simplified version also triggers animation when push+ does not exit (list enters as target page) and pop+ exits (list exits as source page), resulting in an unexpected change in opacy.
> -**pushPath transfer must contain `doDefaultTransition` back**: `param['doDefaultTransition'] = () => { this.doFinishTransition() }`. Details pages receive this callback in `onReady` and pass `prePageOnFinish` parameters to `AnimationProperties.doAnimation`, and `onFinish` calls `prePageOnFinish()` to finish the list page when you exit. The omission of this cross-reference leads to a list page not to resume after pop.
> - ** Bottom Information Line**: Image (18x18, borderRadius=9) + Author (fontSize = 12, #8888) + Categorized Label (fontSize = 11, #ff6b35, backwardColor =#fff3ed, borderRadius = 3) + Time (fontSize = 11, #cccccc).
> - ** The list must be configured with `divider`, ZXKEEP1Z** to align the partition line to the card content.
> - ** The background colour of the list page is `Color.White`**, and does not use a grey tune such as `#f0f0f0`, otherwise it creates a visual difference with the card rounded cut area.

Step 6: NewsDetailContent — Detail page registration on roll-up/take-up animation [core]

> Actual implementer of rerun animation. `onReady` creates CoverNode+Registration Roundup, binding the animation properties of `scale`/`translate`/`clip` in bueld, which is the landing point for step 1-3.

```ts
// NewsDetailContent.ets
@Component
export struct NewsDetailContent {
  @State animProps: AnimationProperties = new AnimationProperties(this.getUIContext())
  @State coverNode: CoverNodeController | undefined = undefined
  pageId: number = -1
  prePageDoFinishTransition: () => void = () => {}
  cardItemInfo: RectInfoInPx = new RectInfoInPx()
  cardIndex: number = 0
  coverSrc: Resource = $r('app.media.transitionanimation_image1')

  private onBackPressed(): boolean {
    if (this.coverNode != undefined) {
This. cover Node.updateSize (110, 76, 6) / / restore card size cover first
    }
    this.pageInfos.pop()
    return true
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            Stack() {
              if (this.coverNode != undefined) {
NodeContainer (this. coverNode)// Cover node shared across page
              }
            }.width('100%').height(240)

            if (this.animProps.showDetailContent) {
              Scroll() {
                Column() {
                  Text(NEWS_DATA[this.cardIndex]?.title ?? '')
                    .fontSize(22).fontWeight(FontWeight.Bold)
                    .fontColor('#333333').lineHeight(30)

                  Row() {
                    Image(NEWS_DATA[this.cardIndex]?.avatarSrc ?? $r('app.media.icon'))
                      .width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
                    Column() {
                      Text(NEWS_DATA[this.cardIndex]?.author ?? '')
                        .fontSize(14).fontColor('#333333').fontWeight(FontWeight.Medium)
                      Text(NEWS_DATA[this.cardIndex]?.time ?? '')
                        .fontSize(12).fontColor('#999999').margin({ top: 2 })
                    }
                    .alignItems(HorizontalAlign.Start).margin({ left: 10 })
                    Blank()
Button.
                      .fontSize(13).fontColor(Color.White)
                      .backgroundColor('#ff6b35').borderRadius(16)
                      .height(30).padding({ left: 16, right: 16 })
                  }
                  .width('100%').margin({ top: 20 })

                  Text(NEWS_DATA[this.cardIndex]?.summary ?? '')
                    .fontSize(16).fontColor('#555555').lineHeight(26).margin({ top: 24 })

                  Row() {
Text('m 128').fontSize(13).fontColor('#99999')
Text ('Comment 56'). FontSize (13). FontColor ('#99999'). Margin({left: 20})
Text(`receiving'). FontSize(13). FontColor('#99999'). Margin({left: 20})
                  }
                  .margin({ top: 30 }).padding({ bottom: 40 })
                }
                .padding({ left: 20, right: 20, top: 16 }).alignItems(HorizontalAlign.Start)
              }
              .layoutWeight(1)
              .transition(TransitionEffect.OPACITY)
            }
          }
          .width('100%').height('100%')
        }
        .width('100%').height('100%')
        .scale({ x: this.animProps.scaleValue, y: this.animProps.scaleValue })
        .translate({ x: this.animProps.translateX, y: this.animProps.translateY })
        .width(this.animProps.clipWidth)
        .height(this.animProps.clipHeight)
        .clip(true)

/ / Navigator Bar (display only) - White text, suspended above the cover sheet
        if (this.animProps.showDetailContent) {
          Row() {
            Text('‹')
              .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
              .margin({ right: 8 })
              .onClick(() => { this.onBackPressed() })
            Blank()
            Text('⋯')
              .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12 })
          .transition(TransitionEffect.OPACITY)
        }
      }
    }
    .backgroundColor(this.animProps.navDestinationBgColor)
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.pageId = this.pageInfos.getAllPathName().length - 1

/ / Parameters transmitted by the receiving list page (including doDefaultTransion)
      let param = context.pathInfo.param as Record<string, Object>
      this.prePageDoFinishTransition = param['doDefaultTransition'] as () => void
      this.cardItemInfo = param['cardItemInfo'] as RectInfoInPx
      this.cardIndex = param['cardIndex'] as number
      this.coverSrc = param['coverSrc'] as Resource

/ / Create Cover Node (fullscreen dimension) - Use chargeSrc received
      let node = new CoverNodeController()
      node.init(this.getUIContext(), this.coverSrc, '100%', 240, 0, ImageFit.Cover)
      this.coverNode = node

/ Retrieval - prePageOnFinish to doAnimation
      CustomTransition.getInstance().registerNavParam(this.pageId,
        (isPush, isExit, proxy) => {
          this.animProps.doAnimation(this.cardItemInfo, isPush, isExit, proxy,
            this.prePageDoFinishTransition)
        }, 1500)
    })
    .onBackPressed(() => { return this.onBackPressed() })
    .onDisAppear(() => { CustomTransition.getInstance().unRegisterNavParam(this.pageId) })
  }
}
```

> ** Key points:**
> - ** The text of the navigation column shall be `Color.White`**: The navigation column shall hang above the cover sheet, which is usually a dark picture. The use of `#333333` dark-coloured text in the dark background is almost invisible, which is a common cause of collapse. `fontColor(Color.White)` +`fontWeight(FontWeight.Bold)`.
> - ** The navigation bar must have `⋯` more buttons on the right side of the bar** and do not show only back arrows. The original layout is `Text('‹') + Blank() + Text('⋯')`, padding is ZXXKEEP2ZX.
> - ** the navigation column is not `backgroundColor(Color.White)`**: the navigation column is transparent and the text is suspended on the cover sheet. Seting the white background will destroy the seamless spread of "a single shot."
> - **Additional pages must contain **: title (fontSize=22, lineHeight=30) → Author Information Line (head 32x32 + author ' s name + time + focus on Button) ** Body (fontSize=16, lineHeight=26, #555555) → Interactive Bar (appraisals/comments/collections). A simplified version cannot be used with a title + summary + classification label, otherwise the visual effects are too different from the original version.
> - **onReady must receive `doDefaultTransition` echo**: `this.prePageDoFinishTransition = param['doDefaultTransition'] as () => void` and pass it on to ZXXKEEP2ZX parameters. `onFinish` calls `prePageOnFinish()` at pop exit, triggers the list page to resume. If the function `() => {}` is emptied, the list page pop will not be restored to effect=1.
> - **onBackPressed `coverNode.updateSize(110, 76, 6)` must be emptied**: `if (this.coverNode != undefined)`. An optional `this.coverNode?.updateSize(...)` direct connection may not be supported in ArkTS.

# # Summarize animation times across pages

| Phase List Page (NewsListPage) | Detail Page (NewsDetailContent) | Cover Node |proxy|
|---|---|---|---|---|
| Initial | force=1, normal display | does not exist
| Click on a card, push | register callback, start fading out | Create CoverNode, register callback | details page create (240vp full screen size) |
|Push rotation starts |listOpacity → |scale/translate/clip from card value to fullscreen |NodeContainer display |
Push rotation completes |finishTransion() | show
| Click back, pop | register back, ready to fade into | cover Node.updateSize (110,76,6) restore card cover | card size |
|Pop Starts the turn of the field |listOpacity →1 scale/translate/clip from fullscreen to card value | card size |
| pop rotation completes |finishTransion(), restores display of | page destruction, unRegister NavParam page destroys |finishTransion() |

---

# Compile and run-time case collection

# Directory

## [I, issue of stability] (# issue of stability)
1. [Web pictures syncload synchronized downloads resulting in freezing screens] (#Scene1 webshots-syncload -- synchronized downloads resulting in freezing screens)
2. [autodefined component about ToDisappear echo abnormal] (#Scene 2 custom component --abouttodisappear-back abnormal)

# [II, rendering Carton]
3. [The time-consuming operation of the main line leads to the loss of frame] (#Scene 3 main route leads to the loss of frame)
4. [Sliding frame and drop frame analysis] (#Sliding scene 4 frame and drop frame analysis)

# # [III, Response Timed] (# Three Response Timed]
5. [Slide list placeholder load completion delay] (#Scene 5 slide list placeholder load completion delay)

# # [iv, state and rendering anomaly] (# four states and rendering anomaly)
6. [list key Unstable Rendering Mist] (#Scene 6 List -key - Unstable Rendering Mist)
7. [@Watch Retweets death cycle of bugged variables] (#Scene7watch-Retweet modification of death cycle of bugged variables] I'm not sure.
8. [Subsidiary direct update @state to UI not refresh] (#Scene 8 subsequent direct update-state-to-ui-no refresh)

---

# I, the problem of stability

## # scene 1: web pictures syncload synchronized download resulting in freezing screens

**Scene description:** List / Nine Palaces covered with web images, page openings for seconds; entire interface frozen and no response when moving quickly; low net direct "Application No Response / ANR" System log appears **AppFreeze / ThreadBlock** event. Small local maps are not visible. Weak webs / Timeout scene symptoms have dramatically deteriorated.

**Ghen:** `Image` component `syncLoad` (API 8+) Default `false` (by walk). Once set as `syncLoad(true)`, the ** download (network IO) and decode (cPU intensive) of the picture will be synchronized with the main route**. Network downloads can take several dozen milliseconds, and the main threads are blocked by both types of operation and cannot handle the input event and the next chromium, and are determined by watchdog to apply the freeze screen over time. ** ZXKEP4ZX is strictly forbidden for use in network maps. **

** Diagnosis:**
- **HiAppEvent**: Subscription to `APP_FREEZE` event, confirmation that the type of failure is ThreadBlock and takes the instant stack.
- **DevEco Studio Profiller / hiLog**: See if the main line stays long in the photo decoding / web request
- ** Weak web re-emergence**: Long duration of blockage with speed limit / off-grid amplification, as evidenced by the deterioration of the freeze screen.

** Solution: ** Webchart maintains `syncLoad` default `false` (apogee), using a placechart to cover the bottom.

```ts
/ / ❌ Example: Web chart opens for simultaneous loading, main thread is downloaded + decoding
List({ space: 8 }) {
  ForEach(this.urls, (url: string) => {
    ListItem() {
Image(url). syncLoad(true).width(120). high(120) / network IO + decode all on main route
    }
  }, (url: string) => url)
}

/ / / / / Positive: Keep moving, below / + Decoding by Display Size
Image(url)
.alt ( 'app.media.ic placeholder') // Show bitmap during loading to avoid whitescreen blinking
.autoResize(true) / / Decoding by display size only, saving memory
  .width(120).height(120)
```

If you really need the synonym "to get the map first and then show" then you should download **Step to local before handing over to Image**:

```ts
import { request } from '@kit.RequestKit';
import { common } from '@kit.AbilityKit';

/ /context imported by caller (component), e. g. getContext(this)
async function prefetch(context: common.UIAbilityContext, url: string): Promise<string> {
const filePath = `${context.cacheDir}/${Date.now()}.png`;/ / Local cache path
  const task = await request.downloadFile(context, { url, filePath });
Waiting on call
    task.on('complete', () => resolve());
(a) (`fail', ( = > subject (new Error (`download failure'));
  });
return filePath; / /Image directly loads this local file
}
```

** KEY POINT / PLACE:**
`syncLoad(true)` is only suitable for ** local small ** (known size icon / decoded PixelMap)** for network **.
2. Long list network maps must be accompanied by `autoResize(true)` + `alt` (placed)+ photo caches to avoid repetition of downloads and memory peaks.
3. Disables any synchronous network/file operation (`fs.openSync` for `await`) within the life cycle function.
Re-emergence priority is given to magnifying the signal with a weak net / offline, and to stifling with the HiAppEvent + Profiller boundary route.

---

Scene 2: Custom Component about ToDisappear

** scene description: ** Navigation route returned, `if` branch reduced or applied by fact false, ForEach array reduced or applied, error-reporting crashed; object read in ZXXKEEP1ZX changed undefined / empty references; ZXXKEEP2ZX / `Promise` ran back to retrace component references and used error or UI not to refresh.

** Gene:** `aboutToDisappear` was executed before the destruction of the self-defined component** the back end node was marked detached, was about to be removed, examples of components and `@State/@Link` were ready to be GC. Three types of typical errors:
- ** Status change variable**: In particular, `@Link` could undermine the binding of the synchronous source, leading to an unstable application.
- ** The scramble holds `this`**: `async/await` / `Promise` / `setTimeout` for example of a closed package holding component to stop GC; the citation rate is no longer valid when the scramble is actually performed.
- ** Methodological renaming override**: The definition of business methods with the same life-cycle name in `@Component`, the time-sequencing of framework reversals and anomalies may be swallowed silently.

** Diagnosis method: ** `aboutToAppear` / `aboutToDisappear` / XKEEP1ZX within an insular mission, respectively, make points to confirm the time sequence of the callback and step-by-step tasks; use `errorManager.on('error')` (`@kit.AbilityKit`, registered global error monitor, whose ZXXKEEP5ZX call can get an abnormal name/message/stack) to observe the anomalies not addressed in the logback; return to the body to add try-catch to the script location invalid object.

**Solution:** Revert only ** Synchronized clean-up** (elimination of timers, de-registration listening, closure of resources) with time-consuming tasks advanced to `aboutToAppear` registration and cancelled before destruction.

```ts
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
struct Child {
  @State count: number = 0
  private timer: number = -1
  private disposed: boolean = false

  aboutToAppear() {
    this.timer = setInterval(() => {
If (this.disposed) return / / / / / / / self-exit after destruction
      this.count++
    }, 1000)
  }

  aboutToDisappear() {
ClearInterval (this.timer) / / 1 sync to clear the timer/ listen
This.disposed = true / / 2 marked destroyed
    try {
      hilog.info(0x0000, 'Child', 'cleanup done')
{/ / 3 try-catch underside to avoid silent swallowing anomalies
      hilog.error(0x0000, 'Child', 'cleanup error: %{public}s', `${e}`)
    }
/ / Do not modify @state/ @Link here and do not start any more different tasks holding this
  }

  build() { Text(`${this.count}`) }
}
```

** KEY POINT / PLACE:**
1. Invert** Disable state variable** (especially `@Link`); read-only subcomponents are not used for `@Link`, instead of `@Prop`.
2. ** Disables async/await / Promise**: a walk-in lockout holds `this` to stop GC.
3. The end of destruction is primarily synchronous clean-up; time-consuming tasks are pre-registered and cancelled before destruction.
4. Do not define in `@Component` the business method under the same name as `aboutToAppear/aboutToDisappear`.

---

# Two, refill Carden #

Scene 3: Time-consuming operation of the main line leads to frame loss

**Scene description:** "List Slide Visible Carden" "Stress button interface freezes half a second" "Standing more animation breaks" "Cool start white screen long" Profiler Trace has a continuous long mission (quoted from performance best practices, single time 20 ms+, exceeding the Vsync cycle of 8.3 ms) and a high drop rate. The cause is not the complexity of the UI, but the fact that the main route is doing a lot of work in "where it shouldn't be."

** Gene: **ArkUI layout, drawing, state refreshing, Vsync back on the main line. Once the main line of a certain code is in excess of one frame (approximately 16.6 ms@60fps / 8.3ms@120fps), the line is squeezed and the frame is dropped. Common time-consuming sources (the following time-consuming values are quoted in best practice performance, Quantification reference):
- ** HF retrusion time operation**: `onWillScroll`, `aboutToReuse`, ZXXKEEP2ZX, ZXXKEEP3ZX, `itemGenerator/keyGenerator`, component attribute reference function - Triggered once per frame/ item, stacked with a million-million cycle, JSON.parse, synced IO, broken 20 ms at a time.
- **Application error**: `getStringSync($r(...))` fax source object (the Reload of Research is obsolete and has an additional cost, ~1.9 ms) and `.id` (number heavy) lighter (~0.07 ms).
- **release residual redundancy**: unremoved `hilog.debug`, empty `onAreaChange`, still cost of cross-layer communication on the ground floor (an average of 84 ms measured in a single log, cumulative at a slide of 35 ms+).

** Diagnosis method: ** Slide/click time with the DevEco Studio Profiller orbit, locates the function of the Main linear red frame (suspect callback can be used with hi TradeMeter `startTrace/finishTrace` time-consuming time); Code Linter allows bulk scan of empty and main route network requests.

** Solution:**

```ts
import { taskpool } from '@kit.ArkTS';

HF back to thinness: light value only, time-consuming calculation of sinking TaskPool
@Concurrent
function parseData(raw: ArrayBuffer): Model[] {
Return JSON.parse (new TextDecode().decode(raw)) as Model[]; / / sub-routine resolution, uncarded Cheng
}
aboutToAppear() {
  taskpool.execute(parseData, this.rawBuffer).then((res: Model[]) => this.dataList = res)
}

/ / 2 interface preferences: pass id instead of source objects
SourceManager. GetStringSync ('app.string.test').id) / / ✅ quote 0.07 ms
/ /ResourceManager. GetStringSync ('app.string.test') / /Deep copy 1.9 ms
```

** KEY POINT / PLACE:**
1. **Step unblocked**: `async/await` is ultimately still being implemented by the main thread, `JSON.parse` large data sample frame, which must sink ZXXKEEP2ZX/`Worker`.
**Reverse frequency determination hazard**: `onWillScroll`, `aboutToReuse`, `itemGenerator` per frame / per trigger, single milliseconds of high frequency superheavy can also be dropped — priority sorting of hot spots.
3. Component properties are " whole refreshing " , and a `width` will be recalculated with the other properties of the component into a reference function and do not hang time-consuming functions on any properties.
Release packages must remove the test interface (`getInspectorByKey`/ `sendEventByKey`) and the redundant log/ empty callback.

---

Scene 4: Slide frame and frame analysis

** scene description:** List / Grid / Scroll long list slides "Carton, Hands": ripping, instant stagnating, white chunks or fragments of slides; continuous frame drops in the Profiller application or the RinderService process (** maximum continuous frame drop ≥ 3 users can notice **); high change in frame rates cannot be stabilized at 60fps / 120fps; particularly evident in the fast fling inertial rolling phase of Cardon.

**Ghen:** Long frame/ drop frame for each chromium dye. The ArkUI Render & SendMessage VII phase, either of which has been too long, has brought down the frame. Common drag items:
- **Repeated component invalid**: A large number of `H:CustomNode:BuildItem` during slides, recreated by unhit re-entry pool.
- ** @Prop Deep Copy**: Complex Object / Cass into trigger `deepCopyObject`, BuildItem Phase 3ms+ (Quoting Best Practice).
-** Redundancy status variable**: `@State` modified without binding UI variables, each update still leaves Set process time-consuming.
- ** LazyForEach fully updated**: `notifyDataReload()` has led to extensive reconstruction.
- ** Entries Deep / CachedCount Too Small** : project created at each frame phase.

** Diagnosis: **ArkUI debug switch (`hdc shell param set persist.ace.trace.enabled 1` et al.) before scratching Trace. Use the Profiller Frame track to determine whether the frame is thrown in ** application process or RS process** (RS drop frame but apply side balance, mostly system drawing problems), then check the red frame to ArkTS Callstack to see the time-consuming phase -- - Focus on `BuildItem` (re-use failure), `deepCopyObject` (@Prop deep copy), ZXXKEEP3ZX (redundant state variable).

** Solution:**

```ts
/ / 1@Reusable +useId correctly enable reuse (BuildItem while removing slide)
@Reusable
@Component
struct OneMomentItem {
  @State item: MomentData = new MomentData()
  aboutToReuse(params: Record<string, Object>): void { this.item = params.item as MomentData }
  build() { /* ... */ }
}
LazyForEach(this.dataSource, (item: MomentData) => {
OneMomentItem({item}). ReuseId (item. type == = 'video'? 'video': 'image') / / Multiple templates must be distinguished by reuseId
}, (item: MomentData) => item.id)

/ 2 Replace @Prop with @ObjectLink (avoid deep copy)
@Observed class MomentData { id: number = 0 }
@ObjectLinkitem: MomentData}/ Light copy

/ 3 Delete unbound UI redundancy variable
Scrollofset: number = 0/ / Change normal variable to no more Set process @state

/ 4 Reduced nesting: RelativeContainer flat or @Builder instead of @component (avoid   Common   node)
```

** KEY POINT / PLACE:**
1. **Standing frame process**: Frame Orbit Distinction Application vs RS to avoid miscalculation.
2. **Trace must open the debug switch** without seeing the specific variables that cause the stain.
3. ** @Prop strictly forbids the transmission of complex objects**: Single Frame BuildItem if 3ms+ is basically a deep copy.
4. **ReuseId**: `@Reusable` alone is not enough. Multiple templates must be distinguished by ZXXKEEP1ZX, otherwise the re-use hit rate is low.

---

# Three, response timed

###5: Slide list placeholder load completion delay

**Scene description:** After the stop of the long list inertial scroll, the picture placeholder is delayed to load and blanks appear on the screen; more loads up end with the loading animation card long enough; the more pull up load slows; the transparency/scaling change drawings on the placechart load is prolonged.

Measurement ** "Slide Page Placeholder Load Completion Delays"**: from Roll Stop (`APP_LIST_FLING` Endpoint) to the end of the Placeholder Loading in the screen (Applicion does not submit Vsync to ReaderService),** Standard 40ms**.

** Roots:**
-**Web time delay**: Up-and-up trigger `createHttp → request → parse → OnDataReloaded` chain excessive length plus web map `CreateImagePixelMap` decoded time-consuming.
-** Rendering time delay**: main line long frame / abnormal frame. It's common for LazyForEach to refresh in full with `notifyDataReload()`, or for sub-components without `@Reusable`, which is reconstructed by `aboutToBeDeleted` resolution in the slide.
- **Animation time extension**: The bitmap loads use `JSAnimation` (transparent / zoom) and duration is then added directly to the load completion.

** Diagnosis method:** Starting with `APP_LIST_FLING` endpoint (roll stop), applying stop frame as endpoint measure, standard **40ms**. Profiler Frame bathing track positioning hyper-long frame cause - common in LazyForEach full-scale refreshing (`notifyDataReload`), unused components (large `aboutToBeDeleted`), position ZXKEEP3Z duration.

** Solution:**

```ts
/ / 1 Network: Pre-request (fast bottom trigger) + local position + photo cache
Image(item.url).alt($r('app.media.placeholder')).objectFit(ImageFit.Cover)

/ / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
This.dataSource.notifyDataAdd(this.dataSource.totalCount()-1) / / / /en only add new entries
/.datasource.notifyDataReload() / / / / key unchanged items have also been rebuilt

/ / 3 @Reusable
@Reusable @Component
struct GridItemView {
  @State item: Item = new Item()
  aboutToReuse(params: Record<string, Object>): void { this.item = params.item as Item }
  build() { /* ... */ }
}
LazyForEach(this.dataSource, (item: Item) => {
  GridItem() { GridItemView({ item }) }.reuseId('gridItem')
}, (item: Item) => item.id.toString())

/ 4 Animation: assess the need for a gradual change in the position map, shorten the situation or remove it
```

** KEY POINT / PLACE:**
1. ** Start-up point before analysis**: the end point of ZXKEP0ZX must be used as the starting point for the time extension, otherwise the caliber error is measured.
** `notifyDataReload` is a performance killer**: Incremental data is partially updated with `notifyDataAdd/notifyDataChange`.
3. ** `@Reusable` + `reuseId` must be paired **: a large number of `aboutToBeDeleted` in Trace is an unused signal.
4. **The length of animated = time delay**: the self-defined animation duration at the placechart loading stage is directly included in the delay when loading is completed and is exempt.

---

# Four, state and rendering abnormal

# # scene 6: list key unsettled rendering

**Scene Description:** List / Grid after deleting, inserting, sorting or placing new, part of the item displays the incorrect content - – Delete the second and the third part of the second, without moving, the thumbnails appear to another entry, the input box text is the wrong one; or the data changes the interface without updating.

**Cause:** ForEach / LazyForEach uses `keyGenerator` to identify "what data corresponds to which component" and decides whether to reuse or rebuild when adding or deleting. The key value must satisfy ** unique + consistency** (data remains unchanged). Common error:
-** Key**: `(item, i) => i.toString()` - Delete / Reorder the same index pointing to different data, frame is determined to be "same component, data has changed" and re-plug old components into new data, leading to a misset of content and a picture string.
- ** LazyForEach does not pass KeyGenerator**: The default key value is `viewId + '-' + index` (only affected by index), which is also unstable.
- **key is not the only one or over time**: the frame cannot correctly recognize additions or deletions; it should be refreshed and not rebuilt.

** Diagnosis: ** The phenomenon only occurs when "Addition, delete, sort and refresh" and is normal when the pure display is not moving. Check if KeyGenerator uses index and whether it is the only and lasting.

** Solution:**

```ts
/ / ❌ Reverse: use index as key, delete/renumber the error
ForEach(this.list, (item: Item) => {
  ListItem() { ItemRow({ item }) }
, (item: Item, index: number)

LazyForEach (this.dataSource, (item: Item) = {// keyGenerator → Default ViewId-index
  ListItem() { ItemRow({ item }) }
})

/ / / Positive: the only stable id of the data itself is key
ForEach(this.list, (item: Item) => {
  ListItem() { ItemRow({ item }) }
}, (item: Item) => item.id.toString())

LazyForEach(this.dataSource, (item: Item) => {
  ListItem() { ItemRow({ item }) }
}, (item: Item) = >item.id.toString()) // Visibility provides the only key to stability
```

** KEY POINT / PLACE:**
Key must satisfy " Unique + Endurance": Each data entry corresponds to the single key and the data remains the same.
2. ** Deleting index as key**: delete / insert / sorting with index and misplaced data and re-use the component to error data.
3. LazyForEach, KeyGenerator (default is index), long list must be visible to `item.id`.
4. KeyGenerator does not perform time-consuming operations (e.g. `JSON.stringify` for the whole object) and drags down the slide performance.

---

# # scene 7: # Watch Retweeting the dead cycle of listening variables

**Scene description:** Added @Watch to a variable @State / @Prop / @Link, changing the variable 's post-interfacing interface to fail to respond and even spill out the crash; or CPU skyrocketing and severe frame loss.

** Gene: ** @Watch echoes ** synchronised **; if the same state variable that is monitored is modified (directly or indirectly) in the echo, it triggers the @Watch → unlimited retrogression / flood. @Watch is designed to "fast-response change to light-calculation" and should not be re-interviewed, and should not be subjected to hiking.

** Diagnosis: ** The phenomenon appears immediately after "changed @watch's variable", checking whether the @watch retort function has been given value for the monitored variable (or the variable that will indirectly trigger it).

** Solution:**

```ts
/ / / ❌ Reverse: Revert to bugged variables / Unlimited Recursive
@State @Watch('onCountChanged') count: number = 0
onCountChanged(prop: string): void {
This. count = this.count + 1 // reset count / triggers again on Count Changed / Death Cycle
}

/ / / ✅ Positive: Retweet only monitored variables, change only "other" status
@State @Watch('onCountChanged') count: number = 0
@State total: number = 0
onCountChanged(prop: string): void {
This. total = this. account * 10 / / read count, total, count itself
}
```

** KEY POINT / PLACE:**
1. ** Do not modify its listening variable (directly or indirectly) in the @Watch echo**, or die.
2. The callback is only for rapid operation; do not use async/await in @Watch (the hiking slows redoing).
3. Multiple variables are bound to the same @Watch and treated with `changedPropertyName` parameters.

---

## # scene 8: Sub-routine direct update @state to UI

** scene description: ** Place time-consuming tasks (data requests, decoding, volume calculations) in the TaskPool/Worker subroutine, with the interface not updated after the result has been completed; the same logical main-line process can be properly refreshed.

** Gene: ** Status variables such as @state drive UI to refresh the rendering line that relies on the main line,** status must be updated at UI (main) **. The result calculated in the sub-routine does not automatically flow back to the state of the main route - the value of the "drop" on the sub-routine does not trigger rendering; and the complex object of the @State / @Observed Decoration itself cannot cross-line.

** Diagnosis method: ** Upon completion of the sub-routine, UI will not move or move the same value to the main line, i.e., cross-line update.

**Solution:** Bring back the result of the sub-routine to the main route, which gives value to @state.

```ts
import { taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';

/ 1 One-time result: return + then (.then executes on main route, simplest)
@Concurrent
function heavyCompute(input: number): number {
Return input * 2 / / / sub-route
}
aboutToAppear() {
  taskpool.execute(heavyCompute, 42).then((res: number) => {
This.value = res / / main-line grant@state → UI normal refresh
  })
}

/ 2 Ongoing/ Streaming Output (e.g. Long Task): emitter returns normal data
const EVT = 1001
@Concurrent
function streamProduce(): void {
/ Continue output, send back "normal data" with emiter (not @state/@observed object)
  emitter.emit({ eventId: EVT }, { data: { v: newData } })
}
aboutToAppear() {
  emitter.on({ eventId: EVT }, (e: emitter.EventData) => {
@state
  })
}
aboutToDisappear() {
emit.off (EVT) / / Unsubscribe when destroyed to avoid leakage
}
```

** KEY POINT / PLACE:**
1. ** The state must be updated in the main thread**: the sub-linear writing / drop result does not trigger rendering.
2. One-time results are given priority `taskpool.execute(fn).then(res => this.x = res)`; ongoing outputs are used instead.
3. Emitter only transmits ** general data** (not an object for @State / @Observed decoration) and regrants state of main-line loop.
4. Emitter Subscriptions must be written off in `aboutToDisappear` to prevent leakage.

---

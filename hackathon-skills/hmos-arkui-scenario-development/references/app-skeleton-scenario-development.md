# Comprehensive application of the skeletal case set

# Functional points typically use scene comparison

| Type of skeletal skeletal | Typical use scene | Core competencies | Non-appliance scenario |
|------------|------------|---------|-----------|
| Navigation+ Breakpoint+Tabs | Information/Social/ElectroApp, sidebar at the bottom of the Tab ↔ flatboard on the cell phone | Page Stack Management + Multi-Equipment + Responsive Layout | Simple application without navigation on a single page
| Map Navigation Consolidated Page (Stack Layer + Float Panel) | Map Navigation App, Full Screen Map + Float Control + Bottom drawer | Layer Collapse + Independent Float Visibility + Hand Drag | Standard Linear Content Page

---

# Scene I: Build an Information/Social/Electro-Treatractive App Basic Page Bones, Multi-Equipment Dynamics

**Scene description**: Building basic page skeletons such as information/social/electronicer type App, requires a combination of top search bars (Search+Row), content areas, bottom multipage layouts with Tabbar, and adjusting the page structure (e.g. mobile phone endbar + bottom tab, tablet sidebar + two/three column layouts) to the type of equipment (cell phone/platform/fold screen).

**Solution**: Using Navigation as a root container, combining breakpoint systems (WidthBreakpoint/HeightBreakpoint), in-house using Row/Column to construct the navigation bar and content area, which selects a different response layout (e.g. GridRow, List, WaterFlow, etc.) based on a different tipping class, using Tabs or custom TabBar components at the bottom. Consolidated Composition Elements: The Navigation provides a stack management + breakpoint to provide equipment fit + Row/Column to provide a base layout + Content Area Responsive Layout + Tabs to provide a bottom navigation, with multiple components working together to construct a complete tripod application base skeleton.

```typescript
/ = = breakpoint state: both wide/high breakpoints require @watch When folded, the width changes at the same time)
@StorageProp('currentWidthBreakpoint') @Watch('onBreakpointChange')
currentWidthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
@StorageProp('currentHeightBreakpoint') @Watch('onBreakpointChange')
currentHeightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_LG;

/ = = BreakpointType: font size, icon size, content margin, list column scaling by breakpoint = =
private titleFont: BreakpointType<number> = new BreakpointType(18, 20, 24);
private contentPadding: BreakpointType<number> = new BreakpointType(16, 24, 48);
private listLanes: BreakpointType<number> = new BreakpointType(1, 2, 3);
private flowColumns: BreakpointType<number> = new BreakpointType(2, 3, 4);

/ = = breakpoint echo: full two-way map = =
onBreakpointChange(): void {
  this.isSmallScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_SM ||
    this.currentWidthBp === WidthBreakpoint.WIDTH_XS;
  this.isLargeScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_LG ||
    this.currentWidthBp === WidthBreakpoint.WIDTH_XL;
// Small Square = Horizontal sm + Vertical md
  this.isSmallSquareScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_SM &&
    this.currentHeightBp === HeightBreakpoint.HEIGHT_MD;
}

build() {
/ Navigation Root Container: Provides Pageboard Management
  Navigation(this.pathStack) {
    Column() {
/ / Top Navigator Bar: Small Square Screen compact layout / Large Screen Title + Search Syndication / Cell Phone Uplink Branch
      this.TopBar()

/ Tabs: Bottom Navigator (sm) side Navigator (lg)
      Tabs({
        barPosition: this.isLargeScreen ? BarPosition.Start : BarPosition.End,
        index: this.currentTab
      }) {
TabContent() {This. NewsContent()}/ List + plans
.tabbar (this.tabbarBuilder ('head page', 0))
TabContent() {This. ProfitContent()}/ / GridRow grid layout
.tabBar (this.tabBarBuilder ('Commodities', 1))
TabContent() {This. SocialContent()}/ WaterFlow Falls Flow Layout
.tabbar (this.tabbarBuilder (`community', 2))
      }
.vertical (this.isLargeScreen) / / Largescreen side navigation vertically
      .barWidth(this.isLargeScreen ? 96 : '100%')
      .barHeight(this.isLargeScreen ? '100%' : 56)
      .barMode(this.isLargeScreen ? BarMode.Scrollable : BarMode.Fixed,
        { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
      .layoutWeight(1)
    }
  }
  .mode(NavigationMode.Stack)
  .hideTitleBar(true)
  .navDestination(this.PageMap)
}

= = Top navigator: Toggle layout by device = = =
@Builder TopBar() {
  if (this.isSmallSquareScreen) {
/ Small square screen: Search box icon, title bar tight
    Row() {
Text ('Information'). FontSize (16). FontWeight.Bold.playoutWeight (1)
      Text('🔍').fontSize(20).onClick(() => {})
    }.width('100%').height(44).padding({ left: 12, right: 12 })
  } else if (this.isLargeScreen) {
/ Largescreen: Title + Search Box Peer Aggregation
    Row() {
Text ('Information'). FontSize (this.titleFont.getValue (this.currentWidthBp))
        .fontWeight(FontWeight.Bold).margin({ right: 24 })
Search ({placeholder: 'search information, goods, users...'}). playoutWeight(1).head(36)
    }.width('100%').height(56).padding({ left: 24, right: 24 })
  } else {
/ / Cell phone vertical: title and search box branches
    // ...
  }
}

// = = front page content: List + plans repeat layout as ListItemGrouphead = = =
@Builder NewsContent() {
  List({ space: this.listSpace.getValue(this.currentWidthBp) }) {
    ListItemGroup({ header: this.CarouselHeader }) {
      ForEach(this.getNewsItems(), (item: NewsItem, index: number) => {
        ListItem() {
          Row() {
            Column({ space: 4 }) {
              Text(item.title).fontSize(this.bodyFont.getValue(this.currentWidthBp))
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
/ ...source, time
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Image(this.getImage(index)).width(80).height(60)
              .objectFit(ImageFit.Cover).borderRadius(4)
          }.width('100%').padding(12)
          .onClick(() => { this.pathStack.pushPath({ name: 'newsDetail' }); })
        }
      })
    }
  }
  .lanes(this.listLanes.getValue(this.currentWidthBp),
    this.listSpace.getValue(this.currentWidthBp))
  // ...
}

= commodity content: GridRow + GridCol grid layout = = =
@Builder ProductContent() {
  Scroll() {
    GridRow({ columns: { sm: 4, md: 6, lg: 12 }, gutter: { x: 12, y: 12 } }) {
      ForEach(this.getProducts(), (item: ProductItem, index: number) => {
        GridCol({ span: { sm: 2, md: 2, lg: 3 } }) {
          Column({ space: 8 }) {
            Image(this.getImage(index)).width('100%').aspectRatio(1).objectFit(ImageFit.Cover)
            Text(item.name).fontSize(this.bodyFont.getValue(this.currentWidthBp)).maxLines(1)
/ ...price, label
          }.width('100%').padding(8)
        }
      })
    }
  }
  // ...
}

= community content: WaterFlow Falls Flow Layout = =
@Builder SocialContent() {
  WaterFlow() {
    ForEach(this.getSocialPosts(), (item: SocialPost, index: number) => {
      FlowItem() {
        Column({ space: 8 }) {
/ / / / / / / user information, content text, graphics, acclaim
        }.width('100%').padding(12)
      }
    })
  }
  .columnsTemplate(`repeat(${this.flowColumns.getValue(this.currentWidthBp)}, 1fr)`)
  // ...
}
```

# WidthBreakpoint

Element count values | width range | equipment type |
|--------|---------|---------|
Z`WIDTH_XS`  <600vp| Miniphone, folding inner screen
`WIDTH_SM` 600 – 840vp
Z`WIDTH_MD` |840–1200vp| Collapse screen development, small tablet
Z`WIDTH_LG` | 1200-1600vp | flat screen, 2in1|
`WIDTH_XL` ≥ 1600vp| Largescreen Device

HeightBreakpoint

| Equation values | Height range | Device type |
|--------|---------|---------|
`HEIGHT_SM` |320vp < collapsive screen |
Z `HEIGHT_MD` | 320–600vp | cell phone screen, small square screen
`HEIGHT_LG` 600 – 840vp
`HEIGHT_XL` ≥840vp| flat, large screen

# NavigationMode

Equation, behaviour, application of scenes,
|--------|------|---------|
`Stack` | Page Post Into Navigation | Cellular Line Bar |
`Split` | Barboard Navigation (left list + right details)
Z `Auto` | Automatically toggle from width

# # BarPosition Enumeration

Quantum count, position, applicable scene,
|--------|------|---------|
`Start` | Side (left when vertical layout)
`End` | Bottom (the bottom of the horizontal layout) | Bottom of the mobile

# BarMode Count

Equation, behaviour, application of scenes,
|--------|------|---------|
Z `Fixed` | Fixed width, no scroll | Small number of Tab |
`Scrollable` | Scrollable, Tab width adapted to | large screen multiple Tab side navigation |
`Auto` | Automatic selection based on content

# LayoutStyle Count (nonScrollableLayoutStyle)

Equation values, layout methods,
|--------|---------|
`ALWAYS_CENTER`
`SPACE_BETWEEN_OR_CENTER` | Centred when space is insufficient and distributed evenly enough
`AVERAGE_INTERVAL`| Average Spacing Distribution

# BreakpointType

| Methodology | Role | Example |
|------|-----|------|
`new BreakpointType(sm, md, lg)` | Different values by breakpoint
`getValue(breakpoint)` | Get the value of the current breakpoint

ImageFit count

| Equation values | Filling mode |
|--------|---------|
`Contain` | Equalize Zoom, full in the container
Z `Cover` | like scaling, filled with containers, possibly cut
Z `Fill` | stretch to fill the container with potential deformation
`None`| Original size, no scaling
`ScaleDown` | equal to scaling, not exceeding the original size

# TextOverflow

Equation values Behaviour
|--------|------|
Z `Ellipsis` | The excess is shown in ellipses
`Clip` ZEX ZEX ZEX ZEX ZEX
`None` zirconium does not process spills

# scene one, no writing

| Prohibition of writing | consequences | correct practice |
|---------|------|---------|
| Use `router.pushUrl` / `router.replaceUrl` instead of Navigation + NavPathStack | The wall is separated from NavDestination's route chart and cannot be managed in uncontrollable return links | Use ZXXKEEP2ZX + `.navDestination(this.PageMap)` registration route chart
| Unheard of breakpoint changes, hard-coding device type judgement (e.g. `if (deviceType === 'phone')`) | unable to adapt to dynamical changes such as folding screens to expand/ folding, tablet rotation | Use `@StorageProp('currentWidthBreakpoint')` + `@StorageProp('currentHeightBreakpoint')` + `@Watch('onBreakpointChange')` for a two-way map wide breakpoint
| No BreakpointType, Hard-coding fonts/margins/columns (e.g. `fontSize(18)` fixed value) | Breakpoint sizes do not change with the device, large screen fonts are too small or too large | Define difference values using `new BreakpointType(sm, md, lg)`, and take values through ZXXKEEP2ZX dynamic
| Tabs does not configure `barPosition` / `vertical` Toggle | Large screens still display bottom navigation, unrealised side navigation moves, waste of horizontal space | toggle `barPosition(BarPosition.Start/End)` + `vertical(true/false)` |

---

# scene II: Build Map Navigation App Consolidated Page, Cascading Float + Cashier Panel + Handprint Interactive

** Example scenario description**: Building a comprehensive page of the Map Navigator App, requiring simultaneous processing of the complex layers of full-screen map (floor) + floating panel (POI details) + interactive control buttons (positioning, zooming, layer switching), each layer requires independent control of the hidden and location.

**Solution**: Using Stack as a root container, map components are full of screens as the bottom floor, detailed panels are constructed using Column + List + RelativeContainer, and the bottom drawers are achieved by alignContent, the control button group is arranged by Row + Column and positioned at the top right corner of the alignContent, and the floats are independently controlled through state variables. Consolidated Composition Elements: Stack provides lasagna capacity + zIndex provides tier control + Column/Row/List/RelativeContainer provides internal layouts of the floats, with multiple components working together to construct complex map navigation interfaces.

```typescript
@state showLayerControl: boolean = false; / /Faceboard hidden
@state showTopBar: boolean = true; // / Topbar hidden
@state currentZoom: number = 17;/ / map scaling level
@state
@state MapOfffsetX: number = 0;/ / Map & X
@state MapOffsetY: number = 0;/ / MapStampY
@state MapScale: number = 2.3; / /map scaling

== sync, corrected by elderman ==
private fetchSafeArea() {
  const uiContext = this.getUIContext();
  const context = uiContext.getHostContext();
  window.getLastWindow(context).then((win: window.Window) => {
    const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this.statusBarHeight = uiContext.px2vp(avoidArea.leftRect.height);
    this.navBarHeight = uiContext.px2vp(avoidArea.leftRect.height);
    // ...
  });
}

/ = bottom floor: Maps full of screens to support slide + let go
@Builder MapBackground() {
  Stack() {
    Image($r('app.media.maps'))
      .width('100%').height('100%').objectFit(ImageFit.Cover)
      .scale({ x: this.mapScale, y: this.mapScale })
      .translate({ x: this.mapOffsetX, y: this.mapOffsetY })
  }
  .width('100%').height('100%').zIndex(0)
  .gesture(
// Cross-referenced gesture groups: single-finger drag or double-finger contraction Fire!
    GestureGroup(GestureMode.Exclusive,
      PanGesture()
        .onActionStart(() => { this.mapStartX = this.mapOffsetX; this.mapStartY = this.mapOffsetY; })
        .onActionUpdate((event: GestureEvent) => {
          this.mapOffsetX = this.mapStartX + event.offsetX;
          this.mapOffsetY = this.mapStartY + event.offsetY;
        }),
      PinchGesture({ fingers: 2 })
        .onActionUpdate((event: GestureEvent) => {
          this.mapScale = Math.max(0.5, Math.min(3.0, event.scale));
        })
    )
  )
}

= = Top navigator: Floating layer, gross glass material = =
@Builder TopNavBar() {
  Row({ space: 12 }) {
    Button('←').width(36).height(36)
      .backgroundColor(Color.Transparent)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
      .onClick(() => { router.back(); })
Text ('Map Navigator'). FontSize(18). FontWeight.Bold.playoutWeight(1)
    // ...
  }
  .width('100%')
  .padding({ left: 12, right: 12, top: this.statusBarHeight, bottom: 10 })
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
}

/ = = control button group: zoom + layer + position, position lower right corner through the outer layer
@Builder ControlButtonGroup() {
  Column({ space: 10 }) {
/ / Zoom button group: Vertically + / -
    Column({ space: 10 }) {
      Button('+').width(44).height(44).backgroundColor(Color.White)
        .onClick(() => { if (this.currentZoom < 20) { this.currentZoom++; } })
      Button('-').width(44).height(44).backgroundColor(Color.White)
        .onClick(() => { if (this.currentZoom > 1) { this.currentZoom--; } })
    }
// Layer / Positioning Button: Horizontally
    Row({ space: 10 }) {
      Button(this.showLayerControl ? '✕' : '☰').width(44).height(44)
        .onClick(() => { this.showLayerControl = !this.showLayerControl; })
      Button('◎').width(44).height(44).fontColor('#0A59F7')
    }
  }
}

/ = bottom drawer panel: Drag handles + Tabs (routing/POI details), overall response to drag gestures = =
@Builder DrawerPanel() {
  Column() {
/ Drag handle
    Row() {
      Column().width(40).height(4).backgroundColor('#CCCCCC').borderRadius(2)
    }.width('100%').height(44).justifyContent(FlexAlign.Center)

/ Tabs Suspended Page Signing: Route / POI Details
    Tabs({ index: this.drawerTabIdx, controller: this.tabController }) {
      TabContent() { Scroll() { Column() { this.RouteContent() } } }
.tabbar (new SubTabBarStyle ('Road' ). SelfedMode (Selected Mode.BOARD). board ({borderRadius: 80}))
      TabContent() { Scroll() { Column() { this.PoiDetailContent() } } }
.tabbar (new SubTabBarStyle ('Details'). Selfed Mode (Selected Mode.BOARD). board ({border Radius: 80}))
    }
    .barPosition(BarPosition.End).barMode(BarMode.Fixed).barOverlap(true).barHeight(48)
    .barFloatingStyle({ barBottomMargin: this.navBarHeight + 8 })
  }
  .width('100%').height(this.drawerHeight)
  .backgroundColor(Color.White)
  .borderRadius({ topLeft: 16, topRight: 16 })
  .parallelGesture(
    PanGesture()
      .onActionStart(() => { this.dragStartHeight = this.drawerHeight; })
      .onActionUpdate((event: GestureEvent) => {
        this.drawerHeight = Math.max(this.collapsedHeight,
          Math.min(this.expandedHeight, this.dragStartHeight - event.offsetY));
      })
      .onActionEnd((event: GestureEvent) => {
        const detents = [this.collapsedHeight, this.midHeight, this.expandedHeight];
/ / Quick Sliding: Jumping in the direction; Slow Drag: Sorbing the nearest slot
        let target: number;
        if (Math.abs(event.velocityY) > 1000) {
/ / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / // / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /  / / / / / / / / / / / / / / / / / / / / /  / / / / / / / / / / / / / /  /  /  /
        } else {
/ / ...slow-trawl suction logic
        }
        animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
          this.drawerHeight = target;
        });
      })
  )
}

/ = = POI Details: RelativeContainer Build Complex Element Layout = = =
@Builder PoiDetailContent() {
  RelativeContainer() {
    Text(this.pois[this.selectedPoiIdx].name).id('poiName')
      .fontSize(18).fontWeight(FontWeight.Bold)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
Text.id (`rating')
      .alignRules({ top: { anchor: 'poiName', align: VerticalAlign.Bottom }, /* ... */ })
/...distance, address, operation button
  }.width('100%')
}

build() {
/ Root packaging: Stack stacking, map full screen as bottom
  Stack() {
/ Bottom: Map
    this.MapBackground()

/ / Top Navigation Bar (top alignment)
    if (this.showTopBar) {
      Stack() { this.TopNavBar() }
        .width('100%').height('100%')
        .alignContent(Alignment.Top)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(2)
    }

/ Layer Selection Panel (above the bottom right control button)
    if (this.showLayerControl) {
      Stack() { this.LayerPanelContent() }
        .width('100%').height('100%')
        .alignContent(Alignment.BottomEnd)
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(9)
    }

// Control button group (bottom right)
    Stack() { this.ControlButtonGroup() }
      .width('100%').height('100%')
      .alignContent(Alignment.BottomEnd)
.opacity(/* narrow screens with drawers spread over the horizon*/)
      .hitTestBehavior(HitTestMode.Transparent)
      .zIndex(10)

/ Bottom drawer panel (bottom alignment)
    Stack() {
      Stack() { this.DrawerPanel() }
        .width(this.drawerWidthPercent).height('100%')
        .alignContent(Alignment.Bottom)
        .expandSafeArea([SafeAreaType.SYSTEM])
    }
    .width('100%').height('100%')
    .alignContent(Alignment.BottomStart)
    .hitTestBehavior(HitTestMode.Transparent)
    .zIndex(7)
  }
  .width('100%').height('100%')
  .onAreaChange((_, newValue: Area) => {
    this.screenHeight = Number(newValue.height);
    this.midHeight = this.screenHeight * 0.5;
    this.expandedHeight = this.screenHeight * 0.9;
/ System breakpoint determination drawer width: sm 100 / md 50 / lg 33 33%
    const bp = this.getUIContext().getWindowWidthBreakpoint();
    if (bp === WidthBreakpoint.WIDTH_LG) {
      this.drawerWidthPercent = '33.33%';
    } else if (bp === WidthBreakpoint.WIDTH_MD) {
      this.drawerWidthPercent = '50%';
    } else {
      this.drawerWidthPercent = '100%';
    }
  })
}
```

# Alignment Count

Quantum count, alignment, alignment.
|--------|---------|
`TopStart` | Top left corner  Z
`Top` ZO ZO ZO ZO ZO
`TopEnd` | Top right corner  Z
`Start` | Centre Left
`Center`
`End` | Centre right side |
`BottomStart` | Bottom left corner  Z
`Bottom` | Centred below
`BottomEnd` | Bottom right corner  Z

# HitTestMode #

Equation, behaviour, application of scenes,
|--------|------|---------|
`Default`| Default, both self and subpoint are involved in touch testing | Normal interactive area |
Z `Block` | does not respond to the touch itself to prevent subnode and lower-level reception
Z `Transparent` | does not respond to touch by itself, but subnodes and lower layers can receive events | Float-transmittance container |
`None` Zulu, neither itself nor the sub-node are involved in touch testing, Zau, pure decorative area, Zi.

# SafeAreaType

| Equation values | Security area type | Applicable scene
|--------|------------|---------|
`SYSTEM` | status bar, navigation bar etc. System area | top bar avoid status bar |
`CUTOUT` ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO ZO
`KEYBOARD`| Floppy Keyboard Area

# SafeAreaEdge

Quantum count, Quantum, Edge, Quincy.
|--------|---------|
`TOP` | Top edge
`BOTTOM` Bottom edge
`LEFT` | Left edge  Z
`RIGHT` | Right edge |
`ALL`

# BlurStyle Count

| | | |
|--------|----------|---------|
`BACKGROUND_THIN`  Z light and blurry background | top bar on map |
`BACKGROUND_REGULAR` ZEZX ZEX ZEX
`BACKGROUND_THICK` ZEZX ZEX ZEX ZEX
`BACKGROUND_ULTRA_THICK` ZEX ZEX
Z `COMPONENT_THIN` | Light Fuzzy Component | Button on Map |
`COMPONENT_REGULAR` | General Fuzzy Component | Control Background  Z
Z `COMPONENT_THICK` | Component thick and fuzzy
Z `COMPONENT_ULTRA_THICK` | Component super thick, fuzzy

# GestureMode

Equation, behaviour, application of scenes,
|--------|------|---------|
`Sequence` | Sequenceding gestures, in order of order
`Parallel` parallel gestures, identifying all gestures, multiple gestures taking effect simultaneously
`Exclusive`  Z cross-referenced hand gestures, identifying only the first triggers  Z drag and zoom

# Secured Mode (SubTabBarStyle)

| Equation Value | Selected Styles | Applicable scene |
|--------|---------|---------|
`INDICATOR` | Bottom indicator | General page sign |
`BOARD` | Border package | drawer page sign  Z
`LABEL`| Label Highlight | Label Page Sign

# Curve Enumeration (animateTo Animated Curve)

Quail, chute, curve, curve, curve, curve, curve, curve, curve, curve, lull, lull.
|--------|---------|---------|
`Linear` ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX
`Ease` Quick!
`EaseIn` | slow in, slow in, slow in, slow in, slow in.
`EaseOut` | slow out (Quick later) | slow down stop
`EaseInOut` X-ray slows in and out
`FastOutSlowIn` ZEX ZEX
`LinearOutSlowIn` ZeroZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiXiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiXiZiZiZiZiXiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZ
`FastLinearInSlowOut` Z0ZX Z0

#AvoidAreaType

Quantum count, Quote area, Zoom apply scene, Zoom
|--------|---------|---------|
Z `TYPE_SYSTEM` | Status Bar, Navigation Bar | Retrieving Security Zone Height |
`TYPE_CUTOUT` | Liu Hai/Pocket Area | Avoid Liu Hai
`TYPE_SYSTEM_INDICATOR` |System indicator
`TYPE_KEYBOARD` ZEX ZEX ZEX ZEX ZEX

# scene two, no writing

| Prohibition of writing | consequences | correct practice |
|---------|------|---------|
| Use Column + Absolute Positioning (`position`/`offset`) instead of Stack Layer Collapse | Can't Align with `alignContent`, Unable to use `zIndex` Control Level, Disrupted Float Cover Relationship | Use `Stack` Root Container + ZXXKEEP5ZX Position Float + `zIndex(n)` Control Level |
| Do not use `GestureGroup(GestureMode.Exclusive, ...)` to repulse the gesture group | single-finger drag and double-finger scaling trigger, hand-finger conflict leads to map horizontal and zooming interference | use `GestureGroup(GestureMode.Exclusive, PanGesture(...), PinchGesture(...))` to identify each other, responding only to the first trigger gesture |
| Float packagings without `hitTestBehavior(HitTestMode.Transparent)` | Float is full-screened, map cannot receive touch events, user cannot drag/scale map | Float layer `Stack` Set up `hitTestBehavior(HitTestMode.Transparent)` for event transmission, and child nodes remain interactive
`onActionEnd` does not use `animateTo` to directly set `drawerHeight` | height jumps into no smooth transition, users experience `animateTo({ duration: 250, curve: Curve.EaseOut }, () => { this.drawerHeight = target; })` to adsorpt animation
| Top bar does not use `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` | Top bar is blocked by status bar, content sinks and map overlaps are not natural | Use `expandSafeArea` Fit Status Bar + `padding({ top: this.statusBarHeight })` avoids statusbar height |

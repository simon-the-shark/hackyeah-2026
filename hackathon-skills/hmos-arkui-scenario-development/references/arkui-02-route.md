# Build base code logic based on UI frames - route entrance

# Route target #

After entering `ARKUI-02`, the secondary sub-scenes of the user's problem message continue to be judged and the corresponding resource files read. The secondary subsituation is not mutually exclusive; when the same issue involves multiple capabilities, it is essential that all resources be struck and read.

Output proposal:

```yaml
parent_scene: ARKUI-02
Primary sub scene: Core subscene ID
Secondary sub senses: [Other neutron scene ID]
next_scene_refs:
- The fate of the leaf document path
```

# The routing tree

```text
Enter basic code logical scene based on UI frames
│
Ideas-Step 1: Create Candidates
Ideas - Do not maintain sub-situation description in decision tree; all specific descriptions below refer to the "situation index"
Ideas - extract component names, APIs, interactive objects, UI behaviors and anomalies from user hints, codes, screenshots and errors
Ideas - indent signals to match all sub-scenes Set
│ - clarify API / component / echo / abnormal signal priority; page, component, interactive generic words only for use in support of judgement
│
Ideas - Step 2: Confirm the scope of application with applies whon
│ - Check each candidate's sub-scenes to see if applies whon covers real needs, objects and acceptance priorities
Ideas - Multiple applies whon were set up at the same time, all of which were kept.
│ -- if only inent signals hit but application wen does not work, does not act as Primary sub sense
│
Idem - Step 3: Fix Borders with Not applies whon
Idem - if not applies whon points to other sub-situations, downgrade or transfer the scene to a more appropriate sub-situation
Ideas - if a capacity is a subsidiary effect, classified as a subdary sub sensees, and an indication of its dependency on the main claim
│ - Select the most common page/component sub-situation in the scene index when the father's scene is hit but the sub-situation is not clear Bottom
│
Ideas - Step 4: Assisting decision-making at the decision-making stage with data
Ideas - REQ: Read statistics.REQ Defines page structure, interactive objects, navigational relationships, temporary UI, action, focus and focus
Ideas - DEV: Read components.DEV determine component structure, API selection, event link, life cycle and code skeleton
Ideas - FIX: Reading capabilities.FIX location abnormalities, parameter configuration, event distribution, resource constraints and re-entry points
│ - VAL: Read publications. VAL generate rendering, navigation, interaction, bullet windows, animation, focus, layout, images, lists and text authentication entries
│
└ - Step 5: Read hit resources
Ideas-primary sub scene takes the strongest and applies wen's most complete sub-scenes
Ideas - secondary sub senses records dependency, association and return to associated subscenes
Resource ref /Resource refs /Resource files
└- resource ref continues to be active when pointing to ROUTE.md; choice by user target if multiple types exist and read more if necessary
```

# Site Index

Interactive events such as ARKUI-02-01 gestures/keyboard

```yaml
scene name: Add interactive events such as gestures/keyboards to make user interactive
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./arkui-interaction/ROUTE.md
intent_signals:
- Hand gestures / hand gesture binding / hand gesture combinations / double-click / long by drag / inertial slide / squeezing / hand zoom / mask penetrating / touch hot zone / embedded scroll
  - onClick / onTouch / TapGesture / LongPressGesture / PanGesture / PinchGesture / RotationGesture / SwipeGesture / gesture / priorityGesture / parallelGesture / GestureGroup / GestureMode
  - responseRegion / hitTestBehavior / HitTestMode / onTouchIntercept / onChildTouchTest / onGestureCollectIntercept / monopolizeEvents / onGestureJudgeBegin / shouldBuiltInRecognizerParallelWith / onGestureRecognizerJudgeBegin / onTouchTestDone / nestedScroll
applies_when:
- Need to bind hand gestures for components or control the identification priority of the parent-son component for the same type of gesture (default / father / father / father / son )
- Need to achieve cross-fertilization of basic gestures such as clicks, double clicks, multiple clicks, long presses, drags, squeezes, rotations, quick slides
- Multiple single gestures need to be combined into complex interaction (sequence recognition / parallel identification / cross-repeated identification)
- Need to deal with touch distribution and hand gesture competition under the parent-son configuration (with touch thermal adjustment, touch test mode, default response order)
- Need to dynamically determine whether to respond to gestures during hand recognition, or to resolve multiple touch, internal gestures and self-defined gestures
not_applies_when:
- Component layout only does not involve interaction (as in ARKUI-02-03)
- Interactive animated effects are core needs (under ARKUI-02-05)
decisions:
  REQ:
- Identification of the desired outcome of the same type of gesture as the father and son component (child priority / father priority / father and son responding)
- Determine basic gesture type and trigger parameters (TapGesture number of hits, LongPressGesture Duration/repeat, PanGesture fans/direction/division, PinchGesture distance, RotationGesture angle, SwapGesture Slide distance and direction)
- Determines the combination mode of multiple gestures (Sequence sequence / Parallel parallel / Exclusive mutually) and derivative rules (e. g. double-click front, click delay ~300 ms)
- Determines the distribution strategy for the touch events under the father-son nest (default pass / block node / block brother / pass node / extend or reduce heat areas)
- Determine whether the dynamic interception or release of gestures (onGesture Judge Begin / onTouch Intercept / on ChildTouchTest / onGestureCollect Intercept) is required at the identification stage, and whether the components need to be monopolizeEvents
  DEV:
- Select handbanding: gesture (default son preference) / priorityGesture (father preference) / parallelGesture (father-son parallel) and use the GestureMask. Normal/IgnoreInternal shield component to make gestures
- Select a single gesture API and configure it by business parameters: TapGesture / LongPressGesture / PanGesture / PinchGesture / RotationGesture / SwideGesture
- Use the GestureGroup to declare gestures in mode (Sequence / Parallel /Exclusive) to ensure that the order of declarations is consistent with the cross-section/sequencing rule, and to reset onCancel
- Configure resonanceregion({x, y, width, head}) to adjust the touchhot area (support negative value extension, exceeding layout area)
- Configure hitTest Behavior (Default / None / Block / Transparent / BLONK HIRRCHY / BLONK DESCENDANTS) to control touch distribution, or return HittestMode by coordinates on TouchIntercept
- Configure paternity conflict resolution
- Configure multi-touched monopolistic, signature dynamic determination in parallel with built-in identifiers
  FIX:
- Checks whether the parent-son component binds to the type of gestures to match the GestureMask configuration for competing demands
- Check whether a single gesture parameter (number/long/distance/hand index/ angle) is in line with expectations for the timing of the recall
- Check the GestureGroup mode and sub-gap order (with double-click pre-rule and onCancel bottom)
- Check responseRegion range, HitTest Behavior mode and touch forward links under multilayer nest
- Checking gesture conflict resolution configuration (multi-touch monopolization, dynamic determination return value, built-in identifier parallel control)
  VAL:
- Recognition priority for parent-son components of the same type of gesture (gesture default / priorityGesture / parallelGesture)
- Validation of all types of single gesture triggers and retweet parameters (inertive slides velocityY/velocityX, hand scaling offset formula, rotation 90° adsorption)
- Combining gestures to verify overall association behaviour in Sequence / Parallel / Exclusive mode (including onCancel Pocket)
- multi-level embedded touch distribution and hand-response link validation (responseRegion / hitTest Behavior / on ChildTouchTest / onGestureCollect Intercept)
- Self-defined gesture determination interception / release and multi-touch confirmation (monopolizeEvents / onGesture Judge Begin / should Built InRecognizer Parallel With)
```

# ARKUI-02-02 Multipage Route & Navigation

```yaml
scene name: Multipage route and navigation
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./routing-navigation-scenario-development.md
intent_signals:
-Navigation / NavDestification / NavRouter / Page Jump / Page Route / Portal
- PushPath / PopPath / Turnover / Deep Link / Intercept
- Dynamic route / query NavDestinationInfo / NavDestinationSwitch / Unsensual Listen / Route Animation
applies_when:
- Multipage Jump, Return and Postboard Management (Navigation/Router)
- Inter-page parameter transfer and result echo
- Route interception and re-direction (authorization/entry interception/underline/AB test)
- NavDestination Page Level Configuration (directive control/simmering) and Transmodular Dynamic Route
- Start flash screen page, multi-end subbar fit (column/bibar/column)
- Page life cycle management (back and back/back intercept/sing) and sensorless listening (place/page information query)
- Page rotation animation (in association with ARKUI-02-05)
not_applies_when:
- Single page application does not involve page jumping
decisions:
  REQ:
- Determination of navigation options: preferred navigation (recommended); Router is a historical legacy, with only the continuation of old Router projects and no new projects
- Determine the page stream: jump process, parameter transfer, return Value
- Identification of route interception/magnification/redirection needs and multi-end sub-bar matching strategies
- Identification of life cycle needs (renewed/return confirmed) and trans-site needs (jointly with ARKUI-02-05)
  DEV:
- Base: Navigation + NavDestification + Router map.json; Parameter Pass Participation Returning with PushPathByName
- Interception/redirection: setInterception read willShow (readable data, non-interception), router map.json 's data declaration rule, getConfigInRouteMap() read
- Page-level configuration: preferredOrientation Declaration Direction Control (system auto-rehabilitation); cross-module Router Modeule+ Dynamicimport
- Collar fit: subbar replacePathByName (avoiding cage explosion)/column pushPathByName,onnavigationModeChange Sync,onNewParam+hideBackButton
- Life cycle selection: onShown (back and back)/onBackPressed/onNewParam (back and back); navDestinizationSwitch/queryNavDestinizationInfo
- Turnover: systemTranstion/customTransion/customNavContentTransion (mustfinishTransion)/geometryTransion (animateTo + Default Turnover)
  FIX:
- Check route configuration/port/parameter transfer
- Interception anomalies: misreading the data/entry page signrequireAuth to infinite loops
- Direction/subbar: Navigation is not covered to preferredOrientation failure/subbar wrongly uses push to explode
- Life cycle: Misuse of onWillShow (not triggered)/onBackPressed does not return true
- Turnover: geometryTransation is not within or without animateTo or default transfer/no transfer Here. Cut. Stay.
  VAL:
- Jump/return/parameter transmission verification
- Intercept verification (no log-in login, no back-up after log-in)
- Direction/column validation (self-restoration in direction, non-growth of bar, synchronization of breakpoint)
- Life cycle/turn-site validation (renewed triggers, return intercepts, animations not Carden)
```

### ARKUI-02-03 Component Build Basic Page

```yaml
scene name: Build basic pages with components
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - Column / Row / List / Grid / Scroll
- Tabs / Stack / Flex / Layout / Page Build
- Component Use / WaterFlow / Swiper
applies_when:
- Need to build a page layout using the ArkUI built-in component
- Need to achieve common UI models such as lists, grids, waterfalls, etc.
- Need to use the structure of the container components Tabs, Navigation, etc.
- Need to roll, refresh, lazy, etc.
not_applies_when:
- In relation to the definition of self-defined components (belonging to ARKUI-01)
- Core needs are interactive events, not layout (as in ARKUI-02-01)
- Core needs are animated effects rather than layout (as in ARKUI-02-05)
decisions:
  REQ:
- Determination of page structure: single / multiple / grid / waterfall/label Page
- Determination of rolling needs: vertical/horizontal/mixed
- Determination of the level of data: small static/medium dynamic/large latency Load
  DEV:
- Layout component: Column/Row/Stack/Flex/RelativeContainer
- List component: List + Listitem + LazyForEach
- Grid component: Grid + GridItem / GridRow + GridCol
- WaterFlow + FlowItem
- Scroll/Scroller control
- Tabs + TabContent
  FIX:
- Checking the layout nesting: whether the layout is reasonable and whether there is an unnecessary nesting
- Check list performance: use LazyForEach and set a reasonable cache
- Checking for scrolling conflicts: whether embedded scrolls are handled correctly
  VAL:
- Layout validation: page layout fit design Draft
- Scroll-validation: whether the scroll is smooth, if there's carton.
- Data loading validation: correct to load and refresh list data
```

# ARKUI-02-04 BLOCK/menu/Temporary UI

```yaml
scene name: Add temporary interactive/tip worlds such as bullet windows/menu Noodles.
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./dialog-menu-scenario-development.md
intent_signals:
  - AlertDialog / bindSheet / bindContentCover / bindPopup / bindMenu
- bindContextMenu / Toast / Promptaction / Customdialog / bullet windows
- Menu / Drop Down Menu / Semi-Model / Total Model
applies_when:
- Popup confirmation dialogue box, hint information required
- semi-modular/total-modular panels required
- Need to bind popup menus or context menus
- Need to show Toast hints
not_applies_when:
- The core need for a bullet window is a rerun animation.
- Temporary UI does not cover bullet windows/menu (e.g. notice bar)
decisions:
  REQ:
- Determination of type of bullet window: confirmation of bullet window/semi-modular/total-modular/menu/toast
- Determination of trigger: click/long press/gang/condition trigger
- Identification of interactive needs: confirmation/cancellation/option/input
  DEV:
- Confirming bullet windows: AlertDialog / Customized bullet windows
- Semi-modular: bindSheet configuration height, drag bars
- All-model: bindContantCover
- Popup menu: bindMenu/ bindContextMenu
- Tip popup bind Popup / Promptaction. showToast
  FIX:
- Check whether bullet window binding: bindSheet/bindContantCover is correctly bound
- Check status control: whether bullet window display/hidden state is properly managed
- Check the z-index level: whether the bullet windows are blocked by other components
  VAL:
- Window display verification: whether the bullet window was correctly ejected and closed
- Interactive validation: whether the interaction within the bullet window is normal
- Mask Validation: Whether the background mask is correctly displayed
```

# ARKUI-02-05 Animation and Page Transfer

```yaml
scene name: access system capability to apply animation and page rotation
phase_tags: [REQ, DEV, FIX, VAL]
resource_files:
  - file: ./animation-transitions-scenario-development/property-animation-scenario-development.md
type: Properties Animation
  - file: ./animation-transitions-scenario-development/custom-property-animation-scenario-development.md
type: Custom attribute animation
  - file: ./animation-transitions-scenario-development/transition-animation-scenario-development.md
type: rotation animation
  - file: ./animation-transitions-scenario-development/modal-transition-animation-scenario-development.md
type: Modular rotation animation
  - file: ./animation-transitions-scenario-development/shared-element-animation-scenario-development.md
type: Share Element Animation
  - file: ./animation-transitions-scenario-development/component-animation-scenario-development.md
type: Component Animation
  - file: ./animation-transitions-scenario-development/frame-animation-scenario-development.md
type: frame animation
intent_signals:
  - animateTo / animation / TransitionEffect / "@AnimatableExtend"
  - geometryTransition / createAnimator / AnimatorResult / curves
- SpringMotion / Animation / Turn
applies_when:
- Requires the implementation of attribute animations, trans-field animations, shared element animations, model animations, component animations or frame animations
- With @animateExtend Custom Animable Properties
- In relation to CreateAnimator frame-by-frame control
not_applies_when:
- It's not about animation.
- Only the model ejection logic does not involve transmutation animation (as in ARKUI-02-04)
decisions:
  REQ:
- Determination of animation type: property animation/autometric/turning/modular animation/sharing elements animation/component animation/frame animation
- Determination of the object properties and parameters of the animation (long/curve/delayed/duplicate)
  DEV:
- Properties animation: animateTo /.animation()/curves.springMotion()
- Custom Properties Animation: @AnistableExtend + Custom Type (plus/subtract/multiple/equals)
- Transverse Animation: TranstionEffect (OPACITY/SLIDE/MOVE/ROTATE/SCALE)+animateTo trigger
- Modular rotation: bindSheet / bindContentCover + TransportEffect
- Shared Elements: / NodeController / CustomNavContentTransion
- Component Animation: TranstionEffect + delay / Attributemodier / Grid.editMode
- Frame Animation: CreateAnist + onFrame/onFinish/onRepeat
  FIX:
- Check for animation triggers: change of state in the echo and binding of a transtion to condition rendering component
- Checking performance: Animation leads to Carton.
  VAL:
- Is animation, fluidity and interaction normal?
```

# ARKUI-02-06 Focus Event and Focus Control

```yaml
scene name: Focus event and focus control
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./arkui-focus/ROUTE.md
intent_signals:
- Focus / Focus / Focus / Focus Out / Focus Box / Default Focus / Cycle Focus
- Active Focus / onFocus / onBlur / Focurable / defaultFocus / requestFocus / clearFocus
  - focusOnTouch / focusBox / stateStyles / outline / nextFocus / FocusController
applies_when:
- Need to control focus activation, configure component focus capabilities and focus box styles, or listen to focus/outsight events associated UI performance
- Focus grabs and follows when level page switching needs to be addressed, or sets the default focus and focus group focus priority
- Need to control focus moving behaviour, including key/click/passive focus, focus algorithm selection, custom focus sequence and active/outline
not_applies_when:
- Not focus only in relation to click/touch events (from ARKUI-02-01)
- The animated effect of the change of focus is core needs (as in ARKUI-02-05)
decisions:
  REQ:
- Identification of components for focus (default difference for three components) and focus preconditions (enabled/visibility / FocusOnTouch)
- Determine focus activated mode of entry (focusOnTouch click/touch active focus vs FocusController.activate(true) API 18+)
- Determines the focus box scheme (focusBox adjustment system default vs stateStyles + outline fully custom) and the timing
- Determines the need for a focused/out-of-focal event listening (onFocus / onBlur) and associated UI performance (e.g. floating tag animation, multi-input box focus tracking)
- Determines the focus capture policy for the focal point interface (Page / Dialog / Menu / Popup / Navbar / NavDestination)
- Determines the default FocusFocus and the subnode priority for the first focus of the container
- Determine the focus algorithm (Column / Row / Flex linear focus vs RelativeContainer projection focus)
- Determines the self-defined focus order (textFocus Six / TabIndex / Cycle Focus) and the active focus/heat timing (requestFocus / clearFocus)
  DEV:
- Configure components for focus: Focusable (default focus difference for three components) +enabled / Vision / Focus OnTouch Precondition + Packaging Focus Precondition
- Configure Focus Activation: Focus OnTouch Click/ Touch Active Focus, or FocusController.activate(true) (API 18+)
- Configure focus box styles: ForcusBox adjust the system default focus box, or stateStyles+outline is fully customised
- Bind onFocus / onBrur event echo, connect UI expression (floating tag animation, multi-entry box focus tracking)
- Configure Level Page Focus Following: Page / Dialog / Menu / Popup / Navbar / NavDestination Switching Focus and Default Focus
- Configure defaultFocus level pages for first display effective and focus / focus priority
- Select the focus algorithm: Column / Row / Flex linear focus vs RelativeContainer projector Move! Focus
- Configure nextFocus (forward / backward / up / down / left / right) custom focus orientation, or TabIndex
- Call FocusController.requestFocus / clearFocus active focus/out of focus and configuration of focused components to respond to car/space trigger click
  FIX:
- Check the focus activated state and focus box configuration (focusable /enabled /visibility / focusOnTouch invalid, container drawing focus box premise)
- Checking of components for focus capacity (a default focus capability difference for three components, precondition for container drawing focus frames)
- Check onFocus / onBlur whether the call triggers and the connection UI is normal
- Check default focus and focus group configuration (defaultFocus level page displays first-time timing, focus group and focus priority)
-Check whether requestFocus / clearFocus calls (target id exists, cross-level page limits)
- Check level page toggle focus following (Page / Dialog / Menu / Popup / Navbar / NavDestination focus capture and loss)
- Check the focus and focus algorithm type of the key (director keys are stuck, projection is out of order)
- Check nextFocus / TabIndex configuration (head finger, Snackbar three pairs, loop focus disconnected)
- Check for passive focus (component remove / attribute change / hierarchy page switching leading to lost focus)
  VAL:
- Focus Active Entry/Exit, Focus Box Display and Style Validation (focusBox Adjustment vs stateStyles + outline custom)
- Validation of the focus and uniqueness of the various components (default focus of the three components+enabled / Vision / FocusOnTouch)
- OnFocus / onBlur UI Performance Validation
- Level Page Focus Validation (Page / Dialog / Menu / Popup / Navbar / NavDestification)
- Focused Algorithm Behaviour Validation (Column / Row / Flex Linear Focus vs RelativeContainer Projection Focus)
- nextFocus / TabIndex custom focus order validation (Snackbar Tab closed circle + List loop focus + Direction key/ Tab key loop)
- FocusController. requestFocus / clearFocus active focus/out-of-focus validation
- Focused component responding to back-to-car/space trigger click and key event bubble verification
```

# ARKUI-02-07 Comprehensive Page Bones

```yaml
scene name: Integrated Page Bones
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./app-skeleton-scenario-development.md
intent_signals:
- Dropped App bone / Multi-Equipable / Breakpoint Response / WidthBreakpoint / HeightBreakpoint
-BreakpointType/ Map Navigator / Stack Layer/ Floating Panel / drawer Panel
- Responsive Layout / NavigationMode / BarPosition
applies_when:
- Need to build an information/social/electrician-type App base-page skeleton (multi-equipment, breakpoint response, column layout)
- Need to build a map navigational combination page (scramble float, drawer panel, hand gesture interaction)
- Need to adjust the page structure to the dynamics of the type of equipment (cell phone/plating/folding)
not_applies_when:
- Simple application with no navigation on single page (from ARKUI-02-03)
- Only a single layout component selection (under ARKUI-02-10)
decisions:
  REQ:
- Determines the skeletal type of the page: tripped App base skeletal vs map navigation synthesis page Noodles.
- Determines equipment suitability policy: Breakpoint system (WidthBreakpoint/HeightBreakpoint)+BreakpointType scale
- Determination of navigation mode: Navigation Mode. Stack/Split/Auto
  DEV:
- Navigation + breakpoint + Tabs + Row/Column + Content Area Responsive Layout (GridRow/List/WaterFlow)
- Map Navigator Page: Stack Layer + Map Bottom + Floating Panel (Column/ List/ RelativeContainer) + Control Button Group + Checkboard (hand positions drag + adsorption)
- Breakpoint echo: onBreakpointChange 2-way map +BreakpointType font/ icon/ margin/ column indentation Fire!
  FIX:
- Check if breakpoint echoes cover wide, two-way changes (fold screens expand and fold)
- Check Tabs barPosition/barWidth/barHeight for breakpoint switching
- Check the drawer panel tow and ads logic.
  VAL:
- Multi-equipment fit-validation: switch to the sidebar at the bottom of the Tab Plate
- Map floats interact with gestures.
- Tow-to-tape check for drawers.
```

##ARKUI-02-08 Custom Component (FrameNode)

```yaml
scene name: Custom Component (FrameNode)
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./custom-component-scenario-development.md
intent_signals:
  - DrawModifier / AttributeModifier / GestureModifier / ContentModifier / FrameNode / RenderNode
  - BuilderNode / XComponent / drawBehind / drawFront / applyGesture / applyContent
- type Node. Create Node / NodeController / NodeContainer / LockCanvas / Customized / Multiform Styles
applies_when:
- Need to customize the drawing (DrawModifeier Gradual Border/Exterior light/ neon/ pattern background)
- A multi-state button style (Attribute Modifier Q: Normal/Press/Focus/ Disable) is required
- Need dynamically toggle gestures (GestureModifier runs toggle gesture type)
- Component content area needs to be replaced (ContentModifeier Button icon + text/Checkbox collection switch)
- Requires JSON drive dynamic form (FrameNode + typeNode. Create Node to add and delete nodes while running)
- Requires handwritten signature for real-time drawing (RenderNode + drawing.Path redrawing)
- Need information flow ads.
- XCommponent Surface is required to customize drawing (lockCanvas/unlockCanvasAndPost)
not_applies_when:
- Use only standard attribute configurations for system components (belonging to ARKUI-02-03)
- Not involving advanced self-defined capabilities such as Frame Node/Modifeer/XComponent
decisions:
  REQ:
- Determines the self-defined capacity type: DrawModifier (drawing)/ Attribute Modifier (attributions)/GestureModifier (porture)/ContentModifier (content)/FrameNode (dynamic node)/RenderNode (render Node)/ Builder Node (mix construction)/ XComponent (Surface)
- Determines the level of custom drawing: drawBehind (background level) vs drawFront (foreground level)
- Establishment of dynamic node management strategy: appendchild/removechild (retention status) vs rebuild (reconstruction of whole tree)
  DEV:
- DrawModifier: DrawBehind/DrawFront + drawing. Brush/Pen + canvas.DrawRect/DrawCircle (vp2px conversion)
- Attribute Modifier:apply NormalAtribute/applyPressedAtribute/applyFocusedAtribute/applyDisabledAtribute
-GestureModifier:applyGesture+PanGestureHandler/PinchGestureHandler/RotationGestureHandler Dynamic Switch
-ContentModiifier:applyContent returns WrappedBuilder + ButtonConfiguration/CheckBoxConfigration
-FrameNode: typeNode. Create Node (ctx, 'Column') root container + appendchild/removechild dynamic add or delete
- RenderNode: rewrite draw. Path + validate() redraw frame by frame
- Builder Node: built (wrappedBuilder, params) + rebuild() dynamic update
- XComponent: SURFACE Type + lockCanvas/ unlockCanvasAndPost + drawing. Brush
  FIX:
- Check the DrawModiifier coordinates (context. size returns vp, canvas needs px, convert with vp2px)
- Checks whether ConstantModifier custom attribute triggers refreshing (driven by config. selfed)
- Check if the FrameNode root container uses typeNode.createNode (normal new Frame Node undeployed policy)
- Check whether the RenderNode Path coordinates are px (vp2px conversion required)
- Check if XComponent clears the previous frame before each drawing
  VAL:
- Custom drawing effect validation (gravity border/exterior light/ neon lamps)
- Multi-state Style Four-State Switch Verifier
- Dynamic node additions, deletions and status retention verification
- Handwritten signature handwriting and revocation/cleaning certification
- Information flow advertising first and then fill in.
```

## ARKUI-02-09 BLOCK MOW

```yaml
scene name: window menu entry case
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./dialog-menu-scenario-development.md
intent_signals:
  - levelOrder / focusable / autoCancel / isModal / maskRect / openCustomDialog
  - ComponentContent / showDialog / showActionMenu / ActionSheet / DatePickerDialog / TimePickerDialog
- TextPickerDialog / CalendarPickerDialog / TranstionWindow Animation / BulletWindow Level / Motion Control
applies_when:
- Need window level management.
- Need for masked control (autoCancel/isModal/maskRect Visibility/interactive/regional control)
- Need for dynamic updates on bullet windows (ComponentContant.update)
- Need a bullet window without focus (focusable:false search proposal/column)
- Need window transition animation
- Selectors need to be selected (DatePickerDialog/TimePickerDialog/TextPickerDialog/CalendarPickerDialog)
-ShowDialog Profise is required to confirm the dialogue box or the operating menu (showActionMenu Profise)
not_applies_when:
- Basic window confirmation/menu only and no hierarchy/membracing/dynamic updating/focus/animation, etc. capability (under ARKUI-02-04)
- The core need for a bullet window is animation of the field.
decisions:
  REQ:
- Determine the type of bullet window: AlertDialog/ActionSheet/showDialog/showActMenu/openCustomDialog/@CustomDialog
- Determination of progression needs: tier management/moderation control/dynamic update/focus control/blast animation
- Identify the bullet window and how it interacts.
  DEV:
- Level management: level Order: Level Order.clamp(n) controls the order of bullet window covering
- Monument control: autoCancel/isModal/non-mode/maskRect (local mask)
- Dynamic Update: ComponentContent + openCustomdialog + center.update (newParams)
- Focus control: Focusable: false bullet windows do not get focus without keyboard
- Animation of bullet windows: transtion effect.OPACITY/translate/scale +.animation
- Selector: DatePickerDialog/TimePickerDialog/TextPickerDialog/CalendarPickerDialog
-ShowDialog/ showActionMenu + Profise returns result.index
  FIX:
- Checks whether the level Order values are correct (higher over low)
- Check if autoCancel/isModal/maskRec configuration meets the mask requirements
- Check whether Component Content.update correctly updates the bullet window
- Check whether Focusable: false keeps the floppy keyboard. Rise
- Check translation animation parameter configuration
- Check whether Component Content.dispos() releases resources
  VAL:
-Window-cover verification.
- masked invisible/interactive/regional control certification
- Dynamic update validation
- Focus on validation.
- Validation of window animation.
```

# ARKUI-02-10 Layout Component Build Page Frame

```yaml
scene name: layout component setup page frame
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - Column / Row / Stack / Flex / RelativeContainer / GridRow
- GridCol / DynamicLayout / Tabs / alignrules / chainMode / Layout
- linear layout / laminate layout / flex layout / relative layout / grid layout
applies_when:
- Selection of layout components (linear/layer/flexible/relative/breed/dynamic/optional) to build a page frame
- Need to compare layout options.
- Responsive grid layout (GridRow/GridCol multi-equipment column matching)
- Need to flatten complex 2D layout.
- Need to switch layout to data source and maintain status (DynamicLayout)
not_applies_when:
- Use only a single layout component and not a layout selection comparison (in ARKUI-02-03)
- related to the integrated application of the skeletal skeletal (at ARKUI-02-07)
decisions:
  REQ:
- Determine layout type: Linear (Column/Row)/ Stack/ Flexi/ RelativeContainer/ GridRow/ GridCol)/ Dynamic (DynamicLayout)/ tabs
- Determine whether a responsive layout is required (multi-equipment column matching)
- Determine whether flat layout is required (reduced nested layers)
  DEV:
- Linear layout: Column/Row + space + playoutWeight + Blank + justyContent/alignItems
- Cascade layout: Stack + alignContant
- Flex + direction/wrap + flexShrink(0) compression
- Relative layout: RelativeContainer + alignrules anchor position + chain Mode layout
- grid layout: GridRow({columns}+ GridCol({span}) 24 grid system
- Dynamic layout: Dynamic Layout + Column Layout Algorinthm/Grid LayoutAlgorinthm/CustomLayoutAlgorinthm
- tabs: Tabs + TabContant + TabsController + scrollable
  FIX:
- Check whether the layout nest is reasonable (are there unnecessary?
- Check if Flex tabs set flexShrink(0) to compress
- Check that RelativeContainer component has the id + alignrules anchor
- Check that GridRow/ GridCol span values match the target columns
  VAL:
- Layout Performance Validation (deficient with the draft)
- Response column validation (multi-equipment column switching)
- Layout toggle for validation (DynamicLayout)
```

## ARKUI-02-11 Graphical component image presentation

```yaml
scene name: Graphic component image presentation
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./media-image-scenario-development.md
intent_signals:
  - Image / ImageAnimator / objectFit / alt
ImageFrameInfo / AnimationStatus / FillMode / Photo Presentation
- Animation / Sequence Frame
applies_when:
- need to display static pictures (local resources/network URL/PixelMap)
- Need to load a picture of failed position map
- Sequence frame animation required (live gift effects/images/directive animation)
not_applies_when:
- Need to customize drawing on Surface (as ARKUI-02-08 XComponent)
- Not involving pictures or frame animations
decisions:
  REQ:
- Determines the type of graphic component: Image (static pictures) vs ImageAnimator (sequence frame animation)
- Identification of photographic data sources: local resources/network URL/PixelMap
- Identification of filling methods: Contain/Cover/Fille/ScaleDown
  DEV:
-Image: src + objectFit + alt (position map)+ onError/onComplete
    - ImageAnimator：images（ImageFrameInfo[]）+ state + iterations + reverse + fillMode
- Frame Animation Resource: $rawfile('xx.png') returns Source type
  FIX:
- Check whether Image objectFit meets the filling requirements
- Check if ImageAnimator images support dynamic updates (not supported, conditioned)
- Checks if the serial frame resource references use $rawfile()
  VAL:
- Photo presentation and location map validation
- Frame animation/suspend/cut control authentication
- Frame Animation Cycle and Fill Mode Validation
```

## ARKUI-02-12 Roll list of components

```yaml
scene name: rolling list of components
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - List / ListItemGroup / ArcList / ArcListItem / Grid
  - GridItem / WaterFlow / FlowItem / sticky / swipeAction
- columnsTemplate / Group Suction / Slide Delete / Falls
applies_when:
- Single-column list needs to be achieved (group-sucking/sliding/drop-sorting)
- Arc list needs to be achieved (smart watch circle screen fit)
- Need to achieve a grid (high nine-gauge/fixed-class)
- We need to achieve waterfalls.
not_applies_when:
- Not involving scrolling components such as lists/grids/waterfalls (from ARKUI-02-03)
- related to the integrated application of the skeletal skeletal (at ARKUI-02-07)
decisions:
  REQ:
- Determines the type of scrolling component: List (single-linear)/ ArcList (argument)/ Grid (multi-column high)/ WaterFlow (multi-column high)
- Determine list functional needs: group suction/sliding/slapping/slapping/slapping Load
- Determine the number and spacing of grid columns
  DEV:
-List: ListItemGroup (grouping)+sticky+slideaction
- ArcList: ArcListItem + circle screens fit
    - Grid：columnsTemplate（'1fr 1fr 1fr'）+ rowsGap/columnsGap
- WaterFlow: ColumnsTemplate + FlowItem AutoPremise
  FIX:
Check if List Sticky is right to suck the top.
- Check that Grid columnsTemplate matches the target column.
- Check whether WaterFlow correctly places the shortest column
  VAL:
- Group Top/Slide Delete Authentication
- Validation of grid columns and spacing
- Misarranged waterfalls.
```

### ARKUI-02-13 Text Component Text Presentation

```yaml
scene name: text component text presentation
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./text-component-scenario-development.md
intent_signals:
  - Text / TextInput / RichEditor / SymbolGlyph / MutableStyledString
  - Span / ImageSpan / setTypingStyle / replaceStyle / ImageSpanAlignment
- Rich text / Keyword Highlight / Toggle / System Icon
applies_when:
- Text display required (defined style/super-long omitted/expanded)
- Text input required (multiple type of input/backboard/form validation)
- Need for rich text editing (coarse/italic/colour/mixed text editing)
- System icon required (SymbolGlyph system-level dynamics)
- Properties string highlight (keywords colour high) required
- Text + Span + ImageSpan required
not_applies_when:
- does not involve text components (from ARKUI-02-03)
decisions:
  REQ:
- Determines the type of text component: Text (read-only presentation)/ TextInput (single-line input)/ RichEditor (rich text editor)/SymbolGlyph (system icon)/ MutableStyledString (responsible string)/Text+Span+ImageSpan (text mix)
- Determines text style requirements: font size/bold/line height/word spacing/ alignment/decoration lines
- Identification of type of input: Normal/Password/Email/Number/PhoneNumber
  DEV:
    - Text：fontSize/fontWeight/lineHeight/letterSpacing/maxLines/textOverflow/decoration
    - TextInput：type（InputType）+ placeholder + onChange + maxLength
- RichEditor: RichEditorController + setTypingStyle
    - SymbolGlyph：fontColor + renderingStrategy + symbolEffect（BounceSymbolEffect）
    - MutableStyledString：replaceStyle + StyledStringKey.FONT + TextController.setStyledString
- Text + Span (text clips) + ImageSpan (line pictures) + verticalAlign
  FIX:
- Checks whether Text maxLines + textOverflow is correctly omitted
- Check whether TextInput type corresponds to the correct keyboard
- Checks whether RichEditor setTypingStyle applies style correctly
- Checks if MutableStyledString ReplaceStyle is correct.
- Check if ImageSpan verticalAlign is aligned
  VAL:
- Text styles and omitted authentication
- Type of input and keyboard authentication
- Free Text Edit Style Authentication
- System icon kinetic validation
- Keyword Highlight Verification
- Tic-text verification.
```

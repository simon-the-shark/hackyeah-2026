# ArkUI Basic Syntax: Route entrance

# The routing tree

```
Enter ArkUI Basic Syntax scene
│
Ideas - Step 1: Does it involve ArkUI basic ui capacity?
│   │
│ Trigger signal (cut by any of the routes and position according to the hit capability chapter):
@ API Keyword: @BuilderParam / @Component / @ComponentV2 / @Builder /
│   │      @LocalBuilder / @Styles / @Extend
│. Interactive Intent: UI position / UI slot / Replaceable UI/ Bottom render / Custom component/
│ has a status component / no status clip / cross file reuse / local reuse / V1 V2 Decorator/
│ style reuse / generic style / exclusive style / parameterized style / style group extraction
• Scene feature: component external exposure to replace UI entrance; custom UI unit reuse;
There are a lot of duplicate style groups in the page that need to be extracted
│   │
Ideas - Any signal hit BASIC-01
BASIC-01
Step 2
│
Ideas - Step 2: Does it involve basic extension capacity (component plant dynamic distribution / custom layout containers)?
│   │
│ Trigger signal (cut by any of the routes and position according to the hit capability chapter):
• API Keyword: WrapBuilder / WrappedBuilder / onMeasureSize /
│   │      onPlaceChildren / child.measure / child.layout / SizeResult
│ Interactive Intent: Component Plant / Dynamic Distribution / type Render / Multitype
│ Custom container / Custom layout / Drag-and-crowd place reorder
• Scene characteristics: the same container is replete with many variants by data type and needs to be extended;
│ Packagings in the system (Row/Column/Grid/WaterFlow) cannot be satisfied and needs to be custom-defined unique layout
│   │
ZOXKEEP0ZX.
BASIC-02
Step 3
│
└ - Step 3: Does it involve basic reuse capability (component reuse/ list reuse / V1 V2 reuse difference)?
    │
│ Triggers a signal (by any of the hits, i.e. by the route, and is located according to the hit capability section):
· API keyword: @Reusable / @ReusableV2 /useId /use /
    │      LazyForEach / IDataSource / Repeat / virtualScroll / cachedCount /
    │      aboutToReuse / aboutToRecycle / BuilderNode / NodeContainer /
    │      NodePool / wrapBuilder / reusePool / poolAccepts
• Interactive intent (user expressions often do not use the word “repeal”, especially if dynamic invisible):
│ Component Reuse / List Item Reuse / Reuse Pool / Scroll Reuse / Multitype List Item / News List / Infoflow /
│Repeat / Global Reuse Pool / Placeholder / V1 V2 Reuse Difference
│ Dynamic Visible Class: Expand Collection / Collapse / Show Hidden Switch /
│ Login state switching / if condition rendering / frequent switching to avoid reconstruction
• Scene feature: long list rolling re-use; multitype by type pool; cross Tab global re-use;
│ If control component dynamic Visibility (expanding collection/entry switch), node mounted/unmounted with conditions
    │
Idea-- Hit any signal.
BASIC-03
```

# Site Index

# BASIC-01 ArkUI Basic ui scene

```yaml
scene_id: ARKUI-BASIC
scene name: ArkUI baseui scene
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-ui.md
```

# BASIC-02 base extension

```yaml
scene_id: ARKUI-BASIC-EXT
scene name: ArkUI base extension
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-extension.md
```

# BASIC-03 Basic reuse scene

```yaml
scene_id: ARKUI-BASIC-REUSE
scene name: ArkUI base reuse
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-reuse.md
```


# Basic reuse scene

** Component reuse of overall architecture:**
! [Single-type list item reused structure] (...././assets/use-strutt.png)

Key API(V1 / V2):

- `@Reusable` / `@ReusableV2`: Markable components can enter the reuse pool (ZXXKEEP2ZX requires API 18+)
- `reuseId`: The same ID shares a reused pool with the default name of the component ID when passed; V1 with `.reuseId('xxx')`, V2 with `.reuse({ reuseId: () => 'xxx' })`
- Data update: V1 automatically reset with `@State`+ by `aboutToReuse(params)`; V2 with `@Param`

# SCENE-01 One-type list item

**Applied scene: **All item layouts in the list are fully consistent (e.g., unified structure message items, trade cards, bulletin entries) and larger data volumes require long scrolling lists. Direct `ForEach` rebuilds sub-components in full amount at data change; `LazyForEach` in conjunction with reusable components allows reusable examples of components rolling out of the visual area to enter the re-use pool, directly reuses and updates the data when required, and avoids recreated/destroyed frame rate and memory vibration.

** Core mechanism:** The example of the component rolls out of the visual area and does not destroy it, but enters the re-use pool of the corresponding component (defaultly identified as the re-use pool); next time the same component is required, the re-use is removed directly from the pool. The way in which data are updated varies according to the status management version:

- **V1 (`@Reusable` + `@Component`)**: frame echo `aboutToReuse(params)`, developer manually assigns new data to `@State`
- **V2 (`@ReusableV2` + `@ComponentV2`, API 18+)**: Auto-replace `@Param` with the new value that is being used for this call, without manual grant (V2 provides `aboutToRecycle` / `aboutToReuse` life cycle echo, no reference, only for side effects)

** Steps to be taken:**

1. ** Declared reusable sub-component**: V1 with `@Reusable` + `@Component`, `@State` with data changes; V2 with `@ReusableV2` + `@ComponentV2`, `@Param` with `title` / `from` / `tail` with type consistent with parent level)
2. **Data update achieved**: V1 rewrite `aboutToReuse(params: Record<string, Object>)` grant to `@State`; V2 automatically reset by `@Param` without rewriting
**Rendering list**: V1 with `LazyForEach (datasource, item => subcomponents ({...field}), item = > key) `(data source `IDataSource`); V2 returns ZXXKEEP2ZX (data source group). ZXXKEEP2Z controls the predivide range, with examples of over-scope policies entering the use room

**V1 Code:**

```typescript
/ / / 1 Mark reusable components with @Reusable, @state declare field changes with data
@Reusable
@Component
struct ItemView {
  @State title: string | Resource = '';
  @State from: string | Resource = '';
  @State tail: string | Resource = '';

/ / 2 rewrite about ToReuse: remove new data values from Params before components are reused to @State
  aboutToReuse(params: Record<string, Object>): void {
    this.title = params.title as string;
    this.from = params.from as string;
    this.tail = params.tail as string;
  }

  build() {
    Column() {
      Text(this.title)
      Row() {
        Text(this.from)
        Text(this.tail)
      }
    }
  }
}

@Component
export struct OneTypeItemPage {
  private dataSource: ItemDataSource = new ItemDataSource();

  aboutToAppear(): void {
    this.dataSource.pushArray(genMockItemData(1000));
  }

  build() {
    NavDestination() {
      List() {
        LazyForEach(this.dataSource, (item: ItemData) => {
/ 3 Call sub-components into fields (defaultly repeated by component name ItemView)
          ItemView({ title: item.title, from: item.from, tail: item.tail })
        }, (item: ItemData) => item.id.toString())
      }
/ / 3 cardedCount (1) controls the preview range, with expansive examples entering the default reuse pool
      .cachedCount(1)
    }
  }
}
```

**V2 Code:**

```typescript
/ / / 1 Mark reusable components with @ReuseableV2 (need @componentV2), @Param declare fields with data changes
@ReusableV2
@ComponentV2
struct ItemView {
  @Param title: string | Resource = '';
  @Param from: string | Resource = '';
  @Param tail: string | Resource = '';

/ / 2 V2 Recycle (both without reference): Trigger about ToReuse, trigger about ToRecile
/ / @Param Automatically use new & reset on reuse without manual grant

  build() {
    Column() {
      Text(this.title)
      Row() {
        Text(this.from)
        Text(this.tail)
      }
    }
  }
}

@ComponentV2
export struct OneTypeItemPage {
  @Local items: ItemData[] = [];

  aboutToAppear(): void {
    this.items = genMockItemData(1000);
  }

  build() {
    NavDestination() {
      List() {
/ 3 V2 Replace LazyForEach (data sources are arrays, not datasources) with Repeat + vitalScroll
        Repeat<ItemData>(this.items)
          .virtualScroll()
          .each((ri: RepeatItem<ItemData>) => {
            ListItem() {
/ / Call sub-components into fields (repeated by TheemView by default)
              ItemView({ title: ri.item.title, from: ri.item.from, tail: ri.item.tail })
            }
          })
      }
/ / 3 cardedCount (1) controls the preview range, with expansive examples entering the default reuse pool
      .cachedCount(1)
    }
  }
}
```

---

# SCENE-02 grouping list item

** Applicable scene:** There are multiple layout types (separate, three charts, video, etc.) in the list and there are structural overlaps between different types (all types share the same title area and base information area, with only intermediate content areas). If a complete `@Reusable` component is developed independently for each type, overlapping title/floor areas are created again in their respective reuse pools, resulting in an expansion of nodes and a low reuse rate. Allows the sharing segment cross-types to fall into the same reuse pool by grouping the split share segment + switch segment, and only the different segments are reused by type.

** Distinction from single/multi-type reuse:**

-**Unique type reuse** (see SCENE-01): whole listitem is a ZXXKEEP1ZX component with the component name Reuse Pool ID; suitable for a scenario with only one layout in the list
-** Multi-type reuse**: each layout type is an independent `@Reusable` component, identified as a re-use pool, which is not used between different types; scenarios that are suitable for multiple layouts and that differ significantly in their structure
-** Group Reassemble** list item is torn to multiple `@Reusable` sub-components (e.g. Top/Middle/Bottom), with the same name sub-components automatically sharing the same reuse pool across types; different type by switching Middle sub-component + reassembly with Top/Bottom sub-components; scenes suitable for multiple layouts but with a public structure (head/tail)

** Core mechanism:** Examples of components rolled out of the visual area and not destroyed, but entered the re-use pool of the corresponding component (defaultly marked as a re-use pool); next time the same component is required, the re-use is removed directly from the pool, avoiding duplication of creation/destruction. Combining to split the list item into sub-components of `@Reusable`, automatically completing the re-use pool by "same-named component into the same pool": The same cross-type part (TopView/BottomView) is the same component, with all typee sharing the same title/floor node; the intermediate segment (MiddleSingleImageView/MiddleThreeImageView/MiddleVideoView) is the same component and is used independently. Data update: V1 with `@Reusable` + `@ObjectLink` + with `aboutToReuse(params)`; V2 with `@ReusableV2` + `@Param` with automatic replacement (as well as ZXKEEP6Z/`aboutToRecycle` with no cross rewrite).

** Grouping reuse structure:**
. . . ././assets/compable-reuse.png)

** Steps to be taken:**

1. ** Declaration of data models**: list item data categories include `type` (for distribution layout) and subassemblies render data (`title` / `tail` / `preview` / `pics` / `duration` etc.); V1 accept with ZXKEEP6Z and subcomponents `@ObjectLink`; V2 use `@ObservedV2` + `@Trace`, subassembly with ZXKEEP10Z X to ensure that the properties change accurately driven UI cleanup
2. ** Split reusable sub-components* *: Identification of cross-type overlapping structures (TopView title area, BottomView tail area) and unique types of structures (MiddleXxxView content area), declared as stand-alone reusable components - –V1 with `@Reusable @Component` + `@ObjectLink item`; V2 with `@ReusableV2 @ComponentV2` + `@Require @Param item`
**Re-use pool division (as determined by the automatic name of the component)**: Each component defaults on the re-use pool identification - TopView/BottomView is the same component, sharing a pool across all typee; MiddleSingleSingleImageView/ MiddleThrieleImageView/ MiddleVideoView is the separate component
4. **Statement `@LocalBuilder`**: Preparation of a `@LocalBuilder` for each `item.type` (e. g. ZXXKEEP3ZX / `itemBuilderThreeImage` / `itemBuilderVideoImage`) for each `item.type`, internal call for the corresponding sub-component in Top → Middle → Bottom; Middle part switch different sub-components by type
V1 with `LazyForEach(IDataSource)`, V2 with `Repeat(array).VirtualScroll().each() `with ZXKEEP2X with ZXKEEP4Z to control the preview range, and over-scope categories of companies usually enter the web of the Internet

**V1 Code:**

```typescript
/ 1 Declaration
@Observed
export class ItemData {
  id: string = '';
  title: string | Resource = '';
  tail: string | Resource = '';
type: number = 0;// 0 = single graph 1 = three graph 2 = video
  pics: Resource[] = [];
  preview: Resource | string = '';
  duration: string = '';
}

/ 2 Dismantling Molecular Component - Title / End Area (TopView/ BottomView cross type, same name automatically entered in the same pool)
@Reusable @Component
struct TopView {
  @ObjectLink item: ItemData;
  build() { Text(this.item.title) }
}
@Reusable @Component
struct BottomView {
  @ObjectLink item: ItemData;
  build() { Text(this.item.tail) }
}

/ 2 Disassembly Molecular Component - Content Area (type for each type, separate pool for each component)
@Reusable @Component
struct MiddleSingleImageView {
  @ObjectLink item: ItemData;
  build() { Image(this.item.preview) }
}
@Reusable @Component
struct MiddleThreeImageView {
  @ObjectLink item: ItemData;
  build() {
    Row() {
      Image(this.item.pics[0]).layoutWeight(1)
      Image(this.item.pics[1]).layoutWeight(1)
      Image(this.item.pics[2]).layoutWeight(1)
    }
  }
}
@Reusable @Component
struct MiddleVideoView {
  @ObjectLink item: ItemData;
  build() {
    Stack() {
      Image(this.item.preview)
      Text(this.item.duration)
    }
  }
}

@Component
export struct ComposableItemPage {
  private dataSource: ItemDataSource = new ItemDataSource();

  aboutToAppear(): void {
    this.dataSource.pushArray(genMockItemData(1000));
  }

/ 4 for the declaration group @LocalBuilder: listitem in Top → Middle → Bottom
  @LocalBuilder itemBuilderSingleImage(item: ItemData) {
    TopView({ item: item })
    MiddleSingleImageView({ item: item })
    BottomView({ item: item })
  }
  @LocalBuilder itemBuilderThreeImage(item: ItemData) {
    TopView({ item: item })
    MiddleThreeImageView({ item: item })
    BottomView({ item: item })
  }
  @LocalBuilder itemBuilderVideoImage(item: ItemData) {
    TopView({ item: item })
    MiddleVideoView({ item: item })
    BottomView({ item: item })
  }

  build() {
    NavDestination() {
      List() {
        LazyForEach(this.dataSource, (item: ItemData) => {
          ListItem() {
            Column() {
/ 5 Assign corresponding @LocalBuilder
              if (item.type === 0) {
                this.itemBuilderSingleImage(item)
              } else if (item.type === 1) {
                this.itemBuilderThreeImage(item)
              } else if (item.type === 2) {
                this.itemBuilderVideoImage(item)
              }
            }
          }
        }, (item: ItemData) => item.id.toString())
      }
/ / 5 cardedCount (1) controls the pre-relay range, with excess sub-components entering the re-use pool of the corresponding component
      .cachedCount(1)
    }
  }
}
```

**V2 Code:**

```typescript
/ / 1 Declaration @ObservedV2 Data Model: Fields to Observe
@ObservedV2
export class ItemData {
  id: string = '';
  @Trace title: string | Resource = '';
  @Trace tail: string | Resource = '';
@Trace type: number = 0;// 0 = single 1 = three = video
  @Trace pics: Resource[] = [];
  @Trace preview: Resource | string = '';
  @Trace duration: string = '';
}

/ 2 Dismantling Molecular Component - Title / End Area (TopView/ BottomView cross type, same name automatically entered in the same pool)
@ReusableV2 @ComponentV2
struct TopView {
  @Require @Param item: ItemData;
  build() { Text(this.item.title) }
}
@ReusableV2 @ComponentV2
struct BottomView {
  @Require @Param item: ItemData;
  build() { Text(this.item.tail) }
}

/ 2 Disassembly Molecular Component - Content Area (type for each type, separate pool for each component)
@ReusableV2 @ComponentV2
struct MiddleSingleImageView {
  @Require @Param item: ItemData;
  build() { Image(this.item.preview) }
}
@ReusableV2 @ComponentV2
struct MiddleThreeImageView {
  @Require @Param item: ItemData;
  build() {
    Row() {
      Image(this.item.pics[0]).layoutWeight(1)
      Image(this.item.pics[1]).layoutWeight(1)
      Image(this.item.pics[2]).layoutWeight(1)
    }
  }
}
@ReusableV2 @ComponentV2
struct MiddleVideoView {
  @Require @Param item: ItemData;
  build() {
    Stack() {
      Image(this.item.preview)
      Text(this.item.duration)
    }
  }
}

@ComponentV2
export struct ComposableItemPage {
  @Local items: ItemData[] = [];

  aboutToAppear(): void {
    this.items = genMockItemData(1000);
  }

/ 4 for the declaration group @LocalBuilder: listitem in Top → Middle → Bottom
  @LocalBuilder itemBuilderSingleImage(item: ItemData) {
    TopView({ item: item })
    MiddleSingleImageView({ item: item })
    BottomView({ item: item })
  }
  @LocalBuilder itemBuilderThreeImage(item: ItemData) {
    TopView({ item: item })
    MiddleThreeImageView({ item: item })
    BottomView({ item: item })
  }
  @LocalBuilder itemBuilderVideoImage(item: ItemData) {
    TopView({ item: item })
    MiddleVideoView({ item: item })
    BottomView({ item: item })
  }

  build() {
    NavDestination() {
      List() {
/ / 5 V2 Replace LazyForEach (data source is array) with Repeat + vitalScroll
        Repeat<ItemData>(this.items)
          .virtualScroll()
          .each((ri: RepeatItem<ItemData>) => {
            ListItem() {
              Column() {
/ According to ri.item. type
                if (ri.item.type === 0) {
                  this.itemBuilderSingleImage(ri.item)
                } else if (ri.item.type === 1) {
                  this.itemBuilderThreeImage(ri.item)
                } else if (ri.item.type === 2) {
                  this.itemBuilderVideoImage(ri.item)
                }
              }
            }
          })
      }
/ / 5 cardedCount (1) controls the pre-relay range, with excess sub-components entering the re-use pool of the corresponding component
      .cachedCount(1)
    }
  }
}
```

---

# SCENE-03 Global Reuse

**Applicable scenario:**Applies to a specified component in the same application. e. g. Tab has multiple parallel lists, each of which is an independent `List`, with different examples of parent-defined components. `@Reusable` Decorators require that reusable components must be configured under " Same parent custom components " , different sub-components of the same structure within Tab are default ** not duplicated.** Recycle/reuse node from "single parent component" to "global" by `BuilderNode` + `NodeContainer` + global single case of `NodePool` self-constructing pool.

**Selection Hint:** SCENE-03 (manual `NodePool`) is ** manual equivalent of ZXXKEEP2ZX declaration pool** with more sample code. ** This scenario is selected only when ** pre-created component** is required and additional operations based on its life cycle (typically ** off-line Web component preheating**); cross-list reuse should ** prioritize SCENE-04** as long as the API version allows (** API 26+**).

** Distinction from SCENE-01/02:**

-**SCENE-01/02 (local reuse)**: relying on ZXXKEEP1ZX + `aboutToReuse` (identified as a re-use pool by component) node can only be reused within the "same ZXXKEEP3ZX/`List` of the same parent component" and invalid cross-list (cross-father component)
- ** SCENE-03 (repealed)**: `@Reusable` is no longer dependent on `@Reusable`, instead of `BuilderNode` (pre-create node) + `NodeContainer` (site mounted) + `NodePool` (single-pool access by `type`) and node is available for any inter-list flow in application

** Core mechanism:** with `NodeContainer(NodeController)` as ** placeholder for the list item* *--- `NodeController.makeNode(uiContext)` Creates real nodes in `new BuilderNode(uiContext)` and `.build(wrappedBuilder, data)` when first required, then mounts them through `.getFrameNode()` to `NodeContainer`; de-mounts ZXXKEEP7ZX when destroyed by `aboutToDisappear`, and returns ZXXKEEP8ZX to the global ZXXKEEP9ZX. `NodePool` is a single case, which is managed internally by `HashMap<string, LinkedList<NodeItem>>` by `type`: `getNode()` gives priority to the "Father is empty (i.e. unloaded, reusable)" node and cannot be created; `recycleNode()` re-enters the recovered node into the pool. This way, rolls the recovered nodes from the Tab A list and can be retrieved from the Tab B list to override the "same parent component" limit.

**NodePool Reuse Pool Structure:**
[NodePool global node reuse pool] (..././.assets/node-pol.png)

-`wrapBuilder(builder)`: Pack the `@Builder` function as `WrappedBuilder` as the building entry for ZXXKEEP3ZX
- `NodeContainer(NodeController)`: Placed container, frame echo `NodeController.makeNode()` determines which ZXXKEEP2ZX node to show
- `BuilderNode`: Custom declaration node, load real component content, support `build()` creation, `reuse()` reuse update, `recycle()` unmount
- `NodePool`: The global single-case reuse pool with `type` access/recycling `NodeItem` is the core of cross-list reuse


** Steps to be taken:**

1. ** Declares that the real component of the list item + Packaging Builder**: packaged with `@Component` / `@ComponentV2`, `wrapBuilder()` received `WrappedBuilder` for ZXXKEEP5ZX
2. ** `NodeItem` (succession `NodeController`)**: holding `builder`/`node`/`data`/`type`, `makeNode()` responsible for the first `new BuilderNode` node creation or reuse of ZXXKEEP8ZX update data (`.reuse(data)`), `aboutToRecycle()` responsible for returning to XKEP11ZX
3. **Universal `NodePool`**: Internal `HashMap<string, LinkedList<NodeItem>>` by `type` sub-pool; ZXXKEEP3ZX round-trip to remove `getFrameNode().getParent()` as an empty (unloaded) reusable node, otherwise new ZXXKEEP5ZX; ZXXKEEP6ZX emptied data into the pool
4. ** Declaration of placeholder `DiffListItemContainer`**: `build()` Rendering only `NodeContainer(this.nodeItem)`; ZXXKEEP3ZX Taking node from `getNode()` in pool, `aboutToDisappear` to `aboutToRecycle()`

**V1 / V2 Code:**

```typescript
/ 1/ @Builder Package Real Component, wrapBuilder() got WrappedBuilder for BuilderNode.build()
@Builder
export function listItemBuilder(data: ESObject) {
  DiffListItemNode({ item: data.item })
}
export const listItemWrapper: WrappedBuilder<ESObject> = wrapBuilder<ESObject>(listItemBuilder);

DiffListItemContainer:build Render NodeContainer only, take from global pool / also node
@Component
export struct DiffListItemContainer {
  @State type: string = '';
  @State item: ItemData = new ItemData('', 0);
  @State builder: WrappedBuilder<ESObject> | null = null;
  private nodeItem: NodeItem = new NodeItem();

  aboutToAppear(): void {
/ 4 Press type node from global pool (reuse old node or new)
    this.nodeItem = NodePool.getInstance().getNode(this.type, this.item, this.builder!)!;
  }
  aboutToDisappear(): void {
/ 4 Return node back to the global pool when component is destroyed
    this.nodeItem?.aboutToRecycle();
  }
  build() {
    NodeContainer(this.nodeItem)
  }
}

/ 2 NodeItem Inheritance NodeController: first creation of Builder Node, update data when reused
export class NodeItem extends NodeController {
  public builder: WrappedBuilder<ESObject> | null = null;
  public node: BuilderNode<ESObject> | null = null;
  public data: ESObject = {};
  public type: string = '';

  aboutToRecycle(): void {
NodePool.getInstance().recycleNode (this. type, this); / / 2 returns to global pool
  }
  update(data: ESObject): void {
    this.data = data;
This.node?.reuse(data); / / 2 Update data on reuse
  }
  makeNode(uiContext: UIContext): FrameNode | null {
    if (!this.node) {
This.node = new Builder Node (uiContext); / / 2: First: Create Node
      this.node.build(this.builder, this.data);
    } else {
This.update(this.data); / / 2 reuse: update data
    }
    return this.node.getFrameNode();
  }
/ Precreate
  prebuild(uiContext: UIContext) {
    this.node = new BuilderNode(uiContext);
    this.node.build(this.builder, this.data);
  }
}

/ / 3 NodePool single example: HashMap<type, LinkedList<NodeItem>
export class NodePool {
  private static instance: NodePool;
  private nodePool: HashMap<string, LinkedList<NodeItem>>;

  private constructor() {
    this.nodePool = new HashMap();
  }
  public static getInstance(): NodePool {
    if (!NodePool.instance) {
      NodePool.instance = new NodePool();
    }
    return NodePool.instance;
  }

  public getNode(type: string, item: ESObject, builder: WrappedBuilder<ESObject>): NodeItem | undefined {
    let nodeItem: NodeItem | undefined = undefined;
    const list: LinkedList<NodeItem> | undefined = this.nodePool.get(type);
If(list){/ / 3 removes the reusable section of "Paternity is empty (unmounted)" Points
      for (let i = 0; i < list.length; i++) {
        const tmpItem: NodeItem = list.get(i);
        if (!tmpItem.node?.getFrameNode()?.getParent()) {
          nodeItem = tmpItem;
          list.removeByIndex(i);
          break;
        }
      }
    }
If (!nodeItem){/ / 3 Unreusable node in pool
      nodeItem = new NodeItem();
      nodeItem.builder = builder;
      nodeItem.type = type;
      nodeItem.data.item = item;
}else {/ / 3 Reuse old nodes to update data
      nodeItem.data.item = item;
    }
    return nodeItem;
  }

Public return Node
    let nodeArray: LinkedList<NodeItem> | undefined = this.nodePool.get(type);
    if (!nodeArray) {
      nodeArray = new LinkedList();
      this.nodePool.set(type, nodeArray);
    }
    node.data.item = {};
    nodeArray.add(node);
  }

  public preBuild(type: string, item: ESObject, builder: WrappedBuilder<ESObject>, uiContext: UIContext) {
    if (type) {
      let nodeItem: NodeItem | undefined = new NodeItem();
      nodeItem.builder = builder;
      nodeItem.data.item = item;
      nodeItem.type = type;
      nodeItem.prebuild(uiContext);
      this.recycleNode(type, nodeItem);
    }
  }
}
```

---

# SCENE-04 global reuse pool scene (declaration reusePool, API 26+)

**Applied scene:**along with SCENE-03 is a "cross-list / cross-father component reuse " requirement (e.g. multiple combinations of Tab, each of which is a separate `List`, an example of a different parent component), but modified to the API 26+ **-global reuse ** capacity ** in ** Declaration**, no handwritten `BuilderNode` + `NodeContainer` + `NodePool`. When a Tab is unmounted (Swiper ZXKEEP5Z cut page), its unmounted reusable component automatically enters the ancestral declared shared re-use pool; the next Tab build list is used directly from the pool to avoid repeated creation/destruction.

**Selection proposal (priority 04, exception 03):** As long as the API version is satisfied (global re-use pool declaration API `reusePool` / ZXKEEP1Z needs **API 26+**), cross-list / cross-father re-use should** give priority to the local scene (SCENE-04 declaration global re-use pool)** — fewer, more declarative, list items are placed directly into ZXXKEEP3ZX, without the need to occupy a local component and manual pool. ** Reverts to SCENE-03 (manual ZXXKEEP5ZX) only if **The business needs** pre-created component** and rely on the component life cycle for additional operations. Typical requirements such as the creation of **offline Web component for preheating (prebuld / preload)**: components need to be constructed in advance and attached to preheating logic at times such as `BuilderNode.build()` / `aboutToAppear` - this "build-up-and-take-up-on-demand" requirement goes beyond ZXXKEEP8ZX automatic recovery / reuse take-over, and must be managed manually with ZXXKEEP10ZX + global ZXXKEEP11ZX.

** Distinction from SCENE-03:**

- **SCENE-03 (Manual NodePool)**: `BuilderNode` / `NodeContainer` / `NodePool` Individually, manual access node at `type` without relying on `@Reusable`; generic, controllable, but with multiple templates code, and list item components must be built independently in ZXXKEEP6ZX and cannot be added to `@ReusableV2`
- ** SCENE-04 (declaration global reuse pool)**: a shared pool is declared on** ancestral components** with `@ComponentV2({ reusePool, poolAccepts, freezeWhenInactive })`, and the frame is automatically recovered / reused from the nearest reception pool ** when reusable components are created/ destroyed; the list item is a regular `@ReusableV2` component and is placed directly into ZXXKEEP3ZX without place-holder components and manual pools. Fewer, more declarative, is the modern equivalent of SCENE-03 (need API 26+)

** Core mechanism:** Direct parent component of each reusable component ** by default* * Separately maintain local reuse ponds, which are not repeated between examples of different parent components (different `List` for Tab). The Global Reuse Pool allows for the configuration of a Reuse Pool on ** parent component** that can be shared by multiple subcomponents (all examples of this type are shared with the same pool in `shared` mode). When `@ReusableV2` component is recycled (e. g. Tab unmounted) or created (e. g. new Tab build list), frame from this component* * Roundup of ** Component Tree found the first `poolAccepts` to host its ancestral pool for recycling / reuse - to upgrade reuse from "same parent component" to "cross father component". The life cycle of the `shared` pool is managed by the citation count: all of the examples stated were destroyed only when the pool was destroyed.

** Global reuse structure:**
... [global reuse structure] (..././assets/global-reuse-struct.png)

**perInstance mode structure:**
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

**Shared model structure:**
.! [Assets/Shared-pool.png]

** Steps to be taken:**

1. ** Declare reusable list item**: Declared list item components (e.g. `@ReusableV2` + `@ComponentV2` + `@Require @Param item`); automatically reset `@Param` when reused, without the need for manual updating of data (rewritten without reference to `aboutToReuse` / `aboutToRecycle`, etc.)
2. **Appliced Re-use Pool**: Add `@ComponentV2({ reusePool: 'shared', poolAccepts: [GlobalPoolItemView], freezeWhenInactive: false })` to all Tab public ancestors (e.g., page `GlobalReusePoolPage`) to make the page a shared pool for `GlobalPoolItemView` Lord

**V2 Code:**

```typescript
Source: GlobalReusePoolPage / GlobalPoolTabContantView / GlobalPoolItemView (V2/API 26+)
/ Note: Global reuse pool declaration API (reusePool / PoolAccepts) requires API 26+;polAccepts can also mix V1@Reusable component

/ / 1 Reusable List Item: @ReuseableV2 + @Require@Param, auto-reset on reuse @Param (no manual update required)
@ReusableV2
@ComponentV2
export struct GlobalPoolItemView {
  @Require @Param item: ItemData;
aboutToReuse(): void{/ * triggered without reference; only side effects, data automatically reset */ } by @Param
about ToRecycle(): void{/* trigger on recovery*/}
bueld(){/* List item UI, omitted details */}
}

/ 2 Ancestral Pages Declaring Global Reuse Pool: All Tab Public ancestors, share one of these examples in Shared mode
@ComponentV2({
ReusePool: 'shared', / / 2 All examples shared one pool (recommended)
PolAccepts: [GlobalPoolItemView], / 2 Admission of GlobalPoolItemView; to match reusePool
FreezeWhenInactive:
})
export struct GlobalReusePoolPage {
  @Local arrayStr: string[] = TAB_TITLES;     // ['News','Hot','Video','Tech','Travel']
  swiperController: SwiperController = new SwiperController();

  build() {
    NavDestination() {
      Swiper(this.swiperController) {
        Repeat<string>(this.arrayStr)
          .virtualScroll()
          .each((ri: RepeatItem<string>) => {
GlobalPoolTaubContantView ({index: ri.index} // Each Tab is independent List
          })
      }
.cachedCount(0) / / / 2 pages off-loaded and recycled list items into the ancestral pool
    }
  }
}

/ 3 List (Independent Parent Component) for each Tab: Directly reuse @ReuseableV2 List Item without placeholder/ manual pool
@ComponentV2
export struct GlobalPoolTabContentView {
  @Require @Param index: number;
  @Local items: ItemData[] = [];
  aboutToAppear(): void { this.items = genMockItemData(1000); }
  build() {
    List() {
      Repeat<ItemData>(this.items)
        .virtualScroll()
        .each((ri: RepeatItem<ItemData>) => {
          ListItem() {
/ 3 Direct @ReusableV2 Component + .use; recovery / reuse taken over by ancestral shared pool
            GlobalPoolItemView({ item: ri.item })
          }
        })
    }
    .cachedCount(1)
  }
}
```

---

# SCENE-05 if dynamically modified layout scenario (V1/V2)

**Applied scene: **Parts are dynamically invisible through `if` sub-conditions (e.g., click on buttons to expand/close, login state switching). When `@Reusable` is not added, each `if` condition is changed to destroy the old node and create a new node; after marking with `@Reusable`(V1) or `@ReusableV2`(V2) the node is destroyed before entering the reuse pool and is next displayed directly to avoid repeated creation/destruction.

** Core mechanism:** Place the `@Reusable`/`@ReusableV2` component in the `if` branch: `true→false` when conditioned (V2 to `aboutToRecycle()`); `false→true` when conditioned (V2 to `aboutToReuse()`, V1 to `aboutToReuse(params)` and refreshed with new parameters).

**V2 (`@ComponentV2` + `@ReusableV2`):**

```typescript
/ condition switch trigger about ToRecycle/ aboutToReuse
@Entry
@ComponentV2
struct Index {
  @Local condition: boolean = true;
  build() {
    Column() {
      Button('Recycle/Reuse')
.onClick(()=> {this.condition=!this.condition;}) // Switch recovery/ reuse
      if (this.condition) {
        ReusableV2Component()
      }
    }
  }
}

@ReusableV2
@ComponentV2
struct ReusableV2Component {
  @Local message: string = 'Hello World';
about ToRecile(){/* Called on Recovery*/}
about ToReuse(){/ * Called on Recall*/}
  build() {
    Text(this.message)
  }
}
```

**V1 (`@Component` + `@Reusable`):**

```typescript
export class Message {
  public value: string | undefined;
  constructor(value: string) { this.value = value; }
}

@Entry
@Component
struct Index {
  @State switch: boolean = true;
  build() {
    Column() {
      Button('Hello')
        .onClick(() => { this.switch = !this.switch; })
      if (this.switch) {
/ / When only one reused component is available
        Child({ message: new Message('Child') });
      }
    }
  }
}

@Reusable
@Component
struct Child {
  @State message: Message = new Message('AboutToReuse');
About ToReuse (params: Recod<string, ESObject>) {/ / / Update with New Parameters Before Restart
    this.message = params.message as Message;
  }
  build() {
    Text(this.message.value)
  }
}
```

---

# SCENE-06 4-type newslist rolling reset (V1 / V2)

** Applicable scene:** There are many list item structures in news, information, community information flows, such as plain text, single text, multiple text, video text. The title area, source area of the four items may be similar, but the middle picture area/video area is structured differently; if the full card is recreated every time the list enters the visual area, the cost of node creation and destruction increases. Re-use ponds by type of news, roll out of the same type of card and enter the corresponding pool, re-use old components and refresh the data next time the same type of data appears.

** Core mechanism: ** Data entry for the news list uses `type` for layout type and reuses id when rendering. V1 Use `List + LazyForEach(IDataSource) + @Reusable + .reuseId(item.type)`; V2 Use `List + Repeat(items).virtualScroll(...) + @ReusableV2 + .reuse({ reuseId })`. Owing to the different UI structures of pure text, single graphs, multigraphs, and video, it is not possible to share the same reuse pool; the same type of item structure is stable, so that data can be replaced and repainted during the `aboutToReuse` phase.

** Steps to be taken:**

1. **Defining news type and data model**: Distinguishing `TEXT` / `SINGLE_IMAGE` / `MULTI_IMAGE` / `VIDEO` category 4item, retaining `id`, `title`, `source`, `time`, `images`, `commentCount`, `duration` in data
2. **Select list data source by version**: `LazyForEach` for V1 The first parameter must achieve `IDataSource`; `Repeat` for V2 can directly use arrays and save list data via ZXXKEEP3ZX
3. ** Sets the third parameter of `LazyForEach` for stable key**: V1, and `.key()` for V2 recommend the use of business unique IDs to avoid insertion, refresh, and scrambling
4. **Repeated components for news cards**: V1 cards with ZXKEP0ZX, V2 cards with ZXKEP1ZX
5. **Re-use pools by type of news**: V1 with `.reuseId(item.type)`; V2 with `.reuse({ reuseId: () => ri.item.type })`
6.** Refresh data when reused**: V1 manually update `@State item`; `aboutToReuse()` for V2 unincorporated, new `@Param item` enters the components when reused, returning only for side effects such as logs, burial sites, resource cleanup
7. ** Render differences by type* *: Pure text only releasing title and bottom information, single graph rendering headchart, multit rendering first three, video rendering cover, play icon and time

**V1 Code:**

```typescript
enum NewsItemType {
  TEXT = 'text',
  SINGLE_IMAGE = 'singleImage',
  MULTI_IMAGE = 'multiImage',
  VIDEO = 'video'
}

interface NewsItem {
  id: string;
  type: NewsItemType;
  title: string;
  source: string;
  time: string;
  images: ResourceStr[];
  commentCount: number;
  duration?: string;
}

class NewsDataSource implements IDataSource {
  private list: NewsItem[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(list: NewsItem[]) {
    this.list = list;
  }

  totalCount(): number {
    return this.list.length;
  }

  getData(index: number): NewsItem {
    return this.list[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listeners = this.listeners.filter((item: DataChangeListener) => item !== listener);
  }

  reload(list: NewsItem[]): void {
    this.list = list;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    })
  }
}

@Component
export struct NewsListPage {
  private dataSource: NewsDataSource = new NewsDataSource([]);

  aboutToAppear(): void {
    this.dataSource.reload(genMockNewsList(1000));
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: NewsItem) => {
        ListItem() {
          NewsReusableItem({ item: item })
.useId(item. type) / / Enter text / singleImage / multiImage / video
        }
      }, (item: NewsItem) => item.id)
    }
    .cachedCount(1)
    .width('100%')
    .height('100%')
  }
}

@Reusable
@Component
struct NewsReusableItem {
  @State item: NewsItem = {
    id: '',
    type: NewsItemType.TEXT,
    title: '',
    source: '',
    time: '',
    images: [],
    commentCount: 0
  };

  aboutToReuse(params: Record<string, Object>): void {
This.item =params.item as NewsItem; / V1 needs to write back the new parameters manually before reuse
  }

  build() {
    if (this.item.type === NewsItemType.SINGLE_IMAGE) {
      //...
    } else if (this.item.type === NewsItemType.VIDEO) {
      //...
    } else if (this.item.type === NewsItemType.MULTI_IMAGE) {
      //...
    } else if (this.item.type === NewsItemType.TEXT) {
      //...
    }
  }
}
```

**V2 Code:**

```typescript
enum NewsItemType {
  TEXT = 'text',
  SINGLE_IMAGE = 'singleImage',
  MULTI_IMAGE = 'multiImage',
  VIDEO = 'video'
}

interface NewsItem {
  id: string;
  type: NewsItemType;
  title: string;
  source: string;
  time: string;
  images: ResourceStr[];
  commentCount: number;
  duration?: string;
}

function createEmptyNewsItem(): NewsItem {
  return {
    id: '',
    type: NewsItemType.TEXT,
    title: '',
    source: '',
    time: '',
    images: [],
    commentCount: 0
  };
}

@ComponentV2
export struct NewsListPageV2 {
  @Local items: NewsItem[] = [];

  aboutToAppear(): void {
    this.items = genMockNewsList(1000);
  }

  build() {
    List() {
      Repeat<NewsItem>(this.items)
        .each((ri: RepeatItem<NewsItem>) => {
          ListItem() {
            NewsReusableItemV2({ item: ri.item })
.reuse({useId:()=>ri.item. type}) / V2 replace V1 with reuseId
          }
        })
        .key((item: NewsItem) => item.id)
.virtualScroll({useable: false}) / / Visible use of @ReuseableV2 component, close Repeat self
    }
    .cachedCount(1)
    .width('100%')
    .height('100%')
  }
}

@ReusableV2
@ComponentV2
struct NewsReusableItemV2 {
  @Param item: NewsItem = createEmptyNewsItem();

  aboutToReuse(): void {
/ V2 about ToReuse no reference; @Paramitem has been updated with this call and can be reset here for log or resource status
  }

  build() {
    if (this.item.type === NewsItemType.SINGLE_IMAGE) {
      //...
    } else if (this.item.type === NewsItemType.VIDEO) {
      //...
    } else if (this.item.type === NewsItemType.MULTI_IMAGE) {
      //...
    } else if (this.item.type === NewsItemType.TEXT) {
      //...
    }
  }
}
```

** Key points:**

** Re-use ponds must be distinguished by `NewsItemType`**: pure text, single graphs, multi-graphs, video, which, if shared, would allow the frame to process different structures before and after reuse, reduce reuse efficiency and even lead to displaying anomalies.
2. `LazyForEach` of **V1 requires ZXKEEP1Z**: do not pass the normal array directly to `LazyForEach`; call `dataSource.reload(newList)` when the list is refreshed and trigger `DataChangeListener` and do not replace `dataSource` objects frequently.
3. **V2 `Repeat` direct consumer group**: List data can be saved in `@Local items`; `LazyForEach + IDataSource` normally migrates from V1 to `Repeat(items).virtualScroll()`.
4. **V1 is not the same as V2 's reused callback**: `aboutToReuse(params)` of V1 has input and needs to be manually updated `@State`; `aboutToReuse()` of V2 is not. Component parameters are updated through `@Param` and are referred back for side effects treatment.
5. ** Distinguishing between `Repeat` self-repeat and `@ReusableV2` components**: If `@ReusableV2 + .reuse({ reuseId })` is used and wishes to trigger the reuse life cycle of a custom component, `.virtualScroll({ reusable: false })` can be used to close `Repeat` self-reuse; if only ZXXKEEP5ZX internal reuse capacity is used, ZXXKEEP6ZX can be used to manage different templates.
6. **key must be stable and the only **:V1 `(item) => item.id`, V2 `.key((item) => item.id)` should use operational ID; not use changing titles, subscripts or random values as key.
7.** Do not keep the derivative status of the old item in the reuse component* *: If the component caches derived data such as number of pictures, video length, roll-out, etc., the re-use must be recalculated or reset to avoid the previous news string to the next one.

---


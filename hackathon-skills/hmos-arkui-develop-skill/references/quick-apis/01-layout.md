# 1. Layout Containers

This quick reference lists the main ArkUI containers and their most commonly used APIs.

## Row

Arranges children horizontally.

`Row(options?: RowOptions)`

| Option or method | Type | Default | Description |
|---|---|---|---|
| `space` | `Length` | 0 | Space between children. |
| `alignItems` | `VerticalAlign` | `Center` | Vertical alignment. |
| `justifyContent` | `FlexAlign` | `Start` | Horizontal distribution. |
| `reverse` | `boolean` | `false` | Reverses child order. |

## Column

Arranges children vertically.

`Column(options?: ColumnOptions)`

| Option or method | Type | Default | Description |
|---|---|---|---|
| `space` | `Length` | 0 | Space between children. |
| `alignItems` | `HorizontalAlign` | `Center` | Horizontal alignment. |
| `justifyContent` | `FlexAlign` | `Start` | Vertical distribution. |
| `reverse` | `boolean` | `false` | Reverses child order. |

## Flex

Provides flexible row or column layout.

`Flex(options?: FlexOptions)`

| Option | Type | Default |
|---|---|---|
| `direction` | `FlexDirection` | `Row` |
| `wrap` | `FlexWrap` | `NoWrap` |
| `justifyContent` | `FlexAlign` | `Start` |
| `alignItems` | `ItemAlign` | `Start` |
| `alignContent` | `FlexAlign` | `Start` |
| `space` | `FlexSpaceOptions` | 0 |

## List and ListItem

`List(options?: ListOptions)` displays scrollable items. Use `ListItem()` for each item and `ListItemGroup()` for grouped items.

Common list APIs include `listDirection(Axis)`, `divider(ListDividerOptions | null)`, `scrollBar(BarState)`, `cachedCount(number)`, `lanes(number | LengthMetrics)`, `edgeEffect(EdgeEffect)`, `sticky(StickyStyle)`, and `nestedScroll(NestedScrollOptions)`.

Common events are `onIndexChange`, `onScroll`, `onScrollIndex`, `onReachStart`, and `onReachEnd`.

`ListItem` supports `swipeAction(SwipeActionOptions)` and `style(ListItemStyle)`. A swipe action can define `start`, `end`, `edgeEffect`, and callbacks such as `onAction` and `onOffsetChange`.

`ListItemGroup` accepts optional `header`, `footer`, and `space` values. Configure dividers on the parent `List`.

## Grid, GridRow, and GridCol

`Grid(scroller?: Scroller, layoutOptions?: GridLayoutOptions)` supports regular and irregular cells. Use `columnsTemplate`, `rowsTemplate`, `columnsGap`, `rowsGap`, `scrollBar`, `cachedCount`, and `edgeEffect` to configure it.

`GridRow(option?: GridRowOptions)` provides responsive rows. Its main options are `columns`, `gutter`, `breakpoints`, and `direction`. `GridCol(option?: GridColOptions)` accepts `span`, `offset`, and `order` values for each breakpoint.

## WaterFlow

`WaterFlow(options?: WaterFlowOptions)` provides a waterfall layout. Configure `columnsTemplate`, `rowsTemplate`, `columnsGap`, `rowsGap`, `layoutMode`, `cachedCount`, `sections`, `footer`, and `scroller`.

## Scroll

`Scroll(scroller?: Scroller)` provides scrolling for one child container. Common APIs are `scrollable`, `scrollBar`, `scrollBarColor`, `scrollBarWidth`, `edgeEffect`, `scrollSnap`, `nestedScroll`, `enablePaging`, `friction`, and `enableScrollInteraction`.

## Tabs, TabContent, and Swiper

`Tabs(options?: TabsOptions)` supports `barPosition`, `index`, and `controller`. Common methods are `vertical`, `scrollable`, `barMode`, `barWidth`, `barHeight`, `animationDuration`, and `divider`.

`TabContent()` defines a tab page. Set its label with `tabBar(ResourceStr | CustomBuilder | SubTabBarStyle | BottomTabBarStyle)`.

`Swiper(controller?: SwiperController)` supports `index`, `autoPlay`, `interval`, `indicator`, `loop`, `vertical`, `itemSpace`, `displayMode`, `displayCount`, `effectMode`, `nestedScroll`, and `disableSwipe`.

## Stack and RelativeContainer

`Stack(options?: StackOptions)` overlays children. Set `alignContent(Alignment)` to control the shared alignment.

`RelativeContainer()` positions children with `alignRules()` and `id()`. Anchors may reference `__container__` or another child ID. Rules can specify `top`, `bottom`, `left`, `right`, `middle`, and `center`, with optional `bias` and `margin` values.

## SideBarContainer and Panel

`SideBarContainer(type?: SideBarContainerType)` provides a collapsible sidebar. Common methods include `showSideBar`, `controlButton`, `sideBarWidth`, `minSideBarWidth`, `maxSideBarWidth`, `showControlButton`, `autoHide`, and `sideBarPosition`.

`Panel(show: boolean)` creates a popup panel. Configure `type`, `mode`, `dragBar`, `fullHeight`, `halfHeight`, `miniHeight`, `show`, and `backgroundMask`.

## Refresh, Badge, Counter, and AlphabetIndexer

`Refresh({ refreshing, builder?, refreshingContent? })` supports `refreshOffset`, `pullToRefresh`, and `pullDownRatio`, with `onStateChange`, `onRefreshing`, and `onOffsetChange` events.

`Badge({ count, maxCount?, position?, style })` displays a numeric badge. A string form accepts `{ value, position?, style }`. `Counter()` exposes `enableInc` and `enableDec` with `onInc` and `onDec` events.

`AlphabetIndexer({ arrayValue, selected })` supports color, font, popup, size, and selection APIs, including `onSelect` and `onRequestPopupData`.

## Other Layout Components

| Component | Constructor | Purpose |
|---|---|---|
| `Hyperlink` | `Hyperlink(address, content?)` | Displays a link. |
| `FolderStack` | `FolderStack(options?)` | Presents a folding stack. |
| `NodeContainer` | `NodeContainer(controller)` | Hosts custom nodes. |

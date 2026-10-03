## 12. Navigation and Routing


> **Component index**: `Navigation`, `NavPathStack operations`, `NavDestination`, `Router`

### Navigation

**Constructor:** `Navigation()`

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .navDestination | `.navDestination(builder)` | — | Route destination mapping |
| .title | `.title(string \| NavigationCommonTitle \| NavigationCustomTitle)` | — | Title |
| .subtitle | `.subtitle(string)` | — | Subtitle |
| .mode | `.mode(NavigationMode)` | Auto | Stack/Split/Auto |
| .navBarHidden | `.navBarHidden(value: boolean)` | false | Hide navigation bar |
| .hideTitleBar | `.hideTitleBar(value: boolean)` | false | Hide title bar |
| .hideToolBar | `.hideToolBar(value: boolean)` | false | Hide toolbar |
| .toolBar | `.toolBar(value: ToolbarConfiguration)` | — | Toolbar |
| .navBarWidth | `.navBarWidth(value: Length)` | 240vp | Navigation bar width |
| .navBarPosition | `.navBarPosition(value: NavBarPosition)` | Start | Navigation bar position |
| .splitResizable | `.splitResizable(value: boolean)` | false | Resizable split view |

### NavPathStack Operations

| Method | Signature | Description |
|------|------|------|
| pushPath | `pushPath(info: NavPathInfo, options?)` | Push a page |
| pushName | `pushName(name, param?, options?)` | Push by name |
| pop | `pop(result?, options?)` | Pop |
| replacePath | `replacePath(info, options?)` | Replace |
| clear | `clear()` | Clear |
| size | `size: number` | Stack size |
| getParent | `getParent(): NavPathStack \| undefined` | Get parent stack |

### NavDestination

**Constructor:** `NavDestination()`

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .title | `.title(string \| CustomBuilder)` | — | Title |
| .hideTitleBar | `.hideTitleBar(boolean)` | false | Hide title bar |
| .hideBackButton | `.hideBackButton(boolean)` | false | Hide back button |
| .backgroundColor | `.backgroundColor(ResourceColor)` | — | Background color |

**Events:** `.onShown()` `.onHidden()` `.onBackPressed()`

### Router

| Method | Signature | Description |
|------|------|------|
| pushUrl | `router.pushUrl({url, params?})` | Push a page |
| replaceUrl | `router.replaceUrl({url, params?})` | Replace current page |
| back | `router.back(url?)` | Back |
| clear | `router.clear()` | Clear stack |
| getLength | `router.getLength(): number` | Stack size |
| getState | `router.getState(): RouterState` | Current state |

---

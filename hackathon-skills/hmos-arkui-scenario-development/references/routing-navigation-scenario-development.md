# Route/navigation case collection

# Directory

## [I, Navigation Life Cycle Management] (#anavigation Life Cycle Management]
1. [Turn back and forth to automatically refresh list data]
2. [Edit page unsaved content returns confirmation] (# scene 2 edit page does not save content returns confirmation)
3. [Tab First Page on NewParam Single Update Data] (#Scene3tab First Page -onnewpam - Single Update Data)

# # [II, routing of subpages by push, pop, replace] (#II routing of subpages by pushpopplace)
1. [Blink page (start page)] (#Scene 1 flash page start page)
2. [page path re-direction (underline/AB test)] (#Scene 2 page path tested by re-direction bottom line ab)
3. [Complicated parameter participant return value] (#scenario 3 complex parameter participant return value)
4. [SideBarContainer + Navigation Multi-end Matching] (#Sid Barcontainer-navigation-Multi-end Matching)
5. [Different-bar chat application (Navigation Split multi-end adaptation)] (#Seven-Fix-Fix-Fix-Split-multi-end adaptation)

##[III, build subpages, configure them to enable Navigation Route Table] (#3 build subpages to enable navigation Route Tables)
1. [Road-to-stop (declaration-only + centralized interception)] (#Scene 1-to-task-to-task -- centralized interception)
2. [NavDestination Page Level Control] (#Scene2navdestinization - Page Level Direction Control)
3. [Multimodule Unified Dynamic Routes] (#More Modules 3 Unified Dynamic Routes)

# [IV, Navigation component undetected]
1. [NavDestinationSwitch achieves a page view of the number of visits statistically buried sites]
2. [query NavDestinationInfo for current page information] (#Scene 2querynavdestinationinfo - Get current page information)

# [V, Navigation by Animation] (#5navigation by Animation)
1. [System transfer type configuration] I'm not sure.
2. [Single Page Custom Animation] (#Scene 2 Page Custom Animation)
3. [Navigation global custom remix animation] (#scene 3navigation global custom remix animation)
4. [Interactive gestures return to the scene]
5. [Shared elements in one mirror]
6. [Dialog mask fading out of animation]

---

# I, Navigation Life Cycle Management

## # scene 1: Toggle automatic refreshing of list data

** scene description:** Application to switch back to the front desk after some time, and list data may have expired (e.g., new news, new orders, price changes). Automatically update data when the NavDestination page is re-visited.

** Solution:** Re-show with NavDestination **`onShown` `onShown` returns to the current page in Pop, applies a backstage cut back to the front desk, and the covered standard page is shown again, and ZXXKEEP2ZX will not be triggered ** when the backstage switch **, so the refreshing scene should use `onShown`.

> ** Common error: replace `onPageShow` / `onPageHide` with `onShown`**
> `onPageShow` is the life cycle echo for the ZXXKEEP1ZX root page, sensed as the entire Ability page, ** push/ pop** of the NavDestination subpage ** — it does not trigger when returned from the detailed page Pop. To listen to NavDestination subpage "Revisive" you must use NavDestination's own `onShown` (and overlap Pop back + back and forth.

# # key life cycle #

♪ Back, back, back, back, back, back ♪
|------|:----------:|:-----------:|:------:|---------|
`onWillShow` | | | | API 12 | page is about to be shown before initialization
**XKEEP0ZX  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **
`onActive` | | API 17 | overlay/Sheet recovery (** not triggered by DIALOG**) |

> ** `onActive` Relationship to DIALOG**: NAVDestination of the DIALOG type is transparent superimposed and displays/disappears** do not affect the life cycle of the standard page of ** and therefore does not trigger `onActive`/`onInactive` of the lower page. The real response to `onActive`/`onInactive` is components such as overlay (`OverlayManager`), `bindSheet`/`bindMenu`/`bindContentCover` that will block the front page of the silo. Upon returning to the top of the inn, `onActive` will also trigger (the page reverts from non-activation to activation), but "back and back-up" should be preferred to a wider `onShown`.

Step 1: Simple refresh (onShown + minimum refresh interval)

Check refresh interval in `onShown` to avoid re-upgrading at short notice:

```typescript
// OrderListPage.ets
@Component
struct OrderListPage {
  navStack: NavPathStack = new NavPathStack();
  @State orderList: Order[] = [];
  @State isRefreshing: boolean = false;
  private lastRefreshTime: number = 0;
Private redonally REFRESH INTERVAL = 30 000; / / 30 seconds without refreshing

  build() {
    NavDestination() {
      Column() {
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            ForEach(this.orderList, (order: Order) => {
              ListItem() {
Text
              }
            })
          }
        }
        .onRefreshing(() => { this.loadData(); })
      }
    }
.title
    .onShown(() => {
/ Check for refreshing every page visible
      const now = Date.now();
      if (now - this.lastRefreshTime > this.REFRESH_INTERVAL) {
        this.loadData();
      }
    })
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
This.loadData(); / / first load data
    })
  }

  private async loadData(): Promise<void> {
    this.lastRefreshTime = Date.now();
    // this.orderList = await OrderService.getList();
  }
}
```

Step 2: Combined UIAbility life cycle (precision control)

More precise refreshing controls are achieved by `AppStorage` passing the application back-to-back switch events to the page layer:

```typescript
/ /entryability/EntryAbility.ets  notify application cut back to the front desk
export default class EntryAbility extends UIAbility {
  onForeground(): void {
// Mark when applying cut back to the front desk
    AppStorage.setOrCreate('appForegroundTime', Date.now());
  }
}
```

```typescript
// Listen to AppStorage changes on page
@StorageProp('appForegroundTime') @Watch('onForegroundTimeChange')
appForegroundTime: number = 0;

onForegroundTimeChange(): void {
Refresh When Back and Back Switches
  this.loadData();
}
```

# # recommended refreshing policy #

♪ The scene, the strategy, the strategy ♪
|------|------|
| Instant Message List
| Order List  `onShown` + Minimal Refresh interval (30s) |
| Commodity Details | `onShown` + Only key data such as price/stock
| Set Page |`onShown` + Do not automatically refresh (manual pull down) |

## # Key API Description

API Note
|-----|------|
`NavDestination.onShown()` | Triggers when the page is visible, including Pop returns and back-to-back and back-to-back switching
`NavDestination.onWillShow()` | The page is about to be activated before display, the back-to-back switch** does not trigger** **
| `NavDestination.onActive()` (API 17) | triggers when active (overlay/ Sheet off, Pop back to the top); ** DIALOG display/ disappearance does not trigger** |
`NavDestination.onReady()`| Triggers when the first creation of the page is complete and is suitable for initial data loading
Z `AppStorage.setOrCreate()` | global status storage for cross-component (UIAbility) forward and forward event

## Attention ##

1. **Driveproof treatment**: back-to-back switch may be triggered several times in a short period of time, setting a minimum refresh interval (e.g. 30 seconds) to avoid frequent requests.

** First loading distinction**: `onReady` for first loading and `onShown` for subsequent updating, with separate duties.

3. ** `onWillShow` is not suitable for reloading back and forth**: The back and forth switch does not trigger `onWillShow`, only ZXXKEEP2ZX can cover both Pop returns and back and backstage switching.

4. **Loating status**: Shows Loating or silent updates on refreshing to avoid sudden data changes leading to UI blinking.

---

scene 2: unsaved contents of the edit page returned confirmation

** scene description: ** When the user enters content on the edit page (forms, comments, personal data editing) but does not save it, press the Return key or click the Return button to pop up the confirmation dialogue box instead of discarding the data directly.

** Solution:** Use NavDestination **`onBackPressed()` Callback** The Interception System Return key to return to `true` consumption event to prevent default pop; determine if there are unsaved changes by comparing the initial snapshot, and pop up **`AlertDialog`** Confirmation dialogue box to confirm the backhand call `navStack.pop()`.

Step 1: Achieve the editing page (stop return + confirm bullet windows)

Record the initial values of the form in `onReady` as a snapshot, and `onBackPressed` determine whether the current values are modified:

```typescript
// EditProfilePage.ets
Note: AlertDialog is global API, no report

@Component
struct EditProfilePage {
  navStack: NavPathStack = new NavPathStack();
  @State nickname: string = '';
  @State bio: string = '';

/ ** Initial snapshot (used to determine whether there have been changes)*/
  private originalNickname: string = '';
  private originalBio: string = '';

/ ** Whether there are unsaved changes */
  private hasUnsavedChanges(): boolean {
    return this.nickname !== this.originalNickname || this.bio !== this.originalBio;
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
TextInput({text: $this.nickname, placeholder: 'nick '}).Width('80%')
TextArea({text: $this.bio, placeholder: 'Personal Profile'}). width('80%').head (120)

        Row({ space: 16 }) {
Button('Save'). onClick()=>
            this.saveProfile();
          })
Button('cancelled').onClick()=>
            this.handleBack();
          })
        }
      }
      .padding(20)
    }
.title
/ / ✅ Core: Intercept system return key
    .onBackPressed(() => {
      if (this.hasUnsavedChanges()) {
        this.showConfirmDialog();
return true; / / consumption return event to stop default pop
      }
return
    })
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      const p = ctx.pathInfo.param as Record<string, string>;
      this.nickname = p?.nickname ?? '';
      this.bio = p?.bio ?? '';
/ Record initial snapshot
      this.originalNickname = this.nickname;
      this.originalBio = this.bio;
    })
  }

/ ** Eject confirmation dialogue*/
  private showConfirmDialog(): void {
    AlertDialog.show({
Title: 'Tip',
message: 'You have unsaved changes, are you sure you want to leave? '...
      primaryButton: {
value: 'Continue editing',
Action: () = > { / / Do nothing, leave it on the current page
      },
      secondaryButton: {
value: 'Unchange',
        action: () => {
This. navStack.pop(); / /verified manual pop
        }
      }
    });
  }

/ ** Generic return processing (this logic is followed when clicking the Cancel button)*/
  private handleBack(): void {
    if (this.hasUnsavedChanges()) {
      this.showConfirmDialog();
    } else {
      this.navStack.pop();
    }
  }

/ ** Preservation of information*/
  private async saveProfile(): Promise<void> {
    // await ProfileService.update({ nickname: this.nickname, bio: this.bio });
This. navStack.pop({saved: true}); / /saved successfully and returned with results
  }
}
```

## # Key API Description

API Note
|-----|------|
`NavDestination.onBackPressed()` | Intercept system return key, return `true` consumption event prevents default pop, return ZXXKEEP2ZX execute default return |
`AlertDialog.show()` | Popup confirmation dialogue box, which provides the options of "continue editing" and "renounce changes"
`navStack.pop()` | Confirms manual pop after waiver of modification returns the previous page
Z`navStack.pop(result)` | Carry Back Results after Saving Successfully

## Attention ##

>  ** Common error: saving initial snapshot in `aboutToAppear`**
> `aboutToAppear` triggers earlier than `onReady`, at which point the route parameter (`ctx.pathInfo.param`) may not have been passed in, the Quick Note has been taken to empty value and the determination of whether there are any unsaved modifications will always be false, returning to the intercept completely invalid. ** Initial snapshot must be saved in `onReady`**, and the parameters are ready.

1. **Return `true` to intercept**: `onBackPressed` to return `true` to indicate a consumption event (stop default pop) and return ZXXKEEP3ZX to perform a default return act.

2. ** The page return button also needs to be addressed**: The "Cancel" button on the page requires the same unsaved judgement called `handleBack()`, consistent with system return key behaviour.

3. **Initial snapshot**: Saves the initial value in `onReady` for comparison of modifications. Avoid saving in `aboutToAppear` because the parameters may not be ready at this time.

4. **Pop**: no need to bomb confirmation after saving successfully, `pop(result)` returns and carries the saving results to the previous page.

---

##3 scene: Tab home page on NewParam

** scene description:** Bottom Tab home page (message / recommendation / mine) is managed as a `NavDestination` case (avoiding creation). When the user returns to the first page from another page, it is necessary to refresh the first page data and to cut to specified Tab - e.g., " Message " Tab when new messages arrive and update unread. The page in the individual mode will not be re-created, so it cannot be re-initiated through `onReady`. It needs to be returned with `onNewParam` to receive new parameters, refresh data and switch to Tab.

** Solution:** Organize a multitab content on the front page of **ZXKEEP0Z**  **  **  **  **  **  **  ** K Z Z Z Z Z ** ** ** ** ** **

The difference between #and onReady

♪ Back, back, back ♪
|------|---------|---------|
`onReady`| Only once | page first created |
Z `onNewParam` | Every time new parameters are received, | Removed to the top of the inn in a single mode

Step 1: First page (support single example + onNewParam refresh)

```typescript
/ HomePage.ets - Bottom Tab Home Page (single + onNewParam refresh)
@Builder
export function HomePageBuilder(name: string, param: Object) {
  HomePage();
}

@Component
struct HomePage {
  navStack: NavPathStack = new NavPathStack();
@state currentIndex: number = 0; // Current activation Tab, bound to Tabs.index
@state unreadCount: number = 0;/ / / Message unread (as shown in Message Tab)
@state feedList: Feed[] =[[]; // / "Recommended" information Stream

  build() {
    NavDestination() {
/ / ★ First Page Multi-Tab; index binding @state, toggle on NewParam
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
/ Tab1: Message
        TabContent() {
          Column({ space: 8 }) {
            if (this.unreadCount > 0) {
Text (`You have {this.unreadCount} Unread `).fontSize(14).fontColor(#FF6B35')
            }
Text('message list contents...').fontSize(16)
          }.width('100%').height('100%').padding(12)
.tabbar.

/ Tab2: Recommendations
        TabContent() {
          Column() {
            List({ space: 8 }) {
              ForEach(this.feedList, (item: Feed) => {
                ListItem() { Text(item.title).fontSize(16) }
              })
            }.layoutWeight(1).width('100%')

/ / From recommended Tab to details page (normal push, return popsonShown, not on NewParam)
Button. onClick()=>
              this.navStack.pushPathByName('DetailPage', null);
            })
          }.width('100%').height('100%')
.tabbar

/ Tab3: Mine
        TabContent() {
Column() {Text('my'). FontSize(16)}
            .width('100%').height('100%').padding(12)
♪ Tab Bar ♪
      }
.scrollable / / Allow Right/ Left Slide Switch Tab
.onChange (index: number)=>{// / User Slide/ Click on Tab
        this.currentIndex = index;
      })
    }
.title

/ / Initialize data at first creation (only once in a single case)
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      this.loadHomeData();
    })

/ / ✅ Core: Receives new parameters when a single page is moved back to the top of the stack
    .onNewParam((param: Object) => {
      console.info('HomePage onNewParam:', JSON.stringify(param));
      const p = param as Record<string, Object>;
/ 1) Switch to specified Tab based on parameters (modify @state, drive Tabs.index switch)
      const tab = p?.['tab'] as string;
      if (tab === 'messages') this.currentIndex = 0;
      else if (tab === 'feed') this.currentIndex = 1;
      else if (tab === 'mine') this.currentIndex = 2;
/ 2) Update unread
      if (p?.['unreadCount']) this.unreadCount = p['unreadCount'] as number;
/ 3) Retake data when carrying refresh marks
      if (p?.['action'] === 'refresh') this.loadHomeData();
    })
  }

  private async loadHomeData(): Promise<void> {
    // this.feedList = await HomeService.getFeed();
    // this.unreadCount = await MessageService.getUnreadCount();
  }
}
```

Step 2: Back to the front page from the other pages (trigger on NewParam + cut Tab)

Carrying new parameters (with target Tab, unread, refreshing tags) through `pushPathByName`, matching `MOVE_TO_TOP_SINGLETON` to move the existing example of the front page in the stack to the top of the post, and `onNewParam` triggers:

```typescript
/ NotificationPage.ets - Click on the notification back to the home page: Cut to Message Tab and refresh unread
Button. onClick(()=>
  this.navStack.pushPathByName('HomePage',
    { action: 'refresh', tab: 'messages', unreadCount: 5 },
{launchMode: LaunchMode. MOVE TO TOP SINGLETON} / / / / / / /larunchMode cannot be omitted: omitted push new examples, onNewParam not touched Fire!
  );
})
```

Upon receiving the parameters on the first page: `tab:'messages'` → `currentIndex=0` (tick to message Tab), `unreadCount:5` → Updates the unreading hint, ZXXKEEP3ZX → Retakes the data.

# # Two LaunchMode comparisons

```
Bars:

MOVE_TO_TOP_SINGLETON('HomePage'):
→ [NavBar, Detila, DetalB, HomePage] / / HomePage moved to the top of the inn, left above

POP_TO_SINGLETON('HomePage'):
→ [Navbar, HomePage] / / HomePage top all pages removed
```

## # Key API Description

|API Note
|-----|------|---------|
`LaunchMode.MOVE_TO_TOP_SINGLETON` | Move the same name page from the search stack to the top of the stack without recreating |API 12+|
`LaunchMode.POP_TO_SINGLETON`| Finds and removes all pages above the same name in the stack |API 12+|
`NavDestination.onNewParam()`| echoes when new parameters are received on a single page and triggers |API 19+| when repositioned to the top in a single case

## Attention ##

> ** Common error 1: `MOVE_TO_TOP_SINGLETON` written in the note, but the code was not passed**
> Only the reference to `launchMode` in the comment / document is invalid and ** must actually be referred to** `pushPathByName(name, param, { launchMode: LaunchMode.MOVE_TO_TOP_SINGLETON })`. Ignores a new example of push from the third session instead of a single example already available in the repeat inn. `onNewParam` does not trigger, cutting Tab/ refreshing logic is all invalid.

> ** Common error 2: Navbar with `Navigation` on the front page but counting on `onNewParam` to trigger**
> Navbar is a permanent root node,** is not `NavDestination`**, does not enter the roadway, and the single mechanism and `onNewParam` are not effective for it. If Tabs must be placed in Navbar, then return to `onShown`/ Component `onAppear`, which can only be refreshed with Navbar. ** This scene requires that the first page is a single example of `NavDestination`** (registered on a route list as a push-able purpose page), which only triggers `onNewParam`.

1. ** Toggle Tab by `@State` instead of controller**: `Tabs.index` binding ZXXKEEP2ZX, `currentIndex` in `onNewParam` to drive the Tab switch; do not bypass the state to call `TabsController.changeIndex()` or conflict with ZXXKEEP6ZX to return the index.

2. ** `onNewParam` is triggered only in a single mode**: an ordinary push new example will not trigger `onNewParam`, only if `MOVE_TO_TOP_SINGLETON` or `POP_TO_SINGLETON` have already appeared on the same name page. Push on the front page and `pop` returns `onShown`, not `onNewParam`.

3. ** `MOVE_TO_TOP_SINGLETON` does not clear the top page**: `POP_TO_SINGLETON` is used if it is necessary to clear all pages above the front page (e.g. from the bottom page directly).

4.** Parameters can be passed on to any object* *: This can be used to pass target Tab, unread, refresh marks, scroll positions, etc., and in the `onNewParam` return, decide which Tab and refresh policy to switch to depending on the parameters content.

5. **`onReady` only triggers once**: the first time the page is created, then the next single case only triggers `onNewParam`, and the two callback duties are separated.

---

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # Zoline the subpages by push, pop and replace # # # # # # # # # # , by # # # # # # # # # # # # # # # # # # # # # # # # # # # # # Through the way by the way of the page by the way of the way of the

scene 1: flash screen page (start page)

** scene description:** When applying cold startup, the system first displays the startup window (assessed by `startWindowIcon` and `startWindowBackground`) and then loads UIAbility and reworks the frame. The flash page assumed responsibility for branding, opening advertising, initialization of the buffer and smooth transition during this period. When the countdown is over or the user clicks, the state switch is made to the content of the home page.

** Solution: ** Use **`module.json5` system start-up window to remove white screen** + **Navigation embedded flash screen page (`showSplash` status driver switch)** ** ** ** parallel preload data during countdown**. The entire application has only one Navigation container, which shares the same NavPathStack with the home page, without having to jump and make a seamless transition.

#### Step 1: Configure system start-up window (free white screen)

Configure the startup window icon and background colour in `entry/src/main/module.json5`:

```json
{
  "module": {
    "abilities": [{
      "name": "EntryAbility",
      "startWindowIcon": "$media:start_window_icon",
      "startWindowBackground": "$color:start_window_background",
      "exported": true
    }]
  }
}
```

> **Key**: Start window background colour (e.g. `#FFFFFF`) should match the background colour of the flash page so that there is no visual flash when the system start window disappears.

Step 2: Achieve an advertising flash page (Index.ets)

Use the flash page as NavBar's first screen content. The following code contains the ability to advertise, displaying the brand page during the loading of the advertisement and switching it to an advertisement when the loading is successful. `showAd`/`adImageUrl` could be deleted without the advertising function:

```typescript
/ pages/Index.ets - Navigation Home Page + Flash Page Embedded
@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();
  @State showSplash: boolean = true;
  @State countdown: number = 5;
@state adImageUrl: string = '; / / ad image URL, delete this and showAd without advertising
  @State showAd: boolean = false;
  private timer: number = -1;

  aboutToAppear(): void { this.loadAdAndStart(); }
  aboutToDisappear(): void { this.clearTimer(); }

  private async loadAdAndStart(): Promise<void> {
This. preloadData(); / / Parallel preloading data (SDK initialization, login status check, home page data)
    try {
/ Rest adData = await AdService.getSplashad(); /// Get ads from service
      this.adImageUrl = 'https://xxx/ad/splash.jpg';
      this.countdown = 5;
      this.showAd = true;
    } catch (error) {
This. showSplash = false; / / Advertisement failed and went directly to the home page
      return;
    }
    this.timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) { this.clearTimer(); this.showSplash = false; }
    }, 1000);
  }

  private clearTimer(): void {
    if (this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
  }

  private async preloadData(): Promise<void> {
// Preload during flash: SDK Initialization, login status check, front page data
  }

  build() {
    Navigation(this.navStack) {
      if (this.showSplash) {
        Stack({ alignContent: Alignment.TopEnd }) {
          if (this.showAd) {
            Image(this.adImageUrl).width('100%').height('100%').objectFit(ImageFit.Cover)
.onClick(()=>{/* Click ads to details page*/})
          } else {
            Column({ space: 16 }) {
              Image($r('app.media.start_window_icon')).width(120).height(120).borderRadius(24)
              Text('MyApp').fontSize(28).fontWeight(FontWeight.Bold)
            }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          }
Button.
            .onClick(() => { this.clearTimer(); this.showSplash = false; })
}.width('100%'). High('100%'). Background Color// Consistent with startWindowBackground
      } else {
        Column({ space: 20 }) {
Text ('head page'). FontSize(28). FontWeight (FontWeight.Bold)
Button. onClick() = {
            this.navStack.pushPathByName('ProductList', null);
          })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
    }
.title
    .hideTitleBar(this.showSplash)
    .mode(NavigationMode.Stack)
  }
}
```

Load this page in `EntryAbility.ets`

```typescript
/ / cruciality/EntryAbility.ets
onWindowStageCreate(windowStage: window.WindowStage): void {
WindowsStage.loadContent ('pages/Index', (err)=> {/* Error processing*/});
}
```

## # Key API Description

|API/ Configuration | Description of | Location |
|-----------|------|------|
`startWindowIcon` / `startWindowBackground` | System Launch Window Icon and Background Colour `module.json5` `abilities` |
`windowStage.loadContent()`| Loading first page contents
`NavPathStack` |Navigation Page Route Stack, managing subpage jump  `Index.ets`|
Hide title bar during `hideTitleBar()` screen flash, restore home page to show `Index.ets`→ Navigation
`aboutToDisappear` | Cleans up the timer to prevent memory leakage  ZXKEEP1Z|

## Attention ##

> ** Common error: StartWindowBackground different from flashbackColor colour**
> Both must be fully consistent (e.g. `#FFFFFF` or both ZXXKEEP1ZX), otherwise the cold start will have a colour flash. ** Do not set the flash screen page to black for "good" and the start-up window to white** - AI generation often advocates a change of colour, so it is important to check word for word.

1. ** `startWindowBackground` must be fully consistent with the flash page `backgroundColor`**: differences in colours will result in cold-start flashing when a system-start window disappears. `module.json5` must have the same character by character as the flash page `.backgroundColor(...)`.

2. ** Flash page transitions by status instead of page jump**: `showSplash` status control flash and home page transitions, where the user does not return to the flash page by pressing the return key, while avoiding visual fractures from the page switch animation.

3. ** Timer must be cleaned in `aboutToDisappear`**: otherwise it causes a memory leak.

4. ** Flash page should be as light as possible**: Data preloading should be done by walk without blocking UI.

** Thermal start-up usually does not show flash screen pages**: flash pages are loaded through `loadContent` at cold start. Thermally activated `onForeground` if the Ability example is still alive, `onForeground` echoes, `showSplash` keeps `false` unshowed; however, if Ability is rebuilt after the system has been recovered, `loadContent`, `showSplash` reset to ZXXKEEP6ZX still displays a flash.

---

## # scene 2: Page path re-direction (underline/AB test)

**Scene description:** In the course of the page route, target pages need to be intercepted and redirected to other pages in accordance with operational rules. Typical scenarios include: auto-jumping to a substitute page or maintenance of a bulletin page after the old page is down, re-directing the old entry to a new page in the A/B test by grouping the different versions of the page according to the user's path, and moving the function.

** Solution:** Use `willShow` of **XKEEP0ZX to return** Intercept page to show that in the echo, re-direction rules are matched according to the target page name, remove the original target page, `pushPathByName` to the new page and retain the original parameters.

### # Step 1: Define a re-direction rule

Configure static redirection map (underline/move) and dynamic redirection logic (A/B test):

```typescript
// RouteRedirector.ets

/**
:: Page Redirection Configuration
* Source page to the left and target page to the right Noodles.
 */
const REDIRECT_RULES: Record<string, string> = {
'OldProdudDetail': 'ProdudDetail', / / Old Page Page Noodles.
'DepturedFeature': 'MaintenancePage', / / Closed maintenance bulletin
};

/**
:: Dynamic reoriented logic (example A/B test)
 */
function getABTestPage(originalPage: string): string {
const userGroup = 'B';/ / Only for example, the actual business scene should be accessed from the service or local cache
  if (originalPage === 'HomePage' && userGroup === 'B') {
    return 'HomePageV2';
  }
  return originalPage;
}
```

Step 2: Registration route interceptor

At the time of the initialization of the Navigation, re-direction was achieved through `setInterception` echoes:

```typescript
/ RouteRedirector.ets (continued)

export function setupRedirectInterceptor(pageStack: NavPathStack): void {
  pageStack.setInterception({
    willShow: (from, to, operation, animated) => {
      if (typeof to === 'string') return;

      const target = to as NavDestinationContext;
      const pageName = target.pathInfo.name;

// Rule 1: static re-direction (underline/transfer)
      if (REDIRECT_RULES[pageName]) {
        const newPage = REDIRECT_RULES[pageName];
        console.info(`Redirect: ${pageName} → ${newPage}`);
        target.pathStack.pop();
        target.pathStack.pushPathByName(newPage, target.pathInfo.param);
        return;
      }

// Rule 2: AB Test dynamic reorientation
      const abPage = getABTestPage(pageName);
      if (abPage !== pageName) {
        target.pathStack.pop();
        target.pathStack.pushPathByName(abPage, target.pathInfo.param);
      }
    }
  });
}
```

Step 3: Enable interception on the Navigation page

Call the interceptor registration function after creating NavPathStack:

```typescript
// pages/Index.ets
/ / RouteRedirector ' s complete code appears in step 1 (redirection rule) and step 2 (interceptor registration)
import { setupRedirectInterceptor } from '../common/RouteRedirector';

@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
Registered routers
    setupRedirectInterceptor(this.navStack);
  }

  build() {
    Navigation(this.navStack) {
/ Homepage content...
      Column({ space: 20 }) {
Text
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

/ / Click to trigger route if OldProdutDetail in Redirect Medium
/ / Autoredirect to ProjectDetail
Button.
          .onClick(() => {
            this.navStack.pushPathByName('OldProductDetail', { id: '123' });
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
.title
    .mode(NavigationMode.Stack)
  }
}
```

## # Key API Description

API Note
|-----|------|
`setInterception({ willShow })` | Intercept the echo before the page displays, where you can modify the router |
`target.pathInfo.name`| Get the target page name to match the redirective rule
`target.pathInfo.param`| Get the target page parameters and redirect them to the new page
`target.pathStack.pop()` | Remove the original target page of the ink
`target.pathStack.pushPathByName(name, param)` | Redirect to new page and keep original parameters

## Attention ##

** `willShow` Trigger**: `willShow` Upon Call Trigger ** Target page has been created** (but subsequently destroyed), which is later than `interception`.

2. **Retention of original parameters**: Redirection must be transmitted to the new page by `target.pathInfo.param` to avoid data loss.

3. ** Avoid re-direction of the cycle**: Ensure that the re-direction chain has an endpoint (e.g., A → B → A cycle leads to an unlimited cycle) and suggest that a closed loop be tested in the rule configuration.

4. ** Redirectional rule centralized**: It is proposed that the redirected rule should be maintained in a uniform manner in `RouteRedirector`, so as to avoid dissipation that would make maintenance difficult.

---

##3 scene: complex parameters involved in return Value

** scene description: ** Multipage Jumping, with complex parameters to carry and receive return results. Typical scenarios are: Commodity List Page with Commodity ID jumps to the Commodity Details page, Detailed Pages jumps to the Shopping Page, and when the Shopping Vehicle returns, it needs to return to the List Page with selected commodity information. Similarly, the address selection page returns the selected address, the filter page returns the filter condition, the date selection page returns the selected date, etc.

** Solution: ** Register returns with the third parameter **`pushPathByName(name, param, onPop)`** + ** `pop(result)` carrier returns**. `onReady` in the target page `ctx.pathInfo.param` to receive ZXXKEEP4ZX Z0ZX on return

Step 1: Define parameters Category

The type of reference and return value defined is centrally managed to ensure that pages can be referenced:

```typescript
// model/ShoppingParams.ets

*/ ** Text of commodity details */
export class ProductDetailParam {
  productId: string = '';
  fromPage: string = '';
}

*/ ** Shopping car returns */
export class CartResult {
  addedItems: CartItem[] = [];
  totalCount: number = 0;
  totalPrice: number = 0;
}

export class CartItem {
  productId: string = '';
  name: string = '';
  price: number = 0;
  quantity: number = 1;
}
```

> ** Type check `instanceof`, not `typeof` or field sniff**: `onPop` returned the `popInfo.result` type `Object`, which must first determine the true type and access to the field using `instanceof`. This is why step 1 defines the parameter class in a `model/` directory — the `instanceof` requirement definition can be found in both callers and echoes.

```typescript
/ / Send page onPop Callback uses instanceof for type check (types are determined before field access)
this.navStack.pushPathByName('ProductDetail',
  { productId: item.id } as ProductDetailParam,
  (popInfo: PopInfo) => {
/ / / use instanceof to judge the true type of return result
    if (popInfo.result instanceof CartResult) {
      const result = popInfo.result as CartResult;
      this.cartCount += result.totalCount;
    }
/ Result is not CartResult (e. g. undefined/ other types) without going into branches to avoid access without field crashes
  }
);
```

Step 2: Send Page (Commodity List → Commodity Details)

`onPop` is registered by `pushPathByName` for the third parameter, receiving the return of the target page:

```typescript
// ProductList.ets
See step 1 for definition of type (Product DetailParam, CartResult, CartItem)
import { ProductDetailParam, CartResult } from '../model/ShoppingParams';

@Component
struct ProductList {
  navStack: NavPathStack = new NavPathStack();
  @State cartCount: number = 0;

  build() {
    NavDestination() {
      List() {
        ForEach(this.products, (item: Product) => {
          ListItem() {
            Row() { Text(item.name); Text(`¥${item.price}`) }
            .onClick(() => {
/ / / / Key: the third parameter is onPop echo, receiving target page returns
              this.navStack.pushPathByName('ProductDetail',
                { productId: item.id } as ProductDetailParam,
                (popInfo: PopInfo) => {
                  const result = popInfo.result as CartResult;
                  if (result) { this.cartCount += result.totalCount; }
                }
              );
            })
          }
        })
      }
    }
    .onReady((ctx) => { this.navStack = ctx.pathStack; })
  }
}
```

Step 3: Midpage (Commodity Details → Jump Shopping)

`onReady` receives parameters from `ctx.pathInfo.param` that entered the previous page:

```typescript
// ProductDetail.ets
/ Shoping Params
import { ProductDetailParam } from '../model/ShoppingParams';

@Component
struct ProductDetail {
  navStack: NavPathStack = new NavPathStack();
  private productId: string = '';

  build() {
    NavDestination() {
      Column() {
Text (`Commodity Details ${this.productId}')
Button. onClick() = {
          this.navStack.pushPathByName('ShoppingCart',
            { productId: this.productId });
        })
      }
    }
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      const p = ctx.pathInfo.param as ProductDetailParam;
      this.productId = p?.productId ?? '';
    })
  }
}
```

Step 4: Return to page (shopping car → returns with results)

Bring the result back to the sending page with `pop(result)`, which automatically triggers the return of `onPop`:

```typescript
// ShoppingCart.ets
/ Shoping Params
import { CartResult, CartItem } from '../model/ShoppingParams';

@Component
struct ShoppingCart {
  navStack: NavPathStack = new NavPathStack();
  @State selectedItems: CartItem[] = [];

  build() {
    NavDestination() {
      Column() {
Text.
Button('Recognition Selection'). onClick()=>
/ / / / key: pop while carrying the return result, triggers the onPop echo on the start page
          const result = new CartResult();
          result.addedItems = this.selectedItems;
          result.totalCount = this.selectedItems.length;
          result.totalPrice = this.selectedItems.reduce((s, i) => s + i.price * i.quantity, 0);
          this.navStack.pop(result);
        })
      }
    }
    .onReady((ctx) => { this.navStack = ctx.pathStack; })
  }
}
```

## # Key API Description

API Note
|-----|------|
`pushPathByName(name, param, onPop)` | Jump and Pass, `onPop` Returns the result of the target page
`ctx.pathInfo.param`| Subject page receives parameters from the previous page in `onReady`
`navStack.pop(result)` | returns the upper layer and carries the results and triggers the `onPop` echo of the launch page
`PopInfo.result` |`onPop` Reverting to get the result objects carried by the returned page
Z`onReady((ctx) => {})` | NavDestination Life Cycle echo for receiving parameters and fetching pathStack |

## Attention ##

1. ** Parameters are to be accessible in the same module**: `instanceof` type check the definition of required category (e.g. `ProductDetailParam`, `CartResult`) on the target page, and it is suggested to focus on the definition under `model/` directory.

2. ** Parameters must be sequenced**: non-serialized values such as non-serialized functions, Symbol and only basic types and serialized objects.

3. ** It is not recommended that too large objects**: large pictures, long lists, etc. should be shared through global state management (AppStorage, PersistentStorage), with parameters only transmitting index or ID.

4. ** `onPop` Backlink**: A push B (registration on Pop) → B push C → C pop (result) → B received results on Pop on A. When multi-layer jumps, be careful whether the results need to be passed through the layers.

---

SideBarContainer + Navigation Multi-end Match

** scene description:** Mailbox type applications require different columns on different devices: cell phone columns (list details), fold screen double columns (list + details), tablet/PC three columns (sidebar + list + details). The core route pains: `push` causes an infinite increase in the router tower every time you click on an e-mail under the sub-column; there are no defaults on the right.

** Solution:** Using **`SideBarContainer` package **. ** `replacePathByName`** (avoiding the explosion of a router) and `pushPathByName` under column. `onNavigationModeChange` Synchronized router policy, using breakpoint detection for the Navigation-driven Stack/Spit mode switch.

# # The route at each breakpoint #

| Device | Breakpoint | Navigation Mode | Email toggle API | HiideBackButton |
|------|------|----------------|-------------|---------------|
`pushPathByName` Zalse
`replacePathByName` true
`replacePathByName` plain
PC/2in1 xl Split column

#### Step 1: Route Support Class (subbar replace / column push)

Three-column development of the most critical ** cover - Auto-select push or replace according to Navigation mode:

```typescript
// common/RouterHelper.ets
export class RouterHelper {
  private navPathStack: NavPathStack;
  private isSplitMode: boolean = false;

  constructor(navPathStack: NavPathStack) {
    this.navPathStack = navPathStack;
  }

  setMode(mode: NavigationMode): void {
    this.isSplitMode = (mode === NavigationMode.Split);
  }

  /**
* Go to Details Page
* - Column: Push New Page (return button)
* - Column: replace right-hand content (avoiding endless growth of roadway walls)
   */
  navigateToDetail(name: string, param?: Object, animated: boolean = true): void {
    if (this.isSplitMode) {
      if (this.navPathStack.size() > 0) {
        this.navPathStack.replacePathByName(name, param, animated);
      } else {
        this.navPathStack.pushPathByName(name, param, animated);
      }
    } else {
      this.navPathStack.pushPathByName(name, param, animated);
    }
  }

/ ** Skipping subpages from details (see attachments, etc.), always push*/
  navigateToSubPage(name: string, param?: Object): void {
    this.navPathStack.pushPathByName(name, param);
  }

  goBack(result?: Object): void {
    if (this.navPathStack.size() > 0) {
      this.navPathStack.pop(result, true);
    }
  }
}
```

### # Step 2a: Breakpoint Drive Stack/Spit Mode Switch (must be driven by breakpoint, Navigation Mode. Auto)

Embedded order: `SideBarContainer > Column > Navigation`. ** The most critical line** is the `mode` - `sm` column with `Stack`.** The rest is with `Split`.** Must be driven by breakpoint, not by ZXKEEP5Z** (cell phone screens are mistouched).

> Step 2a → 2b → 2c is ** the sequence segment of the same `Index` component**, in which the serialization is the complete encoded code and the three pieces cannot be omitted.

```typescript
// pages/Index.ets - Step 2a: Navigation Container + Breakpoint Driver (RouterHelper for Step 1)
@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  private routerHelper: RouterHelper = new RouterHelper(this.navPathStack)

  build() {
SideBarContainer(/* Breakpoint Decision Overlay/ Embed*/) {
Column() { / * Column 1: Sidebar (Accounts/ Folders), clear() Route Wall */ }
      Column() {
        Navigation(this.navPathStack) {
/ Column 2: Maillist (NavBar)
/ / Click Mail →This.routerHelper. navigateToDetail
        }
/ / 🔑 Core: Breakpoint Drive Stack/Spit Switch (no Navigation Mode. Auto)
        .mode(this.currentBreakpoint === 'sm'
          ? NavigationMode.Stack : NavigationMode.Split)
        .navBarWidth(this.currentBreakpoint === 'md' ? '50%' : '40%')
. navDestination (this.PageMap) / /PageMap definition at step 2c
Step 2b: SplitPlaceholder / onnavigationModeChange next to the Navigation chain
```

### # Step 2b: SplitPlaceholder + onnavigationModeChange (must be achieved, synchronized router)

The right side of the column is empty with `splitPlaceholder` for placeholder content; `onNavigationModeChange` syncs the `RouterHelper` mode when the single/subbar is switched, and takes place silently on the `push` page when the first entry of the column is made. ** Both must be achieved** (continuing 2a Navigation chain, then closed)

```typescript
/ / 🔑 column space page (API 20+, not routed)
        .splitPlaceholder(() => {
Column() {Text('Select an email to see details')}
        })
/ / 🔑 Mode Switchback: Synchronize route policy + Process routers
        .onNavigationModeChange((mode: NavigationMode) => {
RouterHelper. setMode; / / Sync Steps 1
          if (mode === NavigationMode.Split && this.navPathStack.size() === 0) {
This. navPathStack. PushPathByName ('MailEmpty', full, false); / / sub-column first occupied Page
          }
        })
} / / Closed Column
SideBarContainer
} / / Closed
```

Step 2c: Route Map PageMap (must be achieved, close)

`navDestination` returns to distribute the corresponding NavDestination component by page name. `PageMap`, member of `@Builder`, attached to `build()` and closed:

```typescript
/ / 🔑 path map (strutt member, after build())
  @Builder
  PageMap(name: string) {
If (name == 'Mail Detail') {Mail DetailPage()} // See Step 3
    else if (name === 'MailEmpty') { MailEmptyPage() }
  }
} / Close
```

#### Step 3: Mail details page (column path appropriate)

In column mode: Hide Return button + `onNewParam` receives new parameters from replace:

```typescript
/ pages/MailDetailPage.ets
@Component
struct MailDetailPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State mail: MailItem | null = null

  build() {
    NavDestination() {
/... Email details UI content
    }
.title (this.mail?
...sideBackButton (this.currentBreakpoint!= 'sm') / / 🔑 subbar hides back buttons (list always visible)
.onNewParam((newParam:Object)=> {this.mail =newParam as MailItem;}) / 🔑replace does not recreate pages, triggers onNewParam
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      this.mail = ctx.pathInfo.param as MailItem;
    })
  }
}
```

## # Step: The path of breakpoints is synchronized by the bar

Automatically handle router status (changed through `@Watch` listening breakpoint) when folding/expanding:

```typescript
@Watch('onBreakpointChange')
@StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'

onBreakpointChange(): void {
  if (this.currentBreakpoint === 'sm') {
/ / Collapse to cell phone state: empty back to pure list when only space pages are in the warehouse
    if (this.navPathStack.size() === 1) {
      let names = this.navPathStack.getAllPathName();
      if (names.length > 0 && names[0] === 'MailEmpty') {
        this.navPathStack.clear();
      }
    }
  } else {
/ / Expand to column pattern: stacks are empty to load placeholder Page
    if (this.navPathStack.size() === 0) {
      this.navPathStack.pushPathByName('MailEmpty', null, false);
    }
  }
}
```

# # Route Quick Check

| Operation Stack Bar (Split) | Reason
|------|--------------|--------------|------|
| Click on e-mail for details  Z`pushPathByName` |`replacePathByName` | Push by column sub-bar
| Details Subpage  `pushPathByName` |`pushPathByName` | Subpage requires a stand-alone stack
| Back to the previous page  Z `pop` | `pop` (sole page)
| Toggle account/folder |XKEEP0ZX |`clear()`| Empty old data to avoid displaying old details

## # Key API Description

|API Note
|-----|------|---------|
`NavigationMode.Stack / Split`| column/column mode, breakpoint driver toggle |API 9+|
`onNavigationModeChange`| mode toggle rotation, synchronized router policy |API 11+|
|`replacePathByName` | Replaces the top of the stack page (subbar to core API for details) |API 11+|
`splitPlaceholder` | Blank space page (without route) |API 20+ |
`NavDestination.onNewParam`| page receives new parameters when replace
`NavDestination.hideBackButton`| Hide Back button for column breakup |API 15+|
Z`navBarWidth` | Navbar width (control list column width at break) |API 9+|

## Attention ##

1. ** Embedded sequence not reversed**: must be `SideBarContainer > Column > Navigation` and cannot be reversed.

2. ** Column e-mail exchange must be `replacePathByName`**: Use `push` will result in an unlimited increase in the routeway.

3. **The account/folder must be replaced by `clear()` router**: Otherwise the mail details of the old account will remain on the right.

4. ** `onNavigationModeChange` is the key echo**: `RouterHelper` must be synchronized here.

5. ** `onNewParam` processing replace parameter update**: `replacePathByName` under column does not rebuild NavDestination, but triggers `onNewParam`, the data must be updated here.

6. ** Do not use `NavigationMode.Auto`**: Cell phone screens may mistouch the column and suggest breakpoint drivers for manual switching.

7. ** Do not devolve the column into a column under the Spiet model `hideNavBar(true)`**.

8. ** `splitPlaceholder` Relation to push placeholder page**: `splitPlaceholder` (API 20+) is an automatic display of UI in the column empty time frame system,** unfocused **; `MailEmpty` in `onNavigationModeChange` is the real page for entry to the roadway portal, with the effect of keeping ZXXKEEP4ZX under the sub-column with a page available for ZXXKEEP5ZX. The two functions are different: `splitPlaceholder` can be used only to save the push space page if the minimum API 20 is supported and `replace` is not subject to routing; this example exists to make it compatible with earlier versions and to ensure that `replace` logic is established.

---

##5: Half-bar chat application

** scene description: ** Chat-type applications (micro-intelligence, nails) need to adapt to cell phones (column list details) peaceboard/folding screen expansion (right/right column, list + details). Unlike the three-column e-mail scene, the two-column does not need SideBarContainer, but only the Navigation Stack/Spit mode. The core routing point is the same: the following table in the column must be replaced by `replacePathByName` to avoid the explosion of the routing.

**Solution:** Using **Navigation 's Split model**, NavBar plays session list, NavDestination plays chat details. The route policy is in line with the three-point scenario (RouterHelper sealed subbar replace / column push). This scenario has additional coverage **Navigation + Tabs Monument Program** (global route management for the bottom Tab bar application).

> The router support class `RouterHelper` is identical to the three-point field scene and is not repeated here. See [Scene 4: Step 1] (#Step-1 by Auxiliary Class Column - Replace - Column - Push).

Step 1a: Navigation skeleton + breakpoint driver Stack/Spirit (must be broken point driven, Navigation Mode.Auto)

Without SideBarContainer, use the Navbar (session list)/ NavDestination (chat details) column to the left. ** The most critical line** is `mode`-`sm`, with `Stack` and the rest with `Split`. ** Must be driven by breakpoints, not `NavigationMode.Auto`**.

> Step 1a → 1b → 1c is ** Sequenced session of the same `Index` component**, in which the serialization is the complete encoded code and the three pieces cannot be omitted.

```typescript
/ /pages/Index.ets - Step 1a: Navigation Container + Breakpoint Drive (repeated with RouterHelper in three-point scenario 4 step 1)
@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State selectedConvId: string = ''
  private routerHelper: RouterHelper = new RouterHelper(this.navPathStack)

  build() {
    Navigation(this.navPathStack) {
/ Navbar: list of sessions
      Column() {
        List({ space: 0 }) {
          ForEach(this.conversations, (conv: Conversation) => {
ListItem(){/* Session List Item*/}
            .onClick(() => {
              this.selectedConvId = conv.id;
/ / 🔑 Core: column with replace and column with push (selected by RouterHelper)
              this.routerHelper.navigateToDetail('ChatDetail', conv);
            })
          })
        }
      }
    }
/ / 🔑 Core: Breakpoint Drive Stack/Spit Switch (no Navigation Mode. Auto)
    .mode(this.currentBreakpoint === 'sm' ? NavigationMode.Stack : NavigationMode.Split)
    .navBarWidth(this.currentBreakpoint === 'lg' ? '44.5%' : '50%')
. navDestinization (this.buildNavDestinization) / / Definition in Step 1c
1b:onNavigationModeChange
```

Step 1b: unnavigation ModeChange Switchback (must be achieved, synchronized router policy)

The column is empty on its first entry, and the `RouterHelper` mode needs to be synchronized in the mode switchback and the `push` placeholder page is silent. ** Must be achieved** (continuing 1a Navigation chain, then closed)

```typescript
/ / 🔑 Mode Switchback: Synchronize Route Policy + Split Bar Stack Processing
    .onNavigationModeChange((mode: NavigationMode) => {
This.routerHelper.setMode (mode); / /Sync RouterHelper Mode State
      if (mode === NavigationMode.Split && this.navPathStack.size() === 0) {
This. navPathStack. PushPathByName ('ChatEmpty', full, false); / / sub-column first occupied Page
      }
    })
} / / Closed
```

### # Step 1c: route map builtNavDestification (must be achieved, close)

`navDestination` returns to distribution by page name to the corresponding NavDestination component, attached to `build()` and closed:

```typescript
/ / 🔑 path map (strutt member, after build())
  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'ChatDetail') { ChatDetailPage({ contact: param as Conversation }) }
    else if (name === 'ChatEmpty') { ChatEmptyPage() }
  }
} / Close
```

#### Step 2: Chat for details pages (column by line)

Same logic as the three-column detailed page route: `hideBackButton`+`onNewParam`:

```typescript
/ pages/ChatDetailPage.ets
@Component
struct ChatDetailPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State contact: Conversation | null = null

  build() {
    NavDestination() {
/... chat content UI
    }
    .title(this.contact?.name ?? '')
...sideBackButton (this.currentBreakpoint!== 'sm') / / 🔑 subbar hides back buttons
.onNewParam((newParam:Object)=> {this.contact=newParam asConversion;}) / 🔑replace parameter refreshing
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      this.contact = ctx.pathInfo.param as Conversation;
    })
  }
}
```

### Progress: Navigation + Tabs Monument Scheme

When application has a bottom Tab bar (e. g. micro-mail: message/message/discovery/me), you can use **navigation embedded Tabs, single NavPathStack to manage the entire application route**:

```typescript
/ Navigation + Tabs Monk Program
@Entry
@Component
struct Index {
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State currentPageIndex: number = 0

  build() {
    Navigation(this.pageInfo) {
      Tabs({ index: this.currentPageIndex,
        barPosition: this.currentBreakpoint === 'lg' ? BarPosition.Start : BarPosition.End
      }) {
TabContent() {MessagesPage()}.tabBar('message')
/...other TabContent
      }
.vertical (this.currentBreakpoint == 'lg') / Tab, lower
      .onChange((index: number) => {
        this.currentPageIndex = index;
This. PageInfo.clar(); / / / 🔑 to switch Tab to clear the route house
        if (this.currentBreakpoint !== 'sm') {
          this.pageInfo.pushPath({ name: 'ConversationDetailNone' });
        }
      })
    }
    .hideTitleBar(true)
    .mode(this.currentBreakpoint === 'sm' ? NavigationMode.Stack : NavigationMode.Split)
    .navBarWidth(this.currentBreakpoint === 'lg' ? '44.5%' : '50%')
    .navDestination(this.PageMap)
  }
}
```

Single stack vs per Tab stand alone:

Zero dimensions per Tab standalone + Tabs standalone
|------|-------------|----------------------|
Isolation of roads, complete independence of Tab, sharing of roads,
| Management complexity, high (multiple NavPathStack) low (single NavPathStack) low
Tab toggle, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lyum, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, lymph, 
|Applicable scene |Asymmetrical differences in the path of Tabs |Asymetics of Tabs

### # Progress: Collapse breakpoint change processing

```typescript
@Watch('onBreakpointChange')
currentBreakpoint: string = 'sm'

onBreakpointChange() {
  if (this.currentBreakpoint !== 'sm') {
    if (this.pageInfo.size() === 0) this.pageInfo.pushPath({ name: 'ConversationDetailNone' });
  } else {
If (this.pageInfo.size() = = 1) this.pageInfo.pop(); / / Only empty pages back to the list
  }
}
```

# # Route Quick Check

| Operation Stack Bar (Split) | Reason
|------|--------------|--------------|------|
| Click on a session for details  Z`pushPathByName` |`replacePathByName` | Push in the column sub-column will result in an infinite increase in the roadway
| Details Subpage  `pushPathByName` |`pushPathByName` | Subpage requires a stand-alone stack
| Back to the previous page  Z `pop` | `pop` (sole page)
| Toggle Tab |XKEEP0ZX + Push |XKEEP1ZX + push placeholder | Empty old stacks and load new Tab default page

## Attention ##

** The column list must be replaced by `replacePathByName`**: In line with the three-point scenario, the use of `push` will result in an unlimited increase in the router.

2. ** Navbar is not controlled by a router **: `push`/`pop`/`replace` affects only the right-hand content area, and Navbar on the left cannot be operated by a router API.

3. ** `onNavigationModeChange` is the key echo**: It is necessary to synchronize routing policies here and to ensure content on the right side of the column (otherwise, white on the right).

** Do not devolve the column to a column under the Split model `hideNavBar(true)`**.

5. ** Cell phone screen error-proofing column**: `NavigationMode.Auto` breakpoint 600vp, possibly triggered. It is recommended to use breakpoint drivers for manual switching.

6. ** Placeholder policy is consistent with the three-point view**: `ChatEmpty` of `onNavigationModeChange` of push of `onNavigationModeChange` is the real route for place-holder (to have `replace` under the column) and `MailEmpty` of the three-point scenario; if API 20 is the minimum, the ZXXKEEP4ZX (automated, unloved) can also be replaced by ZXXKEEP4ZX.

---

# Three, build subpages, configure to enable the Navigation Route Table

## # scene 1: Route Intercept Permission Validation (declaration permission + centralized interception)

** scene description: ** Not all pages in application require login to access (e.g., front page, list of goods is public, while personal centre, order list requires login). If `onReady` is written separately on each page, this leads to duplication of codes, easy to miss and maintenance difficulties. Best practice is to declare page-marking privileges in the `data` field of the system route chart (`router_map.json`), to be read and verified in the `willShow` echo by the `NavPathStack.setInterception` route-interceptor, to achieve **-declaration permission + centralized interception**.

** Solution:** Declared tag permissions using `data` field ** (`requireAuth`, `requireVIP` etc.) ** `willShow` to intercept during mobilization ** + **`NavDestinationContext.getConfigInRouteMap()` read data**. The page code does not need to be concerned about the privileges logic, the interceptor processes the rights, jumps to the login page, and jumps back on login.

Intercept callback selection: why willShow

`setInterception()` objects have 4 echoes:

Whether or not the `getConfigInRouteMap()` page has been created
|------|----------|----------|---------------|-------------------------------|
Z `interception`| **22** ** Before the creation of the page | ❌ does not create | ❌ cannot (parameter `NavPathInfo`) |
`willShow`| **12** ** before displaying | created | (parameter `NavDestinationContext`) |
`didShow` ** **12** ** When the page displays  ** has been created  **
`modeChange`  ** **12** | When a single double-bar switch is made

The programme uses `willShow` for:
`getConfigInRouteMap()` to read router `data` field - `interception` The parameter for ZXXKEEP3ZX (name/ param only) is not available
2. `willShow` is available from API 12 and is best compatible
`interception` (API 22+) suitable for re-direction of hard-coding at pure name level (e. g. A/B test pageA → pageA') and not for permissions to verify scenes requiring reading data

### # Step 1: Declare the data permission tag in the route list

Configure `resources/base/profile/router_map.json` fields for each page:

```json
{
  "routerMap": [
    {
      "name": "HomePage",
      "pageSourceFile": "src/main/ets/pages/HomePage.ets",
      "buildFunction": "HomePageBuilder",
"data": {"requireAuth": false, "title": "front page", "trackId": "page home"}
    },
    {
      "name": "LoginPage",
      "pageSourceFile": "src/main/ets/pages/LoginPage.ets",
      "buildFunction": "LoginPageBuilder",
"data":
    },
    {
      "name": "OrderList",
      "pageSourceFile": "src/main/ets/pages/OrderList.ets",
      "buildFunction": "OrderListBuilder",
"data":
    },
    {
      "name": "Settings",
      "pageSourceFile": "src/main/ets/pages/Settings.ets",
      "buildFunction": "SettingsBuilder",
"data": {"requireAuth": true, "requireVIP": true, "title": "VIP Settings"}
    }
  ]
}
```

`data` field indicates:

| Field | Type | Description |
|------|------|------|
`requireAuth` | Boolean | Do you need to login to access |
`requireVIP` |boolean |Whether VIP permissions are required
`title` | string | page title (which can be used to unify the titlebar configuration)
`trackId` |string| Site ID (for uniform page access statistics)

> `data` fields are fully defined key pairs and developers can freely expand according to business needs (e. g. `role`, `minVersion`, `orientation`, etc.).

### # Step 2: Register a route list in mobile.json5

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "routerMap": "$profile:router_map"
  }
}
```

Step 3: Achieve a unified route interceptor

Read router `willShow` configuration in `willShow` return with `getConfigInRouteMap()` to harmonize check privileges:

```typescript
// AuthInterceptor.ets
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AuthInterceptor';

/**
*Authorization structure for router data fields
 */
interface RouteAuthConfig {
  requireAuth?: boolean;
  requireVIP?: boolean;
  title?: string;
  trackId?: string;
  [key: string]: Object | undefined;
}

/**
:: Login status management (example, actual item replaced with real account module)
 */
export class AuthManager {
  private static isLoggedIn: boolean = false;
  private static isVIP: boolean = false;

  static setLoginStatus(loggedIn: boolean): void {
    AuthManager.isLoggedIn = loggedIn;
  }

  static setVIPStatus(isVIP: boolean): void {
    AuthManager.isVIP = isVIP;
  }

  static checkLoggedIn(): boolean {
    return AuthManager.isLoggedIn;
  }

  static checkIsVIP(): boolean {
    return AuthManager.isVIP;
  }
}

/**
:: Registered routers
:: Harmonize page permissions in willShow
 */
export function setupAuthInterceptor(pageStack: NavPathStack): void {
  pageStack.setInterception({
    willShow: (from: NavDestinationContext | 'navBar',
               to: NavDestinationContext | 'navBar',
               operation: NavigationOperation,
               animated: boolean) => {
/ / Target navbar, direct release
      if (typeof to === 'string') {
        hilog.info(DOMAIN, TAG, 'Target is navBar, allow.');
        return;
      }

      const target = to as NavDestinationContext;
      const pageName = target.pathInfo.name;

/ / Data Configuration in Reading Route Table
      const config = target.getConfigInRouteMap();
      if (!config || !config.data) {
        hilog.info(DOMAIN, TAG, `Page [${pageName}] has no data config, allow.`);
        return;
      }

      const routeData = config.data as Record<string, Object>;
      hilog.info(DOMAIN, TAG, `Page [${pageName}] route data: ${JSON.stringify(routeData)}`);

/ Check for login
      const requireAuth = routeData['requireAuth'];
      if (requireAuth === true && !AuthManager.checkLoggedIn()) {
        hilog.warn(DOMAIN, TAG, `Page [${pageName}] requires auth, redirecting to LoginPage.`);
/ Intercept: First pop the target page, then push to login Page
        target.pathStack.pop();
/ / Pass the original target page name as a parameter to the login page, which will automatically jump back when login is successful
        target.pathStack.pushPathByName('LoginPage', { targetPage: pageName });
        return;
      }

/ / Check for VIP
      const requireVIP = routeData['requireVIP'];
      if (requireVIP === true && !AuthManager.checkIsVIP()) {
        hilog.warn(DOMAIN, TAG, `Page [${pageName}] requires VIP, redirecting to VIP page.`);
        target.pathStack.pop();
        target.pathStack.pushPathByName('LoginPage', {
          targetPage: pageName,
          reason: 'vip_required'
        });
        return;
      }

/ Site: Unified log page access
      const trackId = routeData['trackId'];
      if (trackId) {
        hilog.info(DOMAIN, TAG, `Page track: ${trackId}`);
/ TODO: Call actual site SDK
      }

      hilog.info(DOMAIN, TAG, `Page [${pageName}] auth check passed.`);
    }
  });
}
```

Step 4: Navigation Home Page Access Interceptor

```typescript
// Index.ets
/ /AuthInterctor's complete code is shown above step 3 (same module within the project)
import { setupAuthInterceptor, AuthManager } from '../common/AuthInterceptor';

@Entry
@Component
struct Index {
  pageStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
/ Registered routers
    setupAuthInterceptor(this.pageStack);
  }

  build() {
    Navigation(this.pageStack) {
      Column({ space: 20 }) {
/ / No need to login - Just jump
Button.onClick()= > this.pageStack.pushPathByName('HomePage', null)
/ / Need to login - Autostop to login if not Page
Button ('OrderList', null) .onClick(()=>This.pageStack.pushPathByName
/ Require VIP
Button('VIP Settings').onClick(()=> this.pageStack.pushPathByName ('Settings', null)
        Divider()
// Simulate login/exit (presentation only)
Button.onClick(()=>AuthManager.setLoginStatus(true)
Button.onClick(() = >AuthManager.setLoginStatus (false))
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
.title
    .mode(NavigationMode.Stack)
  }
}
```

### # Step 5: Login page achieved (go back to target page after login successfully)

```typescript
// LoginPage.ets
/ / AuthManager definition in AuthInterctor.ets in step 3 (same module within the project)
import { AuthManager } from '../common/AuthInterceptor';

interface LoginParam {
  targetPage?: string;
  reason?: string;
}

@Builder
export function LoginPageBuilder(name: string, param: Object) {
  LoginPage({ param: param as LoginParam });
}

@Component
struct LoginPage {
  navPathStack: NavPathStack = new NavPathStack();
  private param: LoginParam = {};

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        if (this.param.reason === 'vip_required') {
Text ( 'This function requires VIP permissions, please open VIP')
        }
/... username/cipher input box

Button. Onclick() = {
AuthManager.setLoginStatus; / / Simulation Login
          if (this.param.targetPage) {
/ / ★ Replace to the original target page after successful login, user press returns not to return login Page
            this.navPathStack.replacePathByName(this.param.targetPage, null);
          } else {
            this.navPathStack.pop();
          }
        })
Button (`return').onClick()=> this.navPathStack.pop()
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
.title
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      const p = ctx.pathInfo.param as LoginParam;
      if (p) { this.param = p; }
    })
  }
}
```


## # Progress: more uses for the Data field

The router `data` field is a generic key pair, which, in addition to login check-in, can mark other metadata and be processed in a uniform manner in the interceptor:

```json
{
  "name": "VideoPlayer",
  "pageSourceFile": "src/main/ets/pages/VideoPlayer.ets",
  "buildFunction": "VideoPlayerBuilder",
  "data": {
    "requireAuth": true, "requireVIP": false,
    "orientation": "landscape", "trackId": "page_video_player",
    "enableGesture": true, "keepAlive": false
  }
}
```

Extending processing logic to need in interceptors (entry/ VIP verification code equivalent step 3, omitted):

```typescript
// Continue to add in the return to willShow:
Page direction control
if (data['orientation'] === 'landscape') {
  // target.getUIContext()?.setPreferredOrientation(WindowOrientation.LANDSCAPE);
}
4. Unified burial sites
if (data['trackId']) {
  // AnalyticsService.trackPageView(data['trackId'] as string);
}
```

The page itself can also read data in `onReady`:

```typescript
.onReady((ctx: NavDestinationContext) => {
  const config = ctx.getConfigInRouteMap();
  if (config?.data) {
    const data = config.data as Record<string, Object>;
    console.info('Title:', data['title'], 'TrackId:', data['trackId']);
  }
})
```

## # Key API Description

|API Note
|-----|------|---------|
Custom keys to metadata  ZAPI 12+|
`NavDestinationContext.getConfigInRouteMap()` | Get router configuration (including data) |API 12+ | in the context of the page
`NavPathStack.setInterception()`| Sets the route to intercept the echoes |API 12+|
|XKEEP0ZX| page displays pre-stop (at which time the page is created, data readable) |API 12+|
`NavigationInterception.interception` | Intercept before creating page (parameter NavPathInfo, unable to read data) |API 22+|
Z `NavPathStack.pop()` | Popup Top Page (to remove entered target page when intercepting) |API 11+ |
`NavPathStack.pushPathByName()` |Push page by name |API 10+|
`NavPathStack.replacePathByName()` | Replaces the top page by name (used after login successfully) |API 11+|

## Attention ##

1. **The page was not created when ZXKEEP0Z**: `interception` (API 22+) was triggered. Parameters are `NavPathInfo` (name/ param only) and `getConfigInRouteMap()` cannot be called to read the data field. The page was created when `willShow` (API 12+) was triggered, and the parameter is `NavDestinationContext`, which is readable directly and is more compatible.

2. ** Routes have changed at the time of interception**: At any turnback, at the time of entry, the route has changed. So `pop` needs to drop the new entry page and `push` login.

3. ** The login page itself does not mark `requireAuth: true`**: Otherwise, it will be trapped in an unlimited interception cycle (login page intercepting login and jumping off login page).

** The jump after login has been successful uses `replacePathByName`**: this way the login page will be replaced with the target page, and the user will not return to the login page when the return key is pressed.

5. **data field is a free-format object**: Any key pair can be applied and the system is not verified. Developer needs to agree on the meaning of the field and correctly interpret it in the interceptor.

6. ** Cross-modular scene* *: HAP/HSP/HAR modules are independently configured for `router_map.json`, `getConfigInRouteMap()` only to read the routing of the module on the current page.

---

scene 2: NavDestination Page Level Control

**Scene description: ** In short video application, video list page** vertical screen** browsing, clicking on video into fullscreen playpage** screen** diagnosing and returning to the vertical screen automatically. The NavDestination page needs to have different screen orientations and is automatically managed along the roadway.

** Solution:** Set the page orientation using NavDestination **`.preferredOrientation()`** Declaration format in conjunction with **ZXKEEP1Z** Hidden Status Bar,**`.enableNavigationIndicator(false)`** Hidden Navigation Bar,** `.ignoreLayoutSafeArea()`** Covered with a Safe Zone to achieve a fully immersion screen. The pop-time system automatically restores the direction of the previous page without manual management.

## # compares to the advantage of window.setPreferredOrganization

| | `window.setPreferredOrientation()` | `NavDestination.preferredOrientation()` |
|---|---|---|
** Recovered direction ** has to be recovered manually by `aboutToDisappear`, forgetting that the system ** automatically restores ** the previous direction
** State Management | Requires is Landscape state + windowSizeChange listening  ** no state management** without any listening  **
** Return key  ** must be intercepted and manually recovered in `onBackPressed` ** No need to intercept**  **
** Code Volume ~ 400 Line  ** ** ~ 10 Line**
• Risk of error High - Forget recovery, forget write-offs, life-cycle time-series issues Low - Declaration, system to ensure correctness

> One sentence: If you need to jump to a new page, use `preferredOrientation` across the screen; you need to move dynamically within the same page.

#### Step 1: Configure the default direction and route chart

Sets the default vertical screen in `module.json5`:

```json5
// module.json5
{
  "module": {
    "abilities": [{
      "name": "EntryAbility",
"Orientation": "portrait" // Apply default screen
    }]
  }
}
```

Registration of video list pages and play pages in route lists:

```json
// resources/base/profile/route_map.json
{
  "routerMap": [
    { "name": "VideoList", "pageSourceFile": "src/main/ets/pages/Index.ets" },
    { "name": "VideoPlayer", "pageSourceFile": "src/main/ets/video/VideoPlayerPage.ets" }
  ]
}
```

### # Step 2: List of vertical screens Page

`.width('100%').height('100%')` has to be filled or `preferredOrientation` silently is not effective:

```typescript
// entry/src/main/ets/pages/Index.ets
@Entry
@Component
struct Index {
  private stack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.stack) {
      List({ space: 12 }) {
ForEach ['Video 1', 'Video 2', 'Video 3'], (item: string) = >
          ListItem() {
            Text(item)
              .width('100%').height(200).textAlign(TextAlign.Center)
              .onClick(() => {
                this.stack.pushPath({ name: 'VideoPlayer', param: { title: item } });
              })
          }
        }, (item: string) => item)
      }
    }
    .width('100%')
.head('100%') / / Navigation must be covered or preferredOrientation not effective
    .mode(NavigationMode.Stack)
    .hideNavBar(true)
    .navDestination(this.pageMap)
  }

  @Builder
  pageMap(name: string) {
    if (name === 'VideoPlayer') {
      VideoPlayerPage();
    }
  }
}
```

Step 3: Full-screen page

Declares the + immersion configuration on NavDestination with only a few lines of code:

```typescript
// entry/src/main/ets/video/VideoPlayerPage.ets
Report {window} from '@kit. ArkUI';/ / System Standard Kit, no additional creation required

@Component
struct VideoPlayerPage {
  private stack: NavPathStack | undefined = undefined;

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
/ /... screen content
Button('return'). onClick()=>
This.stack?.pop(); / /Pop System Auto-restoration without manual processing
        })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
.preferedOrientation (window.operation.LANDSCAPE) / / Core: Declaration screen
.enableStatusBar (false) / / Hide status bar (sunk)
...enablenavigationIndicator// Hide Navigator
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
[LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM]) / /
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
    })
  }
}
```

# # # Revert to multiple pages

Each page of the roadway can be independently stated and the system automatically rotates in the direction of the top:

```
A (demon) poush B (blank) poush C (demon)

Bark State System Window Direction
─────────────────────────
A screen
A →B screen (auto-toggle)
A → B → C vertical (auto-switch)
A →B screen (pop C, automatically restore B orientation)
A vertical (pop B, automatically restore A orientation)
```

If `preferredOrientation` is not set for a page, the default direction in ZXKEP1ZX is restored.

## # Key API Description

|API Note
|-----|------|---------|
`.preferredOrientation(orientation)`| states the direction of the page. The system rotates automatically when entering and automatically restores a page direction when leaving |API 19+|
`.enableStatusBar(enabled, animated?)` | Shows/ hides the status bar when entering this page
`.enableNavigationIndicator(enabled)` | Show/ hide bottom navigator when entering this page |API 19+ |
| `.ignoreLayoutSafeArea(types, edges)` | Enriched in a secure area (use on full screen or black side) |API 12+|

** Conditions for entry into force** (three must be met simultaneously):
1. NavDestination is an application main window page with a full screen window
2. Navigation Full Application Page (`.width('100%').height('100%')`)
3. NavDestination type `NavDestinationMode.STANDARD` (non-DIALOG)

## Attention ##

1. **API 19+ only has this interface**: Low-compatible versions require manual `onShown`/`onHidden` on the page to call down `window.setPreferredOrientation()` manually.

2. **Navigation must be full**: If the outer layer cannot be packed with other containers, the size of Navigation is insufficient, otherwise `preferredOrientation` silently does not take effect.

3. ** No manual recovery direction required* *: Autorehabilitate when pop, do not remodify `onBackPressed` or `aboutToDisappear`.

4. ** `ignoreLayoutSafeArea` co-use**: After hiding the status bar and the navigator, the content must be covered in a safe area, otherwise there will be a black side up and down.

5. **Turn scintillation**: If a rotation during animation of the page is leading to scintillation, `.systemTransition(NavigationSystemTransitionType.FADE)` may be used to fade out.

---

##3 scene: Multimodule Unified Dynamic Route

** scene description:** In multi-module applications, the main module (HAP) and several business modules (HAR/HSP) have separate pages, and between pages there is a need to jump freely — harA page to harB page and harB to harC. However, it is not possible to rely on a compilation period between modules, otherwise static `import` would lead to a coding, slower start, and risk of recycle dependence.

** Solution:** Distribution using **Router Modeule (Shared HAR)+ Dynamic `import()` 3rd floor**. RouterModule maintains a global `builderMap` (page registration form) and `routerMap` (routing reference) and jumps with ZXXKEEP3ZX to load target HAR modules and page files on demand, with zero inter-module translation.

# # Compared to the system route chart

| Route chart of system | Custom route chart (this scheme) |
|---|---|---|
How do you do it?
| Dynamic load, | system automatically load  Z Manual `import()` 3rd floor distribution
Application of scenes Standard jumpovers, no self-defined logic
API version

> If your scene is just a simple leap across, there's no need for a custom logic,** the system path chart is simpler** -- Configure routes in each module with `resources/base/profile/router_map.json`, and then jump with `pushPathByName()`. This programme applies to scenarios requiring interception (e.g. log-in check) before jump, uniform treatment of route parameters or highly customized route behaviour.

Modular Structure

```
RouterModule
                   ┌──────────────────────┐
BuilderMap: Page Registration Form
RouterMap: Roadhouse Reference
                   │ push/pop/clear/register│
                   └─────────┬────────────┘
│ Reliance on all modules
              ┌──────────────┼──────────────┐
              │              │              │
          entry (HAP)     harA (HAR)     harB (HAR)
          ┌─────────┐   ┌─────────┐   ┌─────────┐
          │Navigation│   │ A1, A2  │   │B1, B2, B3│
          │NavPathStack│  │harInit()│   │harInit() │
          └─────────┘   └─────────┘   └─────────┘
```

# # Three Layers Dynamic Load

```
Base level 1: push dynamic import(harName) loads the HAR module entrance
Layer 2: harInit() dynamic report("./page") loads specific page files
Level 3: Page file wrapBuilder + registerBuilder → Register @Builder to buildMap
```

Then `Navigation` returns `navDestination` to find and render pages from the bilderMap.

Step 1: Router Modeule - Route infrastructure

RouterModule is an independent HAR, dependent on all business modules and anentry. Map:

```typescript
// RouterModule/src/main/ets/utils/RouterModule.ets
/ RouterModel definition in step 2 (module with RouterModule)
import { RouterModel } from '../model/RouterModel';

export class RouterModule {
/ Page Registration Table: name →
  static builderMap: Map<string, WrappedBuilder<[object]>> = new Map();
/ / Route Inn Reference: name → NavPathStack
  static routerMap: Map<string, NavPathStack> = new Map();

/ / / core: Construct route information / dynamic Import → PushPath
  public static async push(router: RouterModel): Promise<void> {
    const harName = router.builderName.split('_')[0];  // '@ohos/hara'
/ / Layer 1: Dynamic Import whole AR module
    await import(harName).then((ns: ESObject): Promise<void> =>
ns.harInit(router.builderName) / 2nd Layer: Initialization function to call HAR
    );
/ Upon completion of 3rd floor, builder is registered to bilderMap to execute PushPath
    RouterModule.getRouter(router.routerName)
      .pushPath({ name: router.builderName, param: router.param });
  }

  public static registerBuilder(builderName: string, builder: WrappedBuilder<[object]>): void {
    RouterModule.builderMap.set(builderName, builder);
  }

  public static getBuilder(builderName: string): WrappedBuilder<[object]> {
    return RouterModule.builderMap.get(builderName) as WrappedBuilder<[object]>;
  }

  public static createRouter(routerName: string, router: NavPathStack): void {
    RouterModule.routerMap.set(routerName, router);
  }

  public static getRouter(routerName: string): NavPathStack {
    return RouterModule.routerMap.get(routerName) as NavPathStack;
  }

  public static pop(routerName: string): void {
    RouterModule.getRouter(routerName).pop();
  }

  public static clear(routerName: string): void {
    RouterModule.getRouter(routerName).clear();
  }
}
```

Step 2: RouterModel + Route Name Constant

Construct a route information model and a uniform route name constant:

```typescript
// RouterModule/src/main/ets/model/RouterModel.ets
/ RouterModule definition in step 1 (with module in RouterModule)
import { RouterModule } from '../utils/RouterModule';

export class RouterModel {
bilderName: string = "; / / page name, format '@ohos/hara A1'
RouterName: string = "; / / Roadblock name, such as 'EntryHap Router'
  param?: object = new Object();
}

/ / / / Easy method: construct route information and immediately push
export function buildRouterModel(routerName: string, builderName: string, param?: object) {
  let router = new RouterModel();
  router.builderName = builderName;
  router.routerName = routerName;
  router.param = param;
  RouterModule.push(router);
}
```

```typescript
// RouterModule/src/main/ets/constants/RouterConstants.ets
export class BuilderNameConstants {
  static readonly HARA_A1: string = '@ohos/hara_A1';
  static readonly HARA_A2: string = '@ohos/hara_A2';
  static readonly HARB_B1: string = '@ohos/harb_B1';
/ ... Add more page constants as needed
}

export class RouterNameConstants {
  static readonly ENTRY_HAP: string = 'EntryHap_Router';
}
```

`, which includes that `split('_')[0]` in ZXKEEP2X can address the AR Modeule name.

Step 3: HAR module portal --harInit distribution

Each HAR module in its root directory has a `Index.ets` function that exports `harInit()`:

```typescript
// harA/Index.ets
/ @ohos/routermodule is a customised shared HAR module (RouterModule) for this project, code used in step 1-2
import { BuilderNameConstants } from '@ohos/routermodule';

export function harInit(builderName: string): void {
  switch (builderName) {
    case BuilderNameConstants.HARA_A1:
Import("./src/main/ets/components/mainpage/A1"); // ★ 2nd floor: load pages as required Noodles.
      break;
    case BuilderNameConstants.HARA_A2:
      import("./src/main/ets/components/mainpage/A2");
      break;
    default:
      break;
  }
}
```

Switch distributes to ensure that only the required page files are loaded and that all pages in HAR are not loaded once.

Step 4: Page File - @Builder+ AutoRegistration

Each page file defines `@Builder`, constructs NavDestination UI and automatically registers it at the top of the module to buildMap:

```typescript
// harA/src/main/ets/components/mainpage/A1.ets
/ @ohos/routermodule is a customised shared HAR module (RouterModule) for this project, code used in step 1-2
import { BuilderNameConstants, buildRouterModel, RouterModule, RouterNameConstants } from '@ohos/routermodule';

/ 1/ Definition @Builder, Receive Parameters, Build NavDestination
@Builder
export function harBuilder(value: object) {
  NavDestination() {
    Column() {
      Text(JSON.stringify(value))

Button (`return home'). onClick() = >
        RouterModule.clear(RouterNameConstants.ENTRY_HAP);
      })

Button (`jump to A2 (same module)'). Oncick() = >
        buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARA_A2);
      })

Button (`jump to B1 (cross module)'). onClick() = >
        buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARB_B1);
      })
    }
  }
  .title('A1Page')
  .onBackPressed(() => {
    RouterModule.pop(RouterNameConstants.ENTRY_HAP);
    return true;
  })
}

/ 2 ★ Top Level of Module Code: Automatically register when a file is import
const builderName = BuilderNameConstants.HARA_A1;
if (!RouterModule.getBuilder(builderName)) {
  const builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  RouterModule.registerBuilder(builderName, builder);
}
```

`wrapBuilder(harBuilder)` packages the `@Builder` function as an object of `WrappedBuilder<[object]>` and places it in the bilderMap.

Step 5: HAP Home Page — Navigation + navDestification

```typescript
// entry/src/main/ets/pages/Index.ets
/ @ohos/routermodule is a customised shared HAR module (RouterModule) for this project, code used in step 1-2
import { BuilderNameConstants, buildRouterModel, RouterModule, RouterNameConstants } from '@ohos/routermodule';

@Entry
@Component
struct EntryHap {
  @State entryHapRouter: NavPathStack = new NavPathStack();

  aboutToAppear() {
Register NavPathStack to RouterModule for all modules
    RouterModule.createRouter(RouterNameConstants.ENTRY_HAP, this.entryHapRouter);
  }

/ / navDestination Callback: Find @Builder by name
  @Builder
  routerMap(builderName: string, param: object) {
    RouterModule.getBuilder(builderName).builder(param);
  }

  build() {
    Navigation(this.entryHapRouter) {
      Column() {
Button (`jump to A1'). onClick()=>
          buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARA_A1, { origin: 'Entry' });
        })
Button. Oncick()=>
          buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARB_B2);
        })
      }
    }
.navDestination (this.routerMap); / / / / /routing route by distribution back
  }
}
```

## # Key API Description

API Note
|-----|------|
`RouterModule.builderMap` page registration form, name ZXKEP1ZX
`RouterModule.routerMap` ZEX Quote, name `NavPathStack`
`wrapBuilder(builder)` | Packing of ZXKEP1ZX into a `WrappedBuilder` object to Map
Z `dynamic import(harName)` | 1st Layer: Dynamic Loading of HAR Module Entry
`harInit(builderName)` | 2nd floor: distribution to specific page files in the HAR module
`Navigation.navDestination()`| Rendering entrance: remove registered builder from bilderMap and call |

## Attention ##

1. ** `wrapBuilder` is mandatory**: `@Builder` function cannot be entered directly into Map to `navDestination` and must be packaged as `WrappedBuilder<[object]>` object with `wrapBuilder()`.

** The top level registration code is automatically executed**: `import("./B1")` loading the page file, the top level code of the file will be executed immediately and no manual call is required.

** `if (!getBuilder(builderName))` Protection against duplicate registration**: the same page may be subject to multiple imports, checking before registration.

If the mobile name is a codee, the resolution log needs to be enforced.

5. ** All modules share the same NavPathStack**: `RouterModule.routerMap` stored NavPathStack references, and cross-module jumps to the same router, `pop()` returns normally to the previous page.

6. ** The system route chart is a simpler alternative**: if it is a standard cross-package jump, then `router_map.json` configuration + `pushPathByName()` is sufficient and this Router Modeule is not required.

---

# Four, Navigation component undetected

Scene 1: NavDestinationSwitch

** scene description: ** No-invasion page site with `UIObserver` event, PV (number of page views), UV (number of independent visits after weight) and long user stay on each page. Access data on all NavDestination pages can be automatically collected without the need to manually add the burial point code to each page, by listening to the whole world.

** Solution:** Use **`UIObserver.on('navDestinationSwitch')`** global listening page to switch events + ** single case `PageTracker`** to manage collection and statistics of buried site data. `NavDestinationSwitchInfo` to access source and target page information via `from`/`to`. ZXXKEEP5ZX to track the entry/ departure time of each page example.

### # Step 1: Achieve a Page Emplacement Manager

The `handleSwitch` method is at the core of PV/UV statistics managed through a single case:

```typescript
/ PageTracker.ets - Page Emplacement Manager (full code in step 1)

*/ ** Page Speculation */
interface PageStats {
  pageName: string;
  pv: number;
uv: number; / / / independent visits after heavy
  totalDuration: number;
  avgDuration: number;
}

export class PageTracker {
  private static instance: PageTracker | null = null;
  private visitStack: Map<string, number> = new Map(); // navDestinationId → enterTime
  private stats: Map<string, PageStats> = new Map();

  static getInstance(): PageTracker {
    if (!PageTracker.instance) {
      PageTracker.instance = new PageTracker();
    }
    return PageTracker.instance;
  }

/ ** Handle Page Switch Events - Core Method */
  handleSwitch(info: NavDestinationSwitchInfo): void {
    const fromName = typeof info.from === 'string' ? 'NavBar' : info.from.name;
    const fromId = typeof info.from === 'string' ? '' : info.from.navDestinationId;
    const toName = typeof info.to === 'string' ? 'NavBar' : info.to.name;
    const toId = typeof info.to === 'string' ? '' : info.to.navDestinationId;
    const opMap: Record<number, string> = { 0: 'PUSH', 1: 'POP', 2: 'REPLACE' };
    const op = opMap[info.operation] ?? 'UNKNOWN';
    const now = Date.now();

/ Source page: Record time of departure and stay Long
    if (fromId && this.visitStack.has(fromId)) {
      const enterTime = this.visitStack.get(fromId)!;
      const duration = now - enterTime;
      this.updateDuration(fromName, duration);
      this.visitStack.delete(fromId);
    }

/ Target page: Record entry time and PV +1 (Navbar not recorded)
    if (toId) {
      this.visitStack.set(toId, now);
      this.incrementPV(toName);
/ / UV Go to Logical: use sessionId/userId in actual projects to weigh, omitted
    }

    console.info(`[Tracker] ${op}: ${fromName} → ${toName}`);
  }

  private getOrCreateStats(pageName: string): PageStats {
    let stat = this.stats.get(pageName);
    if (!stat) {
      stat = { pageName, pv: 0, uv: 0, totalDuration: 0, avgDuration: 0 };
      this.stats.set(pageName, stat);
    }
    return stat;
  }

  private incrementPV(pageName: string): void {
    this.getOrCreateStats(pageName).pv++;
  }

  private updateDuration(pageName: string, duration: number): void {
    const stat = this.getOrCreateStats(pageName);
    stat.totalDuration += duration;
    stat.avgDuration = Math.round(stat.totalDuration / stat.pv);
  }

/** Get all pages */
  getStats(): PageStats[] {
    return Array.from(this.stats.values());
  }
}
```

Step 2: Register listening in EntryAbility

Get `UIContext` in `onWindowStageCreate`, register global page to switch to listening:

```typescript
// entryability/EntryAbility.ets
Full realization of the / PageTracker class
import { PageTracker } from '../common/PageTracker';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      const uiContext = windowStage.getMainWindowSync().getUIContext();
      const tracker = PageTracker.getInstance();

/ / Register Page Switch Listening
      uiContext.getUIObserver().on('navDestinationSwitch', (info) => {
        tracker.handleSwitch(info);
      });
    });
  }

  onWindowStageDestroy(): void {
    const uiContext = this.context.getMainWindowSync().getUIContext();
/ De-interception to prevent leakage of memory
    uiContext.getUIObserver().off('navDestinationSwitch');
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
`UIObserver.on('navDestinationSwitch')`| listen to NavDestination Page Switch Event |API 12+|
|XKEEP0ZX| Source page and target page information (including `name`, `navDestinationId`) |API 12+|
`NavDestinationSwitchInfo.operation`| route type: `PUSH(0)` / `POP(1)` / `REPLACE(2)` |API 12+|
`UIObserver.off('navDestinationSwitch')` | Write-off Page Switch-to-Face

## Attention ##

>  ** Common error: detached listening in component `aboutToDisappear`**
> `off('navDestinationSwitch')` wrote off `UIContext` / `UIObserver`-level global listening, which the `aboutToDisappear` of the page component could not reach, leaving the wiretapping uncancelled and memory leaks. ** Must be written off in ZXKEP4ZX**.

1. **Registration at `UIContext` level**: Direct registration of single Navigation applications is sufficient and multiple Navigation applications can assign a listening to a Navigation through `navigationId` parameters.

2. ** Timing of write-off**: `onWindowStageDestroy` call `off('navDestinationSwitch')` off-hearing to prevent memory leakage.

3. **PV calculation logic**: Each page is changed from invisible to a visible count PV (including POP returns), and the same page example is counted back by PUSH and POP.

4. **UV heavy**: using session Id or userId heavy, the same user has repeatedly visited the same page only once.

5. **Long stay accuracy**: track the entry/departure time for each instance using `navDestinationId` (rather than page name) to ensure that multiple examples of the same name page correctly calculate the length of the stay.

---

Scene 2: query NavDestinationInfo for current page information

** scene description: ** In a deep-seated, custom sub-component, it is necessary to know which NavDestination sub-page, what page name is, where the route is. `queryNavDestinationInfo` allows any sub-component (not limited to NavDestination root level) to directly query the current page information, typically for the purpose of determining which sub-page the component is in, by which path parameters to access the current page, debugging and tagging the context of the page in the log.

** Solution:** Use **`this.queryNavDestinationInfo()`** to search for current page information (name, ID, index, parameter, mode) in any sub-component within NavDestination, in conjunction with **`this.queryNavigationInfo()`** to obtain Navigation information (pathStack). No level-by-level transmission of NavPathStack or page parameters is required.

### # Step 1: Achieve Context Perception Component on Universal Pages

Automatically sense the page in any subcomponent by `queryNavDestinationInfo`:

```typescript
/ PageContextTag.ets - can be placed on any subcomponent, automatically sense page
@Component
export struct PageContextTag {
@StatepageName: string = 'unknown page '
  @State pageId: string = '';
  @State stackIndex: number = -1;
  @State navMode: string = '';
  private navStack?: NavPathStack;

  aboutToAppear(): void {
/ / ✅ Core: Search for current page information in any subcomponent
    const destInfo = this.queryNavDestinationInfo();
    if (destInfo) {
      this.pageName = destInfo.name;
      this.pageId = destInfo.navDestinationId;
      this.stackIndex = destInfo.index;
      this.navMode = destInfo.mode === NavDestinationMode.DIALOG ? 'DIALOG' : 'STANDARD';
    }

/ / Can also search for Navigation information
    const navInfo = this.queryNavigationInfo();
    if (navInfo) {
      this.navStack = navInfo.pathStack;
    }
  }

  build() {
    Text(`[${this.pageName}] #${this.pageId} @${this.stackIndex} (${this.navMode})`)
      .fontSize(10)
      .fontColor('#999999')
      .padding(4)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
  }
}
```

Step 2: Use in pages and deep sub-components

Even a multilayered sub-component can directly call `queryNavDestinationInfo` for page information:

```typescript
// ProductDetail.ets
@Component
struct ProductDetail {
  build() {
    NavDestination() {
      Column() {
/ / The context of the page can also be sensed in the deep subcomponent
ProjectInfoCard() / / In-house
RecommendSection() / / Internal
      }
    }
  }
}

/ / The context of the page can also be sensed in the deep subcomponent
@Component
struct ProductInfoCard {
  private currentPageName: string = '';

  aboutToAppear(): void {
/ / Can access page information even in deep embedded subcomponents
    const info = this.queryNavDestinationInfo();
    if (info) {
      this.currentPageName = info.name;
Console.info (`The current component is on page: ${info.name}, ID: ${info.navDestinationId} ');
    }
  }

  build() {
    Column() {
PageContextTag()/ / AutoShow Context Information on Page
    }
  }
}
```

## # Typical application scene #

```typescript
/ / scene A: AutoRetrieving Pages for Global Site Component First Name
@Component
struct TrackableButton {
  @Prop actionName: string = '';
  build() {
    Button(this.actionName)
      .onClick(() => {
        const info = this.queryNavDestinationInfo();
        const pageName = info?.name ?? 'unknown';
        console.info(`[Track] page=${pageName}, action=${this.actionName}`);
      })
  }
}
```

** Other typical usage (elements):**

-** Debug Float**: Read `info.name`, `info.navDestinationId`, `info.index`, ZXXKEEP3ZX to display context information on the current page
- **Conditional funcing**: ZXKEEP0Zdetermines the current page and only allow a fight (e. g. `if (info? == 'HomePage') {/ * Enable the exclusive function of the homepage */ }

## # Key API Description

|API Note
|-----|------|---------|
Query XKEEP0ZX| NavDestination
|XKEEP0ZX |NavigationQuery of any sub-component within `this.queryNavigationInfo()` |Navigation Info (PathStack, Mode) |API 12+|
`NavDestinationInfo.name` page name
`NavDestinationInfo.index` | Route Index |
`NavDestinationInfo.navDestinationId` | Only ID |
`NavDestinationInfo.param`| Page Parameter |
`NavDestinationInfo.mode`| Page Mode: STANDARD / DIALOG|

# # get in comparison #

| Mode | Call location | Return content | Apply scene |
|------|---------|---------|---------|
Any subcomponent within `queryNavDestinationInfo()` | NavDestination
Z `queryNavigationInfo()` | Navigational controller for any subcomponents of |pathStack, mode |
`onReady(ctx)` | NavDestination Root Component |PathStack, param, navDestinationId | Initialise Page Level

## Attention ##

1. ** Callable only in NavDestination**: Call back to `undefined` in NavBar area of Navigation, requiring empty value check before call.

2. **Regression of `undefined` means not in NavDestination**: Always empty value judgement of return values, avoiding access to properties of `undefined` leading to collapse.

3. ** Multi-examples page**: Different `navDestinationId` from the same name page can be used to distinguish between different page examples.

4. ** Complementarity with ZXKEEP0Z**: `onReady` for page-level initialization (trigger only once), and ZXXKEEP2ZX for any sub-component to search for current page information at any time.

---

# Five, Navigation Route Animation

## # scene 1: System transfer type configuration

**Scene description: ** The different pages in the set-up application need a different style: Main list Second-level pages use right-slides in, about pages use gradients, bottom bullet windows use up slides, and some silent jumps do not require any animation. Configure the appropriate system transfer type for each page through `NavDestination.systemTransition`.

** Solution:** Using **`NavDestination.systemTransition(type)`** to declare the type of switch for each NavDestination system, to achieve a different switch style without having to define animated, by **ZXKEEP1Z** ** Equip Effect (FADE/EXPRODE/SLIDE RIGHT/SLIDE BOTOM, etc.).

### # A complete overview of the type of system transition

Quantum count, effect, typical scene,
|--------|------|----------|
|DeFAULT | Title Bar + Default Content Animation | General Page |
|NONE | no animation | | silent jump, initialization |
|TITLE | Animation of the title bar only | Title to change the page with the same content |
| CONTENT | Animation of content only
|FADE | Gradually enter | About pages, set subpages |
| EXPLODE Central Zoom Zoom Zoom Photo & Card Launch
| SLIDE RIGHT | Shift right | Standard in (setlist details) |
| SLIDE BOTTOM | Slipper on the bottom, | bottom panel, filter page

Example ###: Configure different system transfer types

Pages will only be treated by `.systemTranstion ' on NavDestification, with reference to the above table:

```typescript
@Component
struct AboutPage {
  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('HarmonyOS 5.0').fontSize(24).fontWeight(FontWeight.Bold)
/... other information
      }.width('100%').padding(20)
    }
.title
/ / ★ Gradients
    .systemTransition(NavigationSystemTransitionType.FADE)
  }
}

@Component
struct PhotoViewer {
  build() {
    NavDestination() {
      Stack() {
        Image($r('app.media.profile_avatar')).width('90%').objectFit(ImageFit.Contain)
      }.width('100%').height('100%').backgroundColor(Color.Black)
    }
    .hideTitleBar(true)
/ / / / Centre Zoom Turner
    .systemTransition(NavigationSystemTransitionType.EXPLODE)
  }
}

/ Filter Panel - .systemTransion (NavigationSystemType.SLIDE BOTTOM)
/ Standard Source Page - .systemTransion (NavigationSystemType.SLIDE RIGHT)
```

Step A: Disable Animation

** All subsequent jumps** on `NavPathStack` are of a "switch" nature - - Once set to `true`, remember to set back `false` when animated:

```typescript
/ / Global Close: no rerun animations for the navStack
this.navStack.disableAnimation(true);
/... a series of silent jumps...
This. navStack.disableAnimation; / / Open if animated
```

### # Step B: Close animated one-time (animatized parameter for push/pop)

The only way to affect the current ** operation, without changing the global status, is the most common mode of silent jump. Last parameter for `pushPath` / `pushPathByName` / `pop`

```typescript
/ / One-time closure: no animation for this jump only, no subsequent jumps affected
this.navStack.pushPath({ name: 'SilentPage' }, false);
/ pushPathByName also supports animated
this.navStack.pushPathByName('SilentPage', null, false);
/ pop can also close once
this.navStack.pop(false);
```

### # Step C: Silent push (avoiding animated conflict of Router + Navigation)

`push` for the first time when applying initial frame loading, or moving from Router to Navigation, `push`, should be used in `aboutToAppear` as ZXXKEEP2ZX silently push initial page if the animation and Router animation superstition are activated with the system:

```typescript
@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
/ / Initialization of silent push: Avoid First Frame Animation superimpose / Flash
    this.navStack.pushPath({ name: 'SettingsHome' }, false);
  }

  build() {
    // Navigation(this.navStack) { ... }
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
`NavDestination.systemTransition(type)`| Setup NavDestination System Animation Type |API 14+|
| `NavigationSystemTransitionType` | remix list (DEFAUT/NONE/TITLE/ CONTENT/FADE/EXPODE/SLIDE RIGHT/SLIDE BOTTOM) | API 14+ |
`NavPathStack.disableAnimation(true)` ZeroZX Zero-Close All rotation animations
Z `pushPath({ name }, animated)` | One-time closing/opening of arcade animation, `animated` for `false` without animation | API 10+ |

## Attention ##

1. ** The default roller is using spring curves**: time is associated with physical parameters, different equipment is performing differently and not recommended for alignment with business logic.
2. **TITLE/CONTENT is separately controlled**: TITLE Animation only in title bar, CONTENT Animation only in content area, and a change of content-free area when setting NONE or TITLE.
** Two ways to close animated **: `disableAnimation` global closure affects all jumps; ZXXKEEP1ZX parameter one-time closure only affects current operations.
4. ** When set at the same time as CustomTransation, subsequent settings become effective**.

---

## # scene 2: Single Page Custom Animation

** scene description: ** Bottom popup panel (BottomSheet style) needs to slide from the bottom to the bottom, and the background becomes more visible; when exiting, the background goes down, and the background becomes invisible. This effect should be applied only to specific pages, and the other pages still use the system default switch.

** Solution: ** Use **`NavDestination.customTransition(delegate)`** to achieve a single-page level of custom transition. The proxy function returns a different animation configuration based on `operation` (PUSH/POP) and `isEnter` (entry/exit) and uses the system default switch when `undefined` returns.

# # Fulfill code: bottom popup panel Page Noodles.

```typescript
// BottomSheetPage.ets

@Component
export struct BottomSheetPage {
  navStack: NavPathStack = new NavPathStack();
@state Panelofset: string = '100%';/ / Initial at the bottom of the screen External
@state bgOpacity: number = 0; / / Background initial transparency

  build() {
    NavDestination() {
      Stack() {
/ Background mask
        Column()
          .width('100%').height('100%')
          .backgroundColor(Color.Black)
          .opacity(this.bgOpacity)

// Content Panel (sliding from bottom)
        Column({ space: 16 }) {
/ ... Options List UI
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding({ left: 16, right: 16, bottom: 32 })
        .translate({ y: this.panelOffset })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
    })
/ / / ★ Core: Set a single page custom switch
    .customTransition(
      (operation: NavigationOperation, isEnter: boolean)
        : Array<NavDestinationTransition> | undefined => {

        if (operation === NavigationOperation.PUSH) {
          if (isEnter) {
/ / ★ PUSH Entry: panel slides from bottom to background
            return [{
              duration: 350,
              curve: Curve.EaseOut,
              event: () => {
This.panelofset = '100%'; // Start position: bottom of screen
                this.bgOpacity = 0;
                this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseOut }, () => {
This.panelofset = '0%'; / /end: in place
                  this.bgOpacity = 0.5;
                });
              }
            }];
          }
/ /PUSH
        }

        if (operation === NavigationOperation.POP) {
          if (isEnter) {
Restore system default for return undefined; / / POP
          }
/ / ★ POP exit: panel descends + background becomes invisible
          return [{
            duration: 300,
            curve: Curve.EaseIn,
            event: () => {
              this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
                this.panelOffset = '100%';
                this.bgOpacity = 0;
              });
            }
          }];
        }

        return undefined;
      }
    )
  }
}
```

** This example's “Four Range” configuration policy**: `customTransition` proxy based on `operation` (PUSH / POP) x `isEnter` (entry/ exit). The example of a bottom popup panel** has been customised only 2 quadrants** and 2 returns `undefined` walk system default:

|Operation is Enter
|-----------|---------|------|------|
|PUSH | true(entry) | Custom: panel slides from bottom to background + | Popup effect is the core of this page
|PUSH|False (retire) |`undefined`: The default for going system |PUSH is the previous page, the default for going system |
| POP | true (entry) |  Z XKEEP0ZX: Default to walk system | POP restores the previous page, the system default allows |
| POP | falle | | | ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ + + + + + + + + + + + + + + + + + + + + + + + + +

If you have four pages dedicated to animation (e.g., card flipping), replace the other two `return undefined` with the corresponding ZXXKEEP1ZX configuration, with the same structure.

## # Key API Description

|API Note
|-----|------|---------|
`NavDestination.customTransition(delegate)` | Single Page Customises Conversions, Receiving Agent Functions |API 15+ |
|XKEEP0ZX | Rotation Protocol object; `event` returns to be executed in the context of animateTo, directly setting the target state to drive animated |API 15+ |
Z `NavigationOperation`| Operating enumerator (PUSH/POP/REPLACE) |API 11+ |

Could not close temporary folder: %s Returns `undefined` using the system default switch; returns multiple `NavDestinationTransition` animations superimpose.

## Attention ##

1. ** Priority is lower than the Navigation level**: `customNavContentTransition` and `customTransition` were set at the same time.

2. **Return undefined system default**: return to `undefined` when some operations/directions do not require custom animation.

3. ** Multiple animated superimposement**: the animated effects of returning multiple protocol objects in arrays will be played simultaneously and layer by layer.

4. **NavDestinization suggests using the STANDARD model**: DIALOG model itself is transparently superimposed, with different remix animation effects.

---

##3 scene: Navigation Global Custom Animation

** Scenario Description: ** Application requires a uniform branding of the animation effect: a custom scaling + gradual change painting is performed on all page jumps and a return (e.g., burial point) is performed after the animation is completed. Manages the switch of all pages through `customNavContentTransition` at the Navigation level.

** Solution:** Use ** **`Navigation.customNavContentTransition(handler)`** Harmonized Interception of Transit Incidents at the Navigation level + ** Unique Tool Type to manage animated echoes of pages** (registered in `onReady`, `aboutToDisappear` cancelled). The page simply registers an animated echo and does not sense the rotation logic.

Step 1: Custom rotation animation tool Category

```typescript
/ CustomNavigationUtils.ets - a single-case tool to manage animated rotation of pages

interface AnimateCallback {
  timeout: number;
  animation: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void;
}

export class CustomNavigationUtils {
  private static instance: CustomNavigationUtils = new CustomNavigationUtils();
  private customTransitionMap: Map<string, AnimateCallback> = new Map();

  static getInstance(): CustomNavigationUtils {
    return CustomNavigationUtils.instance;
  }

/** Register when the page is created; update when existing*/
  registerNavParam(name: string,
    animationCallback: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void,
    timeout: number): void {
    this.customTransitionMap.set(name, { timeout, animation: animationCallback });
  }

/** Write-off on page destruction*/
  unRegisterNavParam(name: string): void {
    this.customTransitionMap.delete(name);
  }

  getAnimateParam(name: string): AnimateCallback | undefined {
    return this.customTransitionMap.get(name);
  }
}
```

Step 2: NavDestination page (register animation)

```typescript
/ / SamplePage.ets - NavDestination Pages Register Animated Callback in this mode
@Component
struct SamplePage {
  navStack: NavPathStack = new NavPathStack();
  @State pageScale: number = 1;
  @State pageOpacity: number = 1;
  private pageId: string = '';

  build() {
    NavDestination() {
      Column({ space: 16 }) {
Text ('example page'). FontSize(24)
        Button('push next').onClick(() => {
          this.navStack.pushPathByName('SamplePage', null);
        })
      }.width('100%').padding(20)
    }
...title ('example page')
    .scale({ x: this.pageScale, y: this.pageScale })
    .opacity(this.pageOpacity)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      this.pageId = ctx.navDestinationId ?? '';
/ / ★ Register an animation echo on the current page
      CustomNavigationUtils.getInstance().registerNavParam(
        this.pageId,
        (isPush, isExit, transitionProxy) => {
          this.runTransitionAnimation(isPush, isExit, transitionProxy);
        },
800 / / Overtime (ms)
      );
    })
  }

/ ** Scale + Gradually Modified - PUSH/POP x Enter/Exit
  private runTransitionAnimation(isPush: boolean, isExit: boolean,
    transitionProxy: NavigationTransitionProxy): void {
/ / PUSH Entry: Zooming + Graduation from Small; PUSH Back: Shrink + Decline
/ / POP exit: Zoom + Decline; POP recovery: Zoom Back + Gradient
    let targetScale = (isPush && !isExit) || (!isPush && isExit) ? 1 : 0.9;
    let startOpacity = (isPush && !isExit) ? 0 : (!isPush && !isExit) ? 0.5 : 1;
    let endOpacity = isExit ? 0 : 1;
    if (!isExit) {
      this.pageScale = 0.9;
      this.pageOpacity = startOpacity;
    }
    this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
      this.pageScale = targetScale;
      this.pageOpacity = endOpacity;
    });
/ / / / / must call: notification system transfer complete
    transitionProxy.finishTransition();
  }
}
```

### # Step 3: Navigation Home Page (bound to custom transfer)

```typescript
/ Index.ets - Navigation home page bound to a defined transfer
See step 1 for definition of the tool class

@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  @Builder
  pageMap(name: string) {
    if (name === 'SamplePage') {
      SamplePage();
    }
  }

  build() {
    Navigation(this.navStack) {
      Column({ space: 16 }) {
Button('jump').onClick(()=>This.navStack.pushPathByName('SamplePage', null)
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    }
    .hideNavBar(true)
    .navDestination(this.pageMap)
/ / / / Bind Custom Rotation Animation
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo,
      operation: NavigationOperation) => {
// Home page (NavBar, index =-1) does not participate in custom transfer
      if (from.index === -1 || to.index === -1) return undefined;

      let fromParam = CustomNavigationUtils.getInstance().getAnimateParam(from.navDestinationId);
      let toParam = CustomNavigationUtils.getInstance().getAnimateParam(to.navDestinationId);
      if (!fromParam?.animation || !toParam?.animation) return undefined;

      return {
        timeout: Math.max(fromParam.timeout, toParam.timeout),
        onTransitionEnd: (success: boolean) => console.info(`Transition end: ${success}`),
        transition: (proxy: NavigationTransitionProxy) => {
          fromParam!.animation!(operation === NavigationOperation.PUSH, true, proxy);
          toParam!.animation!(operation === NavigationOperation.PUSH, false, proxy);
        }
      } as NavigationAnimatedTransition;
    })
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
`Navigation.customNavContentTransition(handler)` |Navigation-level custom switch event |API 11+|
`NavigationAnimatedTransition`|Transion/timeout/onTransionEnd)|API 11+|
`NavigationTransitionProxy` | Interactive Rotation Agency, `finishTransition()` Notification System Relay Complete

## Attention ##

>  ** Common error: forget to call `transitionProxy.finishTransition()`**
> Without calling, the system will wait until `timeout` ends,** the page is stuck in hundreds of milliseconds to several seconds** -- this is the most high-frequency bug of the scene. `finishTransition()` must be called immediately after animation in the page registration. Second: `onReady` registered a callback and forgot to write off `unRegisterNavParam` in `aboutToDisappear`, resulting in a memory leak.

1. **Priority**: `customNavContentTransition` priority above `NavDestination.customTransition`, effective when used.

2. **finishTransion must be called**: otherwise the system will wait until it completes the switch, causing the page to be stuck. This is called in the registration function of the page.

** Timing of registration/cancellation**: Registered in `onReady` and written off in ZXXKEEP1ZX to prevent leakage of memory. The first page of Navbar's `from.index` is -1, to skip.

---

Scene 4: interactive hand moves back to the scene

> ** This scene is based on `Navigation.customNavContentTransition()` (Navigation global transfer), not `NavDestination.customTransition()` (page level transfer). ** The `customTransition` on scene 2 is hanging on a single NavDestination,** which cannot be matched with `NavigationTransitionProxy` to achieve a hand-drive interactive field**; the interactive field must be taken over with `customNavContentTransition` on the Navigation and time completed through `NavigationTransitionProxy.finishTransition()` control. The difference between the former setting the timing of completion of the transition on Navigation and the latter setting the timing of completion on NavDestination. The gesture must be used to return the scene. This scene shares a `CustomNavigationUtils` registration mechanism with scene 3.

**Scene description:** In social applications, users click images in a chat into a full-screen image viewer. The viewer supports a sign-down: when the user presses the image down, the image shrinks and moves down with the finger in real time, and the background becomes more transparent; then release and decide whether to close or to return to its place of origin depending on the distance of the slide. The key to achieving this is the division of labour: the visual status of `PanGesture` real-time drive pictures (scale / offset / effect), the timing of the completion of ZXXKEEP1ZX, which controls the switch** — PUSH enters at the end of the animation, POP exits and calls `finishTransition()` to the end, avoiding a turnover from the timeout.

** Solution:** Use **`Navigation.customNavContentTransition()`** Global Custom Rotation + **`PanGesture` Gestures ** Real-time update of photo status (scale/translate/opacy) ** ** `NavigationTransitionProxy`** Control Time to Complete the Rotation. `navStack.pop(false)` is called upon when the gesture drops above the threshold to trigger an animation, and spring animated repulsive rounds do not exceed the threshold.

Step 1: Photo Viewer page (core gesture driven logic)

```typescript
// PhotoViewerPage.ets
/ / CustomNavigationUtils as defined in Reuse 3

@Component
struct PhotoViewerPage {
  navStack: NavPathStack = new NavPathStack();
  @State imgScale: number = 1;
  @State imgOffsetY: number = 0;
  @State bgOpacity: number = 1;
  private pageId: string = '';
  private panOffsetY: number = 0;

  build() {
    NavDestination() {
      Stack() {
/ Background mask
        Column().width('100%').height('100%').backgroundColor(Color.Black).opacity(this.bgOpacity)
Image
        Image($r('app.media.photo_placeholder'))
          .objectFit(ImageFit.Contain).width('90%').height('70%')
          .scale({ x: this.imgScale, y: this.imgScale })
          .translate({ y: this.imgOffsetY })
/ / / / / / Tie a flat / sign - drive interactive turns
          .gesture(
            PanGesture({ fingers: 1, direction: PanDirection.Vertical })
              .onActionStart(() => { this.panOffsetY = 0; })
              .onActionUpdate((event: GestureEvent) => {
                this.panOffsetY += event.offsetY;
                let ratio = Math.min(Math.abs(this.panOffsetY) / 300, 1);
                this.imgOffsetY = this.panOffsetY;
                this.imgScale = 1 - ratio * 0.3;
                this.bgOpacity = 1 - ratio * 0.8;
              })
              .onActionEnd(() => {
/ / ★ Release: Drop > 100vp off or bounce
                this.panOffsetY > 100 ? this.dismissViewer() : this.snapBack();
              })
          )
      }.width('100%').height('100%')
    }
    .hideTitleBar(true).backgroundColor(Color.Black)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      this.pageId = ctx.navDestinationId ?? '';
/ / ★ Retrieval callback (CustomNavigationUtils for Re-Case 3)
      CustomNavigationUtils.getInstance().registerNavParam(
        this.pageId,
        (isPush, isExit, transitionProxy) => { this.runTransition(isPush, isExit, transitionProxy); },
3000 / / The gesture scene takes longer time
      );
    })
  }

/ TranstionProxy is at the heart of the scene: using it to control the "time of completion".
// - PUSH entry is a single-time animation → the end of animation (onFinish) i.e. finishTransis;
/ / - POP exit vision has been processed by hand gesture Dismiss Viewer() → immediately finishfinishTransion.
/ / Both paths must call FinnishTransation() or otherwise hang up until the timeout (3s) page is falsely dead.
  private runTransition(isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy): void {
    if (isPush && !isExit) {
/ PUSH Entry: Picture Zooming + Motion Fade
      this.imgScale = 0.5; this.bgOpacity = 0;
      this.getUIContext().animateTo({
        duration: 400, curve: Curve.Spring,
/ / ★ Notification system rerun after animation is completed (no call to timeout)
        onFinish: () => { transitionProxy.finishTransition(); }
      }, () => {
        this.imgScale = 1; this.bgOpacity = 1;
      });
      return;
    }
/ POP exit (isExit=true): Image visual has been completed by dississViewer() handiwork.
/ / No more animations are required here, but ★ still has to call finishTransion() to notify the end of the switch.
    transitionProxy.finishTransition();
  }

/ ** gesture confirmed closed*/
  private dismissViewer(): void {
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.imgScale = 0.3; this.imgOffsetY = 500; this.bgOpacity = 0;
    });
    setTimeout(() => { this.navStack.pop(false); }, 300);
  }

*/ ** Gear canceled
  private snapBack(): void {
    this.getUIContext().animateTo({ duration: 300, curve: Curve.Spring }, () => {
      this.imgScale = 1; this.imgOffsetY = 0; this.bgOpacity = 1;
    });
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
`NavigationTransitionProxy` | Interactive Rotation Agency, `finishTransition()` Notification System Relay Complete
`PanGesture` ZiZiZiZiZi ZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZiZOZiZi
`Navigation.customNavContentTransition()` |Navigation Custom Rotation Event |API 11+|

# # # Additional explanation #

1. **finishTransion must be called**: the uncalled system waits for timeout before the switch is completed and the page is stuck. Both paths to this scene are: PUSH enters in the `onFinish` echo (completed at the end of the animation); POP exit vision is handled by gestures, ** in `runTransition` ** immediately ** (no more animation ends).

2. **Shows need to be larger timeout**: users in interactive transitions may be hesitant or slow to slide, and timeout is suggested to be 2000 ~ 3,000 ms.

3. **System default animated unended echo**: `onTransitionEnd` must be used to monitor the end of animated animation.

4. **Router conflict**: Router page rotation and Navigation push animations may be played at the same time, and the animations are closed at the initial push: `this.navStack.pushPath({ name: 'HomePage' }, false)`.

**Pop+Push execution**: based on pre-operational top page - push animation is performed while the top is still in the stack, otherwise pop animation is performed. If you need to pop after push and perform push animation, use `LaunchMode.NEW_INSTANCE`.

---

Scene 5: Share the elements and turn the scene

** scene description:** After the commodity list page clicks on the commodity picture, the picture smooths the transition to the large map area of the commodity details page to achieve the Hero animation effect of "one shot at the end". The user visual sense "fly" from the list location to the details page, and the transition to natural flow.

** Solution:** Use **`geometryTransition(id)`** to mark the same sharing element ID + **`animateTo` in the start and end pages to execute the route jump** (`pushPath` set for ZXXKEEP4ZX to close the default transfer). The system automatically calculates the location and size of the shared element and performs the transition animation.

### # Key constraints (Article 6 must be met in its entirety and one is not possible)

> ** List of common errors (self-check by article, animation abnormal/not effective for any failure)**:
> 1. ✗ Start page with Navbar / Navigation root content → Start page and destination page** must be NavDestification** (NavBar → NavDestification not supported)
> 2.  Z `pushPath` Untransmitted `animated: false` → ** Must pass `false`**, otherwise the default transposition and sharing elements animated with anomalous
> 3. `pop()` No pass `false` → `pop(false)` ** must pass `false`** to have a reverse animation
> 4.  Z `geometryTransition` on NavDestination** on content components** (e.g. `Image`), not NavDestination
> 5. ✗ Sets `zIndex`  ** ** Bans zIndex** (would overwrite system level to cause animation anomalies)
> 6. ✗ ✗  Z  Z ✓ ✓ ✓  **  **  **  **  **  ** ** ** ** **

Step 1: Commodity List Page (start page)

```typescript
// ProductListPage.ets
@Component
struct ProductListPage {
  navStack: NavPathStack = new NavPathStack();

  private products = [
id: '1', name: 'The Wireless Bluetooth Headphone', price: 299,
{id: '2', name: 'A smart watch', price: 1299},
id: '3', name: 'Put the chargeable treasure', price:99,
  ];

  build() {
    NavDestination() {
      List({ space: 12 }) {
        ForEach(this.products, (product) => {
          ListItem() {
            Row({ space: 12 }) {
/ / ★ Merchandise Picture: Marked as Shared Element
              Image($r('app.media.product_1'))
                .geometryTransition(`product_${product.id}`)
                .width(100)
                .height(100)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)

              Column({ space: 4 }) {
                Text(product.name).fontSize(16).fontWeight(FontWeight.Bold)
                Text(`¥${product.price}`).fontSize(14).fontColor(Color.Red)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onClick(() => {
/ / Wing core: execute jump within animateTo 's closed package + close the default switch
              this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
                this.navStack.pushPath(
                  { name: 'ProductDetailPage', param: { productId: product.id } },
default / / / / / close default switch
                );
              });
            })
          }
        }, (product) => product.id)
      }
      .width('100%')
      .padding(12)
    }
.title
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
    })
  }
}
```

Step 2: Commodity Details Page (head page)

```typescript
// ProductDetailPage.ets
@Component
struct ProductDetailPage {
  navStack: NavPathStack = new NavPathStack();
  @State productId: string = '';

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
/ / ★ Large chart of the details page: use the same shared element id
          Image($r('app.media.product_placeholder'))
            .geometryTransition(`product_${this.productId}`)
            .width('100%')
            .height(300)
            .objectFit(ImageFit.Cover)

Text('Commodity Details').fontSize(24).fontWeight (FontWeight.Bold)
Text (`Commodity Number: {this.productId}`).fontSize (14).fontColor (Color.Gray)

Button('return'). onClick()=>
/ / / / W
            this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
              this.navStack.pop(false);
            });
          })
        }
      }
    }
.title ('Commodity Details')
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      const param = ctx.pathInfo.param as Record<string, string>;
      this.productId = param?.productId ?? '';
    })
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
Z `geometryTransition(id)` | Tag Component is a shared element, id is an automatic transition |API 11+ |
Z `animateTo(options, callback)` | Triggered routing in a closed package, the system automatically calculates the share element transition |
`pushPath(name, animated)` | routed by `animated` set for ZXXKEEP2ZX to close the default switch |API 10+ |

## Attention ##

1. **id must be consistent**: `geometryTransition` parameters on the starting and end pages must be identical and not empty strings.

2. **The default rollover** must be closed: otherwise the two sections of the animation superimpose abnormally.

3. **The system must be in animateTo closed **: route operation in `animateTo` echo to calculate the animation range correctly.

4. ** The content component is set without NavDestification**: `geometryTransition` added to content components such as `Image` and not to `NavDestination`.

5. **NavDestination Do not set zIndex**: Animation anomalies can result from covering the system level.

6. **Pop returns also require animateTo**: return also requires `animateTo` in a `pop(false)` closed package to trigger reverse sharing of element animation.

---

# # scene 6: Dialog layers retreating from animation

**Scene description:** When `NavDestinationMode.DIALOG` is used to achieve the bottom bullet window, the default switch under animation pop exit has an experience problem: the mask layer does not have a hidden effect, but falls with the content. The desired effect is to be invisible at the time of exit + the content declines simultaneously.

**Solution:** Tie NavDESTINATION **`backgroundColor` to the state variable**, Gradiently from transparency to semi-transparent (entry) via `animateTo` in **XKEEP1ZX**, and Driverly Gradually from semi-transparent to transparent (release) in **XKEEP3ZX**. The system DIALOG exits animated (sliding in content) and the manual mask is gradually supermuted, creating a combination.

## # Accomplish the code: a dialog bullet window with a masked layer

```typescript
// DialogSheetPage.ets

@Builder
export function DialogSheetPageBuilder() {
  DialogSheetPage();
}

@Component
export struct DialogSheetPage {
  navStack: NavPathStack = AppStorage.get<NavPathStack>('navStack')!;
/ / / core: masked background colour as a state variable driven by animation
  @State backColor: ResourceColor = '#00000000';
  @State contentOffset: number = 0;

  build() {
    NavDestination() {
      Stack() {
// Bullet window content
        Column({ space: 16 }) {
/ Drag pointer
          Row() {
            Row().width(36).height(4).borderRadius(2).backgroundColor('#e0e0e0')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })

Text('Recognition Operation'). FontSize(20). FontWeight (FontWeight.Bold)
Text ( 'This operation is irrevocable, please confirm if it continues? I'm sorry.
            .fontSize(14)
            .fontColor('#666666')

          Row({ space: 12 }) {
Button.
              .layoutWeight(1)
              .backgroundColor('#f5f5f5')
              .fontColor('#333333')
              .onClick(() => {
                this.navStack.pop();
              })

Button.
              .layoutWeight(1)
              .onClick(() => {
                this.navStack.pop({ confirmed: true });
              })
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding({ left: 20, right: 20, top: 12, bottom: 28 })
        .translate({ y: this.contentOffset })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
.backgroundColor (this.backColor) / / / ★ state variable bound to masked background colour
    .mode(NavDestinationMode.DIALOG)
/ / / / When you enter, you're blindfolded. Current
    .onWillAppear(() => {
This.backColor = '#000000000';/ / Initial Transparency
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
This.backColor = '#66 million';/ / Gradient to Semi-Transparent Black
      });
    })
/ / / / / / / / / / / / / / / / / / /
    .onWillDisappear(() => {
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseIn }, () => {
This.backColor = '#000000'; / / Gradient Back to Full Transparency
      });
    })
  }
}
```

## # Key API Description

|API Note
|-----|------|---------|
`NavDestinationMode.DIALOG` | DIALOG mode, transparent superseding API 11+ |
`NavDestination.onWillAppear()` |Purpose to activate the API 12+ |
`NavDestination.onWillDisappear()`|back before unmounting page to start animation |API 12+|

## Attention ##

1. ** Background colour on NavDestination**: `backgroundColor` binding to status variable, animation driving background colour changes across the entire page (including the masked area). Do not set it on the content panel, otherwise the pop time mask will exit with the content.

2. **onWillAppear vs onWillDiseappear**: The entrance to the site starts animated at `onWillAppear` (before the page is mounted) and the exit starts animated at ZXXKEEP1ZX (before the page is unmounted) at the right time to see the effects.

3. **DIALOG Default Animation**: API 13 active system animation (min area down) with hand-on-faced animated animation combined with it.

4. **Duration Match**: It is recommended that the duration of the entrance/retire animation be closer to the time of the DIALOG rotation and more visually coordinated.


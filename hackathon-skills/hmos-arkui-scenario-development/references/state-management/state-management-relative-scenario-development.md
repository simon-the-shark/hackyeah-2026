# State management V1 & V2 associated developments

# Directory

1. [State variable support interface] (# status variable support interface)
- 1.1 [Advancement Management Capacity using state variables] (#Advance Management Capacity using state variables)
- 1.2 [Synthetic refreshing interface to solve V2-version kinetic problems] (#Sync refresh interface to solve V2 version kinetic problems I'm not sure.
2. [Acquiring system environment variables] (#Acquiring system environment variables)
- 2.1 [Acquire system environment variables through Environment] (#Acquire system environment variables through Environment)
- 2.2 [Acquire system environment variables through the Ability interface] (#Acquire system environment variables through the Ability interface)
3. [Dual-directed syntax sugar] (#bi-directed syntax sugar)
- 3.1 [$realization of two-way binding of system component parameters] (#$realization of two-way binding of system component parameters)
-3.2 [!! achieve two-way synchronization between defined components and two-way binding of system component parameters] (#!! achieve two-way synchronization between defined components and two-way binding of system component parameters)
4. [Associate animation] (#Associate animation)
- 4.1 [V1 status variable achieves attribute animation] (#V1 status variable achieves attribute animation)
- 4.2 [V2 status variable achieves attribute animation] (#V2 status variable achieves attribute animation)
5. [Participation reuse function] (#component reuse function)+
- 5.1 [V1 status variable achieves component reuse] (#V1 status variable achieves component reuse)
- 5.2 [V2 status variable achieves component reuse] (#V2 status variable achieves component reuse)
6. [Custom component freeze function] (#Custom component freeze function)
- 6.1 [V1 status variable achieves a custom component freeze] (#V1 status variable achieves a custom component freeze)
- 6.2 [V2 status variable achieves a custom component freeze] (#V2 status variable achieves a custom component freeze)
7. [@Builder Support State Variable Refreshed] (#@Builder Support State Variable Refreshed)
- 7.1 [achievement@Builder Parameter Transfer and UI Refresh] (#achievement@Builder Parameter Transfer and UI Refresh)
8. [Circle Rendering] (#Circle Rendering)
- 8.1 [V1 version circulation] (#V1 version circulation) I'm not sure.
- 8.2 [Circle Rendering V2] (#V2 Cycle Rendering) I'm not sure.

---

# State variable support interface

The `UIUtils` tool class contains a range of supporting interfaces for the management of state variables for observation, listening, debugging and synchronizing. These interfaces compensate for scenes (e.g., triangulation, JSON.parse return values) that cannot be covered by the decorator, and provide dynamic listening, debugging and synchronization.

> **Note:** Imported using the following interface: `import { UIUtils } from '@kit.ArkUI'`

** Auxiliary interface overview**

| Interface | Functions | API version | Scope of use |
|------|------|---------|----------|
| MakeObserved | Turns non-observable data into  @12  @ ComponentV2 and  @Component (cannot be used with V1 decorator)  @
| CanBeObserved | Can the subject be observed to obtain information about the associated components | 23 | Any location |
Get Target and get the original object before the agent.
@dMonitor | dynamic addition to listening function  @20 @ ComponentV2 and @ObservedV2|
@ClarMonitor | Dynamic Disable listening function  @20 @ ComponentV2 and @ObservedV2|
@ApplySync|SyncSyncSynthetically refreshing changes in the closed package
| FlushUpdates| Synchronize all changes before call  @ 22 @
@FlushUIPdates|

> **Note:** `addMonitor` and `clearMonitor` interface . ./state-management-v1v2-scenario-development.md

---
## # Use state variable assistive interface to enhance state management capability

**Scene ID:** STATE RELATIVE 01

** scene description:** imitation of the social applications user home page, managing user information (name, age, image, number of fans, etc.). User data are derived from the three parties SDK (not possible to add `@Trace`) and also support loading from the service side JSON; UI without updating problems encountered in page development requires debugging; dynamic listening notifications of changes in user attributes (e.g., changes in the number of fans trigger the logo update); and the original object before the agent needs to be retrieved for type judgement. Covers `makeObserved`, `canBeObserved`, `getTarget` support interface.

** Solution:** Observation capability and listening with ** ** `UIUtils` Tool Type for the secondary interface to manage state variables: `makeObserved` transforms the tripartite data into ZO `canBeObserved` debug UI without updating `getTarget` to obtain the original object for type judgement.

```
Process for developing the social applications home page:

  ┌──────────────────────────────────────────────────────────┐
  │  1. makeObserved                                         │
Three-way SDK user category / JSON.parse / Observable data
@Monitor/ @Compued / @Param
  ├──────────────────────────────────────────────────────────┤
  │  2. canBeObserved                                        │
│ UI does not refresh → Checks if the object can be observed → → → →
  ├──────────────────────────────────────────────────────────┤
  │  3. getTarget                                            │
│ Proxy → Get original object → Type judgement / NAPI Call │
  └──────────────────────────────────────────────────────────┘
```

Use makeObserved to make third-party user data visible

When the class definition cannot add `@Trace` to the tripartite package, or when an anonymous object returned by `interface`/`JSON.parse` cannot mark `@Trace`, use `makeObserved` to make it visible.

**makeObserved limit**

- Supporting only non-empty object-type participation. `undefined`, `null`, non-Object type not supported.
- Do not support the introduction of `@ObservedV2`, `@Observed` decorations and `makeObserved` sealed proxy data (preventing double agent).
- V1 state variable decorators (e.g. `@State`) cannot be used in conjunction with them, otherwise they are not normal when they are dropped.
- Supports the type of Array, Map, Set, Date, Collactions, Array/Set/Map, `@Sendable` Decoration, JSON.parse returned Object.

##### # Third party class cannot add @Trace

```ts
import { UIUtils } from '@kit.ArkUI'

/ / Simulates the class in the tripartite package, the developer cannot manually add
class ThirdPartyUserProfile {
Public userName: string = 'Zhang Three'
  public age: number = 25
  public avatar: string = 'default.png'
}

@Entry
@ComponentV2
struct UserProfilePage {
/ / using makeObserved to convert third-party class examples into observable data
  @Local profile: ThirdPartyUserProfile = UIUtils.makeObserved(new ThirdPartyUserProfile())

  build() {
    Column({ space: 15 }) {
Text (`Username: {this.profile.userName} ')
        .fontSize(20)
.onClick(() => {this.profile.userName += '!'} / makeObserved makes attribute changes visible

Text
        .fontSize(18)
        .onClick(() => { this.profile.age++ })

/ / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
Button (`replace user information'). onClick() = {
        this.profile = UIUtils.makeObserved(new ThirdPartyUserProfile())
      })
    }
    .padding(20)
  }
}
```

# # # # # # JSON.parse returns values to be visible

```ts
import { UIUtils } from '@kit.ArkUI'

Let profileJsonStr: string = '"userName": "Lee Four" ♪ I'm not sure ♪

@Entry
@ComponentV2
struct JsonProfilePage {
/ /JSON.parse returned to an object that could not be used @Trace, makeObserved to observationable data
  profile: Record<string, Object> =
    UIUtils.makeObserved<Record<string, Object>>(JSON.parse(profileJsonStr) as Record<string, Object>)

  build() {
    Column() {
Text (`Username: {this.profile['userName']}')
        .fontSize(30)
.onClick(()=> {this.profile['userName'] += '!'})/ /observable, trigger refreshing

Text (`Age: {this.profile['age']})
        .fontSize(30)
        .onClick(() => { (this.profile['age'] as number)++ })
    }
  }
}
```

Key points: `JSON.parse` returns anonymous `Object`, unable to use `@Trace` tag properties and using `makeObserved` to make it visible.

## # makeObserved with V2 decorations

```ts
import { UIUtils } from '@kit.ArkUI'

class ProfileInfo {
  public id: number = 0
  public age: number = 20

  constructor(id: number) {
    this.id = id
  }
}

@Entry
@ComponentV2
struct ProfileMonitorPage {
  @Local message: ProfileInfo = UIUtils.makeObserved(new ProfileInfo(20))

/ makeObserved returns value can be monitored at @Monitor depth
  @Monitor('message.id')
  onIdChange(monitor: IMonitor) {
    console.info(`id change from ${monitor.value()?.before} to ${monitor.value()?.now}`)
  }

/ makeObserved returned value dependent on
  @Computed
  get profileLabel(): string {
    return `ID: ${this.message.id} Age: ${this.message.age}`
  }

  build() {
    Column() {
      Text(`id: ${this.message.id}`)
        .fontSize(30)
        .onClick(() => { this.message.id++ })

      Text(`Computed: ${this.profileLabel}`)
        .fontSize(30)

Button (`reset'). onClick()=>
        this.message = UIUtils.makeObserved(new ProfileInfo(200))
      })

/ Passable to Subcomponent@Param
      ProfileChild({ message: this.message })
    }
  }
}

@ComponentV2
struct ProfileChild {
  @Param @Require message: ProfileInfo

  build() {
    Text(`Child id: ${this.message.id}`).fontSize(30)
  }
}
```

###2 Use canBeObserved to debug UI without refreshing questions

The `canBeObserved` interface determines whether the object is an object that can be observed and takes information about the components associated with the object to help the developer locate UI without updating the problem.

## # judge whether the data can be observed in the home page

```ts
import { UIUtils } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProfileDebug'

@ObservedV2
class UserProfileV2 {
@Trace public userName: string = 'Zhang Three'
  @Trace public age: number = 25

  test(): void {
    hilog.info(0x00, TAG, `canBeObserved: ${JSON.stringify(UIUtils.canBeObserved(this))}`)
  }
}

@Entry
@ComponentV2
struct ProfileDebugPage {
  @Local profile: UserProfileV2 = new UserProfileV2()

  build() {
    Column({ space: 15 }) {
Text (`Username: {this.profile.userName} ')
        .fontSize(20)
        .onClick(() => { this.profile.userName += '!' })

Text
        .fontSize(18)
        .onClick(() => { this.profile.age++ })

Button('Checkable State'). onClick() = {
        this.profile.test()
/ / Example of return result:
        // { "isObserved": true,
        //   "reason": "The object data is decorated with V2 @ObservedV2 and @Trace",
        //   "decoratorInfo": [{
        //     "decoratorName": "@Trace",
        //     "stateVariableName": "userName",
        //     "owningComponentOrClassName": "UserProfileV2",
        //     "owningComponentId": -1,
        //     "dependentInfo": [{ "elementName": "Text", "elementId": 6 }]
        //   }]
        // }
      })
    }
    .padding(20)
  }
}
```

Key points: `canBeObserved` returns `ObservedResult` object, which includes `isObserved` (observable), `reason` (justification of cause), ZXXKEEP4ZX (decoration information and associated components). If `reason` contains `but not used in UI`, indicate that the object is detectable but not used by the UI component, the modified value does not trigger UI refreshing.

# # locate UI without refreshing the problem

```ts
import { UIUtils } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProfileDebug'

class UnobservedProfile {
Public userName: string = 'King Five'
  public age: number = 30
}

@Entry
@ComponentV2
struct ProfileNotRefreshPage {
/ / Normal variable, not decorated by decorator, modified does not trigger UI brush New
  profile: UnobservedProfile = new UnobservedProfile()

  build() {
    Column() {
Text (`Username: {this.profile.userName} ')
        .fontSize(20)
        .onClick(() => {
/ Check for observation before amendment
          hilog.info(0x00, TAG, `res: ${JSON.stringify(UIUtils.canBeObserved(this.profile))}`)
/ Return result:   "isObserved": false, "reason": "The object data is not an observable object", "decorator Info":[]
This. process.userName += '!' / Unobserved, UI does not refresh
        })
    }
  }
}
```

###3 Use gettarget to get the original object before the agent

The status management framework adds an agent layer to the object, leading to an unexpected outcome from the type judgement and NAPI call. `getTarget` can get the original object before the agent.

### # # V1 Get original object

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProfileObserved {
Public userName: string = 'Zhang Three'
}

@Entry
@Component
struct ProfileGetTargetV1 {
  @State profile: ProfileObserved = new ProfileObserved()

  build() {
    Column() {
Text (`Username: {this.profile.userName} ')
        .fontSize(20)
.onClick(()=> {this.profile.userName = 'Alice'})/ / Proxy Changes, UI Refresh

Button ('Get Original Object Changes'). onClick() = >
        let rawProfile: ProfileObserved = UIUtils.getTarget(this.profile)
RawProfile.userName = 'Bob '// Original Object Modified, UI does not refresh!
      })
    }
  }
}
```

# # # # V2 Get original object

```ts
import { UIUtils } from '@kit.ArkUI'

@ObservedV2
class ProfileV2 {
@Trace public userName: string = 'Zhang Three'
}

@Entry
@ComponentV2
struct ProfileGetTargetV2 {
@Localprofile:ProfileV2 = newProfileV2()//V2 class not represented
@Localtags: string[] = ['Technology', 'Social']/ /Array type represented

  build() {
    Column() {
Text (`Username: {this.profile.userName}.fontSize(20)
Text(`label: {this.tags.join(,')}.fontSize(18)

Button ('Gettags Original Object'). Onclick() = {
        let rawTags: string[] = UIUtils.getTarget(this.tags)
/ / RawTags is the original array before the agent. The modification will not trigger the UI brush New
      })
    }
  }
}
```

## # Use synchronous refresh interface to solve V2-version kinetic problems

**Scene ID:** STATE RELATIVE 02

** scene description: ** Simulate weather forecasting application, where users smooth-up weather icons by clicking on the weather details page from the city list to share the element transfer; thermometer animations when temperature changes are not shown in the details page; and a first-time animation frame error after bulk updates of weather data. These problems stem from the problem of state-managed V2 steroids in conflict with the `animateTo`/shared element conversion mechanism. Covers three simultaneous refreshing interfaces for `applySync`, `flushUpdates`, and `flushUIUpdates`.

** Solution: ** Synchronize V2 with the **ZXKEEP0Z resource class**: `applySync` Synchronize changes in the closed package `flushUpdates` Synchronize all changes before the start-up `flushUIUpdates` only adds UI nodes.

```
The weather forecast applies a synchronized refreshing process:

  ┌──────────────────────────────────────────────────────────┐
1. Three interfaces
│ Batch update of weather data → Open animation → Comparison of three simultaneous refreshing methods
  ├──────────────────────────────────────────────────────────┤
2. Dynamic scenarios
@Monitor listens to the temperature, boom, triggers animateTo #applySync
  ├──────────────────────────────────────────────────────────┤
3. Route scenario
│ City list for weather details → Shared Element Rotation → ApplySync Syncname │
  └──────────────────────────────────────────────────────────┘
```

> **Note:** Imported using the following interface: `import { UIUtils } from '@kit.ArkUI'`

## 1. Use and distinction of three synchronized refreshing interfaces

The state management V2 changes the state variable not to be dirty immediately, but rather to throw the Promise microtask, which is processed after the current macro assignment has been completed. `animateTo` action will immediately refresh the marked dirty node to determine the action frame. If the V2 status variable is used in the action effect and is modified before the action, the change in the status variable at the time of `animateTo` has not yet been painted, resulting in a failure of the action frame.

In the weather details page, click on the Refreshing Data button to provide a batch update of temperature, humidity, and after the wind speed trigger, the details card is animated and synchronized with three interfaces:

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct WeatherDetailPage {
  @Local temp: number = 25
  @Local humidity: number = 60
  @Local windSpeed: number = 10
  @Local cardHeight: number = 80
@Localstatus: string = 'To be refreshed'

  @Monitor('status')
  onStatusChange(monitor: IMonitor) {
})
  }

  build() {
    Column({ space: 15 }) {
Text (`${this.temp} °C Humidity: {this.humidity} % Wind speed: {this.windSpeed}m/s`).fontSize(16)

// Method 1: applySync - Sync to refresh changes in the closed package, @Monitor returns twice
Button ('applySync refreshing'). onClick() = {
        UIUtils.applySync(() => {
This.temp = 28; this.humidity = 45; this.status = 'updated'
        })
        this.getUIContext().animateTo({ duration: 500 }, () => {
This.cardHeight = 200; this.status = 'Animated'
        })
      })

// Method 2: flushUpdates - Sync to refresh all changes before calling, @Monitor returns twice
Button ('flushUpdates '). onClick() = {
This.temp = 28; this.humidity = 45; this.status = 'updated'
        UIUtils.flushUpdates()
        this.getUIContext().animateTo({ duration: 500 }, () => {
This.cardHeight = 200; this.status = 'Animated'
        })
      })

// Mode 3: flushUIupdates - only synchronize to refresh UI nodes without trigger@Monitor, only once
Button ('flushUIPDATEs refreshing'). Oncrick()=>
This.status = 'updated'
        UIUtils.flushUIUpdates()
This.status = 'Animated' / @Monitor returns only once
      })

      Column() { Text(this.status).fontSize(14) }
        .height(this.cardHeight).backgroundColor('#f0f8ff').animation({ duration: 500 })
    }
    .padding(20)
  }
}
```

Key points: `applySync` and `flushUpdates` will both synchronize the `@Computed` calculation and `@Monitor` echo, the example of which is triggered twice by a single click. `flushUIUpdates` only synchronizes to refresh UI nodes, does not execute `@Computed` and `@Monitor` echo, and `@Monitor` only triggers once.

@ Interface  @ Effect  @ Monitor/ @Computed| Appliance scene  @
|------|------|-------------------|----------|
|ApplySync|Sync Synchronizes changes in a closed package
| flushUpdates| Synchronize all changes before call | Trigger execution | Batch changes before action need to be synchronized
| FlushUIupdates | Only synchronize to refresh UI node | do not trigger | UI synchronise before working, do not want @Monitor to echo |

@####2. Action scenario @Monitor trigger animateTo achieve temperature change animation

When temperature changes, `@Monitor` listens to temperature changes and triggers `animateTo` to achieve temperature + gradual animation. The `animateTo` closed package has not yet been altered to topple because of the dirty V2 walk mark, resulting in the animation not being shown. Use `applySync` in a `animateTo` closed package to refresh the problem.

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct TempAnimationPage {
  @Local temp: number = 25
  @Local offsetY: number = 0
  @Local opacity: number = 1

  @Monitor('temp')
  onTempChange() {
    this.playTempAnimation()
  }

  playTempAnimation() {
    this.getUIContext().animateTo({ duration: 800 }, () => {
/ / Call applySync to synchronize refreshing and transparency, and if not, the animation does not appear
      UIUtils.applySync(() => {
        this.offsetY = 20
        this.opacity = 0.5
      })
    })
  }

  build() {
    Column({ space: 20 }) {
      Text(`${this.temp}°C`)
        .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#ff9800')
        .offset({ y: this.offsetY })
        .opacity(this.opacity)

Button (`temperature+1'). onClick()=>
This. Temp+=1 / Trigger@Monitor→playTempAnimation
      })
    }
    .padding(20)
  }
}
```

Key points: When `@Monitor` was triggered in `animateTo` in the ZXKEEP1Z return, the V2 isostep stain caused the changes in the ZXXKEEP2ZX closed package to remain unpainted and the animation was not shown. Use `applySync` in the `animateTo` closed package to synchronize changes to the state variable to ensure that the animation is displayed correctly.

###3 Route scene - City list of shared elements to weather details page

The user clicks on the weather icon from the city list to enter the details page and smooths up the icon by sharing the elements. Use `applySync` to ensure that `sharedTransition` 's `name` values are synchronised before the route jumps. Lists the name(s) that does not match when the page jumps, and the name(s) that matches when the detailed page returns.

```ts
import { UIUtils, AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
export class TransitionName {
  @Trace public name: string = ''
}

/ / City list page: Click on weather icons to jump and set a name that does not match
@Entry
@ComponentV2
struct CityListTransitionPage {
  @Local tn: TransitionName = AppStorageV2.connect(TransitionName, () => new TransitionName())!

  build() {
    Column() {
      Text('☀').fontSize(40)
        .sharedTransition(this.tn.name, { duration: 500, curve: Curve.EaseInOut })
    }
    .width('100%').height('100%')
    .onClick(() => {
UIUtils.applySync(()=> {This.tn.name= 'list icon'})/ / / not matching the details page
      this.getUIContext().getRouter().pushUrl({ url: 'pages/WeatherDetailTransitionPage' })
    })
  }
}

/ / Weather details page: Click back, set a matching name (go-live)
@Entry
@ComponentV2
struct WeatherDetailTransitionPage {
  build() {
    Stack() {
      Text('☀').fontSize(80)
        .sharedTransition('detail_icon', { duration: 500, curve: Curve.EaseInOut })
        .onClick(() => {
          UIUtils.applySync(() => { AppStorageV2.connect(TransitionName, () => new TransitionName())!.name = 'detail_icon' })
          this.getUIContext().getRouter().back()
        })
    }
    .width('100%').height('100%')
  }
}
```

Key points: `list_icon` does not match the `detail_icon` when the list page jumps to the details page; `name` is synchronized to ZXXKEEP4ZX, matching ZXXKEEP5ZX to the list page to create a roller effect when the details page returns through `applySync`. `applySync` ensures that the `name` value is synchronised and refreshed before the route jump.

# # # 4. Limits

- Embedded `applySync` in a `applySync` in a `applySync`, where the inner layer will skip and return undefined, while printing warning messages.
- `applySync` Call in `flushUpdates` or `flushUIUpdates` does not work while printing warning messages.
- Calles to these three interfaces in `@Computed` getter are not supported and errors are reported when running (fault code 140001).
- Calles `flushUpdates` and `flushUIUpdates` in `@Monitor` are not supported, and errors are reported when running (fault code 140002).

---

# Get the system environment variable

In state management V1, environmental variables can be obtained through Environment, but the results obtained by Environment cannot be used directly and need to be matched to AppStorage to obtain the value of the corresponding environmental variables. In state management V2, no more environmental variables need to be obtained through Envirronment, and system environmental variables can be obtained directly through the UIAbilityContext config properties.

** Two ways to compare**

| Capabilities | Retrieved via Envirronment
|------|---------|---------|
Start of API conversion 7
Use form |XKEEP0ZX interface to write values to AppStorage and components to get |`UIAbility.context.config` reading configuration memory to get |

---

# # Get system environment variables through Envirronment

**Inline list of parameters**

| Key | Data type | Description |
|------|---------|------|
Whether or not to use an accessible screen view. 'true 'is enabled, 'false' is not enabled
|colorMode|ColorMode|Colour Color Mode (LIGHT/ DArk)|
|fontScale | number | font size ratio. Cannot initialise Evolution's mail component.
|FontWeightScale | number | font sizes, different systems or machine types may vary
LTR/RTL
|rangeCode |string | Current system language (e. g. zh, en) to be a lower case letter

**Environment Restrictions**

- Environment is linked to UIContext and requires UIContext to call the `envProp` interface. The context can be specified by ZXXKEEP1ZX, otherwise the device environment data cannot be accessed.
- Environment does not have a response capability and does not automatically notify an update when a system environment variable changes. New values need to be obtained by applying a new `envProp`.
- Applies that cannot modify the parameters of an environmental variable, `@StorageProp` should be used to obtain (one-way sync), even if changes within the component do not synchronize back to AppStorage.
- The default value for `envProp` only takes effect when there is no key in AppStorage, and it will not be overridden if already in AppStorage (reset after deletion).

**Scene ID:** STATE RELATIVE 03

**Scene description:** Simulation of the multilingual social applications settings page, which needs to be adapted to the device environment information interface: Show localised labels according to system language, and change the colour of the page according to the dark light pattern.

** Solution:** Use **`Environment.envProp`** to deposit the device environment variable in AppStorage + **`@StorageProp`** in a one-way synchronized acquisition (read-only) in components
```
Multilingual social applications settings Page
  ┌──────────────────────────────────────────────────────────┐
1. EntryAbility Initialisation (runScopedTask specified UIContext)
  │     Environment.envProp('languageCode', 'en')  → AppStorage│
  │     Environment.envProp('colorMode', ...)      → AppStorage│
  ├──────────────────────────────────────────────────────────┤
2. UI Component (@StorageProp Unidirectional, Read-only)
Localized tag (Chinese/English)
│colorMode
  └──────────────────────────────────────────────────────────┘
```

Initialize Environment in EntryAbility

`Environment.envProp` needs to be called when UIContext is clear, usually in `EntryAbility` with `onWindowStageCreate` after `runScopedTask`.

```ts
import { UIAbility } from '@kit.AbilityKit';
import { window, Environment } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/SocialSettingsPage');

    windowStage.getMainWindow().then((mainWindow) => {
      let uiContext = mainWindow.getUIContext();
/ / must be called in runScopedTask, specify UIContext
      uiContext.runScopedTask(() => {
/ / Save 6 device environment variables in AppStorage, the second parameter is the bottom default
Other Organiser
Environment. envProp ('colorMode', ColorMode. LIGHT); / / Dark Light Mode
      });
    });
  }
}
```

Set Page UI Fit - @StorageProp for All Environmental Variables (read-only)

The component acquires the environment variable by `@StorageProp` from AppStorage One-way Synchronization. Application cannot modify the environment variable and therefore uses `@StorageProp` (one-way) - even within the component changes do not synchronize back to AppStorage.

```ts
@Entry
@Component
struct SocialSettingsPage {
/ @StorageProp Un-sync: Fetch environment variables from AppStorage (read-only)
  @StorageProp('languageCode') languageCode: string = 'en';
  @StorageProp('colorMode') colorMode: ColorMode = ColorMode.LIGHT;

  build() {
    Column({ space: 15 }) {
// Show localized titles according to system language, font size follows system scaling
Text
        .fontSize(24 * this.fontScale)
        .fontWeight(this.fontWeightScale > 1.0 ? FontWeight.Bold : FontWeight.Normal)

/ / Toggle Colour based on Dark Light
      Column({ space: 10 }) {
Text
          .fontSize(18 * this.fontScale)
          .fontColor(this.colorMode === ColorMode.DARK ? Color.White : Color.Black)
      }
    }
    .padding(20)
    .backgroundColor(this.colorMode === ColorMode.DARK ? '#1a1a1a' : '#ffffff')
  }
}
```
---

# # Acquiring system environment variables through the Ability interface #

**Configuration Common Support Parameters List**

| Parameter | Data type | Description |
|------|---------|------|
|range | string | system language (e. g. `zh`, `en`)
|colorMode| number| color pattern: `COLOR_MODE_LIGHT`(0)/ `COLOR_MODE_DARK`(1)|
|direction | number | Screen orientation: vertical (0) / screen (1)
♪ ScreenDensity ♪
FontSizeScale
fFontWeightScale | number | size

**Scene ID:** STATE RELATIVE 04

**Scene description:** Simulation of the multilingual social application settings page, requiring a system environment information adaptation interface: Show localised labels according to system language, and change the colour of the page according to the dark light pattern.

** Solution:** Writing AppStorage using **`UIAbility.context.config`** to read system environment variables directly in the Ability life cycle.

```
Multilingual social applications settings Page
  ┌──────────────────────────────────────────────────────────┐
1. EntryAbility Initialisation (onCreate ReadContext.config)
  │     config.language → AppStorage('sysLanguage')           │
  │     config.colorMode → AppStorage('sysColorMode')         │
  ├──────────────────────────────────────────────────────────┤
│2. UI Component (@StorageProp+@watch Unidirectional) │
│ sysLanguage
│ sysColorMode
  └──────────────────────────────────────────────────────────┘
```

#1.EntryAbility Read contact.config and listen to changes

Reads the current system environment variable in `UIAbility.onCreate` through `this.context.config` and writes to AppStorage; changes to the sensor system in ZXXKEEP2ZX are configured and updated in AppStorage, thus allowing the bound UI component to be automatically updated.

```ts
import { AbilityConstant, UIAbility, Want, Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
// Read system environment variables directly through context.config
    const config = this.context.config;
    AppStorage.setOrCreate('sysLanguage', config.language);
    AppStorage.setOrCreate('sysColorMode', config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

Set Page UI Fit @StorageProp

The component acquires the environment variable by `@StorageProp` from AppStorage One-way Synchronization.

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

@Entry
@Component
struct SettingsPage {
/ @StorageProp Un-sync: Fetch environment variables from AppStorage (read-only)
  @StorageProp('sysLanguage')  sysLanguage: string = 'en';
  @StorageProp('sysColorMode') sysColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  build() {
    Column({ space: 15 }) {
      Text(`Language: ${this.sysLanguage}`)
        .fontSize(14)
        .fontColor(this.sysColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? Color.Black : Color.White)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}
```
---

# Two-way semantic sugar

`$$` and `!!` are two-way binding syntax sugars provided by ArkUI to synchronize data in both directions. `$$` is recommended for state management V1 to achieve a two-way binding of system components and state variables; and ZXXKEEP3ZX for state management V2 is recommended for a two-way binding between ZXKEEP3Z components and custom components.

** `$$` vs. `!!`**

`$$` `!!`
|------|-----------|-----------|
Recommended range V1 state management V2 state management
| Two-way binding of system components | Support (API 10+) | Support (API 18+) |
| Custom component two-way binding | does not support | support (simplified ZXKEEP0Z+`@Event`) |
| Type of variable supported
| Multi-layer parent-son component transfer | only supports system component parameters
---

# # # $$ to achieve two-way binding of system component parameters

**Scene ID:** STATE RELATIVE 05

** Scene description: ** Equivalent manufacturer ' s commodity release form sheet page, business needs to fill in information such as a description of the commodity, and supports interaction at the bottom with advanced bullet windows, etc. The two-way synchronization of the system component parameters with the state variable is required through `$$` syntax sugar: the state variable is automatically updated when the user operates the control and the control is synchronized with the latest values when the status variable changes.

** Solution:** Use **`$$` syntax sugar** to achieve a two-way binding of the system component parameters with the V1 status variable (`@State`), covering the input category (TextInput) and the bullet window category (bindSheet).

```
Electrician Commodity Release Form Page ($$2-direction binding)

  ┌──────────────────────────────────────────────────────────┐
Two-way binding of system components parameters ($US$ uniform syntax)
  │     TextInput({ text: $$this.description })              │
  │     .bindSheet($$this.showSheet, ...)                    │
  ├──────────────────────────────────────────────────────────┤
│$$$$$$$$$$$$$$US$$US$$US$US$$US$$US$US$$US$$US$US$$US$$$US$$US$$US$$US$$US$$US$$US$$US$$$US$$US$US$$US$US$US$$$US$$US$$US$$US$
Use recommended in │V2!
  └──────────────────────────────────────────────────────────┘
```

Two-way binding of system component parameters (TextInput, bindSheet)

The `$$` operator provides a reference to TS variables for the system component, keeping the variable synchronized with the internal state of the system component. Add `$$`, e.g., `text: $$this.description`, to the system component parameters.

```ts
@Entry
@Component
struct ProductPublishPage {
/ Commodity Description
  @State description: string = ''
/ Advanced setting of bullet windows to hide
  @State showSheet: boolean = false

  build() {
    Column({ space: 12 }) {
Text (`publication of goods').fontSize(24).fontWeight (FontWeight.Bold)

/ $$ syntax: TextInput's text parameter synchronizes with description
TextInput ({text: $this.description, placeholder: 'Please enter commodity description'})
        .width('100%')

/ $$ syntax: bindSheet's isShow parameters synchronize with showSheet's two-way
Button.
        .onClick(() => { this.showSheet = true })
        .bindSheet($$this.showSheet, {
          builder: () => {
            Column() {
Text('Advanced Settings'). FontSize(20). Padding(20)
Text('Freight Template, Shipment Address, etc.')
Button (`Closed').onClick()=> {this.showSheet=false}
            }
          }
        })

/ / / / / / / / / / / / / / / / / / / / / /
Text (`Description: ${this.description}')
        .fontSize(14).fontColor(Color.Gray)
    }
    .padding(20)
  }
}
```
---

### #! Achieve two-way synchronization between custom components and two-way binding of system component parameters

**Scene ID:** STATE RELATIVE 06

** Scenario description: ** Equiprtor ' s commodity release form sheet page, where the vendor is required to fill in information such as trade names, trade descriptions and to support interaction at the bottom with high-level bullet windows, etc. This needs to be done through `!!` syntax sugar: two-way binding between defined components (trade name input components synchronized with parent components ZXKEEP1Z+`@Event`); two-way binding of system component parameters (TextInput, bindSheet, etc.).

** Solution: ** Harmonized ** ** ** `!!` syntax ** to achieve a two-way binding of the parameters of the self-defined components (simplified ZXKEEP1Z+`@Event`) and the system component, covering the two-way binding of the self-defined components and the two-way binding of the system component parameters.

```
Electrician Commodity Release Form Page (!!

  ┌──────────────────────────────────────────────────────────┐
1. Double-direction binding between custom components (!! Simplified @Param+@Event) │
  │     ProductNameInput({ productName: this.productName!! })│
│ Parent Component Modification → Sync to Sub Component │
@Event
  ├──────────────────────────────────────────────────────────┤
2. Bi-directional binding of the parameters of the system component (!! Unified syntax)
  │     TextInput({ text: this.description!! })              │
  │     .bindSheet(this.showSheet!!, ...)                    │
  ├──────────────────────────────────────────────────────────┤
│ ⚠ ! ! ! !
@Event
│ 3 or more exclamation marks do not support two-way binding
  └──────────────────────────────────────────────────────────┘
```

####1!! For double-direction binding between custom components (trade name input)

`!!` Two-way Bonded Grammar Sugar simplifys the two-way binding of `@Param`+`@Event`. Changes in variables marked by `!!` for parent components are synchronized with the sub-components and with the parent component.

```ts
@Entry
@ComponentV2
struct ProductPublishPage {
/ Trade names
  @Local productName: string = ''

  build() {
    Column({ space: 15 }) {
Text (`publication of goods').fontSize(24).fontWeight (FontWeight.Bold)

/ /!! syntax sugar: two-way binding between custom components
/ / Equivalent to ProdudNameInput ({productName: This. regulationName, $productName: (val)=> This.produceName=val})
      ProductNameInput({ productName: this.productName!! })

/ / / / / status variable changes to synchronize subcomponent updates
Text
        .fontSize(14).fontColor(Color.Gray)

      Row({ space: 10 }) {
Button (`Setting Default Name').onClick(()=> {this.projectName=`default Commodities'})
      }
    }
    .padding(20)
  }
}

// Trade Name Input Component
@ComponentV2
struct ProductNameInput {
/ / @Param Receives parent input values
  @Param productName: string = ''
/ @Event Declares that the method must be "$" + @Param Properties First Name
  @Event $productName: (val: string) => void = (val: string) => {}

  build() {
    Column() {
Text (`trade names'). FontSize (16)
It can also be used in sub-components! Tie the system components!
TextInput ({text: this.projectName!, placeholder: 'Please enter trade name'})
        .width('100%')
        .onChange((value: string) => {
// Notify parent to modify data by @Event Source
          this.$productName(value)
        })
    }
  }
}
```

####2!! Two-way binding for system assembly parameters (TextInput, bindSheet)

`!!` Operators can also provide TS-variable references to system components, keeping the internal state of variables and system components synchronized. Add `!!` to the variable name, for example `this.description!!`.

```ts
@Local description: string = ''
@Local showSheet: boolean = false

/ /!! syntax: TextInput text parameters synchronized with description in two directions
TextInput ({text: this.description!, placeholder: 'Please enter a description'})
  .width('100%')

/!! Syntax: bindSheet's isShow parameters synchronized with showSheet
Button.
  .onClick(() => { this.showSheet = true })
  .bindSheet(this.showSheet!!, {
    builder: () => {
      Column() {
Text('Advanced Settings'). FontSize(20). Padding(20)
Text('Freight Template, Shipment Address, etc.')
Button (`Closed').onClick()=> {this.showSheet=false}
      }
    }
  })

Text (`Description: ${this.description}')
  .fontSize(14).fontColor(Color.Gray)
```
---

# Attribute Animation

V1 state variable and V2 status variable can be animated with properties by `animateTo`. Additional processing is required due to the incompatibility of the V2 status variable and the animateTo refreshing mechanism.

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
State Variable Decorator
** Promise microtape **
| | | | | |

---

# # V1 status variable achieves attribute animation

**Scene ID:** STATE RELATIVE 07

** scene description:** mimic music player page, bottom mini player bar (show song name, singer). When you click the expanded button, the mini-player is smoothed to the full-screen player view (higher, small corner, background colour gradient, album cover zooming, expanding icon 180°). Animated with V1 `@State` management state, `animateTo` drive.

** Solution:** Modify the state variable drive properties animation using **`@State` Management Animation State** + **`animateTo` closed package**. `@State` immediately after the modification of V1, the modification of `animateTo` has become effective at the end of the closed package and the animation frame is correctly rendered without additional processing.

```
Music Player Page
@state isExpanded  animateTo    @ Expand/Reassembly Animated
Height 80% fullscreen / round corner 24→0 / Background Colour Gradient / Cover / Icon Rotate 180°
@state Synchronized Curtain → amendment effective immediately after closing
```

####1. Mini Player Start/Close Animation - @state + animateTo

```typescript
@Entry
@Component
struct MusicPlayerPage {
  @State isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
/ Background content area...

// Mini Player / Full Screen Player
      Column({ space: 12 }) {
        Row({ space: 12 }) {
// Album cover, song name etc.

/ / Expand/ Collapse button: Rotate Animation
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
/ / V1@state Synchronize the flag as soon as it is modified, and the modifications in the animateTo closed package are directly effective
              animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
                this.isExpanded = !this.isExpanded
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```

Key points: The `@State` modification of V1 immediately synchronizes the stain, and the `animateTo` modification of state variables such as ZXXKEEP2ZX in the closed package is immediately effective at the end of the closed package, and the animation frame is correctly rendered. `animateTo` does not require any extra processing to cooperate with `@State`. Component Properties Animation can also be driven automatically when the status variable changes using the `.animation()` attribute method.

---

## # V2 status variable achieves attribute animation

**Scene ID:** STATE RELATIVE 08

** scene description:** mimics the music player page, and clicks on the bottom mini player bar to expand to a full-screen player view (higher, small corner, background colour gradient, album cover zooming, extension icon rotation 180°). Use the V2 `@Local` management state, the `animateTo` drive animation, and solves the problem of the frame of animation caused by the incompatibility of the V2 heap with the `animateTo` refreshing mechanism.

** Solution:** Use **`@Local` to manage animated state** + **`animateTo` to use `UIUtils.applySync` to synchronize to refresh** (API 22+) or ** ZXKEEP3Z** (API 22 before). `@Local` modified Promise microtape for V2, the `animateTo` closed-pack stain has not yet taken effect, resulting in an incorrect animation frame. API 22 and the subsequent `UIUtils.applySync` call in the `animateTo` closed package will modify the sync to refresh; `animateToImmediately` was replaced by `animateTo` by `animateToImmediately` prior to API 22, which will synchronize changes in the closed package and then perform animations.

```
Music Player Page
@Local isExpanded  animateTo    @ Expand/Reassembly Animated
Height 80% fullscreen / round corner 24→0 / Background Colour Gradient / Cover / Icon Rotate 180°
⚠V2 Step Shape → animateTo Decoration failed at close
✅API Before 22: use animateToImmediately auto-sync refreshing, prefix correct
✅API 22+: Call UIUtils.applySync → Sync to Refresh First Frame Correct
```

Before ##1.API 22: @local + animateToImmediately

```typescript
@ComponentV2
struct V2MusicPlayerLegacy {
  @Local isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
/ Background content area...

// Mini Player / Full Screen Player
      Column({ space: 12 }) {
        Row({ space: 12 }) {
// Album cover, song name etc.

/ / Expand/ Collapse button: Rotate Animation
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
/ / API 22 Before: replace animateToImediately with animateTo
/ animateToImmediately synchronizes changes in a closed package and performs animations
              this.getUIContext().animateToImmediately({ duration: 400, curve: Curve.EaseInOut }, () => {
                this.isExpanded = !this.isExpanded
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```


#### 2.API 22+：@Local + animateTo + UIUtils.applySync

```typescript
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct V2MusicPlayerPage {
  @Local isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
/ Background content area...

// Mini Player / Full Screen Player
      Column({ space: 12 }) {
        Row({ space: 12 }) {
// Album cover, song name etc.

/ / Expand/ Collapse button: Rotate Animation
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
/ / V2@Local Modified rectangles dirty, modified directly in animateTo closed package leads to a frame error
/ / Should use applySync to refresh in animateTo closed package
              this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
                UIUtils.applySync(() => {
                  this.isExpanded = !this.isExpanded
                })
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```

# Component reuse

Both V1 and V2 support component reuse: V1 based on `@Reusable` + `@Component`, V2 based on `@ReusableV2` + `@ComponentV2`.

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
`@Reusable` +`@Component` |XKEEP2ZX +`@ComponentV2` |
| about ToReuse has (`params: Record<string, ESObject>`) | (state variable automatically reset) |
| Status variable reset | needs to be manually updated in about TOReuse @ Autoreset (@Local/@Param/@Event/@Provider/@Consumer/@Compued/@Monitor) |
|useId syntax |XKEEP0ZX directs the string  `.reuse({ reuseId: () => 'id' })` returns the call function |
| default for reuseId | default not set to reuse by component type
Z List Rendering Recommended
API 10 API 18

---

## # # V1 status variable for component reuse

**

- For `@Component` only, custom components may not be used in combination with `@Builder` or `@ComponentV2`.
- The component structure should remain unchanged before and after the re-use of the component, and the structural differences should be distinguished by `.reuseId('id')`.
- `ComponentContent` does not support the `@Reusable` component, which would result in a crash.
- The `aboutToReuse` neutron component will not be effective to modify the state variable of the parent component, and the reuse range will need to be removed using `setTimeout`.
- Do not recommend embedding `@Reusable`, which increases memory and reduces reuse efficiency.
- `ForEach` is fully spread, normal slide does not trigger recurrence, and `LazyForEach` should be preferred in long lists.
- The `aboutToReuse` parameter type does not support ZXKEP1ZX, which requires the use of specified types such as `Record<string, ESObject>`.

**Scene ID:** STATE RELATIVE 9

**Scene description:** emulation of the news message App's first page information stream, including a long list of news messages (LazyForEach). The news card has three structures: text, pictures and videos, which need to be distinguished by reuseId. Cover @Reusable Basic Usages (aboutToRecycle/aboutToReuse), LazyForEach LazyForEach Lazy Loads Co-Ride, ReuseId Distinct Structures.

** Solution:** Use **`@Reusable` Decoration `@Component` Custom Component** ** **`aboutToRecycle`/`aboutToReuse` Life Cycle** ** ** **`.reuseId()` Differentiating Structure** + ** `LazyForEach` Lazy Load Co-operation**

```
News Info App Home Page (@Entry@Component)
└List NewsCardV1 (@Reusable)
.useId
.useId ('imageNews')
.useId - Video News
└ - LazyForEach Scroll about ToRecile → about ToReuse
   
```

####1.@Reusable Basic - news card recovery and reuse (aboutToRecycle/aboutToReuse)

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'

/ News data model
class NewsItem {
  id: number = 0
  title: string = ''
  source: string = ''
  type: 'text' | 'image' | 'video' = 'text'

/ / /... tectonic numeric segment grant
}

/ Base reuse: @Reusable newscard component
@Reusable
@Component
struct NewsCardV1 {
  @State title: string = ''
  @State source: string = ''
  private newsId: number = 0

/ / component triggers when recycled into the reuse pool
  aboutToRecycle(): void {
    hilog.info(0x0001, 'NewsCardV1', `aboutToRecycle newsId=${this.newsId}`)
  }

/ / component triggers when re-use is removed from the reuse pool and the state variable is manually updated
  aboutToReuse(params: Record<string, ESObject>): void {
    const item = params.item as NewsItem
    this.newsId = item.id
    this.title = item.title
    this.source = item.source
    hilog.info(0x0001, 'NewsCardV1', `aboutToReuse newsId=${this.newsId} title=${this.title}`)
  }

  build() {
    Column() {
      Text(this.title).fontSize(16).fontWeight(FontWeight.Bold).maxLines(2)
      Text(this.source).fontSize(12).fontColor('#999999').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
  }
}
```
---

###2. LazyForEach + @Reusable — Newsmessage long list scrolling back

```typescript
/ / News data source to achieve the Datasource interface
class NewsDataSource implements IDataSource {
  private newsList: NewsItem[] = []
  private listeners: DataChangeListener[] = []

  constructor(news: NewsItem[]) { this.newsList = news }
  totalCount(): number { return this.newsList.length }
  getData(index: number): NewsItem { return this.newsList[index] }
/ ...registerDataChangeListener / unregisterDataChangeListener
}

/ News info page
@Entry
@Component
struct NewsFeedPageV1 {
  private newsData: NewsDataSource = new NewsDataSource([
/... News data entry
  ])

  build() {
    Column() {
Text('newsflow').fontSize(20).fontWeight(FontWeight.Bold).margin({buttom:12})

      List({ space: 8 }) {
        LazyForEach(this.newsData, (item: NewsItem) => {
          ListItem() {
            NewsCardV1({ item: item })
          }
        }, (item: NewsItem) => item.id.toString())
      }
      .width('100%').height(400)
.cachedCount (3) / Cache 3 screens to enhance flow flow in conjunction with the reuse pool
    }
    .width('100%').padding(16)
  }
}
```
---

## 3.useId distinguishes between different structures - text/photogram/video news card

```typescript
/ Multistructured news card: Distinguishing text, pictures, video by f/else
@Reusable
@Component
struct MultiTypeNewsCardV1 {
  @State title: string = ''
  @State source: string = ''
  @State type: string = 'text'
  private newsId: number = 0

  aboutToRecycle(): void {
    hilog.info(0x0001, 'MultiTypeNewsCardV1', `aboutToRecycle id=${this.newsId} type=${this.type}`)
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    const item = params.item as NewsItem
    this.newsId = item.id
    this.title = item.title
    this.source = item.source
    this.type = item.type
    hilog.info(0x0001, 'MultiTypeNewsCardV1', `aboutToReuse id=${this.newsId} type=${this.type}`)
  }

  build() {
    Column() {
      if (this.type === 'image') {
/Text information structure
        Image($r('app.media.startIcon')).width('100%').height(120).objectFit(ImageFit.Cover)
        Text(this.title).fontSize(14).padding(8)
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 8, bottom: 8 })
      } else if (this.type === 'video') {
/ Video news structure
        Stack() {
          Image($r('app.media.startIcon')).width('100%').height(120).objectFit(ImageFit.Cover)
          Text('▶').fontSize(32).fontColor('#FFFFFF')
        }
        Text(this.title).fontSize(14).padding(8)
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 8, bottom: 8 })
      } else {
/ Pure text information structure
        Text(this.title).fontSize(16).fontWeight(FontWeight.Bold).padding(12)
        Divider().color('#EEEEEE')
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 12, bottom: 12 })
      }
    }
    .width('100%').backgroundColor('#FFFFFF').borderRadius(8)
  }
}

/ / Use use Id to distinguish the entry of three structures
@Component
struct MultiTypeNewsListPage {
  private multiTypeData: NewsDataSource = new NewsDataSource([
/... Multitype news data entry
  ])

  build() {
    List({ space: 8 }) {
      LazyForEach(this.multiTypeData, (item: NewsItem) => {
        ListItem() {
          MultiTypeNewsCardV1({ item: item })
// Use different use Id structures by type of news
            .reuseId(item.type)
        }
      }, (item: NewsItem) => item.id.toString())
    }
    .width('100%').height(300)
  }
}
```
---

## part reuse V2

**@ReuseableV2 Limit**

- For `@ComponentV2` only, custom components may not be used in combination with `@Component` or `@Builder`.
- The component structure should remain unchanged before and after the re-use of the component, and the structural differences should be distinguished by `.reuse({ reuseId: () => 'id' })`.
- `ComponentContent` not supported for `@ReusableV2` component.
- `aboutToReuse` without reference, status variables are automatically reset and no manual grant is required.
- Do not recommend embedding `@ReusableV2`, which increases memory and reduces reuse efficiency.
- V2 reused components cannot be used directly in `Repeat`, but can be used to customise V2 components in template.
- It is not recommended to change the state variable in `aboutToRecycle` (the change will not take effect due to the freezing mechanism).
- The writing of constant objects (undecorated) containing `@Trace` properties may, in a reuse scenario, lead to an anomaly that the `before` value of `@Monitor` has not been replaced.

**Scene ID:** STATE RELATIVE 10

** Scene description:** Simulator ' s Commodity Browser Page, containing a list of trade falls (Repeat lazy). Override @ReusableV2 Basic Usage (no reference about ToReuse), Repaat Lazy Loading/ Non-Lamp Loading Reave, if condition switchover.

** Solution:** Use **`@ReusableV2` Decoration `@ComponentV2` Custom Component** ** **`Repeat` instead of LazyForEach**

```
Electrician Commodity Browser page (@Entry@ComponentV2)
@RepectCardV2 (@ReuseableV2)
│ - Scrollback about ToRecile
│ - Scrollback about ToReuse
  │
└ - if condition switch → Conditions render trigger recovery/reuse
```

#####1.@ReuseableV2 Basic - Auto-recycling and reuse of commodity cards (no reference to ToReuse)

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'

/ Commodity data model
@ObservedV2
class ProductData {
  @Trace price: number = 0
  constructor(price: number) { this.price = price }
}

/ V2 Commodity Card: @ReusableV2 + @CommonentV2
@ReusableV2
@ComponentV2
struct ProductCardV2 {
  @Require @Param productId: number = 0
  @Param productName: string = ''
  @Param productPrice: number = 0

/ / Trigger when components are recovered (automatic freeze, @Monitor does not trigger)
  aboutToRecycle(): void {
    hilog.info(0x0001, 'ProductCardV2', `aboutToRecycle productId=${this.productId}`)
  }

/ / Component triggers when reuse is removed from the reuse pool (no reference, status variable automatically reset)
  aboutToReuse(): void {
    hilog.info(0x0001, 'ProductCardV2', `aboutToReuse productId=${this.productId} name=${this.productName}`)
  }

  build() {
    Column() {
      Text(this.productName)
      Text(`¥${this.productPrice}`)
Text
    }
/ /... style omitted
  }
}

/ V2 portal page: Repeat + @ReusableV2
@Entry
@ComponentV2
struct ProductListPageV2 {
  @Local products: Array<{ id: number, name: string, price: number }> = [
{id: 1, name: 'A smart phone', price: 299},
/... remaining commodity data omitted
  ]

  build() {
    Column() {
Text('V2 List')
      List({ space: 8 }) {
        Repeat(this.products)
          .each((ri: RepeatItem<typeof this.products[0]>) => {
            ListItem() {
              ProductCardV2({
                productId: ri.item.id,
                productName: ri.item.name,
                productPrice: ri.item.price
              })
            }
          })
          .key((item: typeof this.products[0]) => item.id.toString())
      }
/ /... style omitted
    }
  }
}
```
---

###2Repeat Lazy Load + @ReusableV2 - Long List Rolling Back

```typescript
/ Repeat voluntaryScroll lazy-loading scene: trigger recovery/reuse while rolling
@Entry
@ComponentV2
struct LazyProductListV2 {
  @Local products: number[] = Array.from({ length: 100 }, (_, i) => i + 1)

  build() {
    Column() {
Text (`Lackload List (100 articles)')
      List() {
        Repeat(this.products)
          .virtualScroll({
            getTotalCount: () => this.products.length,
            onItemIndexer: (item: number, index: number) => item === this.products[index]
          })
          .each((ri: RepeatItem<number>) => {
            ListItem() {
              ProductCardV2({
                productId: ri.item,
Product Name: `Commodity${ri.item}'
                productPrice: ri.item * 10
              })
            }
          })
          .key((item: number) => item.toString())
      }
      .cachedCount(3)
/ /... style omitted
    }
  }
}
```
---

###3.if condition switch + @ReuseableV2 — condition rendering triggers reuse

```typescript
/ / if condition transition: control component recovery/reuse by changing condition
@Entry
@ComponentV2
struct ConditionalReusePageV2 {
  @Local showDetail: boolean = false
  @Local currentProductId: number = 42

  build() {
    Column() {
Button.
        .onClick(() => { this.showDetail = !this.showDetail })

      if (this.showDetail) {
Create component when condition is true
        ProductCardV2({
          productId: this.currentProductId,
Product Name: `Commodity${this.currentProducID}'
          productPrice: this.currentProductId * 10
        })
      } else {
/ / / condition to false the upper component is recycled (aboutToRecycle)
/ / When switching again to True, remove reuse (aboutToReuse) from the reuse pool instead of recreate aboutToAppear
Text (`Parts recovered, click on button to re-show')
      }
/ /... style omitted
    }
  }
}
```

---

# Custom component freeze function

The V1 and V2 freezes the custom component through `freezeWhenInactive: true`.

**V1 versus V2 component freeze**

@ComponentV2 @ComponentV2
|------|---------------|-----------------|
Frozen Configuration {freezeWhenInactive: true}
@ Change listening  @ Watch  @ Monitor  @
| Support scene | Page route, TabContent, LazyForEach, Navigation, Component Reuse | Page route, TabContent, Navigation, Replenishment
| LazyForEach supports
|Repeat support | does not support |API 18+|
@ Reuse component freeze | need to manually configure freezeWhenInactive| @ReusableV2 Autofreeze |
| Unfrozen new range | API 17 et seq. unfrozen all subnodes | API 18+ unfreeze only nodes on screen |
|BuilderNode freeze |API 20+ support inheritFreezeOptions |API 22+ support inheritFreezeOptions

**Content freeze restriction**

- FreezeWhenInactive is only effective for custom components and non-defined components are not affected.
- Component active/inactive is not the same as the visibility of the component, and only takes effect under a specific scene (page route, TabContent, LazyForEach/Repeat, Navigation, reuse of components).
- When the V1 component is frozen + the component is re-mixed, unfrozen does not trigger @Watch echo (because the re-use emptys the list of dirty nodes).
-V2@ReusableV2 automatically freezes, but changes in about ToRecycle will not be refreshed to UI.
- Builder Node cannot inherit the parent component freeze (before API 20/22) and needs to configure inheritfreezeOptions as true.

---

## # # V1 status variable achieves a custom component freeze

**Scene ID:** STATE RELATIVE 11

** scene description:** imitation social application first page with three tabs of "message" "dynamic" "my" , and within the message tab, Navigation can jump to chat subpages, chat lists are rendered in LazyForEach and reused with @Reuseable. When you switch tabs, jump pages, scroll lists, reuse components, changes in the status variables of inactive components should not trigger invalid refreshing.

** Solution: ** V1 Use `@Component({ freezeWhenInactive: true })` to decorate the custom component + `@Watch` for listening status changes; inactive tab page, non-stamp NavDestification, Cache List item, ZXXKEEP2ZX for reused component does not trigger, unfrozen triggers.

```
SocialHomePageV1 (@Entry@componentfreezeWhenInactive:true) < - The entrance remains active and @Watch touched immediately Fire!
  ├─ Tabs
@TabContent: MessageTabV1
  │   │     └─ Navigation → ChatDetailV1 → FreezeNavContentV1 (freezeWhenInactive:true)
@ └ - Push into SettingsPage → Non-stamp freeze, @watch does not trigger; eject unfrozen trigger
  │   │     └─ List + LazyForEach + cachedCount(3) → ReusableChatItemV1 (@Reusable + freezeWhenInactive)
│ └ Cache item freeze, @watch only visible trigger; reuse unfrozen @watch does not trigger
< - Toggle freeze <
< - TabContent my ProfileTabV1 < - Toggle freeze
@ - Cut back the tab → Unfreeze batch triggers the backlog
```

####1. Custom Component Structure V1 — @Component + freezeWhenInactive Basic Configuration

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'
const DOMAIN = 0xFF00
const TAG = 'FreezeV1'

/ / Entry component: @Component + freezeWhenInactive, the entrance remains active, @Watch immediately touches Fire!
@Entry
@Component({ freezeWhenInactive: true })
struct SocialHomePageV1 {
  @State currentTab: number = 0
  @Provide('unreadCount') @Watch('onUnreadChange') unreadCount: number = 5
@Provide('sharedMsg') shareMsg: string = 'Share Initial Message'

OnUnreadChange() {/ / /Enterprise is active, @Watch touched immediately Fire!
    hilog.info(DOMAIN, TAG, `unreadCount → ${this.unreadCount}`)
  }

  build() {
    Column() {
Text (`Unread: {this.unreadCount}').fontSize(20)
Button (`Simulation +1'). onClick() = > This.unreadCount+})
    }
  }
}
```

###2TabContent tab frozen

```typescript
/ / / All three tab subcomponents are configured freezeWhenInactive:true, switch or freeze, @watch does not trigger
@Component({ freezeWhenInactive: true })
struct MessageTabV1 {
  @Prop currentTab: number = 0
  @Consume('unreadCount') @Watch('onUnreadInMessage') unreadCount: number
  @Consume('sharedMsg') @Watch('onSharedMsgInMessage') sharedMsg: string

OnUnreadInmessage(){/ * Triggers only when active; cut-off frozen does not trigger*/ }
{/* Idem*

bueld(){Text('message list')...*/}
}

/ FeedTabV1, ProfileTabV1 Structures Same as MessageTabV1: @Consume('unreadCount')+watch + freezeWhenInactive: true
// ...
```

## # 3.NAvigation page route blocked

```typescript
/ / Freezing sub-component in NavDestination, @watch does not trigger; eject and defrozen Fire!
@Component({ freezeWhenInactive: true })
struct FreezeNavContentV1 {
  @Consume('navStack') navStack: NavPathStack
  @Consume('sharedMsg') @Watch('onSharedMsgInNav') sharedMsg: string
@Sate@watch('onMessageTextChange') messageText: string = 'Welcome to chat details'

OnSharedMsgInNav(){/* non-stamp frozen without trigger; normal trigger */ } on top
  onMessageTextChange() { /* ... */ }

  build() {
    Column({ space: 10 }) {
      // ...
/ / Pushing into settings page, Ben NavDestination becomes non-stamp, FreezeNavContentV1 frozen
Button
        .onClick(() => { this.navStack.pushPathByName('SettingsPage', null) })
    }.padding(20)
  }
}

@Component
struct ChatDetailV1 {
bueld() {NavDestination()}FreezeNavContantV1()}.title(' chat details')}
}
```

## 4. LazyForEach Cache Node Freeze

```typescript
class ChatItemModel {
  id: number = 0
  name: string = ''
  lastMessage: string = ''
  unread: number = 0
  // constructor ...
}

/ IDatasource Fulfilled: totalCount / getData / addDataLister /removeDataChangerLister /notifyDataReload...
class ChatDataSource implements IDataSource { /* ... */ }

/ LazyForEach + CacheedCount (3): Cache item frozen, @watch triggered only visible items
@Component({ freezeWhenInactive: true })
struct MessageListTabV1 {
  @State chatDataSource: ChatDataSource = new ChatDataSource([])

  build() {
    List({ space: 10 }) {
      LazyForEach(this.chatDataSource, (item: ChatItemModel) => {
        ListItem() { ReusableChatItemV1({ chatItem: item }) }
      }, (item: ChatItemModel) => `${item.id}`)
    }
...cachedCount(3) / / Cache 3 nodes, @watch does not trigger when the cache item is frozen
    .width('100%').layoutWeight(1)
  }
}
```

###5 @Reusable + freezeWhenInactive

```typescript
// @Reusable +freezeWhenInactive mix: Re-use unfrozen
@Reusable
@Component({ freezeWhenInactive: true })
struct ReusableChatItemV1 {
  @Prop chatItem: ChatItemModel = new ChatItemModel(0, '', '', 0)
  @Consume('navStack') navStack: NavPathStack
@Slate@watch('onItemStatusChange')

OnTheItemStatusChange(){/* Visible Item Triggered without Cache Item Triggered; or on re-frozen */}
about ToRecile(){/ * Recycled**/}

/ V1 Key feature: aboutToReuse accepts params, but changes the state when unfrozen again, @watch does not trigger
/ Reason: Re-use process emptys the list of dirty nodes before unfrozen components, resulting in @Watch's loss trigger condition
  aboutToReuse(params: Record<string, Object>) {
This.itemstatus = 'Renewal Update'//modifyitemstatus but @watch does not trigger
  }

  build() { /* ... */ }
}
```

---

## # # V1 status variable achieves a custom component freeze

**Scene ID:** STATE RELATIVE 12

** scene description:** Same social application first page scene, V2 with @componentV2 + @Monitor instead of V1 @Component+ @watch, chat list with RecapableV2 Focus on @Monitor getting pre- and post-change values, Repeat cache freeze, @ReusableV2 auto-freeze and reuse unfrozen @Monitor trigger, API 18+ unfreeze cleanup.

** Solution: ** V2 uses `@ComponentV2({ freezeWhenInactive: true })` + `@Monitor` to listen to changes; `@Monitor` to obtain pre- and post-change values; `Repeat` + `virtualScroll` + `cachedCount` to match API 18+ Cache node freeze; ZXXKEEP6ZX to automatically freeze and reuse `@Monitor` when unfrozen; API 18+ to unfreeze only new visible nodes on the screen.

```
SocialHomePageV2 (@Entry@componentV2freezeWhenInactive:true) < - Entry remains active, @Monitor immediately touches Fire!
  ├─ Tabs
TabContent Message
  │   │     └─ Navigation → ChatDetailV2 → FreezeNavContentV2 (freezeWhenInactive:true)
│ └ - Non-stamp freeze, @Monitor does not trigger; unfreeze triggers and display before→now
  │   │     └─ List + Repeat.virtualScroll + cachedCount(3) → ReusableChatItemV2 (@ReusableV2 + freezeWhenInactive)
│ - API 18+ Cache Node Freeze, @Monitor Only Visible Trigger; Re-use unfrozen@Monitor Trigger
Ideas - TabContent Dynamic → FeedTabV2
│-TabContent my ProfileTabV2
└ - API 18+ unfrozen only visible nodes on new screen (V1 unfrozen all subnodes)
```

####1. Custom Component Structure V2 #

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'
const DOMAIN = 0xFF00
const TAG = 'FreezeV2'

/ Entry component: @ComponentV2 + freezeWhenInactive, entrance remains active, @Monitor immediately touches Fire!
@Entry
@ComponentV2({ freezeWhenInactive: true })
struct SocialHomePageV2 {
  @Local currentTab: number = 0
  @Local unreadCount: number = 5
@Provider('sharedMsg') shareMsg: string = 'Share Initial Message'

  @Monitor('unreadCount')
  onUnreadChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
Hilog.info (DOMAIN, TAG, `${path} from ${monitor.value} to ${monitor.value}?now}
    })
  }

  build() {
    Column() {
Text (`Unread: {this.unreadCount}').fontSize(20)
Button (`Simulation +1'). onClick() = > This.unreadCount+})
    }
  }
}
```

###2 @Monitor Replace @watch — Get change back and forth

```typescript
@ComponentV2({ freezeWhenInactive: true })
struct FeedTabV2 {
  @Param unreadCount: number = 0
  @Consumer('sharedMsg') sharedMsg: string
  @Local feedUpdateCount: number = 0

/ @Monitor can access values before and after changes compared to V1@watch only current values
  @Monitor('unreadCount', 'feedUpdateCount')
  onStateChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      // monitor.value(path)?.before / ?.now
    })
  }

  build() {
    Column() {
Text(' Dynamic Page'). FontSize(20)
Button ('updated dynamic count').onClick(()=> {This.fedUpdateCount+})
    }
  }
}
```

##3TabContant + Navigation Freeze

```typescript
@ComponentV2({ freezeWhenInactive: true })
struct MessageTabV2 {
  @Param currentTab: number = 0
  @Param unreadCount: number = 0
  @Consumer('sharedMsg') sharedMsg: string

@Monitor('unreadCount') // Inactive tabs do not trigger; unfreeze triggers and display before→now
  onUnreadInMessage(monitor: IMonitor) { /* monitor.dirty.forEach ... */ }

bueld(){Text('message list')...*/}
}

/ / Freezing sub-component in NavDestination, @Monitor does not trigger; unfrozen triggers and display before→now
@ComponentV2({ freezeWhenInactive: true })
struct FreezeNavContentV2 {
  @Consumer('navStack') navStack: NavPathStack
  @Consumer('sharedMsg') sharedMsg: string
@Local messagetext: string = 'Welcome to chat details'

  @Monitor('sharedMsg')
{/ * Trigger on sharedMsgInNav

  build() {
    Column({ space: 10 }) {
      // ...
Button
        .onClick(() => { this.navStack.pushPathByName('SettingsPage', null) })
    }.padding(20)
  }
}
```

4. Repeat instead of LazyForEach - Cache Node Freeze

```typescript
@ObservedV2
class ChatItemModelV2 {
  id: number = 0
  @Trace name: string = ''
  @Trace lastMessage: string = ''
  @Trace unread: number = 0
  // constructor ...
}

@ComponentV2({ freezeWhenInactive: true })
struct MessageListTabV2 {
  @Local chatList: ChatItemModelV2[] = []

  build() {
    List({ space: 10 }) {
      Repeat<ChatItemModelV2>(this.chatList)
        .each((ri: RepeatItem<ChatItemModelV2>) => {
          ListItem() { ReusableChatItemV2({ chatItem: ri.item }) }
        })
        .virtualScroll({ totalCount: this.chatList.length })
...cachedCount(3) / / API 18+ Cache Node Freeze, @Monitor only triggers
        .key((item: ChatItemModelV2) => `${item.id}`)
    }
    .width('100%').layoutWeight(1)
  }
}
```

### 5.@ReuseableV2 AutoFreeze - Reuse unfreeze @Monitor trigger

```typescript
/ @ReuseableV2 Auto-freeze recovery components; @Monitor triggers (as opposed to V1@watch)
@ReusableV2
@ComponentV2({ freezeWhenInactive: true })
struct ReusableChatItemV2 {
  @Param chatItem: ChatItemModelV2 = new ChatItemModelV2(0, '', '', 0)
  @Consumer('navStack') navStack: NavPathStack
@Localitemstatus: string = 'normal'

@Monitor('itemstatus') / Visible item triggers, Cache item does not trigger; re-use unfrozen triggers
  onItemStatusChange(monitor: IMonitor) { /* monitor.dirty.forEach ... */ }
About ToRecycle(){/ *@ReusableV2 Autofreeze*/}

/ V2 Key feature: aboutToReuse without parameters (V1 has params); re-use unfrozen to change state Fire!
  aboutToReuse() {
This.itemstatus = 'Reuse Update' / @Monitor will trigger
  }

  build() { /* ... */ }
}
```

### # 6.API 18+ unfrozen

```typescript
/ / API 18+: V2 Only new visible nodes on screen when unfrozen, more efficient and accurate than all subnodes of V1 unfrozen
@ComponentV2({ freezeWhenInactive: true })
struct FreezeNavContentV2 {
  @Consumer('sharedMsg') sharedMsg: string
@Local messagetext: string = 'Welcome to chat details'

  @Monitor('sharedMsg', 'messageText')
  onThawRefresh(monitor: IMonitor) {
/ / When unfrozen, only visible nodes on screen trigger this echo; no non-screen nodes are refreshed (API 18+)
    monitor.dirty.forEach((path: string) => { /* before → now */ })
  }

  build() {
    Column({ space: 10 }) {
      // ...
Button ('update').onClick() = {This.messageText = `New news {Date.now(}`)
    }.padding(20)
  }
}
```
---

# @Builder Support Status Variable Refresh

Starting with API version 20, the developer can achieve a state variable in the @Builder function by using `UIUtils.makeBinding()`, `Binding` and `MutableBinding`.

By default, @Builder's state variable changes will not trigger @Builder's UI in value transfer parameters; using `makeBinding` packaging status variables, you can support @Builder's UI components to be refreshed, and by writing back, @Builder's synchronised callback components.

** Binding versus Mutable Binding**

`Binding<T>` `MutableBinding<T>`
|------|-------------|---------------------|
Z Read (`.value`)
| Writing (`.value` grant) | Unsupported (run-time error) | Supported |
@Builder
@Builder Modify Synchronization to Parent Component
`makeBinding` Parameter | Only read back
| Initial version of API 20 | API 20 |

** Containment**

- `UIUtils.makeBinding()` is supported from the API version 20, only for components that are decorated in `@ComponentV2`.
- `Binding<T>` does not support the `.value` grant and returns the error code 140109 (API 23+) when triggered.
- `MutableBinding<T>` must enter a writeback, otherwise a `.value` grant within @Builder will cause a running error.
- When `MutableBinding` is used in the @Builder function to modify the object properties (e. g. `data.value.distance += 100`), it is necessary to ensure that the properties are marked by `@Trace` decorations in order to trigger UI refreshing; the properties that are not modified by `@Trace` decorations do not trigger UI refreshing.
- When `makeBinding` is used, it is not possible to transfer the font amount of the object.

---

# # Achieved @Builder Parameter Transfer and UI Refresh

**Scene ID:** STATE RELATIVE 13

** Scene description: ** Simulates the motion health monitoring application and displays motion data such as heart rate, steps, etc. on the page. Multiple data cards in the page are re-enacted using the @Builder function and need to be realized: the heart rate data is shown only (father change@Builder refreshed), step data can be modified by clicking on a button in @Builder and synchronized back to the parent component, and motion data objects (@ObservedV2+@Trace) are modified and synchronized in @Builder.

** Solution:** Read-only refreshing with **`UIUtils.makeBinding()`** Packaging Status Variable into @Builder Function + **`Binding<T>`**

```
Sports Health Monitor Page
@LocalheartRate - Make Binding -  @ Binding <nomber> - @Builder Heartcard
@ Father modified heart rate → Binding.value read  @ UI refreshed in @Builder
@Builder Unchangeable
  │
@Local stepCount - make Binding - Mutable Binding <nomber> - @Builder Step Card
→Mutable Binding.value Read  @UI refreshed in @Builder
@Builder click +1 → MutableBinding.value grant → Write back → Father Component StepCount Update
  │
@Local workoutData (@ObservedV2) - MakeBinding (Read + Writeback) - MutableBinding <WorkutData> - - @Builder Campaign Data Card
@ Music Binding.value
@Builder change disistance → Mutable Binding.value grant → write back → father component workoutData update
```

###1. Use Binding to refresh read-only variables (heartrate presentation)

`UIUtils.makeBinding()` returns the `Binding<T>` type only on readback, supports @Builder UI component refreshing, but does not support changing parameter values in @Builder.

```typescript
import { Binding, UIUtils } from '@kit.ArkUI'

@Builder
function HeartRateCard(heartRate: Binding<number>) {
Text (`heart rate: ${heartrate.value}bpm')
/ ... style configuration omitted
}

@Entry
@ComponentV2
struct HealthMonitorPage {
  @Local heartRate: number = 72

  build() {
    Column() {
/ makeBinding Only Readback → Return Binding Type, Support @Builder UI Refresh
      HeartRateCard(UIUtils.makeBinding<number>(() => this.heartRate))

Button. onClick(() = {
        this.heartRate = 60 + Math.floor(Math.random() * 80)
      })
    }
    // ...
  }
}
```

###2 Use Mutable Binding to achieve a readable, writeable two-way sync (step counter)

`UIUtils.makeBinding()` also returns the `MutableBinding<T>` type when read and write back, supporting both @Builder UI re-up, and @Builder to modify parameter values and synchronize to parent components.

```typescript
import { MutableBinding, UIUtils } from '@kit.ArkUI'

@Builder
function StepCountCard(stepCount: MutableBinding<number>) {
  Column() {
Text (`StepCount.value}')
Button (`steps + 100')
      .onClick(() => {
/ / @Builder Changes MutableBinding.value # Writeback # # Sync to Father Component
        stepCount.value += 100
      })
  }
/ ... style configuration omitted
}

@Entry
@ComponentV2
struct StepMonitorPage {
  @Local stepCount: number = 0

  build() {
    Column() {
Text

/ makeBinding Readback + Writeback Return returns MutableBinding type
      StepCountCard(UIUtils.makeBinding<number>(
        () => this.stepCount,
        (val: number) => { this.stepCount = val }
      ))

Button ('Father Component Reset Step'). onClick(()=> {this.stepCount=0})
    }
    // ...
  }
}
```

Use Mutable Binding to pass @ObservedV2 objects (motion data cards)

`MutableBinding` also supports the transfer of `@ObservedV2` + `@Trace` decorations to modify object properties in @Builder and synchronize with parent components.

```typescript
import { MutableBinding, UIUtils } from '@kit.ArkUI'

@ObservedV2
class WorkoutData {
  @Trace public distance: number = 0
  @Trace public duration: number = 0
  @Trace public calories: number = 0
/ / /...the construction function omitted
}

@Builder
function WorkoutDataCard(data: MutableBinding<WorkoutData>) {
  Column() {
Text (`m')
Text
Text

Button (`range +100m'). onClick() = {
/ / @Builder Changes @Trace Properties → Syncback parent component + Trigger UI Refresh
      data.value.distance += 100
    })
  }
/ ... style configuration omitted
}

@Entry
@ComponentV2
struct WorkoutMonitorPage {
  @Local workoutData: WorkoutData = new WorkoutData(1000, 1800, 200)

  build() {
    Column() {
Text (`Paternal Component Data - Distance: ${this.workoutData.distance}m ')

/ makeBinding pass@observedV2 objects
      WorkoutDataCard(UIUtils.makeBinding<WorkoutData>(
        () => this.workoutData,
        (val: WorkoutData) => { this.workoutData = val }
      ))

Button (`Pather Component Reset Data'). Onclick() = >
        this.workoutData = new WorkoutData(0, 0, 0)
      })
    }
    // ...
  }
}
```
---

# Loop Render

ArkUI provides for ForEach and LazyForEach recirculating components (V1) and Repaat components (V2).

**V1 v. V2**

V1 (ForEach / LazyForEach)
| --- | --- | --- |
|ForEach Full Render / LazyForEach Lazy Load (Render + Cache Area) |Repeat Virtual Rolling (Rendering) |
Data source |Array array / IDataSource interface achieves |Array or Iterable|
|ForEach Key Compare Incremental Update / LazyForEach NotifyData* Method Notification |Repeat Key Compare Incremental Update
| Multi Template | Not supported, manual if/else judgement type in itemGenerator | Support `.template()` declaration multiple templates
Z Node reuse | does not support | Support `reusable` + `template`
Zipat `.lazyCachedCount()`
Z  Z  Z  Z  Z  Z |
Z  Z XKEEP0ZX | `@ComponentV2` |
|API-supported version |10+1212+|

---

# V1 version of the loop rendering

**Scene ID:** STATE RELATIVE 14

** scene description:** Simulation of music player song sheet management page with two parts: (1) "I like" songlists - short list (<100) with ForEach full rendering to support the addition/delegate/receiving/ drag sorting; (2) "local music" library - long list (500+ head) with LazyForEach lazy rendering to support the search/addition/removal/reload/ drag sorting. Both lists use `@Observed` + `@ObjectLink` to achieve deep observations of song sub-relations (isFavorite, playCount).

** Solution:** Short list uses **`ForEach`** Full Render + **ZXKEEP1Z** Cluster Management + **`@Observed` + ZXKEEP3Z** Sub-Input Observation + List ** XKEEP4Z** Drag Sorting; Long list uses **ZXKEEP5Z** Lazy Load ** ** ZXKEEP6Z** Realization + 5 ** ZXKEEP7Z** Method Notification Updates **`@Observed` + ZXKEEP9Z** Deep Layer Properties Observation

```
Music Player List Management Page
I miss-- "I like" songlists (short list < 100)-- ForEach full rendering.
│   ├── @State songs: Song[] ──ForEach(arr, itemGenerator, keyGenerator)──→ SongCard(@ObjectLink)
@Push/splice Trigger Addition Update
│ - List .onMove (froom, to) - Exchange Numerical Elements - ForEach Key Comparison → Incremental Update Order
{\cHFFFFFF}{\cH00FFFF} LazyForEach lazyly loaded
    ├── SongDataSource(IDataSource) ──LazyForEach(ds, itemGenerator, keyGenerator)──→ SongCard(@ObjectLink)
TotalCount/getData/register/unregister CatchedCount(5) Cache
│ notifyDataAdd/Delete/Change/Move/Reload
List .onMove (froom, to) -swapData internal exchange - notify DataMove
```

###1.ForEach Basic Rendering and Key Generation Rules - "like" playlist presentation

```typescript
// Song Data Model, using @Observed Decoration to support observation of sub-relations
@Observed
class Song {
  id: number = 0
  title: string = ''
  // ...
}

// Singcard sub-component, @ObjectLink Receive @ObservedSong Example, can observe sub-alignment changes
@Component
struct SongCard {
  @ObjectLink song: Song

  build() {
    Row({ space: 12 }) {
      // ...
/ Collection button: @ObjectLink observation isFavorite changes, icon automatic switch
      Button() {
        SymbolGlyph(this.song.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
      }.onClick(() => { this.song.isFavorite = !this.song.isFavorite })
    }
/ /... style omitted
  }
}

@Entry
@Component
struct FavoritesPlaylistPage {
/ / @state Decorated song arrays, array changes trigger ForEach repainting
  @State songs: Song[] = [
New Song (1, 'A', 'A', 269),
New Song (2, 'B', 'B', 223),
New Song
  ]

  build() {
    Column({ space: 10 }) {
Text.

/ ForEach Three Parameters: Numericals, Subsection Generation Functions, Key Generation Functions
/keyGenerator must return the only and stable string, using item.id as a key value
      ForEach(this.songs, (item: Song) => {
        SongCard({ song: item })
      }, (item: Song): string => item.id.toString())
    }
/ /... style omitted
  }
}
```

###2.ForEach data add/ delete and @Observed+@ObjectLink sub attributes observation - add/ delete/revenue songs

```typescript
/ / Page Structure Same Step 1, Add Data Operation buttons below ForEach
// @statesongs / nextId defines step 1, nextId as 4
/ / SongCard Collection Button: @Observed is Favorite Changes  @

Row({ space: 10 }) {
Button. onClick()=>
/ push new song, @state detects array changes, ForEach key compares the incremental rendering of new entries
This.songs.push.
  })
Button ('Delete the last'). onClick(()=> if (this.songs. Length > 0) this.songs.splice (this.songs. Length - 1, 1)}
Button ('Delete the first').onClick(()=> {if (this.songs. Length > 0) This.songs.Shift()})
}
```

##3ForEach Drag Sort (onMove) - Scroll Sort

```typescript
/ Page Structure Same Step 1, Place ForEach in List and add.onMove to drag and drag to sort back
List({ space: 8 }) {
  ForEach(this.songs, (item: Song) => {
    ListItem() { SongCard({ song: item }) }
  }, (item: Song): string => item.id.toString())
}
.onMove((from: number, to: number) => {
/ onMove
/ / Exchange array elements: First removed from position from position, then inserted to position
  const moved = this.songs.splice(from, 1)[0]
  this.songs.splice(to, 0, moved)
/ / State detects array changes, ForEach key comparison incremental order
})
```

# # 4. LazyForEach IDatasource achieves laziness replicating - list of "local music" treasurers

```typescript
/ / SongDataSource
class SongDataSource implements IDataSource {
  private songs: Song[] = []
  private listeners: DataChangeListener[] = []

= 4 methods to be achieved
  totalCount(): number { return this.songs.length }
  getData(index: number): Song { return this.songs[index] }
//Registration/Cancellation of data change listening devices (Auto-Advocated Call within LazyForEach)
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) === -1) { this.listeners.push(listener) }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) { this.listeners.splice(pos, 1) }
  }

/ = = 5 notification methods, notification of LazyForEach Update UI = = = =
  notifyDataReload(): void { this.listeners.forEach((l: DataChangeListener) => l.onDataReloaded()) }
  notifyDataAdd(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataAdd(index)) }
  notifyDataDelete(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataDelete(index)) }
  notifyDataChange(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataChange(index)) }
  notifyDataMove(from: number, to: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataMove(from, to)) }

  setSongs(songs: Song[]): void { this.songs = songs }
}

@Entry
@Component
struct LocalMusicLibraryPage {
  private dataSource: SongDataSource = new SongDataSource()

  aboutToAppear() {
// Generate 500+ song simulation of local music Library
    const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
New Song (i + 1, 'song 'i +', 'song' (i + 1) %2 ', 180 + (i + 1) %120))
    this.dataSource.setSongs(songs)
  }

  build() {
    Column({ space: 10 }) {
Text

/ LazyForEach Lazy Render, CachedCount (5) Cache, visible + Cache area only
      List({ space: 8 }) {
        LazyForEach(this.dataSource, (item: Song) => {
          ListItem() { SongCard({ song: item }) }
        }, (item: Song): string => item.id.toString())
      }
      .cachedCount(5)
    }
/ /... style omitted
  }
}
```

5. LazyForEach Data Adding, Deleting, Reloading - Searching/Addending/Deleting/Moving

```typescript
// Expand the following data operations in the SongDataSource of Step 4
/ / Every method to modify an internal array must call the corresponding notify UI update
class SongDataSource implements IDataSource {
  private songs: Song[] = []
  private listeners: DataChangeListener[] = []

= IDatasource interface achieved (see step 4) = =
  // ... totalCount / getData / register / unregister / notifyData* / setSongs

/ = = data operating method: modify internal data + call notify UI = = = =
  addSong(song: Song): void {
    this.songs.push(song)
    this.notifyDataAdd(this.songs.length - 1)
  }
  deleteSong(index: number): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs.splice(index, 1); this.notifyDataDelete(index)
    }
  }
  changeSong(index: number, song: Song): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs[index] = song; this.notifyDataChange(index)
    }
  }
  moveSong(from: number, to: number): void {
    if (from < 0 || from >= this.songs.length || to < 0 || to >= this.songs.length) return
    const moved = this.songs.splice(from, 1)[0]
    this.songs.splice(to, 0, moved)
    this.notifyDataMove(from, to)
  }
  reloadSongs(songs: Song[]): void { this.songs = songs; this.notifyDataReload() }
  swapData(from: number, to: number): void { this.moveSong(from, to) }
/ / Search filter: returns songs that match keywords
  searchSongs(keyword: string): Song[] {
    return this.songs.filter((s: Song) =>
      s.title.includes(keyword) || s.artist.includes(keyword))
  }
}

@Entry
@Component
struct LocalMusicLibraryPage {
  private dataSource: SongDataSource = new SongDataSource()
  @State searchKeyword: string = ''
  private nextId: number = 501

  aboutToAppear() {
    const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
New Song (i + 1, 'song 'i +', 'song' (i + 1) %2 ', 180 + (i + 1) %120))
    this.dataSource.setSongs(songs)
  }

  build() {
    Column({ space: 10 }) {
Text

/ / Search box: click on search after key words are entered, reloadSongs reload filtered data
TextInput({placeholder: 'search song or singer', text: this.searchKeyword})
        .onChange((value: string) => { this.searchKeyword = value })
Button. onClick() = {
/ / Search and reload filtered data, notifyDataReload to destroy and rebuild all items
        this.dataSource.reloadSongs(this.dataSource.searchSongs(this.searchKeyword))
      })

      List({ space: 8 }) {
        LazyForEach(this.dataSource, (item: Song) => {
          ListItem() { SongCard({ song: item }) }
        }, (item: Song): string => item.id.toString())
      }
      .cachedCount(5)

/ / Data Operation Button: Presentation of 5 NoteData* Methods
      Row({ space: 8 }) {
Button('Add'). onClick() = >
This.datasource.addSong
        })
Button ('Delete first').onClick(()=>{this.datasource.deleteSong(0)})
Button. Oncick()=>
/ / Change only @Observed sub- attribute does not require notifyDataChange, @ObjectLink
/ NoteDataChange scene to replace the entire data entry
This.datasource.changeSong
        })
Button (`Moving').onClick()=> {this.datasource.moveSong(0,2)})
Button. Oncick()=>
          const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
New Song (i + 1, `reload song $i{, `singer (i + 1) %2 ', 180 + (i + 1) %120)
          this.dataSource.reloadSongs(songs)
        })
      }
    }
/ /... style omitted
  }
}
```

6. LazyForEach Drag Sorting and @Observed+@ObjectLink Deep Properties Observation

```typescript
/ / Page Structure Same Step 4, add .onMove to list drag-and-drop sorting on List
List({ space: 8 }) {
  LazyForEach(this.dataSource, (item: Song) => {
    ListItem() {
/ / SongCard uses @ObjectLink to observe isFavorite/playCount changes
/ Change @Observed sub- attribute →ObjectLink Auto refresh, notifyDataChange
      SongCard({ song: item })
    }
  }, (item: Song): string => item.id.toString())
}
.cachedCount(5)
.onMove((from: number, to: number) => {
/ onMove Call back: call swapData for IDatasource internal data
/ / swapData Internal Call notify UI to update entry
  this.dataSource.swapData(from, to)
})
```
---

# V1 version of the loop rendering

**Scene ID:** STATE RELATIVE 15

** scene description:** emulation of music player song sheet management page showing different types of music items (songs, albums, ads) in the list, supporting lazy loads, nodal reuses, unlimited scrolling, drag-sorting and precise attribute observations. Multiple types of template rendering, as required, load-and-deep property change observations are required through the V2 Repeat chain API, covering ...each() basic rendering, .key() key generation, .template()/.templateId() multiple templates, .virtualScroll() lazy load + @ReusableV2 node reuse, .onLazyLoadding() fine lazy load, .onMove() drag sorting +@ObservedV2@Trace+@Param deep attribute observation.

** Solution:** Use **`Repeat`** Chain API to render the cycle + **`@ObservedV2` + `@Trace` + `@Param`** to make an accurate observation of deep properties ** ZXKEEP4Z** to reuse node

```
Repeat<MusicItem>(songs)
Ideas - .each() — — basic rendering (like ForEach, default full rendering)
Ideas --.key() -- -- -- -- -- key generation (single stable string, with ForEach rule)
Ideas -.templateId() - Type Selector (returns template name or undefined)
  │     ├── .template('album') → AlbumCardV2 / .template('ad') → AdCardV2
│ - returns undefined →. each() Default Rendering (SongCardV2)
Ideas - .virtualScroll() - Lazy Load + @ReusableV2 notation (shared with template type)
Ideas - .onLazyLoating() - Precision Lazy Loading (autoloading when rolling closes the end, index & Step Request Additional Data)
@.onMove() -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------, , ------, , 
```

###1. Repeat .each() Basic rendering with .key() key generation

```typescript
/ / Musical Data Model (V2 version, in conjunction with @ObservedV2 + @Trace observation of changes in deep properties)
@ObservedV2
class MusicItem {
  @Trace id: number = 0
  @Trace title: string = ''
  // ...
}

// Song Card Component @Param Receives @ObservedV2+@Trace Data, sub- attribute changes can be observed
@ComponentV2
struct SongCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')

  build() {
    Row({ space: 12 }) {
      // ...
/ Collection Button - @Trace Decoration isFavorite Changes can be observed by @Param, trigger UI refresh
      Image(this.item.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .onClick(() => { this.item.isFavorite = !this.item.isFavorite })
    }
/ /... style omitted
  }
}

@Entry
@ComponentV2
struct PlaylistPage {
  @Local songs: MusicItem[] = [
New Musicitem (1, 'A', 'song'),
New Musicitem (2, 'B', 'song'),
New Musicitem.
  ]

  build() {
    Column() {
Text

      List({ space: 10 }) {
/Repeat Chain Call: .each() Specifies the rendering function →.key() Specifies the key value generation Device
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { SongCardV2({ item: ri.item }) }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
      }
    }
/ /... style omitted
  }
}
```

##2.Repeat .template()/.templateId() Multitype rendering (songs/ albums/advertisements)

```typescript
/ / Musical data models MusicItem and SongCardV2 are defined in Step 1

// Album Card Component
@ComponentV2
struct AlbumCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')
  build() { Row({ space: 12 }) { /* ... */ } }
}

// Advertising card components (Orange background distinction)
@ComponentV2
struct AdCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')
  build() { Row({ space: 10 }) { /* ... */ } }
}

@Entry
@ComponentV2
struct PlaylistTemplatePage {
  @Local songs: MusicItem[] = [
New Musicitem (1, 'A', 'song'),
New Musicitem (2, 'B', 'song'),
New Musicitem.
  ]

  build() {
    Column() {
Text

      List({ space: 10 }) {
/ Repeat co-ordinates .template() achieves multitype rendering, .each() as default rendering function (song type)
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { SongCardV2({ item: ri.item }) }
          })
          .template('album', (ri: RepeatItem<MusicItem>) => {
            ListItem() { AlbumCardV2({ item: ri.item }) }
          })
          .template('ad', (ri: RepeatItem<MusicItem>) => {
            ListItem() { AdCardV2({ item: ri.item }) }
          })
/ templateId: returns the template name by type field of the data item, uses . each() default rendering when returning undefined
          .templateId((ri: RepeatItem<MusicItem>) => {
            if (ri.item.type === 'album') return 'album'
            if (ri.item.type === 'ad') return 'ad'
            return undefined
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
      }
    }
/ /... style omitted
  }
}
```

##3Repeat .virtualScroll() lazy load and reuse with @ReusableV2

```typescript
// Musical data model (see step 1 for definition)

/ / Co-operate with @ReuseableV2 achieve node reuse - recover invisible components on scroll and reuse recovered components
/ / SongCardReusableV2 / AlbumCardReusableV2 / AdCardReusableV2 Structure corresponds to step 2, adding @ReusableV2 Decorator

@Entry
@ComponentV2
struct PlaylistLazyPage {
  @Local songs: MusicItem[] = createLongMusicList()

  build() {
    Column() {
Text

      List({ space: 10 }) {
/ Template Configuration Same Step 2, card component changed to @ReuseableV2 version
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => { ListItem() { SongCardReusableV2({ item: ri.item }) } })
          .template('album', (ri: RepeatItem<MusicItem>) => { ListItem() { AlbumCardReusableV2({ item: ri.item }) } })
          .template('ad', (ri: RepeatItem<MusicItem>) => { ListItem() { AdCardReusableV2({ item: ri.item }) } })
          .templateId((ri: RepeatItem<MusicItem>) => ri.item.type === 'album' ? 'album' : ri.item.type === 'ad' ? 'ad' : undefined)
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
/ / virtualScroll: Start lazy loads, replicating components only in visual and cache areas
          .virtualScroll({ cachedCount: 5 })
      }
    }
/ /... style omitted
  }
}
```

##4Repeat .onLazyLoating() Practicably lazy load (rolling bottom automatically)

```typescript
// Musical data model (see step 1 for definition)

let nextLazyId: number = 21

@Entry
@ComponentV2
struct PlaylistOnLazyPage {
  @Local songs: MusicItem[] = []
  @Local isLoading: boolean = false

  aboutToAppear(): void {
/ / 20 data before initial loading
    for (let i = 1; i <= 20; i++) {
Let item = new Musicitem (i, `song }, `song `, i %7 = 0? 'ad': 'song')
      item.duration = Math.floor(Math.random() * 300) + 120
      this.songs.push(item)
    }
  }
  build() {
    Column() {
Text

      if (this.isLoading) {
        LoadingProgress()
      }

      List({ space: 10 }) {
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { /* ... */ }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
          .virtualScroll({ cachedCount: 3 })
/ on LazyLoating: Start when rolling closes the end, add data as needed
          .onLazyLoading((index: number) => {
            this.isLoading = true
/ / Simulation of the walk request: delay in adding 10 additional data
            setTimeout(() => {
              for (let i = 0; i < 10; i++) {
Let item = new Musicitem.
♪ 'next Lazy Id, next Lazy Id = 0? 'ad': 'song')
                item.duration = Math.floor(Math.random() * 300) + 120
                this.songs.push(item)
                nextLazyId++
              }
              this.isLoading = false
            }, 500)
          })
      }
    }
/ /... style omitted
  }
}
```

5. Repeat .onMove() Drag Sorting with @ObservedV2+@Trace Deep Properties Observation

```typescript
// Musical data model (see step 1 for definition)

/ / Generate 20 musical data to drag and sort
function createDragMusicList(): MusicItem[] {
  return Array.from({ length: 20 }, (_, i) => {
Let item = new Musicitem (i + 1, `song' , `singer' )
    item.duration = Math.floor(Math.random() * 300) + 120
    return item
  })
}

@Entry
@ComponentV2
struct PlaylistDragSortPage {
  @Local songs: MusicItem[] = createDragMusicList()

  build() {
    Column() {
Text

      Row({ space: 8 }) {
Button. onClick() = {
Let it itself = new Musicitem (this.songs. Length + 1, `New song'
          item.duration = Math.floor(Math.random() * 300) + 120
          this.songs.push(item)
        })
Button. Oncick()=>
          if (this.songs.length > 0) { this.songs.pop() }
        })
      }

      List({ space: 10 }) {
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { /* ... */ }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
          .virtualScroll({ cachedCount: 5 })
/ onMove
          .onMove((from: number, to: number) => {
            let temp: MusicItem = this.songs[from]
            this.songs[from] = this.songs[to]
            this.songs[to] = temp
          })
      }
    }
/ /... style omitted
  }
}
```
---
# Animated collection of model reruns

# Apply scene

* Reissued for technical reasons.
|---|---|---|
| Share panel/city selection  `bindSheet` semi-modular | system auto-process ejection animation; `dragBar: true` supports drag-off
| Full Screen Login/Detail Overwrite  `bindContentCover` + `TransitionEffect` | Full Screen Overwrite + Custom Rotation Effect Reuse |
|File Operations Menu |XKEEP0ZX + `MenuElement[]`|Simplified scheme without managing the invisible state |
| Long by icon/photogram menu |`bindContextMenu` + `@Builder` | Automatically handle long by trigger; custom Builder flexible custom |
| Dark Draw menu  `bindPopup` Custom Builder | requires precise control of arrow position and background colour
| Login ↔XKEEP0ZX Conditions Render +`TransitionEffect` + `setTimeout` | Maintains the pattern when the internal switch is crossed and the content fades out

# Core Animation API Enumeration Reference

# # ModalTransion ModalTransion

| | |
|---|---|---|
Z `ModalTransition.DEFAULT` | Default system switch (slide into/slide out)
`ModalTransition.NONE` | Disable System Modular Animation | Shared Element One Mirror (only `geometryTransition`) |
Z `ModalTransition.ALPHA` | Transparency fades out | Purely fades out of pattern |

# TranstionEffect Static Method (commonly used in the modular rotation field)

| Methodology | Description
|---|---|---|
`TransitionEffect.OPACITY` | Transparency transition | Fullscreen mode login faded
| `TransitionEffect.opacity(value)`| Custom transparency threshold | Mode transition from 0.4 transparency
`TransitionEffect.translate(offset)` ZEX ZEX ZEX ZEX TRANSPORT ZEX ZEX ZEX
`TransitionEffect.scale(scale)`| Zoom Field | Registration page 0.95 Zoom to 1 Increase Depth
`.combine(effect)`| Group rotation effect |OPACITY + transport + scale
`.animation(params)` | Additional animated parameters | Setup curation/curve/deray |
`TransitionEffect.asymmetric(enter, exit)`  Z Asymmetrical rotation  Z enters delay, exits no delay |

## bindSheet Common Parameters

| Parameter | Type | Description |
|---|---|---|
`height` | number | semi-modular panel height (vp)|
Whether `dragBar` | Boolean | shows drag strips
Whether `showClose` | boolean| displays the off button
`onDisappear`()= void | panel disappears and returns

# bincontentCover Common Parameters

| Parameter | Type | Description |
|---|---|---|
`modalTransition` | ModalTransion| ModularTransion
`onDisappear`()= void| Full Screen Cover Missing Echo

---

scene 1: share panel

**Scene description:** Simulate the social sharing panel, click on the button and pop up from the bottom a semi-modular panel containing sharing channels such as micro-mail/friendring/QQ to support drag-down.

**Solution:** Use **`bindSheet` semi-modular** + **Grid 4 layout**

```ts
Button.
  .bindSheet($$this.isPresent, this.ShareSheetBuilder(), {
    height: 360,
    dragBar: true,
    showClose: false,
    onDisappear: () => { this.isPresent = false }
  })

@Builder
ShareSheetBuilder() {
  Column() {
Text (`shared'). FontSize (16)
    Grid() {
      ForEach(shareItems, (item) => {
        GridItem() {
          Column() { Image(item.icon).width(40); Text(item.name) }
        }
      })
    }.columnsTemplate('1fr 1fr 1fr 1fr')
Button (`Closed'). onClick() > {this.isPresent=false})
  }
}
```

---

# scene 2: chatlist popup menu

** scene description:** mimic list of micro-mail chats, top title bar with "+" buttons, click the pop-up dark drop-down menu (starting group chats/adding friends/cleaning/receiving payments), list items containing headers, names, summaries of messages and times.

** Solution:** Use **`bindPopup` Customized Dark Eject Menu** + **ZXKEEP1Z** ** ** `enableArrow` Arrow pointed**

> **Note:**
> 1. `bindPopup` by default using `COMPONENT_ULTRA_THICK` blurry background on the end of a mobile phone, overwhelming `popupColor` will invalidate the dark background. If you want to customize background colour,** you must clearly set ZXKEEP3Z** to close the default blur.
> 2. Column in `@Builder` shall set a fixed width (e.g. `.width(160)`), otherwise the width of the bullet window will be too wide with content.

```ts
Text('+')
  .fontSize(24)
  .onClick(() => { this.showMenu = !this.showMenu })
  .bindPopup(this.showMenu, {
    builder: this.wechatMenu,
    placement: Placement.Bottom,
    arrowPointPosition: ArrowPointPosition.END,
    maskColor: 'rgba(0,0,0,0)',
    popupColor: '#4C4C4C',
    backgroundBlurStyle: BlurStyle.NONE,
    enableArrow: true,
    onStateChange: (state) => {
      if (!state.isVisible) { this.showMenu = false }
    }
  })

@Builder
wechatMenu() {
  Column() {
    ForEach(menuItems, (item) => {
      Row() { Image(item.icon); Text(item.name).fontColor(Color.White) }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    })
  }
  .width(160)
  .borderRadius(8)
}
```

---

scene 3: Slide Selector

** scene description:** Simulates the city/date selector, clicks the button and pops the selection panel from the bottom, with a cancellation/fixing button at the top, in the middle of the scrollable city list, with the selected fonts magnified and highlighted.

** Solution:** Use **`bindSheet` 380px panel** + **List Scrollable Selection** + ** Selected Highlight**

```ts
Button.
  .bindSheet(this.isPresent, this.pickerBuilder(), {
    height: 380,
    dragBar: false,
    showClose: false
  })

@Builder
pickerBuilder() {
  Column() {
    Row() {
Text('cancelled'). onClick()=> {This.isPresent=false}
Text('City Choice'). FontWeight
Text('Sure'). onClick(()=> {this.isPrevent=false})
    }
    List() {
      ForEach(cities, (city, index) => {
        ListItem() {
          Text(city)
            .fontSize(this.selectedIndex === index ? 20 : 16)
            .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedIndex === index ? '#333' : '#999')
        }
        .onClick(() => { this.selectedIndex = index })
      })
    }
  }
}
```

---

scene 4: Fullscreen mode login

**Scene description:** Simulate full-screen access window, click on the button to cover full-screen pop-up login page, default display one-key login (cell phone number + protocol tick), switch to fade-out transition for other log-in modes, and return buttons do different operations according to the current page.

** Solution:** Use **`bindContentCover` fullscreen mode** + ** Predefined `TransitionEffect` variable reuse** ** ** Stack superheavy returns button** ** ** ** `expandSafeArea` Extension Safety **

## # Step 1: Define the effect and state of the diversion

```ts
const EFFECT_DURATION = 800;
const EFFECT_OPACITY = 0.4;

@State isPresent: boolean = false;
@State isDefaultLogin: boolean = true;

private effect: TransitionEffect = TransitionEffect.OPACITY
  .animation({ duration: EFFECT_DURATION })
  .combine(TransitionEffect.opacity(EFFECT_OPACITY))
```

Predefined `effect` variable: Based on `OPACITY` rotation, superseding `opacity(0.4)` start transparency, lasting 800 ms. `.transition(this.effect)` was then tied to the condition re-routing content.

Step 2: Trigger full screen mode

```ts
Button.
  .onClick(() => { this.isPresent = true })

/ / Father Bind Full Screen Mode
.bindContentCover($$this.isPresent, this.fullCoverContent())
```

### Step 3: Fullscreen mode content - Conditional rendering + Stack superimpose back button

```ts
@Builder
fullCoverContent() {
  Stack({ alignContent: Alignment.TopStart }) {
    if (this.isDefaultLogin) {
      this.defaultLoginPage()
    } else {
      this.otherWaysToLogin()
    }
    Text('←')
      .fontSize(24)
      .width(50)
      .height(50)
      .textAlign(TextAlign.Center)
      .padding({ top: 15 })
      .onClick(() => {
        if (this.isDefaultLogin) {
This.isPrevent=false; // Default login page
        } else {
This.isDefaultLogin = true; / / Other login pages returns default login
        }
      })
  }
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  .size({ width: '100%', height: '100%' })
  .padding({ top: 10, left: 10, right: 10 })
  .backgroundColor(Color.White)
}
```

The Stack Layout superimposes the button to the top of the condition rendering content to determine which page is currently in `isDefaultLogin` and to perform a different return logic.

### Step 4: Default login page - One key login

```ts
@Builder
defaultLoginPage() {
  Column({ space: 10 }) {
/ /... layout of headers, welcome titles, mobile phone displays, etc.

    Row() {
      Checkbox({ name: 'checkbox1' })
        .select(this.isConfirmed)
        .onChange((value: boolean) => { this.isConfirmed = value; })
      Text() {
Span. FontColor.
Span (`service agreements and rules for the treatment of personal information'). FontColor (Color. Orange)
      }
    }

Button.
      .onClick(() => {
        if (this.isConfirmed) {
Promptaction. showToast ({message: 'login successful'});
        } else {
})
        }
      })

    Row() {
Text
.onClick(() => {this.isDefaultLogin=false;}) / / ← switch to other login Page
      Blank()
Text.
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.White)
  .justifyContent(FlexAlign.Center)
}
```

Note: `defaultLoginPage` does not bind `.transition(this.effect)`, so no fade-out effect occurs when switching back to the default login page; the transcuration effect is only effective on ZXXKEEP2ZX.

Step 5: Other login - binding transtion Out

```ts
@Builder
otherWaysToLogin() {
  Column({ space: 20 }) {
/... layouts such as titlebar, cell phone number input box, authentication code button, protocol ticking, tripartite login icons

    Row() {
      Checkbox({ name: 'agreement' })
        .select(this.isAgree)
        .onChange((value: boolean) => { this.isAgree = value; })
      Text() {
Span. FontColor.
Span (`service agreements and rules for the treatment of personal information'). FontColor (Color. Orange)
      }
    }.width('100%')

/... tripartite login Indicators
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.White)
  .padding({ bottom: 30, top: 60 })
.trastion (this.effect) / / ← binding predefined rollover effects to achieve dilution Out
}
```

Key points:
- Predefined `TransitionEffect` variable ZXXKEEP1ZX, binding ZXXKEEP2ZX to ZXXKEEP3ZX to achieve a dilution transition from default login to other login mode (from 0.4 transparency to 1.0, continuous 800 ms)
- `isDefaultLogin` control condition rendering, ZXXKEEP1ZX two-way binding-driving full-screen modulus invisibility; click "other ways to login" to set `isDefaultLogin` to ZXXKEEP3ZX, trigger `otherWaysToLogin` transfer effect into
-Stack layout to superimpose the button: the default login page clicks back to shut-down mode (`isPresent = false`) and the other login pages clicks back to cut-back default login (`isDefaultLogin = true`)
- Use constant `EFFECT_DURATION` / `EFFECT_OPACITY` to extract transhipment parameters for uniform adjustment
- `expandSafeArea` Extension of the security zone to avoid the bottom being blocked by the system navigation bar

---

# Scenario 5: More operations menu

** scene description: ** Simulates the file manager list, each file entry has a "snap" button on the right, clicks on the pop-up system-level operations menu (copying/mobile/naming/sharing/deleting), and the menu item clicks with a corresponding operation and automatically closes.

** Solution:** To bind menu arrays using **`bindMenu`** + **`MenuElement` menu item configuration** + ** `action`

Step 1: File List Data

```ts
private fileItems: Record<string, string>[] = [
{title: ' Project Book.docx', size: '2.3 MB', icon: '📄, '}
{title: 'the minutes of the meeting.pdf, size: '1.1 MB', icon: '📑' ,
{title: 'Design v3.fig', size: '15.7 MB', icon: '🎨
]
```

## # Step 2: bindMenu binding operations menu

```ts
List({ space: 8 }) {
  ForEach(this.fileItems, (item: Record<string, string>) => {
    ListItem() {
      Row() {
        Text(item.icon).fontSize(28).width(44).height(44)
          .backgroundColor('#f0f0f0').borderRadius(8)
        Column() {
          Text(item.title).fontSize(15).fontColor('#333')
          Text(item.size).fontSize(12).fontColor('#999').margin({ top: 4 })
        }.layoutWeight(1)
        Text('⋮')
          .fontSize(22).fontColor('#666').width(36).height(36)
          .textAlign(TextAlign.Center).borderRadius(18)
          .bindMenu([
{value: ' Duplicate ', action: () = >/ * Copy operation*/ },
{value: 'move', action: () = >/ * move */ },
{value: 'Rename ', action: () = >/ * Rename operation */ },
{value: 'Shared', action: () = > share operation */ },
{value: 'Delete ', action: () = > {/ * Delete operation*/},
          ])
      }
      .width('100%').padding(12).backgroundColor(Color.White).borderRadius(8)
    }
  })
}
```

Key points:
- `bindMenu` Receives `MenuElement[]` arrays, each containing `value` (showing text) and `action` (clickback)
- The menu automatically locates above/under bound components and closes automatically after clicking on the menu item
- `bindMenu` is automatically processed by the system without manual management of the hidden state of the menu

---

scene 6: Long by menu

**Scene description:** Simulate desktop icons and picture lengths by operation. Long pop-up shortcut menus (sharing/applying information/dismounting), long pop-up picture operations menus (maintaining picture/receiving/searching links/replicating links) using an icon for desktop applications, and two scenes toggle through Tab.

** Solution:** Use **`bindContextMenu` + ZXKEEP1Z** ** **`@Builder` Custom menu layout** + ** Tab Toggle Two scenes**

Step 1: Define Custom Menu

```ts
@Builder
ImageContextMenu() {
  Column() {
    Row() {
      Text('💾').fontSize(20).margin({ right: 12 })
Text ('Save Picture'). FontSize (16). FontColor ('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })
.onclick(()=>{/* Save Picture */})

    Divider().color('#f0f0f0')

    Row() {
      Text('⭐').fontSize(20).margin({ right: 12 })
Text('re collection').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('🔍').fontSize(20).margin({ right: 12 })
Text ('Diagram search'). FontSize (16). FontColor ('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('🔗').fontSize(20).margin({ right: 12 })
Text (' Duplicate Link'). FontSize (16). FontColor ('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('📤').fontSize(20).margin({ right: 12 })
Text('re forward').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })
  }
  .width(180)
  .backgroundColor(Color.White)
  .borderRadius(12)
}
```

Step 2: Tie long by the menu

```ts
/ Desktop Icon scene
Column() {
  Text(app.icon).fontSize(32)
}
.width(56).height(56).borderRadius(14).backgroundColor(app.color)
.justifyContent(FlexAlign.Center)
.bindContextMenu(this.DesktopAppMenu, ResponseType.LongPress)

Image scene
Column() {
  Text('🌅').fontSize(60)
}
.width('100%').height(140).backgroundColor('#ff9500')
.justifyContent(FlexAlign.Center)
.bindContextMenu(this.ImageContextMenu, ResponseType.LongPress)
```

Step 3: Tab to switch two scenarios

```ts
@State currentTab: number = 0

Row() {
ForEach([' Desktop Icon', 'Photo Long Press '), (tab: string, index: number) = >
    Column() {
      Text(tab)
        .fontColor(this.currentTab === index ? '#007dff' : '#666')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1).height(44).justifyContent(FlexAlign.Center)
    .onClick(() => { this.currentTab = index })
  })
}

if (this.currentTab === 0) {
  this.DesktopIconScene()
} else {
  this.ImageLongPressScene()
}
```

Key points:
- `bindContextMenu(Builder, ResponseType.LongPress)` binds the custom menu to long gestures, and the system autoprocesss the popup and off
- `ResponseType.LongPress` specifies the trigger method as a long press, different from the `bindMenu` click trigger
- Different `@Builder` menus (e. g. desktop icon menu vs picture menus) can be bound to different components to make the scene different
- Custom menu layouts and styles in `@Builder`, which support the richness of icon + text, partition lines, etc.

---

# 7: Login to register model

**Scene description:** Simulates the login registration process, slides the login page from the bottom to the full cover screen by clicking on the "login" button, slips the registration page from the right side by clicking on the "registration" button; you can switch the cell phone number/cipher login to the login login and jumps between login login login login login and drops out of the old page.

** Solution:** using **`if` condition render + ZXKEEP1Z** ** `curves.springMotion(0.6, 0.9)` elastic curve** ** ** ** ** `setTimeout` organized login login with **

Step 1: Status and diversion

```ts
@State showLogin: boolean = false
@State showRegister: boolean = false
@State isPhoneLogin: boolean = true

private toggleLogin(): void {
  this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
    this.showLogin = !this.showLogin
  })
}

private toggleRegister(): void {
  this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
    this.showRegister = !this.showRegister
  })
}
```

Step 2: Login registration crossover

```ts
private switchToRegister(): void {
  this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
    this.showLogin = false
  })
  setTimeout(() => {
    this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showRegister = true
    })
  }, 200)
}

private switchToLogin(): void {
  this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
    this.showRegister = false
  })
  setTimeout(() => {
    this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showLogin = true
    })
  }, 200)
}
```

Key points: `setTimeout(200)` allows the old page to fade 200 ms before the new page begins to fade, creating a cross-turn rather than a simultaneous switch.

Step 3: Login Page - Flex in from bottom

```ts
if (this.showLogin) {
  Column() {
/ Top Navigator
    Row() {
      Text('<').onClick(() => this.toggleLogin())
Text('entry'). playoutWeight(1).textAlign(TextAlign.Center)
    }.width('100%').height(56).padding({ left: 16, right: 16 })

/ / Log-in form (support mobile phone number/cipher switch)
    Column() {
Text. FontSize(28). FontWeight.Bold
Text (`Register your account'). FontSize (14). FontColor (`#999')

      Row() {
Text (this.isPhoneLogin? ' Cell phone login': 'cipher login'). FontColor ('#ff6b35')
Text.
          .onClick(() => { this.isPhoneLogin = !this.isPhoneLogin })
      }

      if (this.isPhoneLogin) {
TextInput({placeholder: 'Please enter cell phone'})
/ / Authentication Code Input + Get Authentication Code button
      } else {
TextInput({placeholder: 'Please enter cell number/mail'})
TextInput({placeholder: 'please enter password'}). type (InputType.password)
      }

Button.onClick() = > this.toggleLogin())
Text ('Direct Registration').onClick(()=> This.switchToRegister())
    }
  }
  .width('100%').height('100%').backgroundColor(Color.White)
  .transition(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ y: 300 }))
      .animation({ duration: 400, curve: curves.springMotion(0.6, 0.9) })
  )
}
```

Step 4: Registration page - Flexed from right

```ts
if (this.showRegister) {
  Column() {
/ Top Navigator
    Row() {
      Text('<').onClick(() => this.toggleRegister())
Text (`Registration'). PlayoutWeight(1).textAlign (TextAlign.Center)
    }

    Scroll() {
      Column() {
Text (`create a new account'). FontSize(28). FontWeight (FontWeight.Bold)
Text ('Enjoy full functionality after registration'). FontSize (14). FontColor ('#999')

TextInput({placeholder: 'Please enter cell phone'})
// Authentication Code + Password + Confirm Password
Checkbox() / / Consent protocol
Button ('Registration').onClick()=> This.toggleRegister()
Text.onClick(() = > this.switchToLogin())
      }
    }
  }
  .width('100%').height('100%').backgroundColor(Color.White)
  .transition(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: '100%' }))
      .combine(TransitionEffect.scale({ x: 0.95, y: 0.95 }))
      .animation({ duration: 400, curve: curves.springMotion(0.6, 0.9) })
  )
}
```

Key points:
- The login page slips from the bottom with `translate({ y: 300 })`, the registration page slides from the right with `translate({ x: '100%' })`, and directional differentiation reflects the page hierarchy
- Add `scale({ x: 0.95, y: 0.95 })` to the registration page, expanding from 0.95 to 1 times, increasing even more deeply
- `curves.springMotion(0.6, 0.9)` Flex Curve provides a natural rebound for slide animation
- Login cross-register organized via `setTimeout(200)`: Close the current page (300ms animated), 200ms and then open the target page to form 100ms cross

---

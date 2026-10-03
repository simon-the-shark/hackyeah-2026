# Temporary interactive/tip interface cases such as window/menu Set

---

# The ability to pop a window #

# Functional points typically use scene comparison

♪ Bang, bang, bang, bang, bang ♪
|---------|------------|---------|-----------|
|AlertDialog | remove confirmation, exit login, version update | system fixed style + button back
|ActionSheet | Share channel, message operation, change header | Bottom list selection + Title | Date selection, pure operation menu |
| Selector bullet window | Birthday selection, appointment, academic choice | Roller selection + range control | Free text input |
| ShowDialog (promptaction) | Submit confirmation, file overwrite, Next |Promise Stepback Button Index | Need Custom Styles
| ShowActionMenu (promptaction) | Edit/delegate/Share/Receive menu | Light Pure menu +Promise | Select bullet window with message description
| OpenCustomDialog (ComponentContent) | Countdown ad, global notification | Dynamic update of bullet window contents + Simple bullet windows with fixed content without UI context
@CustomDialog + CustomDialogController
| levelOrder | layer management of multiple bullet windows | control the order of covering between bullet windows
|Focusable: false | Search for suggestions/message windows | Blast windows do not get focus without keyboard | Need to enter inside the bullet window |
| autoCancel/isModal/maskRect | Payment confirmation, non-modern, local-molecular guidance | Mascular/interactive/regional control | Default membrane can be satisfied
|Transion |View/Slide

---

# Scenario I: second confirmation of sensitive operations such as delete/exit

**Scene example description**: Users who perform sensitive operations such as deleting files, exiting login, clearing data, etc. require a second confirmation to prevent error.

** Solution**: Use AlertDialog.show() to pop up a warning window with a fixed style, set a title, message and confirm/cancell button.

```typescript
/ Double button confirmation (primaryButton + secondaryButton)
this.getUIContext().showAlertDialog({
Title: 'Delete confirmation',
message: 'Are you sure you want to delete the file? Could not be restored after deletion. '...
PrimaryButton: {value: 'cancelled', action: () = { / * ... */ },
SecondaryButton: {value: 'Certified Delete', FontColor: '#e74c3c', action: () = { {/* ... */}
});

/ Single button hint
this.getUIContext().showAlertDialog({
Title: 'Web error',
Could not close temporary folder: %s '...
Confirm: {value: 'Retry', action: () = {/*... */}
});

/ Three button variants (buttons array, up to 3)
this.getUIContext().showAlertDialog({
Title: 'Save Changes',
message: 'Do you save changes to documents? '...
  buttons: [
{value: 'not saved', FontColor: '#999', action: ()=>},
{value: 'cancelled', action: () = },
{value: 'Save', FontColor: '#007DFF', action: () = >
  ]
});
```

# AlertDialog button configuration

| Properties | Number of buttons | Applicable scene |
|------|---------|---------|
`confirm` | single button | only "know/try" hint
Z `primaryButton` + `secondaryButton` | Double button | Confirm/Uncheck One |
| `buttons` | Multiple buttons (maximum 3) | Non-save/cancell/save 3 or 1 |

---

Scene II: Share Channel List Selection

**Scenario description**: Users who click on the sharing button display a list of sharing channels such as Twitter, QQQ, and Twitter for choice by users.

** Solution**: Configure the icons and titles of the sharing channels by using ActionSheet.show() arrays.

```typescript
this.getUIContext().showActionSheet({
Title: 'Shared',
Subtitle: 'Select a shared platform',
message: 'Please choose the platform to share',
  sheets: [
{title: 'Wire', action: () = { ... */ },
    { title: 'QQ', action: () => { /* ... */ } },
{title: 'Webbo', action: () = { ... */ }
  ] as Array<SheetInfo>,
cancel: ()=>{/ * Cancel sharing*/}
});
```

---

scene III: Date/time/text selector bullet window

**Scene example description**: The user sets a birthday, chooses the date of the trip or makes an appointment, etc., that needs to slide the selection of the calendar.

** Solution**: Use DatePickerDialog.show(), set the start/end range, selected default date, and retrieve the selected date by returning on DateAccept.

```typescript
/ Date selection
this.getUIContext().showDatePickerDialog({
  start: new Date('2000-01-01'),
  end: new Date('2030-12-31'),
  selected: new Date(),
  lunar: false,
  onDateAccept: (value: Date) => { /* ... */ },
  onCancel: () => {}
});

/ Time selection
this.getUIContext().showTimePickerDialog({
  selected: new Date(),
  useMilitaryTime: true,
  onAccept: (value: TimePickerResult) => { /* ... */ },
  onCancel: () => {}
});

/ Text Selection
this.getUIContext().showTextPickerDialog({
Range: ['High School', 'Academies', 'Academy', 'Master', 'Dr.'],
  onAccept: (value: TextPickerResult) => { /* ... */ },
  onCancel: () => {}
});

Calendar Selection
CalendarPickerDialog.show({
  selected: new Date(),
  start: new Date('2024-01-01'),
  end: new Date('2027-12-31'),
  onAccept: (value: Date) => {},
  onCancel: () => {}
});
```

# # Selector window comparison

♪ Bang, bang, bang, bang ♪
|------|---------|---------|---------|
`getUIContext().showDatePickerDialog()` Date `onDateAccept`
TimePickerDialog `getUIContext().showTimePickerDialog()` Time `onAccept`
|TextPickerDialog |`getUIContext().showTextPickerDialog()` | text array |XXKEEP1ZX |
|CalendarPickerDialog |`CalendarPickerDialog.show()`| Calendar date  ZXXKEEP1ZX|

---

# scene four: the step confirmation dialogue

** Example description of scene **: A step-by-step confirmation is required prior to the submission of the form to confirm whether the subsequent submission will be executed on the basis of the result of the user's step-by-step return of "confirmation" or "cancellation".

** Solution**: using promptaction.showDialog() to access the user-clicked button index by Promise, to process the heretic logic in the then back.

```typescript
async showSubmitDialog(): Promise<void> {
  try {
    const result = await this.getUIContext().getPromptAction().showDialog({
Title: 'Submit confirmation',
message: 'Certified submission of current form data? Not modified after submission. '...
      buttons: [
{text: 'Cancel', color: '#999'},
{text: 'confirm ', color: '#007DFF'}
      ]
    });
    if (result.index === 1) {
// Confirmation of submission
    } else {
/ / Unsubmit
    }
  } catch (err) {
/ Window close
  }
}
```

# ShowDialog versus AlertDialog

AlertDialog
|------|------------|-----------|
| Return mode | Sync action back | Promise step back |
Z Button Index
`getUIContext().showAlertDialog()` `getUIContext().getPromptAction().showDialog()`
| Appliance scenario | Direct execution operation | Differential processing results before operation

---

# Scenario 5: Operation menu

** Example description of scene **: Click on the "More" button in the toolbar, pop up the menu of operational options such as "Edit/Delete/Share/Face collection", which requires a step-by-step operation based on the menu item selected by the user.

** Solution**: Using the promptaction.showactionMenu(), returning the button index selected by the user using the buttons configuration menu item.

```typescript
async showMoreActions(): Promise<void> {
  try {
    const result = await this.getUIContext().getPromptAction().showActionMenu({
Title: 'More operations',
      buttons: [
{text: 'edit', color: '#333'},
{text: 'Delete', color: '#e74c3c'},
{text: 'Shared', color: '#007DFF'},
{text: 'Receivable', color: '#f39c12'}
      ]
    });
(a) Const actions: string[[] = ['edit', 'delete', 'share', 'revenue'];
// Execute actions [result.index]
  } catch (err) {
/ Cancel Operation
  }
}
```

---

# Scene VI: Global bullet windows that do not depend on UI

** Example description of scene **: In the electrician ' s promotion campaign, the advertisement window was ejected and it needed to be updated dynamically after the countdown (e.g., countdown, button file turned into "immediate buy").

** Solutions**: use get UIContext().getPromptaction().openCustomDialog() to create bullet windows, and dynamically update bullet window properties by update() of Component.

```typescript
import { ComponentContent } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

Definition of parameter categories
class CountdownParams {
  countdownText: string = '';
  buttonText: string = '';
  onButton: () => void = () => {};
  onClose: () => void = () => {};
  constructor(countdownText: string, buttonText: string,
    onButton: () => void, onClose: () => void) { /* ... */ }
}

Definition
@Builder
function buildCountdownDialog(params: CountdownParams) {
  Column({ space: 16 }) {
Text('s time-limited').fontSize(20).fontWeight (FontWeight.Bold)
    Text(params.countdownText).fontSize(28).fontColor('#e74c3c')
Text ('The Whole Market ' ) .fontSize (14).fontColor ('#666')
    Button(params.buttonText).width('100%').onClick(() => params.onButton())
Button (`Closed'). Width ('100%'). Background Color ('#f0f0f0').onClick(()=>params.onClose())
  }.width(280).padding(24).backgroundColor(Color.White).borderRadius(16)
}

Create ComponentContent and open bullet windows
private content: ComponentContent<CountdownParams> | null = null;

showCountdownDialog(): void {
  this.content = new ComponentContent(
    this.getUIContext(),
    wrapBuilder(buildCountdownDialog),
New CountryParams (`Counterdown: 5 seconds ' , 'Waring for Countdown', () =}, () > {this. closedialog(;})
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.content, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: false
  }).then(() => {
This.startCountdown(); // Start Timer
  }).catch((error: BusinessError) => {});
}

Dynamic updates of bullet windows in timers
startCountdown(): void {
  this.timerId = setInterval(() => {
    this.countdown--;
    if (this.countdown <= 0) {
      clearInterval(this.timerId);
/ / Countdown is over. Update button file is "Seques immediate."
      this.content?.update(new CountdownParams(
"The countdown is over!", "As soon as possible." () = > { * * /}, () = { {this. closedialog();}
      ));
    } else {
/ Update Countdown
      this.content?.update(new CountdownParams(
`Countdown: {this.countdown}seconds `, 'waiting the countdown', () = > {, () = {This. closedialog();}
      ));
    }
  }, 1000);
}

/ 5. Closure of bullet windows & destruction of resources
closeDialog(): void {
  if (this.timerId !== -1) { clearInterval(this.timerId); }
  if (this.content) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.content)
      .then(() => { this.content = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
  if (this.timerId !== -1) { clearInterval(this.timerId); }
If (this.content) {this.content.dispose();} // Must release resources
}
```

# OpenCustomDialog Key API

| Methodology
|------|-----|
`new ComponentContent(uiContext, wrapBuilder(builder), params)`| Create bullet window contents
`openCustomDialog(content, options)` | Open the bullet window and return to Promise |
`content.update(newParams)` | Dynamic update of bullet windows
`closeCustomDialog(content)` | Close the bullet window and return to Promise |
Z `content.dispose()`| Destruction of components, release of resources

---

# scene seven: Base custom bullet windows

** Example description of scene**: In an electrician ' s application, the commodity details ejected a bullet window containing a choice of commodity specifications (colour/foot size), volume regulation and addition of a shopping car button.

** Solution**: using @CustomDialog decorator to define a bullet window with specification selected components, manage the bullet window interactively through CustomDialogController.

```typescript
// 1. Definition
@CustomDialog
struct SpecDialog {
  controller: CustomDialogController;
  onResult: (result: string) => void = () => {};
  @State selectedColor: string = '';
  @State selectedSize: string = '';
  @State quantity: number = 1;

  build() {
    Column({ space: 12 }) {
Text (`Commodity Specifications'). FontSize(18). FontWeight (FontWeight.Bold)

Colour Selection
Text('Colour').fontSize(14).alignSelf(ItemAlign.Start)
      Flex({ wrap: FlexWrap.Wrap }) {
ForEach ['Black', 'White', 'Blue', 'Red']
          Button(item)
            .backgroundColor(this.selectedColor === item ? '#007DFF' : '#f0f0f0')
            .onClick(() => { this.selectedColor = item; })
        })
      }.width('100%')

// Ruler Selection (same omitted)
      // ...

/ Quantity reconciliation
      Row({ space: 16 }) {
        Button('-').enabled(this.quantity > 1).onClick(() => { this.quantity--; })
        Text(this.quantity.toString()).fontSize(16)
        Button('+').onClick(() => { this.quantity++; })
      }

/ Operation button
      Row({ space: 12 }) {
Button('cancelled').onClick(()=> {This.controller.close(;})
Button.
          .enabled(this.selectedColor !== '' && this.selectedSize !== '')
          .onClick(() => {
This.onResult (`Beed: $ {this.selfColor} $ {this.selfSize} x $ {this.quantity} ' );
            this.controller.close();
          })
      }
    }.width(300).padding(24)
  }
}

// 2. Create Controller in the page and use
private specDialogController: CustomDialogController = new CustomDialogController({
  builder: SpecDialog({ onResult: (result: string) => { /* ... */ } }),
  autoCancel: true,
  alignment: DialogAlignment.Bottom,
  customStyle: true
});

/ Use
Button ('Commodity Specifications').onClick(()=> {this.specDialogController.open();})
```

# CustomDialogController Key Configuration

| Properties | Role | Example |
|------|-----|------|
`builder` | bullet window content builder  `SpecDialog({ onResult: ... })` |
`autoCancel`| Click on the mask to close |XKEEP1ZX / `false`|
`alignment` | Location of bullet windows  `Center` / `Bottom` / `Top` |
`customStyle`| Remove the default rounded background when custom style |XKEEP1ZX

# DialogAlignment

| Equivalent value | Location of bullet windows | Applicable scene |
|--------|---------|---------|
`Top` | Top alignment | Search proposal, top tip |
Z`Center` | Centered | General bullet window, confirmation frame
`Bottom` | base alignment | specification selection, bottom panel |
`Default`| Default (centre) | Default when not specified

@CustomDialog compares to openCustomDialog

@CustomDialog +Controller
|------|---------------------------|-----------------------------------|
| Dynamic Update | Unsupported, created after attribute fixed | support, via `content.update()`|
| State sharing | Tie to parent components to facilitate sharing | does not depend on the context of the specific component |
API recommended 12 cases not recommended
| Applicable scene | Customized bullet window with fixed content | Dynamic update, global window |

# @CustomDialog Compatibility with Transtion
> ** Bans the use of @CustomDialog+CustomDialogController to achieve a custom-defined bullet window that requires transition animation** The CustomDialogController configuration ** does not contain transtion parameters** and cannot set the TransitionEffect transition animation; custom bullet window animations must use the `openCustomDialog(content, { transition: ... })` scheme. Similarly, it is prohibited to simulate a window transition manually with animateTo or animation attribute modifiers - they cannot function during the entry/exit transition phase of the bullet window/skinner layer, and only `transition` parameters can take over the window system transition.

---

# Scenario 8: Window Level Management

**Scene Example Description**: In a multi-task editor, the "unsaved alarm" bullet window (Stage 200) pops up above the base settings window (Stage 50) to ensure that the saved alarm always covers the set window.

** Solution**: set a different level order value for each of the two bullet windows to ensure that the key alarm window level is higher than the normal set window.

```typescript
// Low-level bullet windows
showLowLevelDialog(): void {
  this.lowContent = new ComponentContent(
    this.getUIContext(), wrapBuilder(buildLevelDialog),
New LevelDialogParams ('Basic Settings Window'), 'General Priority Settings Message. ', 50, () = { This. closeLowDialog(;})
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.lowContent, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: true,
LoveOrder: LevelOrder.clamp(50) / / Level 50
  }).then(() => {}).catch((error: BusinessError) => {});
}

// Top-level bullet windows (level Order: 200, over low-level)
showHighLevelDialog(): void {
  this.highContent = new ComponentContent(
    this.getUIContext(), wrapBuilder(buildLevelDialog),
New LevelDialogParams ('not saving alarms'), 'Do you have unsaved changes, save them? ', 200, ()=> {this. closeHighDialog(;})
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.highContent, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: true,
level 200, above 50
  }).then(() => {}).catch((error: BusinessError) => {});
}

Close two windows and release resources, respectively
closeLowDialog(): void {
  if (this.lowContent) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.lowContent)
      .then(() => { this.lowContent?.dispose(); this.lowContent = null; })
      .catch((error: BusinessError) => {});
  }
}

closeHighDialog(): void {
  if (this.highContent) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.highContent)
      .then(() => { this.highContent?.dispose(); this.highContent = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
/ / high-level and low-level, both of which require dispossess
  this.closeHighDialog();
  this.closeLowDialog();
}
```

#levelOrder forbidden writing
> ** Bans the use of zIndex or Project absolute positioning instead of level Order to manage the bullet window level**. zIndex/Position functions at the normal node in the component tree and cannot affect the independent rendering order of the `promptAction.openCustomDialog` bullet window; only ZXXKEEP1ZX parameters control the priority of the cover between openCustomDialog bullet windows. Two bullet windows must use separate Component Content objects and cannot share the same example, otherwise content conflicts.

---

scene nine: bullet window focus management

** Example description of scene **: When a user enters text in a search box, a real-time pop-up search proposal/message window should not close the keyboard, and focus should remain in the input box to allow the user to continue the input.

** Solution**: using openCustomDialog() and setting a Focusable false without a focus when the window pops up and the keyboard does not close.

```typescript
@Builder
function buildSuggestionDialog(param: SuggestionParams) {
  Column({ space: 8 }) {
Text('search recommendations').fontSize(14).fontWeight (FontWeight.Bold)
    Column({ space: 4 }) {
      ForEach(param.suggestions, (item: string) => {
        Text('• ' + item)
          .fontSize(13).fontColor('#007DFF').width('100%')
.onClick(() => param.onSelect(item)) / Click Proposal: Fill in the search box and close Play. Window
      })
    }.width('100%').padding(8).backgroundColor('#f5f5f5').borderRadius(8)
Button (`Closed').onClick()=>param.onCloose()
  }.width(260).padding(16).backgroundColor(Color.White).borderRadius(12)
}

/ SuggestionParams to add onSelect
class SuggestionParams {
  suggestions: string[] = [];
  onSelect: (item: string) => void = () => {};
  onClose: () => void = () => {};
  constructor(suggestions: string[], onSelect: (item: string) => void, onClose: () => void) { /* ... */ }
}

showSuggestionDialog(): void {
  this.content = new ComponentContent(
    this.getUIContext(),
    wrapBuilder(buildSuggestionDialog),
    new SuggestionParams(
['ArkTS Development Guide', 'ArkUI Component Reference', 'Best Practice of Bullet Window'],
(item: string) = > {/ * Fill the selected word in the search box */ this. closedialog();},
      () => { this.closeDialog(); }
    )
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.content, {
    alignment: DialogAlignment.Top,
isModal: false, / / non-modular, allowed to interact with ecstasy
    autoCancel: true,
Focusable: key // key: bullet windows do not get focus, keyboard does not take Rise
  }).then(() => {}).catch((error: BusinessError) => {});
}
```

---

# scene X: Curtain layer control (hidden/style/interactive)

** Example description of scene **: payment confirmation window does not allow clicks on blindfolding to prevent error; new hands guide middle blindfolding only partially shielded areas to achieve local highlight; non-modular bullet windows allow interaction with outside covered components.

** Solution **: Control of masked behaviour through autoCancel, IsModal, maskRect.

```typescript
/ / / 0. Defines the content of the confirmation bullet window (buttons must be provided, autoCancel:false can only be closed by button)
class PaymentParams {
  onConfirm: () => void = () => {};
  onCancel: () => void = () => {};
  constructor(onConfirm: () => void, onCancel: () => void) { /* ... */ }
}

@Builder
function buildPaymentDialog(param: PaymentParams) {
  Column({ space: 16 }) {
Text('Pay confirmation'). FontSize(20). FontWeight (FontWeight.Bold)
Text ('"Recognition of Payment 99.00').fontSize (14).fontColor ('#666')
    Row({ space: 12 }) {
Button (`cancelled'). Width (`50%'). Background Color (`#f0f0f0')
        .onClick(() => param.onCancel())
Button (`confirmed payment'). Width ('50%'). Background Color ('#007DFF'). FontColor (Color. White)
        .onClick(() => param.onConfirm())
    }.width('100%')
  }.width(300).padding(24).backgroundColor(Color.White).borderRadius(16)
}

/ This.content needs to be created before calling
this.content = new ComponentContent(
  this.getUIContext(), wrapBuilder(buildPaymentDialog),
New PaymentParams(() = > {/* Execute Payments */ This.closeDialog();},
                    () => { this.closeDialog(); })
);

// 1. Prohibition of blindfolding (pay confirmation scene)
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
AutoCancel: false / / Click on the mask to do it without closing
});

// 2. Non-modular bullet windows (permissible to interact with ecstasy components)
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
isModal: false, / / non-modular, interoperable outside of the mask
  autoCancel: true
});

/ 3. Local hoods (covering only 10 per cent of the top area, out-of-scope events)
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Top,
  isModal: true,
  autoCancel: true,
  maskRect: { x: 0, y: 0, width: '100%', height: '10%' }
});
```

No, no, no, no, no.

| Parameters, | Activation, | Typical scene, |
|------|-----|---------|
`autoCancel: false` | Bans click on the mask to close | Payment confirmation, critical operation error protection |
Z`isModal: false` | non-modular, interoperable masked | search suggestions, suspension tips  Z
`maskRect: { x, y, width, height }` | Customised Monument Area | Newman Guide Local Highlight

---

# Scene 11: Animation control

** Example description of scene **: The festival window requires a self-defined fade-out animation effect, and the window and lacquer as a whole appears in a three-second slow-momenting manner to enhance the visual atmosphere.

** Solution**: using the OpenCustomDialog() parameter to set TransitionEffect custom-defined transition animations.

```typescript
/ / 1. Slow fade (in 3 seconds)
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
  autoCancel: true,
  transition: TransitionEffect.OPACITY.animation({ duration: 3000 })
});

// 2. Fast fade (1 second)
transition: TransitionEffect.OPACITY.animation({ duration: 1000 })

// 3. Slide + fade into group animation
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
  autoCancel: true,
  transition: TransitionEffect.translate({ y: 300 })
    .combine(TransitionEffect.OPACITY)
    .animation({ duration: 800 })
});

/ 4. Closing of bullet windows and release of resources (transion scenario also requires resource closure)
closeDialog(): void {
  if (this.content) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.content)
      .then(() => { this.content?.dispose(); this.content = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
  if (this.content) { this.content.dispose(); }
}
```

# TransportEffect

Equation values/methods Effects Usage
|------------|------|-----|
`OPACITY`| Transparency Transition |XKEEP1ZX|
`translate({ x, y })` ZEX
`scale({ x, y })` ZEZX ZEX ZEKEP1ZX
`rotate({ angle })`| Rotation Transition  `TransitionEffect.rotate({ angle: 180 })`|
`move(...)` | Transition `TransitionEffect.move(TransitionEdge.TOP)` |
`.combine(effect)`| Multi-effect combination |XKEEP1ZX|
`.animation({ duration })`| Set animation duration  `.animation({ duration: 800 })`|

# TranstionEdge

Quantum count values
|--------|------|
`TOP` | slides in/out of top |
Z `BOTTOM` | slides in/out from the bottom |
Z `START` | Slide from the beginning (left) into/out
Z `END` | Slide from end side (right) to/out

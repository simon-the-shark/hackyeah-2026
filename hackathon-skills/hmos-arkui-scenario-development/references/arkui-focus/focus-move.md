# Focus moving scenes

# SCENE-01 Snackbar Permanent notice bullet window Tab Ring

**Applicable scene: **Application requires the popup of a permanent reminder (which does not automatically disappear), the user can use the keyboard Tab to focus from the trigger button to the Snackbar text button, and the focus can return to the original trigger button when the action is triggered. Circumstances that need to be continuously displayed and allowed to interact, such as alerts after successful attention/collection/saving, web-disconnected tips, and file uploads.

** Core mechanism:**

1. **`duration: -1` Declaration Permanent**: `SnackBarStyleOptions` sets `duration` to -1, Snackbar does not automatically disappear
2. **`textButtonId` Identifier Snackbar Text button**: When `SnackBarOperationOptions.operationType = SnackBarOperationType.TEXT_WITH_CLOSE`, set a unique identifier to Snackbar 's internal text button by ZXXKEEP2ZX
3. **House button `.nextFocus({ forward })`**: Trigger a button displayed by Snackbar (e. g. "Care" button) by `.nextFocus({ forward: 'snackBarTextButton' })` declaring Tab to enter Snackbar 's focus rules
4. **`nextFocusId` Configuration Return Component**: Set `nextFocusId: 'button'` in `SnackBarStyleOptions` to declare Snackbar to return id to `button` after closing

** Three sets of key links:** HdsSnackBar exposed `textButtonId` in `SnackBarOperationOptions`, exposed ZXXKEEP3ZX in `SnackBarStyleOptions`, and the host component aligned with the original ArkUI ZXXKEEP4ZX. Three through `id` string.

** Following the focal link:**

```
[House "Care" button] - - Tab - - [Snackbar Text Button Id]
       ▲                              │
│ (Snackbar close/disappear)
       │                              ▼
nextFocusId specified component
```

** Steps to be taken:**

1. **Import HdsSnackBar related module**: Import `HdsSnackBar`, `SnackBarIconOptions`, `SnackBarMessageOptions`, `SnackBarOperationOptions`, `SnackBarStyleOptions`, `SnackBarOperationType`
2. **Current example of HdsSnackBar**: feed into `UIContext` as the basis for calling on ZXXKEEP1ZX
3. ** Configuration.textButtonId**: right-hand operating area type set to `TEXT_WITH_CLOSE` and specified `textButtonId: 'snackBarTextButton'`
4. ** Configure style. NextFocusId and duration**: `nextFocusId: 'button'` Specifies components id, `duration: -1` to return after Snackbar closes
5. ** Host Focus button setting nextFocus**: `forward` must be strictly consistent with `textButtonId`
6. ** Trigger button call show**: click the trigger button call `hdsSnackBar.show(icon, message, operation, style)`

```typescript
import {
  HdsSnackBar,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarStyleOptions,
  SnackBarOperationType
} from '@kit.UIDesignKit';

@Entry
@ComponentV2
struct TestSnackBar {
  uiContext: UIContext = this.getUIContext();
  hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);

/ / 1 left icon
  icon: SnackBarIconOptions = {
    icon: $r('sys.symbol.checkmark_circle')
  }

/ 2 Intermediate
  message: SnackBarMessageOptions = {
    title: $r('sys.string.ohos_id_text_location_button_description_current_position'),
    content: $r('sys.string.ohos_id_text_save_button_description_save')
  }

/ 3 Key: right-hand operating area sets textButtonId as Tab's focus into Snackbar
  operation: SnackBarOperationOptions = {
    operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
    content: $r('sys.string.ohos_id_text_save_button_description_save_image'),
    textButtonId: 'snackBarTextButton'
  }

/ 4 Key: set nextFocusId (Snackbar returns component) and duration (-1 indicates permanent) in style
  style: SnackBarStyleOptions = {
    nextFocusId: 'button',
    duration: -1
  }

  build() {
    Column() {
      Blank().height(400)

// Trigger the button displayed by Snackbar, id is 'button', aligned with nextFocusId
Button.
        .onClick(() => {
          this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
        })
        .id("button")

/ 5 Key: Host Focus Configure NextFocus.Forward with the same value as textButtonId
Button.
        .nextFocus({
id of / Forward must be the same as the textButtonId that was passed on in the SnackBarOperationOptions interface
          forward: 'snackBarTextButton'
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xF1F3F5)
  }
}
```

---

# ZXKEEP0ZList loop focus

** Applicable scene: ** TV application, machine, tablet keyboard, etc. using ** Direction/Tab key** for navigation between List items. User-clicked (up/down or left/right) to arrive list* *In the end**, the expected focus returns to the first**,** to the first**,** to the end**,** and then to the end**,** to form a circular navigation. Common in settings, menu lists, video and video collections, Tab tabs, digital keyboards, etc.

** Core mechanism: ** `List` + `ListItem` container, where the system's default focus is "stucked" when it reaches the boundary (linear focus algorithms refuse to focus requests in the direction opposite of the current focus). The `nextFocus` internal focus on each ZXXKEEP3ZX ** Remarkable statements point to each other at the end**:

- Directional key cycle (`up` / `down` / `left` / `right`): Configure the reverse key to the end** id** in the end** and the positive key to the first** id**
- Tab cycle (`forward` / XKEEP1ZX): Configure `forward` to first id** and `backward` to last** id** at end**

** Steps to be taken:**

1. **List + ForEach Rendering ListItem**: Each ListItem has a focusable component (Button / Text + Focusable)
2. ** Unique id**: using `item_${index}` for each focusable component to facilitate reference to a neighbouring index in nextFocus
3. ** First configuring the reverse direction key to the end of the item**: e.g. first `.nextFocus({ up: 'item_${last}' })`, to get the orientation key up to the end of the item
4. **The last item is configured in a positive direction key to the first item**: `.nextFocus({ down: 'item_0' })`, for example, to get the arrows down and jump back to the first entry
5. **option Tab Cycle**: First `.nextFocus({ backward: 'item_${last}' })`, Last `.nextFocus({ forward: 'item_0' })`
6. ** Optimal focus visual feedback**: `onFocus` / `onBlur` toggle background colour or border to give users a clear view of the current focus item

```typescript
interface SettingItem {
  id: string
  title: string
}

@Entry
@Component
struct LoopFocusListDemo {
  private items: SettingItem[] = [
    { id: 'wifi', title: 'WLAN' },
id: 'bt', title: 'Bluetooth',
{id: 'display', type: 'Show and Brightness'},
♪ id: 'sound', title: ' Sound' ♪
♪ id: 'storage', title: 'store' ♪
  ]

  @State focusedIndex: number = -1

  build() {
    Column() {
Text('Standing (Keys Looping)')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      List({ space: 8 }) {
        ForEach(this.items, (item: SettingItem, index: number) => {
          ListItem() {
            Row() {
              Text(item.title)
                .fontSize(16)
                .fontColor(this.focusedIndex === index ? '#007DFF' : '#333333')
              Blank()
              Text('›')
                .fontSize(20)
                .fontColor('#999999')
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .borderRadius(8)
            .backgroundColor(this.focusedIndex === index ? '#E6F0FF' : '#FFFFFF')
/ / 1 Key: The only id for each ListItem internal component
            .id(`item_${index}`)
.onclick(()=>{/ * Click to enter the corresponding settings */})
            .focusable(true)
/ 2 Key: key loop - First click top to last item, last click bottom to first item
            .nextFocus({
/ / Intermediate: normal point to the adjacent index; first (index = = 0) press "up" to end
              up: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`,
/ / Intermediate: normal point to the adjacent index; last click "down" to jump back to the first entry
              down: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`
            })
Focus visual feedback
            .onFocus(() => { this.focusedIndex = index })
          }
        }, (item: SettingItem) => item.id)
      }
      .width('90%')
      .height('70%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24 })
  }
}
```

```typescript
/ Step: Support the directional key cycle + Tab cycle
/ / scene suitable for keyboard users with both the arrow keys and the Tab keys
ListItem() {
Row(){/* Idem*/}
    .id(`item_${index}`)
    .focusable(true)
    .nextFocus({
/ key loop
      up: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`,
      down: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`,
/ Tab cycle: press Tab for last entry
      forward: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`,
/ Shift+Tab Cycle: First click Shift+Tab to end
      backward: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`
    })
}
```

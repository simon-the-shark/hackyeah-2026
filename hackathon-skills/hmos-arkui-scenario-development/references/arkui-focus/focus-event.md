# Focus event scene

# SCENE-01 responding to the focusout

**Application scenario:** scenes requiring response in response to changes in the focus / in focus status of components, consisting of two types of claims: 1-drive UI switch - change of style or invisible support elements (e.g. floating labels, high-light input frames, prompting cases, in association with other components); 2 execution of assigned backsizing - Catalysing business logic (e.g. lost calibration input, submission/ suspense data, burial site reporting, eject search congregate, etc.) at focal / loss of focus. Often, there is a need for focused feedback or interaction between focused operations such as form input, search boxes, editable cards, etc.

** Core mechanism:** Responding to change in focus in the `onFocus` / `onBlur` (in conjunction with `onChange`, as necessary), common two paths: 1 change state variable (e.g. `@State` scaling, style switch) drives UI repainting, often with loss of focus combined with content determinations (the content is returned empty) and can be accompanied by `.animation()` smooth transition; 2 direct execution of assigned business back-up (checking, submission, burial point, thought request, etc.) without UI repainting. Both can coexist in the same echo.

## # Apply scene: address details sheet floating label

The address details page contains four input items: `Text` with `Stack`; the `Text` label is stacked on `TextInput`; the label is displayed in the input box in original size when not entered and without focus; `onFocus` is reduced and floated; and `onBlur` is restored when the contents are empty. This is a typical use for zooming up labels using a focus / focal event drive, with the same "Audience `onFocus` / `onBlur` Change Styles" writing that is moved evenly to other focus feedback scenarios such as high-lighted input frames and low-intensity tips.

** Steps to be taken:**

1. **Stack stacking TextInput and Text labels**: labels over input frames setting `hitTestBehavior(Transparent)` without intercepting touch
2. **onFocus Zoom-out Label**: `scaleTimes = 0.75` when input box is focused
3. **onBrur Restoration Label**: Recover `scaleTimes = 1` if the content is empty at focal
4. **onChange **: Synchronize update `scaleTimes` when content changes, recovers when empty and shrinks when content is available
5. **animation animation**: Add `.animation()` to the label to smooth the scaling transition

```typescript
@Component
struct UserInfoTextInput {
  componentId: string = '';
  @Link text: string;
  contentType: ContentType | undefined = undefined;
  label: ResourceStr | undefined = undefined;
  index: number = -1;
  @State scaleTimes: number = 1;
  @State currentIndex: number = -1;

  build() {
    Stack({ alignContent: Alignment.Center }) {
// 1 TextInput input box
      TextInput({ text: this.text })
        .id(this.componentId)
        .width('100%')
        .backgroundColor(Color.White)
        .contentType(this.contentType)
        .padding({ left: 12, top: 0, bottom: 0 })
        .selectionMenuHidden(true)
/ 3 Changed Content Link Label
        .onChange((value: string) => {
          this.text = value;
          this.scaleTimes = value === '' ? 1 : 0.75;
        })
/ 4 Focused: downscaling labels, focused indexing of records
        .onFocus(() => {
          this.scaleTimes = 0.75;
          this.currentIndex = this.index;
        })
/ 5 lost focus: reset label with empty content
        .onBlur(() => {
          if (this.text === '') {
            this.scaleTimes = 1;
          }
        })

// 2 Floating Tag Text
      Text() {
        Span('*').fontColor('#ff5000')
        Span(this.label)
      }
      .scale(this.index === this.currentIndex || this.text !== '' ? {
        x: this.scaleTimes,
        y: this.scaleTimes,
        centerX: 0,
        centerY: -80
      } : { x: 1, y: 1, centerX: 0, centerY: -80 })
      .animation({ duration: CommonConstants.ANIMATION_DURATION })
      .height(this.index === this.currentIndex ? 24 : undefined)
      .width('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .padding({ left: 12 })
    }
    .height(72)
  }
}
```

---

# SCENE-02 Specifies the default focus component (defaultFocus)

** Applicable scene: ** When containers (pages, bullet windows, semi-modulars, etc.) are loaded or activated, it is hoped that a component will automatically receive a focus and save the user the step of manually clicking.

** Core mechanism: ** Sets `.defaultFocus(true)` on target component, declaring it as the default focus component of the focus container in which it is located. When the container (page, bullet window, modulus, etc.) is loaded or activated, the system automatically assigns the focus to the component without the need for a user to click manually or to call `focusControl.requestFocus()` manually.

## # Apply scene: custom bullet window input box automatically focused

The comment input window (`CommentInputDialog`) uses `@CustomDialog` decorations to declare a custom bullet window, which contains an ZXXKEEP2ZX input box and a "publishing" button. When a bullet window is open, `TextInput` requires immediate focus so that the input method will eject automatically and the user can start input comments directly. This is the typical use of `defaultFocus` under a window container, where the same writing can be moved evenly to other containers, such as pages, molds, etc.

** Steps to be taken:**

1. **Communication of bullet window components using @CustomDialog**: `@CustomDialog` Decorators Declaration of components as custom bombs Window
2. **DefaultFocus (true)** on TextInput: declaration of the default focus component of the bullet window
3. ** Configure window layout**: Set anchor alignment rules through `RelativeContainer` layout input box and release button
4.** Process release logic**: Close the bullet window when clicking on the `publish` Noodles.

```typescript
import promptAction from '@ohos.promptAction';

/ / anchor point of component in relative layout id
const ID_TEXT_INPUT: string = "id_text_input";
const ID_TEXT_PUSH: string = "id_text_publish";

@CustomDialog
export struct CommentInputDialog {
  @State selectedImages: string[] = [];
  @State text: string = "";
  @Link textInComment: string;
  @State placeholder: string = "";
  controller?: CustomDialogController;
  publish: () => void = (): void => {};

  build() {
    Column() {
      RelativeContainer() {
        TextInput({ placeholder: this.placeholder })
          .height($r('app.integer.text_flow_root_text_input_height'))
          .padding({
            left: $r('app.integer.text_flow_root_text_input_padding_left'),
            right: $r('app.integer.text_flow_root_text_input_padding_right'),
            top: $r('app.integer.text_flow_root_text_input_padding_top'),
            bottom: $r('app.integer.text_flow_root_text_input_padding_bottom')
          })
          .margin({ right: $r('app.integer.text_flow_root_text_input_margin_right') })
          .onChange((textInComment: string) => {
            this.text = textInComment;
          })
/ Key: Declared as the default focus component of the bullet window, automatically focused and ejected when the bullet window is open
          .defaultFocus(true)
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            left: { anchor: "__container__", align: HorizontalAlign.Start },
            right: { anchor: ID_TEXT_PUSH, align: HorizontalAlign.Start }
          })
          .id(ID_TEXT_INPUT)

        Button($r("app.string.text_flow_publish"))
          .width($r('app.integer.text_flow_root_btn_width'))
          .height($r('app.integer.text_flow_root_btn_height'))
          .borderRadius(15)
          .backgroundColor($r('app.color.text_flow_color_red'))
          .fontColor(Color.White)
          .onClick(() => {
            if (this.controller) {
              this.textInComment = this.text;
              this.publish();
              this.controller.close();
              this.textInComment = "";
              promptAction.showToast({ message: $r('app.string.text_flow_reply_success') });
            }
          })
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            right: { anchor: "__container__", align: HorizontalAlign.End }
          })
          .id(ID_TEXT_PUSH)
      }
      .height($r('app.integer.text_flow_relative_container_height'))
    }
    .padding($r('app.integer.text_flow_column_padding'))
    .backgroundColor(Color.White)
.offset({y: 20}) / / Add y-axis offsets, otherwise the bullet window and input method will be free White
  }
}
```

---

# SCENE-03 Overwrite original focus box style (focusBox / stateStyles + outline)

**Applicable scene:**Any scene that needs to cover the system ' s default focus frame vision. When the components are focused, the system draws focus frames (colour, width, animation) in accordance with the default rules, but in practice there is often a need to replace, as drafts, the self-defined pure colour border, the dot/point border, the frame with a rounded angle, or to completely remove the focal animation with the system itself. Common claims include the removal of luminous (lighting) effects from TV devices/partial simulators, correction of system focus box colours overwhelmed, alignment of focus visions to the Zicard grid, and realization of the Material style with soft and focused edges.

** Core mechanism: ** `focusBox` is a focused border mapping capability provided by ArkUI to configure `margin`/`strokeColor`/`strokeWidth`. When the default effect does not meet expectations, it can be covered in two directions:

- **Program A (adjusted in focusbox)**: Retain `focusBox` syntax, overwrite the default drawing by parameters - for example, set `strokeWidth` as `LengthMetrics.px(0)` to hide the default side or side effects, or adjust ZXXKEEP3ZX to change the border colour. It is appropriate to simply remove some default effects and do not need to replace the drawing mechanism.
- **Program B(stateStyles + outline fully taken over)**: Use a `stateStyles` multi-state style (`normal` / `focused`) in conjunction with the external `outline` properties, bypassing ZXXKEEP4ZX to control its own focus visualization. `outline` supports `OutlineStyle.SOLID / DASHED / DOTTED`, `radius`, ZXXKEEP8ZX, `width`, which is more expressive. **Note: Once `outline`, `focusBox` is set, it will no longer take effect** and is suitable for a scenario that requires a complete replacement of the default effect.

** Steps to be taken:**

1. **Assumption of the extent of the coverage**: First, it is clear whether the wish is "a fine-tuned default frame" (colour/wide) or "a full replacement with a custom border". The former goes to Programme A and the latter to Programme B.
**Program A - Adjustment for FocusBox parameters**.
3. **Program B - stateStyles + outline takeover**: `normal` and `outline`, respectively declared using `stateStyles`, and `focused`, respectively, switch from `width` /`color` /`radius` / `style`, to the definition border on the focus.
**cillation statement**: `focusBox` and `outline`, `outline` have higher priority and `focusBox` is invalid - `focusBox` is not required for selection B.

```typescript

/ = = = scheme A: Keep focusBox and remove current effects (TV scene most commonly) = = = = =
Button('Button1')
  .width(140)
  .height(45)
. FocusBox({strokeWidth: LengthMetrics.px(0)})/ / will set the edge width to 0 and remove the fluid effect

/ = = = scheme B: stateStyles + outline fully defined focus style = = = = =
// Fits to scenes that require a dotted line/point/tangular angle, or want to completely replace the default focus box
Button('Button2')
  .width(140)
  .height(45)
  .stateStyles({
    normal: {
/ / Not focused: width 0, do not show sides
      .outline({
        width: 0,
        color: Color.Red,
        radius: 50,
        style: OutlineStyle.DASHED
      })
    },
    focused: {
/ / Focused: red dotted edge of width 5
      .outline({
        width: 5,
        color: Color.Red,
        radius: 50,
        style: OutlineStyle.DASHED
      })
    }
  })
```

---

# SCENE-04 Active Control Focus

** Applies scenario: ** Validation code input, OTP (one-time password), payment password, cell phone-numbered segment input, etc. Focus flow depends on business logic (input length, key event, click location), requiring active migration between boxes** and boxes** or clearing ** focus when clicking on space**.

** Core mechanism:** `getUIContext().getFocusController()` provides two core API:

- `requestFocus(key: string)`: On the initiative of component `.id()`, focus the specified component
-`clearFocus()`: Clear all focus of the current page

Unlike `defaultFocus` (passive declaration), `requestFocus` / `clearFocus` is ** called ** when running at the initiative of the conditions, and the focus is determined by business logic. Two APIs can be used in the same scene.

Application scene: FourTextInput

Four separate `TextInput` boxes, each allowing only one character to be entered. Covers 4 Focus Control Times:

♪ Time, time, trigger event ♪
|------|---------|---------|------|
|1 Page Load  `Row.onAppear` |`requestFocus('0')` | Automatically focus first input box, popup input method |
|2 Enter finished  `TextInput.onChange` |`requestFocus((index + 1).toString())` | Current frame full of 1 characters jump to the next frame
|3 Delete Backback |`TextInput.onDidDelete` |`requestFocus((index - 1).toString())` | Press Delete buttons when the current frame is empty, emptys a box and focuses on |
|4 Click Blank  `Column.onClick` |`clearFocus()` | Collapse input method and clear all focus |

** Steps to be taken:**

1. ** Unique id** for each TextInput setting: using `index.toString()` as id, `requestFocus` through id
2. **onAppear Initial Focus**: Call `requestFocus('0')` when page loading completes to automatically focus the first input box
3. **onChange 's high **: Call `requestFocus((index + 1).toString())` when judging input length 1 and not end box
4. **onDidDelete retreat**: current box** triggers again when the deletion key is empty**, emptys the last box and calls `requestFocus((index - 1).toString())`
5. ** Outer packagings on Crick Focus**: Call `clearFocus()` to lose focus and close the keyboard

```typescript
@Entry
@Component
struct FourTextInput {
  @State inputValue: string[] = ['', '', '', ''];
  @State inputEnable: boolean[] = [true, false, false, false];
  inputIndex: number[] = [0, 1, 2, 3];

  build() {
    Column() {
      Row() {
        ForEach(this.inputIndex, (index: number) => {
          RelativeContainer() {
            TextInput({ text: this.inputValue[index] })
              .fontSize('30vp')
              .textAlign(TextAlign.Center)
              .maxLength(1)
              .showPasswordIcon(false)
              .height(80)
              .border({
                width: 1,
                color: this.inputEnable[index] ? '#1b91e0' : '#999999',
                radius: 4,
                style: BorderStyle.Solid,
              })
Key: Set the only id, requestFocus through id
              .id(index.toString())
/ / 3 Delete Back: Press Delete key when the current box is empty, empty a box and focus on a box
              .onDidDelete(() => {
                if (this.inputValue[index].length === 0) {
                  if (index !== 0) {
                    this.inputValue[index - 1] = '';
                    this.inputEnable[index] = false;
                    this.inputEnable[index - 1] = true;
                    this.getUIContext().getFocusController().requestFocus((index - 1).toString());
                  } else {
                    this.inputValue[index] = '';
                  }
                }
              })
/ / / 2 Enter the next box after the focus has been completed:
              .onChange((value: string) => {
                this.inputValue[index] = value;
                if (value.length !== 1) {
                  return;
                }
                if (index !== 3) {
                  this.inputEnable[index + 1] = true;
                  this.inputEnable[index] = false;
                  this.getUIContext().getFocusController().requestFocus((index + 1).toString());
                }
              })
          }.layoutWeight(1).margin({ right: 5, left: index === 0 ? 5 : 0 })
        })
      }
/ / / / 1 first input box when loading page
      .onAppear(() => {
        this.getUIContext().getFocusController().requestFocus('0');
      })
    }
    .height('100%')
    .width('100%')
/ 4 Click to clear all focus (and close your keyboard)
    .onClick(() => {
      this.getUIContext().getFocusController().clearFocus()
    })
  }
}
```

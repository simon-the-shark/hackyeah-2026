
# Base UI scene

# Decorator Selection: Local UI Use @LocalBuilder, Global UI Use @Builder

** Based on only one dimension of "declaration position"**, select one according to Table II below (no middle area):

| Declaration position  Z must be bound by  ZXKEP0ZX |
|---|---|---|---|
| struct** Internal** (membership method) ** `@LocalBuilder` | always bound to ** the internal ** component ** the default UI structured split within this component, `this.xxx` |
** struct** external** (global function)** | `@Builder function` | no `this`, no independent status | empty position, general label, etc.** no status**, cross-component/cross file reuse **

** Core rules:**

- Written in struct**** `@LocalBuilder`.
- Written in struct** ** without relying on any component `this` →
- `@LocalBuilder` is used for the "Default Rendering Method within the Component" in all scenarios below.

# SCENE-01 Component UI Places

**Applied scene:** When an UI area within the component (e.g. menu bar, content area) wishes to display both the default style when the user is not imported and the user is able to cover it as needed. Through the `@BuilderParam` declaration placeholder/ slot and the initialisation of the component's own `@LocalBuilder` method, the component is exposed externally to the UI portal "Replaceable + Rounded " , avoiding the need for the user to visibly enter to lead to the sample code.

** Distinguished from the common member variable:** The common member variable can only carry basic data or object references and cannot carry UI clips; `@BuilderParam` receives a construction function that returns to UI, allowing the user to pass into any ArkUI declaration structure (state, event, sub-component) as a component sub-tree.

** Steps to be taken:**

1. ** Declares the default `@LocalBuilder` method**: `@LocalBuilder` membership method defined within components as the default rendering structure (e.g. `titleExpansionMenu` / `titleExpansionContent`), which can be achieved in space (without UI) or contain a placeholder structure (e.g. ZXXKEEP4ZX) as a user without entering placeholder/ slot
2. ** Declares `@BuilderParam` and binds default**: Declares placeholder / slot members with ZXXKEEP1ZX, aligns type signatures to `() => void`, initials the default value as a reference to the ZXXKEEP3ZX method in step 1 (e.g. ZXXKEEP4ZX) and allows users to automatically take bottom logic when they do not pass
3. **Pilot / slot called in `build()`**: Direct call to placeholder / slot function via `this.menu()` / `this.content()`, call position, i.e. UI embedded position, syntax is consistent with normal member method; UI tree declared within placeholder / slot is embedded for use in the tone
4. ** User overwrites as needed**: when exemplifying the component, then render the default `@LocalBuilder`; if new `@LocalBuilder` (local) or global ZXXKEEP2ZX (e.g. `TitleExpansion({ menu: this.customMenu, content: this.customContent })`) overwrites the default and achieves a "replaceable +-dived" external interface

```typescript
@Component
export struct TitleExpansion {
// General Member Variables, Main Title and Subtitle Properties, Dynamic Properties, etc.
  titleAttribute: TitleAttribute = new TitleAttribute(Constants.MEMO_TITLE, new TitleAttributeModifier());
  subTitleAttribute: TitleAttribute = new TitleAttribute(Constants.MEMO_SUB_TITLE, new SubTitleAttributeModifier());
  animationAttribute: AnimationAttribute = new AnimationAttribute(Constants.NORMAL_TITLE_HEIGHT,
    Constants.EXPAND_TITLE_HEIGHT, Constants.CONTINUE_PULL_THRESHOLD,
    Constants.TITLE_SCALE_MAX_VALUE, Constants.ANIMATION_DURATION);

/ 1/ Declaration placeholders/ slots: use the internal component @LocalBuilder as the default value for bottom rendering when the user is not moving
  @BuilderParam menu: () => void = this.titleExpansionMenu;
  @BuilderParam content: () => void = this.titleExpansionContent;

  build() {
    RelativeContainer() {
      RelativeContainer() {
        Column() {
          Text(this.titleAttribute.text)
            .attributeModifier(this.titleAttribute.attribute)
          Text(this.subTitleAttribute.text)
            .attributeModifier(this.subTitleAttribute.attribute)
        }

/ / 2 menu placeholder/ slot: Call this.menu() Rendering or default UI
        Column() {
          this.menu();
        }
        .id("titleImage")
        .height(Constants.ONE_HUNDRED_PERCENT)
      }

      List({ space: Constants.SEARCH_MEMO_SPACE }) {
        ListItem() {
/ 3 Content Placeholder/ Slot: Call this.content() Rendering or Default UI
          this.content();
        }
      }
    }
  }

/ ** Default Menu Style: Empty Bottom */
  @LocalBuilder
  titleExpansionMenu(): void {
  }

/ ** Default Content Style: Top of the Placebook */
  @LocalBuilder
  titleExpansionContent(): void {
    Column() {
      Text("Text")
    }
      .height(Constants.ONE_HUNDRED_PERCENT)
      .width(Constants.ONE_HUNDRED_PERCENT)
  }
}
```

---

# SCENE-02 Component Encapsulation scene

**Applicable scenario: **The self-defined UI module needs to be sealed as a stand-alone component or segment. ArkUI offers three different particle size containment options, and selects the appropriate decorator according to two dimensions:

- `@Component` / `@ComponentV2` components suitable for internal status management** - have their own state capability and can be embedded as stand-alone functional units (shopping vehicle commodity items, form entry items, open cards, etc.). The function of `@ComponentV2` is exactly the same as that of `@Component`, except for a different system of accompanying state decorators (V1 with `@State`/`@Prop`/`@Link`, V2 with `@Local`/`@Param`/`@Once`/`@Event`, etc.)
- `@Builder` suitable for achieving a simple UI-encapable segment** of the ** global — no independent state, defined as an external (`@Builder function xxx`) to be used across components/cross documents for non-state display segments (empty position, generic price labels, loading skeletons)
- `@LocalBuilder` is suitable to achieve a simple UI-encapsulated segment** in part** - No state of independence, defined as within the struct (membership method), only in the current component, not exposed, for small UI structured splits in this component

** Core mechanism:** All three can produce reusable UI modules, but with different capacity boundaries. `@Builder` is a parallel "global vs local" relationship with `@LocalBuilder` - the former declared to be called in a struct external cross-file, the latter declared only current components available within struct; neither has a separate state and is used solely for UI structural sealing. `@Component` and `@ComponentV2` are two generations of the same decorator, working in the same way and having the same ability, but they** are mutually exclusive** - the same struct can only be used in one, and the accompanying state decorator cannot be used in a mix.

** Selected decision tree:**

1. ** Need for internal state management? ** Yes (selection, quantity, roll-out, input, etc.) `@Component` or `@ComponentV2` (new project recommends V2, old project follows V1; both cannot be used)
2. ** No state, cross-document/cross-component envelope? ** Yes, global `@Builder function`
3. ** No state, only sealed in the current component? ** Yes, `@LocalBuilder`

** Steps to be taken:**

** Selected type according to “Need to internal state + containment range”**: one/three choice for decision tree with reference to top selection - Need internal state of `@Component` / `@ComponentV2`; non-state and cross-component, cross-file cover global `@Builder function`; non-state and only `@LocalBuilder` for current component
2. **Accomplishment of state-type containment units (`@ComponentV2` / `@Component`)**
3. **Achieving a global state-of-the-art segment (`@Builder function`)* *: declaration with parameters in ZXKEEP1Z; cross-file ZXXKEEP3ZX after `export`, transfer to different parameters, i.e. different outputs UI
4. **Accomplishment of a partial non-state segment (`@LocalBuilder`)**: declaration of membership method at state**,** directly read ZXXKEEP1ZX; ZXXKEEP2ZX with parameters to compress multiple duplicate structures within the component
5. ** Cross-file**: status component and global `@Builder` definition, `export` use; `@LocalBuilder` does not cross documents due to binding `this`

### # state package unit: @componentV2 (V2)

```typescript
/ / Encapsulation unit: self-banded, independently embedded in any parent (V2)
/ V1 Equivalent: @Component +@Require@Propdata / @State action / @watch('externalToggle') + Resume Member Variable
@ComponentV2
export struct UnitItem {
@Require
@Require

@Local action: boolean = false; / / 2
@Event on StateChange: (id: string, activ: boolean) = >void =() =>; / / 3

/ 4 V2 with @Monitor
  @Monitor('externalToggle')
  onExternalToggle(monitor: IMonitor): void {
    this.active = this.externalToggle;
    this.onStateChange(this.data.id, this.active);
  }

  build() {
    Row() {
      Text(this.data.title).fontSize(14).layoutWeight(1)
      Toggle({ type: ToggleType.Checkbox, isOn: this.active })
        .onChange((on: boolean) => {
          this.active = on;
          this.onStateChange(this.data.id, on);
        })
    }
    .padding(12)
  }
}
```

## # No status clip: @Builder (global) and @LocalBuilder (local)

```typescript
/ / Global no-state segment: definition outside struct, cross-file use (empty position, generic label, etc.)
@Builder
export function EmptyHint(text: ResourceStr) {
  Column() {
    Text(text).fontSize(14).fontColor('#999999')
  }
  .padding(20)
}

@Entry
@ComponentV2
struct HostPage {
  @Local items: ItemData[] = [];

  build() {
    Column() {
      if (this.items.length === 0) {
EmttyHint ('no data available')/ / Call Global
      }
This.Footer() / / Call this component
    }
  }

/ / Partially Non-state Snippet: Defined within struct, only current components are available and can be accessed directly from the outer layer
  @LocalBuilder
  Footer() {
Text (`total {this.items.length} item `).fontSize(12)
  }
}
```

---

# SCENE-03 component style reuse scene

**Applied scene:** There are a large number of duplicate style combinations on the page (the rounded card container, the "id + colour + bold + ellipsis" combination of the price text, the "background + font + round angle" combination of the main button, etc.), writing directly on each component would result in a large number of sample codes and subsequent changes of styles would have to be changed from place to place. `AttributeModifier` Sealed " Style + Business Logic" as a reusable Modifuer object to support cross-file export, transfer, multi-state style and `if/else` business logic - with a better ability than ZXXKEEP2ZX/`@Extend` (the latter compile processing, not supporting cross-document export, not supporting business logic).

** Core mechanism:** Achieving `AttributeModifier<T>` interface, a broad `T` determines the range of components to function in the style. Generic styles (container appearance, layout alignment) are `CommonAttribute`, which can be hung up to any component; specific component exclusive styles (text fonts, graphic scaling, button form) use the Attribute type corresponding to the component (`TextAttribute`/`ImageAttribute`/`ButtonAttribute`). Set properties in `applyNormalAttribute(instance)` by `instance` chain; need to pass + member variable load by tectonic function in a style that changes parameters; automatic re-starting of `applyNormalAttribute` when the component is initially initialized or the association status variable changes. An example of a Modiifier can be hung over multiple components for reuse.

** Selected decision tree:**

1. ** Do styles bind specific component types? ** Attribute type (e. g. `TextAttribute`) of ZXKEP0ZX set to Modifier (Text/Image/Button)
2. ** Is it a generic style (not related to the type of component)? ** `T` set to ZXXKEEP1ZX with any component to hang
3. ** Need to change by parameters? ** is → tectonic + Member Variable, read in `applyNormalAttribute` (parametrically supported, not limited as `@Styles`)
4. ** Need cross-document reuse? ** is `export` Modiifier class (`@Styles`/`@Extend` cannot cross file)
5. ** Need to press pressure/focus/disable/select multi-state styles? ** Yes `applyPressedAttribute`/`applyFocusedAttribute` etc.

** Steps to be taken:**

** Reconciling Style Re-use **: First list all re-emerging style units on the page, and judge the two dimensions on a case-by-case basis — "Whether or not to bind specific components" (deciding whether Modifeier's broad `T`) and "Whether or not to engage in tectonic functions " . The examples are grouped as follows:

| Style Unit | Whether or not to bind specific components | Whether to pass on |
   |---------|---------------|-----------|
| General card container (white base / round corner / inner margin) | No (can be attached to any container) | No (look fixed) |
| Block / Bar Background (Due + Fixed Height) | No (can hang any container) | No
| Puts emphasis on text (word + colour + bold) | (text only) | (word, colour and scene) |
| Thumbnail (wide-high + rounded) | (Image only) | (rounded by scene) |
| Main Operations button (background colour + round corner) | (Button only) | (background colour scene) |

Direction to be taken from the table:** Tie specific components** pane `T` to the Attribute type (`TextAttribute` / `ImageAttribute` / `ButtonAttribute`);** Do not bind** `T` to `CommonAttribute` and can hang any component;** Need cross-reference** Constructive transfer + Member Variable Loading ** Do not need ** Direct examples to be used.

2. **Accomplish `AttributeModifier<T>`**: Use `applyNormalAttribute(instance)` in `applyNormalAttribute(instance)` to set attributes; need to pass + public member variable load by tectonic function in a style that changes parameters
3. **decided field**:  Z definition of `export` to cross file external; current page only without external exposure No export, private in file
4. ** exemplify and mount**: component holds Modifeier instance** (one example can be mounted on multiple components), `build()` mounts with `.attributeModifier(this.xxx)`; parameters can be repeated multiple times once they have been created in a fixed style, depending on `new`
5. ** (optional) Multi-state Style**: Additional `applyPressedAttribute` / `applyFocusedAttribute` / `applyDisabledAttribute` by pressure / focus / disable / selection

#### Define Modifuier: General packaging / Parametric exclusive / Page Private

```typescript
/ / 1 Generic packaging style: T = CommonAttribute, which can be hung to any component such as Row/Column
export class CardModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor(Color.White).borderRadius(16).padding(12);
  }
}

/ / 2 Parametric Exclusive Style: T = TextAtribute, tectonic transfer ( character, colour)
export class EmphasizedTextModifier implements AttributeModifier<TextAttribute> {
  public size: number;
  public color: ResourceColor;
  constructor(size: number, color: ResourceColor) {
    this.size = size;
    this.color = color;
  }
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(this.size).fontColor(this.color).fontWeight(FontWeight.Bold);
  }
}

/ 3 Page Private Styles: Not Exported, Only Current Files Available
class SectionModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor('#F5F5F5').height(56);
  }
}
```

#### Member variable holds examples and remounts

```typescript
@Entry
@Component
struct StyleDemoPage {
/ / Member variable holds the Modiffier instance: parameters are fixed and can be reused on multiple components once created
  private cardModifier: CardModifier = new CardModifier();
  private sectionModifier: SectionModifier = new SectionModifier();
  private titleModifier: EmphasizedTextModifier = new EmphasizedTextModifier(16, '#333333');
  private priceModifier: EmphasizedTextModifier = new EmphasizedTextModifier(18, '#FF4D4F');

  @LocalBuilder Item(title: string, price: string) {
    Column() {
Text(title).attributeModifeier//TextAttribute (repeated with the same, different examples)
      Text(price).attributeModifier(this.priceModifier)   // TextAttribute
    }
.attributemodifier (this.cardmodifier) / /CommonAttribute packaging
  }

  build() {
    Column() {
      Row() {
Text
      }
.attributemodifier (this.sectionmodifier) / /CommonAttribute packaging

This. Item ('unit A', '¥99') / / The same Modife example has been repeated several times
This.Item
    }
  }
}
```

---

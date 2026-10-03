# State management V1 & V2 mixed scene

# Profile

Before API version 19, mixed scenes were relatively stringently verified. Starting with API version 19, the constraints on state management of V1 and V2 mixed scenes have been reduced, while new methods are available V2compatibility and makeV1Observed to help solve the problem of mixing.

In the absence of an explicit requirement to mix V1 and V2 status variables, self-decision and inference use of the mix is prohibited, and relocation is preferred.

> ** Annotations:**
> This paper uses "sing" to represent the transmission of variables, such as "V1→V2" and "V1" to the V2 status variable.

# Directory

1. [V1 use V2 custom components] (#V1 use V2 self-defined components) I'm not sure.
- 1.1 [V2 component-API19 in V1] (#V1 V2 component-API19)
- 1.2 [Use V2 components in V1 - API19 et seq.] (#V1 use V2 components - API19 et seq.)

2. [Customs for V1 in V2] (#V2 for V1) I'm not sure.
- 2.1 [V2 before V1-API19] (#V2 before V1-API19)
- 2.2 [V2 uses V1 components API19 et seq.] (#V2 uses V1 components-API19 et seq.)

---

# V1 custom components using V2

**API19 comparison**

API19 and beyond
|------|---------|-------------|
|V1→V2 Simple Type |`@Param` Direct Receiver  ZXXKEEP1ZX Direct Receiver (No change)|
|V1→V2Class|Errored, requiring a bridge component |`enableV2Compatibility` for direct transmission to see first floor
|V1→V2@Observed+@Track class|
|V1→V2Inline Type (Array)
|V1→V2-D2-Systems
| V1→V2 Embedded Type | Only @ObjectLink split |`makeV1Observed` layer by layer package +ZXKEEP1Z Depth observation +ZXKEEP2Z split |
New interface  Z `enableV2Compatibility`, `makeV1Observed`|
There's no problem with not using an interface.

# # V1 uses V2 components - API19

**Scene ID:** STATE MIXED V1V2 01

** scene description:** In the electronics commodity details page, the V1 parent component manages the commodity information (trade names, scores, author details, commodity labels), requiring the embedding of multiple V2 sub-components to display information on different dimensions. Owing to the typologies of V1→V2 data transmission before API19, different adaptation options are needed for different data types: simple type of direct transmission, @ObservedV2 as normal variable, @Observed through bridge component, embedded object through @ObjectLink split, inner type only to remove decorator as normal variable.

** Solution: ** API19 preV1→V2 only supports simple types (boolean, Number, Stiling, Null, undefined) to @Param; @ObservedV2+@Trace decorated class need to remove the V1 decorator to pass to @Param as a normal variable; @Observed decorator needs to transit through the bridge assembly mode (V1@watch #V2@ObservedV2 case →V2 component); embedded objects are unable to observe changes in V2 via @ObprojectLink molecule components @ObservedV2+@Trace objects.

```
V1 parent component
Ideas - Do Not Transmit Variables - - V2
No limit on the use of V2 components in V1 without transmitting variables
  │
Idea - Simple Type (ProducingName, Raising) - (@Param) - V2 ProductionRatingView
│ Support only boolean/number/string/null/undefined
@state and V1 decorator type and internal type will be compiled Wrong.
  │
Ideas - @ObservedV2+@Trace(AuthorDetain) - (Agent Variable) - →V2 AutoDetailView (@Param)
Unable to decorate in │V1 @state as a normal variable
@Trace properties change can be observed in depth by V2 @Param
  │
Ideas - @Observed(ProductModelV1) - (Bridging Component) - V2 PRODUC MOdelV2
@ Three steps: define a V2 case  @ Watch listens  @ V2 component uses a single case
@Param receiving @observed
  │
→V2 AutoV2View (@Param)
@ State only observes the first layer  @
@Param Deep Observation Inner Layer@Trace Properties, @ObjectLink and @Param quote the same object
  │
Array < Number> races - (ordinary variable) - V2 ProductionRatingListV2 (@Param)
@state: @state
V2 cannot observe changes (push/modification arrays do not trigger refreshing)
```

####1. Define data categories - Commodity information, author details and label lists

```ts
/ / Commodity Master Information: @Observed Decoration, for V1 components and embedded object scenes
@Observed
class ProductInfo {
@Track public protectionName: string = 'smart phone Pro'// First Name
@Track public racing: number = 4.5//
@Track public mouthor: AutoDetail = new AutoDetail() // Inner Embedded Author Details
}

// Author details: @ObservedV2+@Trace Decoration for V2 deep observations
@ObservedV2
class AuthorDetail {
@Trace public orderName: string = 'Lee Ming'// Author First Name
@Trace publicauthorLevel: number = 5 // Impact index
Public biography: string = 'senior digital blogger' / / non@Trace, unobservable
}

/ / Side side of bridge mode V1: @Observed Decoration for V1 data source in bridge component
@Observed
class ProductModelV1 {
@Track public protectionName: string = 'smart phone Pro'
  @Track public rating: number = 4.5

  constructor(productName: string, rating: number) {
    this.productName = productName
    this.rating = rating
  }
}

/ / Side of Bridge Mode V2: @ObservedV2 for the V2 receiving end of the bridge component
@ObservedV2
class ProductModelV2 {
  private static singleton_: ProductModelV2
  @Trace public productName: string = ''
  @Trace public rating: number = 0

  private constructor() {}

  static instance(): ProductModelV2 {
    if (!ProductModelV2.singleton_) {
      ProductModelV2.singleton_ = new ProductModelV2()
    }
    return ProductModelV2.singleton_
  }
}
```

Key points: `ProductInfo` uses ZXKEEP1Z+XKEEP2ZX decorations to fit V1 observation systems; `AuthorDetail` uses `@ObservedV2`+`@Trace` decorations to fit V2 depth observation capabilities. `ProductModelV1` is the V1 data source for the bridge mode and `ProductModelV2` is the V2 single-case receiver for the bridge mode. Two decorator systems cannot be mixed: the V1 decorator (`@State` et al.) cannot be used with `@ObservedV2` (miscryption) and the V2 decorator (`@Local` et al.) cannot be used with `@Observed` (miscration).

2. Non-transmission of variables and simple type of delivery - V2 status badge component and rating presentation

```ts
/ V2 component: Unlimited not to transmit variables, independently manage internal state
@ComponentV2
struct ProductStatusBadge {
@Localstatus: string = 'Sale'

  build() {
Text (`Commodity State: ${this.status}')
      .fontSize(16)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
.backgroundColor (this.status = = 'sale'?'#4CAF50':'#F44336')
      .fontColor(Color.White)
      .borderRadius(12)
      .onClick(() => {
This.status = this.status = 'sale'? 'Sale': 'Sale'
      })
  }
}

/ V2 component: simple type status variable to receive V1 transmission
@ComponentV2
struct ProductRatingView {
  @Param productName: string = ''
  @Param rating: number = 0

  build() {
    Column() {
Text (`V2 Commodities: ${this.productName} ')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row() {
Text
          .fontSize(18)
          .fontColor('#FF9800')
        Text('/ 5.0')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

// V1 parent component: display of state badges and scoring with V2 subcomponents
@Entry
@Component
struct ProductDetailPageV1Simple {
@state preventionName: string = 'smart phone Pro'
  @State rating: number = 4.5

  build() {
    Column({ space: 15 }) {
Text (`Commodity Details Page ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ / Non-transmit variables: V2 components in V1 are not restricted
      ProductStatusBadge()

/ / Pass Simple Type: V1
      ProductRatingView({ productName: this.productName, rating: this.rating })

/ / Parent component modification simple type, V2 sub-component synchronized update
      Row({ space: 10 }) {
Button ('Modified Rating'). onClick(()=> {This.wing++})
Button ('change of name').onClick() = { This.productName = 'Max'})
      }
    }
    .padding(20)
  }
}
```

Key points: The use of V2 components in V1 does not transmit variables without any limitations, including components that import `@ComponentV2` decorations from third parties. When transmitting simple-type state variables (boolean, number, string, Null, undefined), V2 can simply receive with `@Param`. However, prior to API19, the type of mass or built-in (Array, Map, Set, Date) that passes the decorations of `@Prop`, `@Link`, `@ObjectLink`, `@Provide`, `@Consume`, and V1 decorations, such as `@State`, will cause errors in the compilation.

###3 Pass@ObservedV2+@Class with Trace decorated #######3 Pass

The observation capacity of `@ObservedV2`+`@Trace` is independent of the V1/V2 decorator and is supported in both V1 and V2. However, V1 cannot be used in conjunction with V1 decorations (e.g. `@State`) and must be transmitted as a normal variable to V2 `@Param`.

```ts
/ / AutoDetail has been defined in Step 1 (@ObservedV2 + @Trace)

// V2 component: Receiving @ObservedV2+@Class for Trace Decoration, @Param Depth Observation@Trace Properties Change
@ComponentV2
struct AuthorDetailView {
  @Param author: AuthorDetail = new AuthorDetail()

  build() {
    Column() {
Text
        .fontSize(18)
.onClick(() => {this.author.authorName + = '!'} / @Trace is visible, trigger refreshing
Text
        .fontSize(16)
.onClick(() => {this.author.authorLive+}) // @Traceable, trigger refreshing
/ biography is not @Trace Decoration, modification does not trigger refreshing
Text
        .fontSize(14)
.onClick(()=> {this.author.biography+= '!'} / do not trigger refreshing
    }
    .padding(10)
    .backgroundColor('#e3f2fd')
    .borderRadius(8)
  }
}

/ / V1 parent component: @ObservedV2+@Trace
@Entry
@Component
struct ProductDetailPageV1ObservedV2 {
/ / State order: AutoDetail = new AutoDetail() / / Compile error! V1 Decorator cannot be used with @ObservedV2
author: AutoDetail = new AutoDetail() / / Correct: passed as a normal variable

  build() {
    Column({ space: 15 }) {
Text (`Commodity Details Page - Author Information ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ V1 as a normal variable, @Trace attribute changes can be observed (dependent on @ObservedV2+@Trace's own capabilities)
Text
        .fontSize(20)
        .onClick(() => { this.author.authorName += '!' })

/ / Passed to V2 @Param, @Trace properties changes can be observed in depth
      AuthorDetailView({ author: this.author })

Button. onClick() = {
This.author.authorName = " Wang Fong"//V1 and V2 components are updated
      })
    }
    .padding(20)
  }
}
```

Key points: V1 Decorators (`@State`, etc.) cannot be used with `@ObservedV2` (miscruited) and V1 Decorators must be removed as normal variables. The observation capacity of ZXKEEP2Z+XKEP3ZX is independent of the V1/V2 decorator, and changes in ZXXKEEP4ZX properties can trigger UI refreshing when used as a normal variable in V1. Changes in ZXKEP6ZX properties after `@Param` passed to V2 can be observed at V2 depth.

###4 Transfer@ObservedClass - Bridge Component Mode

When V1 passes `@Observed` decorations to V2, it cannot be received directly with `@Param`. The bridge component model is required: the V1 bridge component monitors data changes with `@Watch`, synchronizes data with the ZXKEEP3Z case of V2, and the V2 component uses a single case.

```ts
/ ProjectModelV1 and ProjectModelV2 are defined in Step 1

/ V1 Bridge Component: Listen to V1 data changes, synchronize to V2 case
@Component
struct ProductBridgeComponent {
@Sate@watch('onProdutChange')produtV1:ProdectModelV1 = newProdutModelV1

  onProductChange() {
// Sync V1 data to V2 case
    ProductModelV2.instance().productName = this.productV1.productName
    ProductModelV2.instance().rating = this.productV1.rating
  }

  build() {
    Column({ space: 15 }) {
Text (`V1 Original Data: {this.productV1.projectName} - Rating $ {this. regulationV1. Rating}')
        .fontSize(18)

Button. onClick(() = {
This. policyV1. regulationName = 'the flagship phone Max' // Trigger@watch → V2 case update @ V2 component refresh
      })

Button ('V1 modified rating'). onClick() = {
This.projectV1.
      })

// V2 Operational Component Use of Individual Data
      ProductV2Comp()
    }
    .padding(20)
  }
}

/ V2 Operational Component: Direct V2 case
@ComponentV2
struct ProductV2Comp {
  private v2Model: ProductModelV2 = ProductModelV2.instance()

  build() {
    Column() {
Text (`V2 Component: ${this.v2Model.projectName} - Rating ${this.v2Model.wing} ')
        .fontSize(18)

Button ('V2 modified rating'). onClick() = {
This.v2Model.ering = 5.0 / / V2 component refreshed (@Trace
      })
    }
    .padding(10)
    .backgroundColor('#e8f5e9')
    .borderRadius(8)
  }
}

/ V1 portal component
@Entry
@Component
struct ProductDetailPageV1Bridge {
  build() {
    Column({ space: 15 }) {
Text (`Commodity Details Page - Bridge Mode ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ V1 component directly to bridge component
      ProductBridgeComponent()
    }
    .padding(20)
  }
}
```

Key points: When ZXKEEP0ZEX decorations are handed over to V2 by the API19 ex-V1 Class through the bridge assembly mode, in three steps: 1) define V2 case VewModel (ZXKEEP1Z+`@Trace`) and the private constructor ensures the individual case; 2) V1 bridge component listens to V1 data changes with `@Watch`, giving the data value to V2 single attribute; 3) V2 business component directly uses V2 case examples and ZXKEP4Z property changes can be observed. Data flow: V1 modified data → bridge component `@Watch` triggered → V2 single case attribute → V2 component refreshed.

####5 Pass Embedded Object @ObjectLink Split @ObservedV2+@Trace

In the embedded object scene, the `@State` of V1 can only observe changes in the first layer, with deep changes requiring the dismantling of molecular components through `@ObjectLink`. ZXKEEP2Z+XKEP3ZX objects passed to V2 can be observed in depth.

```ts
/ ProjectInfo (@Observed) and AutoDetail (@ObservedV2) have been defined in Step 1

/ V2 component: Receiving inner layer@ObservedV2+@Trace object, @Param Depth observation@Trace properties change
@ComponentV2
struct AuthorV2View {
  @Param author: AuthorDetail = new AuthorDetail()

  build() {
    Column() {
Text
        .fontSize(18)
.onClick(() => {this.author.authorName + = '!'} / @Trace is visible, trigger refreshing
Text
        .fontSize(16)
.onClick(() => {this.author.authorLive+}) // @Traceable, trigger refreshing
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

// V1 component: @ObjectLink split to observe changes in inner layer properties
@Component
struct ProductV1DetailView {
  @ObjectLink product: ProductInfo

  build() {
    Column() {
Text
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })
Text (`V1- Rating: ${this.project.wing} ')
        .fontSize(16)
        .onClick(() => { this.product.rating++ })

/ / Pass the inner layer @ObservedV2 object to the V2 component, @Param deep observation
      AuthorV2View({ author: this.product.author })
    }
    .padding(10)
    .backgroundColor('#e3f2fd')
    .borderRadius(8)
  }
}

/ V1 parent component: @State only observes the first layer, and deep changes require /ObjectLink split
@Entry
@Component
struct ProductDetailPageV1Nested {
  @State product: ProductInfo = new ProductInfo()

  build() {
    Column({ space: 15 }) {
Text (`Commodity Details Page - Embedded Object ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ / State can only observe changes in the first layer: general value of producName can be refreshed here
/ /author. authorName does not refresh here (second floor)
Text
        .fontSize(20)

/ / See changes in the inner layer by @ObjectLink split
      ProductV1DetailView({ product: this.product })

Button. onClick() = {
        this.product.author.authorName += '!'
/ / State does not refresh parent components here, but @ObjectLink and @Param can observe and refresh subcomponents
      })

Button. onClick() = {
        this.product.productName += '!'
/ /Sate can observe first floor, both parent and @ObjectLink sub-component updated
      })
    }
    .padding(20)
  }
}
```

Key points: `@State` can only observe changes in the first layer (e.g. `product.productName`) in the embedded object scene, and changes in the deep layer (e.g. `product.author.authorName`) are to be observed through ZXXKEEP3Z molecule components. ZXKEEP4Z+`@Trace` Object (`AuthorDetail`) in the inner layer can be observed in depth after it is passed to V2. `@ObjectLink` and `@Param` refer to the same object and the modifications are updated with each other - the V1 component changes `author.authorName`; the V2 component changes `author.authorName`; and the V1 `ProductV1DetailView`.

####6 Transfer Internal Type - Not Supported Before API19

Before API19, the state variable of V1→V2 (Array, Map, Set, Date) for the transfer of the built-in type (Array, Map, Set, Date) can lead to an incorrect translation. The V1 decorator can only be removed as a normal variable, but changes cannot be observed in V2.

```ts
/ V2 component: the type of built-in to receive a general variable transfer, which cannot be observed
@ComponentV2
struct ProductRatingListV2 {
  @Param ratings: Array<number> = []

  build() {
    Column() {
Text
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      ForEach(this.ratings, (item: number, index: number) => {
Text (`rated {index + ')
          .fontSize(14)
      })
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}

/ V1 parent component: Inline type can only be removed
@Entry
@Component
struct ProductDetailPageV1BuiltIn {
@state preventionName: string = 'smart phone Pro'
/ / State Raisings: Array<nomber> = [4.5, 4.0, 5.0] // Compiled error! API19 preset type does not support transmission to V2
Races: Array<number> = [4.5, 4.0, 5.0] / / Correct: Remove@state as normal variable

  build() {
    Column({ space: 15 }) {
Text (`Commodity Details Page - Internal Type ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

Text
        .fontSize(20)

/ / pass to V2, V2 as a normal variable and cannot observe changes in radiants
      ProductRatingListV2({ ratings: this.ratings })

/ / The following operation does not trigger V2 component refreshment (ratings are common variables, no observation capability)
      Row({ space: 10 }) {
Button ('New Rating'). onClick() = >
          this.ratings.push(4.8)
/ V2 component will not be refreshed, because atings are not state variables
        })
Button. onClick()=>
          this.ratings[0]++
/ V2 component not updated
        })
      }
    }
    .padding(20)
  }
}
```

Key points: Before API19, the state variable for the V1→V2 transmission of the built-in type (Array, Map, Set, Date) leads to an incorrect translation. The V1 decorations (e.g. `@State`) can only be removed from the `@Param`, which is transmitted to V2 as a normal variable, but internal changes cannot be observed in V2 (push, modification of arrays, etc. will not trigger the retrofit of V2 components). ZXKEEP2Z+XKEEP3ZX should be observed until API19 and later.

# # Data flow to summary #

```
V1 parent component
Ideas - Do Not Transmit Variables - - V2
No limit on the use of V2 components in V1 without transmitting variables
  │
Idea - Simple Type (ProducingName, Raising) - (@Param) - V2 ProductionRatingView
│ Support only boolean/number/string/null/undefined
@state and V1 decorator type and internal type will be compiled Wrong.
  │
Ideas - @ObservedV2+@Trace(AuthorDetain) - (Agent Variable) - →V2 AutoDetailView (@Param)
Unable to decorate in │V1 @state as a normal variable
@Trace properties change can be observed in depth by V2 @Param
  │
Ideas - @Observed(ProductModelV1) - (Bridging Component) - V2 PRODUC MOdelV2
@ Three steps: define a V2 case  @ Watch listens  @ V2 component uses a single case
@Param receiving @observed
  │
→V2 AutoV2View (@Param)
@ State only observes the first layer  @
@Param Deep Observation Inner Layer@Trace Properties, @ObjectLink and @Param quote the same object
  │
Array < Number> races - (ordinary variable) - V2 ProductionRatingListV2 (@Param)
@state: @state
V2 cannot observe changes (push/modification arrays do not trigger refreshing)
```

---

# # V1 uses V2 components-API19 and beyond

**Scene ID:** STATE MIXED V1V2 02

**Scene description:** Electrician Commodity Details Page, V1 parent component manages commodity information (trade names, scores, author details, label groups) and V2 sub-components are required to display commodity details and author information. The same scene as before API19, however, API19 then simplified the data transfer of V1→V2 through `enableV2Compatibility` and `makeV1Observed`, without bridging the components.

** Solution:** Use **`enableV2Compatibility` to make the V1 state variable visible in V2** + **`makeV1Observed` package the general object as V1 detectable **, directly to V2 `@Param` without the need for a bridge-to-construct module mode.

> ** Annotations:**
> Starting with API version 19, developers can use `UIUtils.enableV2Compatibility` and `UIUtils.makeV1Observed` interfaces to solve V1→V2 mixing problems. `enableV2Compatibility` makes the V1 status variable compatible with the V2 observation capability; `makeV1Observed` packages unobservable objects as V1 observable objects and returns values can be initialized by `@ObjectLink`.

```
V1 parent component
→V2@Param (observable level 1)
│ Suggested to be called in the V2 component configuration: SubcompV2 ({param: UIUtils.enableV2Compatibility})
  │
→V2@Param (no makeV1Observed)
@Track property V1/V2 is visible, not @Track property V1 UI running error, V2 not reporting error but not responding to update
  │
  ├── ratings(Array<number>) ──(makeV1Observed+enableV2Compatibility)──→ V2 @Param
│ MakeV1Observed packaged V1 state variable →enableV2compatibility allows V2 to be observed → and avoid double representation
  │
Ideas - tagGroups - (makeV1Observed +enableV2compatibility) - V2@Param
MakeV1Observed
  │
→V2@Param+V1@ObjectLink
MakeV1Observed to ensure that every layer is a V1 state variable → availableV2compatibility depth observation
@Sate only watch first floor  @
Add data to makeV1Observed
```

Definition of categories of data - commodity information, evaluation, author details and labels Group

Five data categories need to be defined in the vendor ' s detail page scene to cover ordinary class, @Observed+@Track decorated class, built-in type, two-dimensional array and embedded-type transmission scenarios.

```ts
import { UIUtils } from '@kit.ArkUI'

// Knowledge point 1: Normal class, no decorator
class ProductClass {
Public policyName: string = 'smart phone Pro'
  public rating: number = 4.5
  public price: number = 3999
}

// Knowledge point 2: @Observed+@Track Decoration
@Observed
class ProductObservedClass {
@Track public protectionName: string = 'smart phone Pro'
  @Track public rating: number = 4.5
Public CompanyCount: number = 0/// Non@Track Properties
}

/ / Knowledge point 5 nesting type: rating sub-headings (most internal general class)
class RatingItem {
  public value: number = 0
  constructor(value: number) {
    this.value = value
  }
}

/ / Knowledge point 5 nesting type: Author details (ordinary class in the middle layer, with RatingItem arrays)
class AuthorDetail {
Public orderName: string = 'Li Ming'
  public ratings: Array<RatingItem>
  constructor(ratings: Array<RatingItem>) {
    this.ratings = ratings
  }
}

/ / Knowledge Point 5 Embedded Type: Commodity Details (Terrestrial Class, with @Track Properties and EmbeddedAuthorDetail)
class ProductDetail {
@Track public protectionName: string = 'smart phone Pro'
  @Track public author: AuthorDetail
  constructor(author: AuthorDetail) {
    this.author = author
  }
}
```

Key points: Data class design covers five transmission scenarios: (1) `ProductClass` is a regular class-free decorator; (2) `ProductObservedClass` uses ZXKEEP2Z+`@Track` decorations; (3) the built-in type `Array<number>` does not need to define a data class; (4) the two-dimensional array `Array<Array<string>>` does not need to define a data class; (5) the embedded type ZXXKEEP6ZX contains `AuthorDetail` containing ZXXKEEP8ZX, the three-tiered embedded structure displays the need for layer-by-floor packaging.

###2 Pass #enableV2 Compatibility makes V2 visible

When `@State` decorations of V1 are passed to V2, the `enableV2Compatibility` is called so that the V1 status variable can be observed in V2 `@Param` without the need for bridging components.

```ts
import { UIUtils } from '@kit.ArkUI'

class ProductClass {
Public policyName: string = 'smart phone Pro'
  public rating: number = 4.5
  public price: number = 3999
}

// V2 sub-component: Receive normal class
@ComponentV2
struct ProductV2DetailView {
  @Param product: ProductClass = new ProductClass()

  build() {
    Column() {
/ /enableV2compatibility allows V1 status variables to observe changes in the first tier properties in V2
Text (`V2 Commodities: $ {this.product.projectName} - Rating $ {this.project.wing} - $ {this.project.price} `)
        .fontSize(18)
        .onClick(() => {
/ V1 status variable can be observed in V2 and changes to the first level properties can trigger refreshing
          this.product.productName += '!'
        })
    }
  }
}

/ V1 parent component: using @state to manage normal class
@Entry
@Component
struct ProductDetailPageV1Api19 {
  @State product: ProductClass = new ProductClass()

  build() {
    Column({ space: 15 }) {
/ /V1@state observes changes in properties of the first layer
Text (`V1 Commodities: {this.product.produdName} - Rating $ {this.produce.rating} ')
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

/ / Call enabling V2 Compatibility to have V1 status variables in V2
/ / Suggest to call at V2 Component Structure instead of at @State Initial
      ProductV2DetailView({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

Key points: `enableV2Compatibility` allows `@State` variable of V1 to observe changes in the properties of the first tier in `@Param` of V2. It is proposed to call `enableV2Compatibility` (e.g. `SubCompV2({param: UIUtils.enableV2Compatibility(this.state)})`) at the V2 component structure instead of `@State` at initialization to avoid the need to call again manually when the overall value of the variable is assigned.

###3 Pass@Observed+@Track DecoratedClass — enablingV2compatibility without makingV1Observed

When `@Observed` decorations are passed on to V2, use `enableV2Compatibility` is sufficient (without `makeV1Observed`). The `@Track` properties are observed in V1 and V2; the non-ZXKEEP4Z properties are used in UI in V1 for running errors, and do not miss but respond to updates in V2.

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProductObservedClass {
@Track public protectionName: string = 'smart phone Pro'
  @Track public rating: number = 4.5
Public CompanyCount: number = 0/// Non@Track Properties
}

// V2 Sub-component: Receiving @Observed+@Track Decoration
@ComponentV2
struct ProductV2ObservedView {
  @Param product: ProductObservedClass = new ProductObservedClass()

  build() {
    Column() {
/ @Track property is visible in V2 and changes can trigger refreshment
Text (`V2 name: {this.project.projectName} - Rating $ {this.project.wing} ')
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })

// Non@Track Properties do not collapse in V2 but do not respond to updates
Text
        .fontSize(16)
.onClick(()=> {this.product.commentCount+})// do not trigger refreshing
    }
  }
}

// V1 parent component: use @State Management@Observed+@Track Decoration
@Entry
@Component
struct ProductDetailPageV1ObservedApi19 {
  @State product: ProductObservedClass = new ProductObservedClass()

  build() {
    Column({ space: 15 }) {
/ V1: @Track Properties Observable, Non-Track Properties Run Times in UI Wrong.
Text (`V1 Commodities: {this.product.produdName} - Rating $ {this.produce.rating} ')
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

/ @Observed Decorated Class, availableV2compatibility, without makingV1Observed
      ProductV2ObservedView({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

Critical point: `@Observed` decorated class do not need to call `makeV1Observed`, just `enableV2Compatibility`. ZXKEP3ZX properties can be observed in V1 and V2. Non-`@Track` property: UI used running error in V1 and no error was reported in V2 but did not respond to the update.

###4 Transfer Internal Type (Array) — makeV1Observed + enablingV2Compatibility

When V1 transfers to V2 the built-in type (Array), use `makeV1Observed` to package Array as a V1 state variable, and `enableV2Compatibility` to make V2 detectable and avoid double-agent problems.

```ts
import { UIUtils } from '@kit.ArkUI'

Sub-component / V2: Receiver of Array type
@ComponentV2
struct ProductRatingV2View {
  @Param ratings: Array<number> = [0]

  build() {
    Column() {
Array's internal element changes can be observed in / V2.
Text
        .fontSize(18)
        .onClick(() => {
/ Changes trigger V1 and V2 changes
          this.ratings[0]++
        })

Button ('V2 ') . onClick(() = >
        this.ratings.push(4.8)
      })
    }
  }
}

/ / V1 parent component: use @state to manage Array, makeV1Observed package with V1 status variable
@Entry
@Component
struct ProductRatingPageV1Api19 {
/ makeV1Observed package Array as a V1 state variable with return values to be initialized@ObjectLink
  @State ratings: Array<number> = UIUtils.makeV1Observed([4.5, 4.0, 5.0])

  build() {
    Column({ space: 15 }) {
Text (`V1 First Rating: ${this.ratings[0}})
        .fontSize(20)
        .onClick(() => { this.ratings[0]++ })

/ / When passed to V2, call available V2 Compatibility to avoid double representation
      ProductRatingV2View({ ratings: UIUtils.enableV2Compatibility(this.ratings) })
    }
    .padding(20)
  }
}
```

Key points: Array is packaged as a V1 state variable using `makeV1Observed`, and its return value can be initialized by `@ObjectLink`. Another ZXKEP2ZX allows V2 to be observed and avoids double representation. The non-use of `enableV2Compatibility` and `makeV1Observed` could lead to a problem of double representation, which would result in the same-status object being generated by both the V1 and V2 status management systems as a proxy object, giving rise to a logical conflict of listening.

###5 Transmit 2-dimensional arrays — makeV1Observed layer by layer

The two-dimensional array is to be packaged layer by layer with `makeV1Observed` as a V1 state variable, and the `enableV2Compatibility` is to be transferred to V2 by calling `enableV2Compatibility` to avoid double-agenting, and the new array element is to be packaged with `makeV1Observed`.

```ts
import { UIUtils } from '@kit.ArkUI'

// V2 sub-component: Receive 1-dimensional array (inner layer of 2-dimensional array)
@ComponentV2
struct ProductTagItem {
  @Require @Param tagArr: Array<string>

  build() {
    Row() {
      ForEach(this.tagArr, (item: string, index: number) => {
        Text(`${index}: ${item}  `)
          .fontSize(16)
      })
Button ('@Param Add Label'). onClick() = >
/ Observable array changes in V2
This.tagArr.push
      })
    }
    .padding(8)
    .backgroundColor('#f0f0f0')
    .borderRadius(4)
  }
}

// V1 parent component: Management of 2-dimensional arrays using @state, layer by layer, makeV1Observed packaging
@Entry
@Component
struct ProductTagPageV1Api19 {
/ makeV1Observed layer by layer
  @State tagGroups: Array<Array<string>> = [
UIUtils.makeV1Observed(['technology', 'programmed']),
UIUtils.makeV1Observed([' bestseller','hotdoor']),
UIUtils.makeV1Observed(['Recommended', 'Initiative'])
  ]

  build() {
    Column({ space: 15 }) {
Text
        .fontSize(20)

/ ForEach goes through two-dimensional arrays, and the inner-story arrays are transferred to a V2 callable V2compatibility
      ForEach(this.tagGroups, (tagArr: Array<string>) => {
        ProductTagItem({ tagArr: UIUtils.enableV2Compatibility(tagArr) })
      })

// Add new array elements to be packaged in MakeV1Observed
Button ('@state Add a new label group'). Oncick()=>
/ / The new inner layer arrays shall be packaged in makeV1Observed to ensure V2 is visible
This.tagGroups.push
      })

Button('@state changes the first label'). Oncick() = >
/ / Change inner layer array elements, V1 and V2 can be observed
        this.tagGroups[0][0] = 'TECH'
      })
    }
    .padding(20)
  }
}
```

Key points: The two-dimensional set of scenarios needs to be presented with a V1 status variable for the ZXKEEP0Z-packaging inner layer, which is passed to V2 by calling `enableV2Compatibility` in ForEach to avoid double representation. `makeV1Observed` will not be rolled over and will be packaged only for the first layer, so that the inner layer arrays will be manually packaged on a layer by layer basis. The new array elements shall be packaged in `makeV1Observed` to ensure V2 is detectable.

#### 6. Transfer nesting type — makeV1Observed layer by layer + enablingV2compatibility Depth observation

Embedded-types ensure that each layer is a V1 status variable (`makeV1Observed` layer by layer) and is passed to V2 with ZXKEEP1Z as a depth observation. `@State` can only observe changes in the first layer, with ZXKEEP3Z splitting or `@Param` required for deep depth observations with `enableV2Compatibility`. The new data need to be packaged in `makeV1Observed`.

```ts
import { UIUtils } from '@kit.ArkUI'

/ RatingItem, AutoDetail, ProdutDetail have been defined in Step 1

/ V1 sub-component: @ObjectLink to observe changes in inner layer properties
@Component
struct ProductNestedV1ObjectLink {
  @ObjectLink author: AuthorDetail

  build() {
    Column() {
// @ObjectLink observes changes in inner layer properties
Text (`@ObjectLink author: {this.author.authorName}})
        .fontSize(18)
        .onClick(() => { this.author.authorName += '!' })
    }
  }
}

// V2 sub-component: @Param for in-depth observation of available V2 Compatibility
@ComponentV2
struct ProductNestedV2View {
  @Require @Param product: ProductDetail

  build() {
    Column() {
@Param can observe changes in the first floor
Text (`@Param trade name: {this.produce.produceName} ')
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })

// @Param with availableV2compatibility to observe changes in the second layer in depth
Text (`@Param by: {this.product.author.authorName})
        .fontSize(16)
        .onClick(() => { this.product.author.authorName += '!' })

Button ('@Param Add Rating'). Onclick() = {
// Additional data to be packaged in MakeV1Observed to ensure V2 is visible
        this.product.author.ratings.push(UIUtils.makeV1Observed(new RatingItem(3)))
      })

Button. onClick(() = {
// Modify innermost properties, V2 can be observed in depth
        this.product.author.ratings[this.product.author.ratings.length - 1].value++
      })
    }
  }
}

// V1 parent component: layer by layer MakeV1Observed package to ensure that each layer is a V1 state variable
@Entry
@Component
struct ProductNestedPageV1Api19 {
/ / Make sure each layer is a V1 state variable: layer by layer
/ MakeV1Observed will not be carried over, packing only first floor
  @State product: ProductDetail =
    UIUtils.makeV1Observed(new ProductDetail(
      UIUtils.makeV1Observed(new AuthorDetail(UIUtils.makeV1Observed([
        UIUtils.makeV1Observed(new RatingItem(4)),
        UIUtils.makeV1Observed(new RatingItem(5))
      ])))
    ))

  build() {
    Column({ space: 15 }) {
/ /state can observe changes in the first layer
Text (`@state trade name: {this.produce.produceName})
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

/ / State could not observe changes in the second layer, but would be observed by @ObjectLink and @Param
Text (`@state by: {this.product.author.authorName})
        .fontSize(18)
        .onClick(() => { this.product.author.authorName += '!' })

/ / State only observes the first layer, with deep changes @ObjectLink split
      ProductNestedV1ObjectLink({ author: this.product.author })

/ / Call enabling V2 Compatibility for in-depth observation when passed to V2
      ProductNestedV2View({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

Key points: Embedded typologies are required to be packaged with V1 state variable by ZXKEEP0Z, and `makeV1Observed` will not be carried over to the first stage of implementation only. Call `enableV2Compatibility` for Depth Observation at transfer to V2. `@State` can only observe changes in the first layer, which require ZXKEEP4Z or `@Param` to be observed at depths with `enableV2Compatibility`. `@ObjectLink` and `@Param` refer to the same object and the changes are updated. Additional data will need to be packaged with `makeV1Observed` to ensure V2 is detectable.

---

# V2 custom components using V1

**API19 comparison**

API19 and beyond
|------|---------|-------------|
|V2→V1 Simple Type | `@State`/`@Prop`/`@Provide` Receiving | | |  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z  Z
|V2→V1Ass |`@State` Reception (one level only) |`enableV2Compatibility`+`makeV1Observed`+`@ObjectLink` (two-way connection)
@V2→V1@ObservedV2 class |V1 cannot be decorated, common variable+`@Trace` | pre-API19 (@ObservedV2 cannot be decorated with V1) |
@V2→V1@Observed class  @`enableV2Compatibility`+XKEEP1ZX|
@V2→V1 Internal Type @V2 Remove
|V2→V1 Embedded Type |V1@ObjectLink only |`makeV1Observed` Layer by Layer +`enableV2Compatibility` (V2 Depth Observation) +V1 Layer
New interface  Z `enableV2Compatibility`, `makeV1Observed`|


# # V2 Before using V1-API19

**Scene ID:** STATE MIXED V1V2 03

**Scene description: ** Out-of-sale order page, V2 parent component management order information (payment status, commodity information, order details, distribution labels), need to display the order details using V1 third-party component. Restrictions and adaptation options for the transmission of different types of data from V2 to V1 need to be addressed.

** Solution:** API19 preV2→V1 transmits a simple type of state variable, which V1 can only be received through `@State`, `@Prop`, `@Provide`; pass ordinary class passes can be accepted by V1`@State`, which can observe a change in class properties; pass ZXKEEP4Z+`@Trace` decorations, V1 cannot be received with a decorator (formation error) and rely on `@Trace` for independent observation only as a normal variable; pass inside type (Set, etc.), V2 decorations and V1 receivers need to be removed from `@Local` as a normal variable; and ZXKEEP8Z decorations are not supported by V2 decorations, and V2 cannot be used with ZXKEP9ZX as a common variable.

```
Home order page V2 father component@Local
→ V1 Orderstatus Comp (payment status)
│ Simple type, V1 received only by @state/@Prop/@Provide
@ Not supported@Link/@ObjectLink/@Consume
  │
Ideas -ProductInfo Common Class - (@State) -V1 ProductDetailcomp (Commodity Details)
│ V1 used @state receiving, can observe changes in class properties
  │
Ideas -orderInfo @ObservedV2+@Trace — (common variable) -V1 OrderDetailcomp (order details)
│V1 cannot receive with @state (miscruited) as normal variable
@ Reliance on @Trace's independent observation capability to refresh UI
@Trace Properties are visible, not new
  │
Ideas -Tags (Set<stream> built-in type) - (ordinary variable) -V1 OrderTagcomp (@Provide)
@V2 delete@Local as normal variable
│V1 received by @Provide, V2 cannot observe change
  │
└ -ProductObserved - -(not supported) -V1
V2 Decorators cannot be used with @Observed.
Only as a normal variable, no data connection is possible
```

Definition of categories of data - order information, commodity information and distribution labels

```ts
/ / Order Details Class: Using @ObservedV2+@Trace Decoration
@ObservedV2
class OrderInfo {
@Trace public orderId: string = 'ORD-20250101' / @Trace Decoration, change can be observed
@Trace public totalPrice: number = 36.8 / @Trace Decoration, change is visible
@Trace public disclosure benefit: number = 5.0 / @Trace Decoration, change visible
Public notes: string = 'Please lower spicy'/// Non@Trace, cannot observe changes
}

/ / Commodity information class: regular class, without any decorator
class ProductInfo {
Public productName: string = 'Yowl rice'
  public price: number = 28.8
  public quantity: number = 1

  constructor(productName?: string, price?: number, quantity?: number) {
This. preventionName = preventionName ? 'Chicken rice'
    this.price = price ?? 28.8
    this.quantity = quantity ?? 1
  }
}

// Commodity group: using @Observed Decoration (V1)
@Observed
class ProductObserved {
Public productName: string = 'Spicy pan'
  public price: number = 35.0
}
```

Key points: `OrderInfo` uses ZXKEEP1Z+XKEEP2ZX decorations, and changes in ZXKEEP3Z properties can be independently observed; `ProductInfo` is normal class, undecorated; `ProductObserved` uses `@Observed` decorations, which belong to the V1 decorations and cannot be used with V2 decorations.

####2 Transmit a simple type status variable @state/@Prop/@Provide

V2 can only be received through `@State`, `@Prop`, `@Provide` Decorator when transmitting simple type state variables (boolean, Nuber, sting, Null, undefined).

```ts
/ / Simulate the V1 component imported from the Triangular Library: Display payment status
@Component
struct OrderStatusComp {
/ V1 receives simple type status variables from V2, only @State, @Prop, @Provide
@state isPaid: oolean = false / / can observe changes

  build() {
    Column() {
Text (`Payment status: {this.isPaid? 'paid': 'to be paid'}')
        .fontSize(18)
        .fontColor(this.isPaid ? Color.Green : Color.Red)
// Unsupported
    }
  }
}

@Entry
@ComponentV2
struct FoodOrderPage {
@Local isPaid: Bolean = pay//V2 payment status

  build() {
    Column({ space: 12 }) {
Text (`out of order - payment status: ${this.isPaid? 'paid': 'to be paid'}
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

/ V2 Simple state variable passed to V1 component, received by @state
      OrderStatusComp({ isPaid: this.isPaid })

Button.onClick(()=> {This.isPaid= true}
Button. onClick(()=> {This.isPaid=false})
    }
    .padding(20)
  }
}
```

Key points: When V2→V1 transmits a simple type of state variable, V1 can only receive it through `@State`, `@Prop`, `@Provide`, and does not support `@Link`, `@ObjectLink`, `@Consume`. `@Link` follows its original initialization rule and can only be initialized by the V1 status variable.

# # # # 3. Pass Normal Class # @state receiving

When V2 transmits to V1 the normal class (not decorated by `@ObservedV2` or `@Observed`), V1 can use `@State` to receive a class change.

```ts
/ / Simulate V1 components imported from the Triangular Library: displaying commodity details
@Component
struct ProductDetailComp {
/ V1 Use@state to receive normal class to observe a class change
  @State product: ProductInfo = new ProductInfo()

  build() {
    Column() {
Text
        .fontSize(18)
Text
        .fontSize(16)
Text
        .fontSize(16)

/ / Modify First Level Properties, @State to Observe and Refresh
Button ('change of name').onClick()=> {this.project.productName= 'Red Bones'}
Button.onClick(()=> {this.product.price=32.}
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageProduct {
@Localproject: PRODECTInfo = new #PhotoInfo

  build() {
    Column({ space: 12 }) {
Text
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

Text (`V2 Commodities: $ {this.product.productName} $ {this.product.price}')
        .fontSize(18)

/ V2 Normal Class to V1
      ProductDetailComp({ product: this.product })
    }
    .padding(20)
  }
}
```

Key points: When V2→V1 transmits normal class, V1 uses `@State` for reception, and observation capability is the value attributed to the data itself and to the first layer of properties. The V1 component UI can be refreshed when the first tier properties of ZXKEEP1Z or `product.price` are modified.

###4 Transmit #ObservedV2+@Class decorated by Trace #V1 cannot be received with a decorator

V1 Decorator cannot be used with `@ObservedV2` (miscryption). The V1 component receives `@ObservedV2`+ZXKEP2ZX decorations, cannot use V1 decorations and needs to be received as a general variable, relying on the independent observation capability of `@Trace` to refresh UI.

```ts
/ / Simulate V1 component imported from the Triangular Library: display order details
@Component
struct OrderDetailComp {
/ / State order: OrderInfo = new OrderInfo()/ / Compil error! V1 Decorator cannot be used with @ObservedV2
Order: OrderInfo = new OrderInfo()/ / Correct: Receive as a common variable, rely on @Trace independent observation

  build() {
    Column() {
/ @Trace Properties Observable, modified to trigger UI brush New
Text
        .fontSize(18)
.onClick(() => {This.order.orderId = 'ORD-20250102'})// @Traceable, refreshable
Text
        .fontSize(16)
.onclick(()=> {this.order.totalPrice+=1}) // @Traceable
Text (`Property for distribution: ¥this.order.deliveryFee}')
        .fontSize(14)
.onClick(()=> {this.order.deliveryFee=6.}) // @Traceable

/ / Non@Trace Properties, changes do not trigger UI refresh
Text
        .fontSize(14)
.onClick(()=> {This.order.notes= 'More chili'} / /no refreshing!notesf@Trace
    }
    .padding(10)
    .backgroundColor('#e8f5e9')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageDetail {
  @Local order: OrderInfo = new OrderInfo()

  build() {
    Column({ space: 12 }) {
Text (`out-of-service order - order details ' )
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

/ /V2@Local Observable@Trace Properties Change
Text (`V2 Order: {this.order.orderId}`)
        .fontSize(18)
Text (`V2 Total Price: {this.order.totalPrice} ')
        .fontSize(16)

/ V2 status variable passed to V1, V1 as normal variable, dependent on @Trace observation
      OrderDetailComp({ order: this.order })
    }
    .padding(20)
  }
}
```

Key points: V1 decorators cannot be used with `@ObservedV2` (miscounting), and V1 components need to receive `@ObservedV2` as a normal variable. ZXKEEP2Z+XKEEP3ZX is independently active: changes in ZXXKEEP4ZX properties (`orderId`, `totalPrice`, `deliveryFee`) can be observed and updated in V1 and V2; changes in non-ZXXKEEP8Z properties (`notes`) cannot trigger UI refreshing.

####5 Transferr-Internal Type - Limit

The V2-V1 state variable decorator and the V1 receiver mutually revealed when transmitting the inner type (Array, Set, Map, Date). When V1 is received with a decorator, the built-in type does not support decoration in V2.

```ts
// Simulate the V1 component imported from the Triangular Library: Show distribution label
@Component
struct OrderTagComp {
/ V1 Use @ProvideReceiving Emplacement Set
  @Provide tags: Set<string> = new Set()

  build() {
    Column() {
Text
        .fontSize(16)
      ForEach(Array.from(this.tags.values()), (item: string) => {
        Text(`${item}`).fontSize(14).margin(4)
      })
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageTag {
/ /Local tags: Set<streaming > = new Set (['hot sale', 'news', 'full decrease']) / / Compiled error! The V2 Decorator and the V1 Receiving Decorator mutually reveal the inner type
/ Correct: Remove @Local as normal variable

  build() {
    Column({ space: 12 }) {
Text
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

/ V2 passed to V1, V1 for @State/@Prop/@Provide
/ / / but changes in tags cannot be observed in V2
      OrderTagComp({ tags: this.tags })
    }
    .padding(20)
  }
}
```

Key points: V2→V1 states variable decorations (`@Local` et al.) and V1 receivers (`@State`, `@Prop`, `@Provide`) are mutually repulsed when transmitting the built-in type. Solutions: V2 removes `@Local` as a normal variable, V1 is received using `@State`/`@Prop`/`@Provide`. However, changes in this variable cannot be observed in V2.

## ## 6. Passes@Observed Decorated Cass - not supported

The V2 status variable does not support the passing of `@Observed` decorations to V1. Decorators such as V2 ' s ZXKEEP1Z could not decorate `@Observed` (incorrected) and V2 ' s could not be used with `@Observed`.

```ts
@Entry
@ComponentV2
struct FoodOrderPageObservedErr {
/ /Local programObserved: ProductionObserved = new productObserved() // Compiled error! V2 Decorators cannot be used with @Observed
ProgramObserved: ProjectObserved =new effectObserved() / / Only as a normal variable cannot be linked to data

  build() {
    Column({ space: 12 }) {
Text
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

/ policyObserved can only be used as a normal variable
/ / Unable to transmit data connection to V1 component (V2 decorator cannot be used with @Observed)
Text
        .fontSize(18)
Text (`Pricing: {this.productobserved.price}`)
        .fontSize(16)
    }
    .padding(20)
  }
}
```

Critical point: V2 Decorator cannot be used with `@Observed` (miscounted). Before API19, V2→V1 passed the `@Observed` decoration class could not achieve data connection and could only be passed as a normal variable, and modification of properties would not trigger UI refreshing.

# # Data flow to summary #

```
V2 parent component
Ideas - Simple Type (isPaid) - (@state/@Prop/@Provide) - →V1 OrderStatuscomp
│ Support only boolean/number/string/null/undefined
│V1 does not support
@Link follows its original initialisation rule and can only be initialised by the V1 state variable
  │
Ideas -ProductInfo - (@state) -V1 ProjectDetailcomp
│ V1 used @state receiving, can observe changes in class properties
• Observation capability: data per se + first tier attribute
  │
Ideas - @ObservedV2+@TradeClass(OrderInfo) - (common variable) - →V1 OrderDetailcomp
│V1 cannot receive with @state (miscruited) as normal variable
@ Dependence on @Trace's independent observation capability: @Trace Properties Available, non @Trace not updated
@ObservedV2+@Trace's observation capability is independent.
  │
Set<streaming> - (ordinary variable) - →V1 OrderTagcomp (@Provide)
@V2 delete@Local as normal variable
│V1 received in @state/@Prop/@Provide
Unobserved change in V2
  │
@ObservedClass (ProductObserved)   (not supported)  V1
V2 Decorators cannot be used with @Observed.
As a normal variable, the data connection cannot be achieved before API19
```

---

# # V2 uses V1 component-API19 and beyond

**Scene ID:** STATE MIXED V1V2 04

**Scene description:** Out-of-sale order page, V2 parent component management order information (order number, commodity details, distribution label, price list), need to display the order details using V1 third-party component. API19 and later, through `enableV2Compatibility` and `makeV1Observed`, the data transfer of V2→V1 was simplified to achieve a two-way data connection.

**Solution:** Use **`enableV2Compatibility`+ZXKEEP1Z** to provide data with both V1 and V2 observation capabilities. `enableV2Compatibility` when transmitting ZXKEEP4Xclass; `enableV2Compatibility` when transmitting ZXKEEP4Xclass; `enableV2Compatibility` when transmitting ZXKEEP4Xclass; `enableV2Compatibility` when transmitting `@ObjectLink`; `makeV1Observed`+XKEEP8ZX when transmitting internal type of transfer; ZXKEEP7Z+XKEEP8ZX to avoid double-agenting, V1 to receive `@ObjectLink`; when transmitting `makeV1Observed` to lower layer, V1 to receive `@ObjectLink`; and ZXKEEP12Z to ensure that each layer is a V1 state variable, `enableV2Compatibility` to achieve depth observation of V2 and VXEKEX14X to lower level when transmitting embedded type.

> ** Annotations:**
> `enableV2Compatibility` allows V1 status variables to be compatible with V2 observation capabilities; `makeV1Observed` packages unobservable objects as V1 observable objects, and returns values to initialize `@ObjectLink`.

# # scene: take-out order page (V2 with V1 component - API19 and later)

```
Home order page V2 father component@Local
→V1@ObjectLink
│ Two-way data connection, V1 receiving makeV1Observed return with @ObjectLink Value
│ Suggest to call at @Local at @UIUtils.enableV2Compatibility (UIUtils.makeV1Observed(new OrderClass())
  │
  ├── ProductObservedClass(@Observed+@Track) ──(enableV2Compatibility)──→ V1 @ObjectLink
@Observed class does not need to makeV1Observed, directly availableV2compatibility
@Track property V1/V2 is visible, not @Track property V1 UI running error, V2 not reporting error but not responding to update
  │
  ├── prices(Array<number>) ──(makeV1Observed+enableV2Compatibility)──→ V1 @ObjectLink
│ MakeV1Observed packaged V1 state variable →enableV2compatibility allows V2 to be observed → and avoid double representation
│V1 receives makeV1Observed return with @ObjectLink Value
  │
Ideas - tagGroups - (makeV1Observed +enableV2Compatibility) - V1@ObjectLink (Inner Layer)
│ Layer by layer of inner array madeV1Observed
│V1 receiving inner layers with @ObjectLink Group
│ Adding array elements to makeV1Observed
  │
→V1 Layers
MakeV1Observed ensures that every layer is a V1 state variable → capable V2compatibility achieves V2 depth observation
V1 only observes the first layer @ multi-layer @ObjectLink split to achieve depth observation
Add data to makeV1Observed
```

Defines the data class - order information, trade details and distribution label

Five data categories need to be defined in the external order-of-order page scene, covering the general class, @Observed+@Track decorated class, built-in type, two-dimensional array and embedded type of transmission scene.

```ts
import { UIUtils } from '@kit.ArkUI'

// Knowledge point 1: Normal class, no decorator
class OrderClass {
  public orderId: string = 'ORD001'
  public totalPrice: number = 2999
}

// Knowledge point 2: @Observed+@Track Decoration
@Observed
class ProductObservedClass {
@Track public protectionName: string = 'smart phone'
  @Track public price: number = 2999
Public Stock: number = 100 / / Non@Track Properties
}

/ / Knowledge point 5 nesting type: orders (most common
class OrderItem {
  public value: number = 0
  constructor(value: number) {
    this.value = value
  }
}

/ / Knowledge point 5 nesting type: Commodity details (median general class, with OrderItem arrays)
class ProductDetail {
Public policyName: string = 'smart phone'
  public items: Array<OrderItem>
  constructor(items: Array<OrderItem>) {
    this.items = items
  }
}

/ / Knowledge Point 5 Embedded Type: Embedded Orders (outside class with @Track Properties and EmbeddedDetail)
class OrderNested {
  @Track public orderId: string = 'ORD001'
  @Track public product: ProductDetail
  constructor(product: ProductDetail) {
    this.product = product
  }
}
```

Key points: Data class design covers five transmission scenarios: (1) `OrderClass` is a regular class-free decorator; (2) `ProductObservedClass` uses ZXKEEP2Z+`@Track` decorations; (3) the built-in type `Array<number>` does not need to define a data class; (4) the two-dimensional array `Array<Array<string>>` does not need to define a data class; (5) the embedded type ZXXKEEP6ZX contains `ProductDetail` containing ZXXKEEP8ZX, the three-tiered embedded structure displays the need for layer-by-floor packaging.

##2 Pass — available V2compatibility + makeV1Observed

When V2→V1 transmits normal class, `enableV2Compatibility(makeV1Observed())` is called to provide data with both V1 and V2 observation capabilities, and V1 is received with `@ObjectLink` to achieve a two-way data connection.

```ts
import { UIUtils } from '@kit.ArkUI'

class OrderClass {
  public orderId: string = 'ORD001'
  public totalPrice: number = 2999
}

@Entry
@ComponentV2
struct OrderPageV2Api19 {
// Use available V2compatibility+makeV1Observed to provide both V1 and V2 observation capabilities
  @Local order: OrderClass = UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new OrderClass()))

  build() {
    Column() {
// @Local was only able to observe itself, but called makeV1Observed to make it a V1 state variable
/ / Call also availableV2compatibility to be visible in V2, so you can observe changes in properties on the first level
Text (`V2 Order: {this.order.orderId}`)
        .fontSize(20)
        .onClick(() => { this.order.orderId += '!' })

// @ObjectLink receives the return of MakeV1Observed Value
      OrderV1DetailView({ order: this.order })
    }
  }
}

@Component
struct OrderV1DetailView {
  @ObjectLink order: OrderClass

  build() {
    Column() {
Text (`V1 Order: {this.order.orderId}')
        .fontSize(18)
        .onClick(() => { this.order.orderId += '!' })
Text (`V1 Total Price: {this.order.totalPrice} ')
        .fontSize(16)
        .onClick(() => { this.order.totalPrice++ })
    }
  }
}
```

Key points: When V2→V1 transmits normal class, `UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new Class()))` is used to provide both V1 and V2 observation capabilities. V1 is received with `@ObjectLink` (the return value of `makeV1Observed` can be initialized by `@ObjectLink`) and V2 is managed with `@Local`, both modifications being observed and updated.

###3 Pass@Observed+@Track DecoratedClass — enablingV2compatibility

When `@Observed` decorations were passed to V1, `enableV2Compatibility` was no longer required to call `makeV1Observed`. The `@Track` properties can be observed in V1 and V2; the non-`@Track` properties use run-time errors in V1 and do not miss but respond to updates in V2.

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProductObservedClass {
@Track public protectionName: string = 'smart phone'
  @Track public price: number = 2999
public stock: number = 100///
}

@Entry
@ComponentV2
struct OrderPageV2ObservedApi19 {
/ @Observed Decoration Class, availableV2compatibility
  @Local product: ProductObservedClass = UIUtils.enableV2Compatibility(new ProductObservedClass())

  build() {
    Column() {
Text (`V2 Commodities: $ {this.product.productName} - $ {this.product.price}}
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

// Non@Track Properties do not collapse in V2 but do not respond to updates
Text
.onClick(()=> {this.project.stock+})/ / do not trigger refreshing

      ProductV1DetailView({ product: this.product })
    }
  }
}

@Component
struct ProductV1DetailView {
  @ObjectLink product: ProductObservedClass

  build() {
    Column() {
/ @Track Properties are visible in V1
Text
        .onClick(() => { this.product.productName += '!' })
    }
  }
}
```

Critical point: `@Observed` Decoration Class does not need to call `makeV1Observed`, just `enableV2Compatibility`. V1 received with ZXKEP3ZX. The `@Track` properties can be observed in V1 and V2. Non-`@Track` properties use run-time error at UI in V1 and do not miss but respond to updates in V2.

###4 Transfer Internal Type (Array) — makeV1Observed + enablingV2Compatibility

When V2→V1 conveys the built-in type, `makeV1Observed` is packaged with a V1 state variable, `enableV2Compatibility` is made visible to V2 and V1 is received with `@ObjectLink`.

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct OrderPageV2ArrayApi19 {
/ / Using makeV1Observed packaged V1 state variable, enabling V2 Compatibility to be observed V2
  @Local prices: Array<number> = UIUtils.enableV2Compatibility(UIUtils.makeV1Observed([2999, 199, 49]))

  build() {
    Column() {
Text (`V2 First Price: $ {this.prices[0}} `)
        .fontSize(20)
        .onClick(() => { this.prices[0]++ })

// @ObjectLink receives the return of MakeV1Observed Value
      OrderV1PriceList({ prices: this.prices })
    }
  }
}

@Component
struct OrderV1PriceList {
  @ObjectLink prices: Array<number>

  build() {
    Column() {
Text (`V1 First Price: {this.prices[0]} `)
        .fontSize(18)
.onClick(()=> {this.prices[0]+})/ / DoubleSync
    }
  }
}
```

Key points: When V2→V1 conveys the built-in type, `makeV1Observed` is packaged with the V1 state variable, and `enableV2Compatibility` allows V2 to be observed and avoids double representation. V1 receives the return value of `makeV1Observed` with `@ObjectLink`. Both sides modify the two-way sync.

###5 Transmit 2-dimensional arrays — makeV1Observed layer by layer

```ts
import { UIUtils } from '@kit.ArkUI'

@Component
struct OrderTagItem {
  @ObjectLink tagArr: Array<string>

  build() {
    Row() {
      ForEach(this.tagArr, (item: string, index: number) => {
        Text(`${index}: ${item}`)
      })
Button('@ObjectLink Add'). Oncick()=>
        this.tagArr.push('ObjectLink')
      })
    }
  }
}

@Entry
@ComponentV2
struct OrderTagPageV2Api19 {
  @Local tagGroups: Array<Array<string>> =
    UIUtils.enableV2Compatibility(UIUtils.makeV1Observed([
UIUtils.makeV1Observed(['thermal']),
UIUtils.makeV1Observed(['new']),
UIUtils.makeV1Observed(['re recommended'])
    ]))

  build() {
    Column() {
      ForEach(this.tagGroups, (tagArr: Array<string>) => {
        OrderTagItem({ tagArr: tagArr })
      })

Button ('@Local Adding Tab Group' ). Onclick() = >
This.tagGroups.push
      })
Button ('@Local modify the first label'). Onclick() = {
        this.tagGroups[0][0] = 'HOT'
      })
    }
  }
}
```

Key points: The two-dimensional array needs to be packaged with a V1 status variable for the inner layer of `makeV1Observed` and also for the outer layer with ZXKEEP1Z+`enableV2Compatibility`. V1 receives inner layers with `@ObjectLink`. The new array elements shall be packaged in `makeV1Observed`.

#### 6. Transfer nesting type — makeV1Observed layer by layer + enablingV2compatibility Depth observation

Embedding types ensure that each layer is a V1 status variable (`makeV1Observed` package) and V2 calls for `enableV2Compatibility` to be observed in depth. V1 requires multi-layered components for Depth observation in conjunction with `@ObjectLink`.

```ts
import { UIUtils } from '@kit.ArkUI'

class OrderItem {
  public value: number = 0
  constructor(value: number) { this.value = value }
}

class ProductDetail {
Public policyName: string = 'smart phone'
  public items: Array<OrderItem>
  constructor(items: Array<OrderItem>) { this.items = items }
}

class OrderNested {
  @Track public orderId: string = 'ORD001'
  @Track public product: ProductDetail
  constructor(product: ProductDetail) { this.product = product }
}

@Entry
@ComponentV2
struct OrderNestedPageV2Api19 {
/ / Make sure each layer is a V1 state variable
  @Local order: OrderNested = UIUtils.enableV2Compatibility(
    UIUtils.makeV1Observed(new OrderNested(
      UIUtils.makeV1Observed(new ProductDetail(UIUtils.makeV1Observed([
        UIUtils.makeV1Observed(new OrderItem(1)),
        UIUtils.makeV1Observed(new OrderItem(2))
      ])))
    )))

  build() {
    Column() {
Text (`@Local Order: ${this.order.orderId}`)
        .fontSize(20)
        .onClick(() => { this.order.orderId += '!' })

Text (`@Local trade name: ${this.order.project.projectName})
        .fontSize(18)
        .onClick(() => { this.order.product.productName += '!' })

/ / Pass program to @ObjectLink to observe changes in inner layer properties
      OrderNestedV1ObjectLink({ product: this.order.product })
    }
  }
}

@Component
struct OrderNestedV1ObjectLink {
  @ObjectLink product: ProductDetail

  build() {
    Column() {
Text (`@ObjectLink Commodities: ${this.project.projectName})
        .onClick(() => { this.product.productName += '!' })

/ Continue dismantling of a sub-component
      OrderNestedV1Array({ items: this.product.items })
    }
  }
}

@Component
struct OrderNestedV1Array {
  @ObjectLink items: Array<OrderItem>

  build() {
    Column() {
      ForEach(this.items, (item: OrderItem, index: number) => {
        OrderNestedV1Item({ item: item })
      })

Button('@ObjectLink Add'). Oncick()=>
        this.items.push(UIUtils.makeV1Observed(new OrderItem(20)))
      })
    }
  }
}

@Component
struct OrderNestedV1Item {
  @ObjectLink item: OrderItem

  build() {
Text
  }
}
```

Key points: V2→V1 transfers the nest type, with a V1 status variable packaged on a layer-by-story basis with ZXKEP0Z and a V2 depth observation using ZXXKEEP1Z. Only changes in the first layer can be observed in V1, with multiple layers of ZXKEEP2Z components split to achieve depth observations. `enableV2Compatibility` in V2 can be observed at direct depth. Additional data need to be packaged with `makeV1Observed`.

---
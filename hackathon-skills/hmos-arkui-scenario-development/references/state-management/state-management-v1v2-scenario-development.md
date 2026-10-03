# State Management V1 & V2 Use scene

# Profile

The current state management is divided into V1 and V2 versions, with a self-defined V1 component of @Component Decoration, which can use state management capabilities for V1 decorators. @ComponentV2 Decoration has a self-defined V2 component, which can use state management capabilities for V2 versions.

Note**
- Select the corresponding version according to the current context, i.e., the V1 version is required or already in use, with reference only to the V1 version; only with reference to the V2 version, with reference only to the V2 version
- If the context does not specify the state variable version and the current code environment is not used, priority is given to the V2 environment variable
- The use of V1 and V2-status variables for self-inferment or decision-making is strictly prohibited, and the use of V2-status variables in V1 and V1-status variables in V2 is prohibited, except in cases where the user specifically requests the mixing of scenes

** Status management V1 versus V2 capabilities**

V1 Capable V2 Capable
| ----------------- | -------------------- | ------------------------------------- |
\Component| \ ComponentV2\ \Commonent's custom component decorator for matching V1 status variables. <br/ > @ComponentV2 custom component decorator for matching V2 status variables. Zenium
\@state| No external initialization: \@Local<br/> External initialization once: \Param\@Once\ and \Local are similar concepts of data sources, the difference being \State can be imported externally, while \Local cannot be imported externally. Zenium
\Prop\\Param\Prop\ and \Param are similar concepts of custom component parameters. \\Prop is a deep copy, \\Param is a reference when the input parameter is a complex type. Zenium
\Link\ \Param\@Event\Link is a two-way sync achieved by the frame's own envelope. For V2 developers, a two-way sync can be achieved by \Param\@Event. Zenium
\ObjectLink \Param| is directly compatible, \ObjectLink needs to be initialized by \Observed decorated class, \Param does not have this restriction. Zenium
\Provide\Provider|compatible. Zenium
\Consume\Consumer|compatibility. Zenium
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ O \ O O O O O O O > > > > observved V2 | indicates that the current object is an observerable object. But they are not the same. <br/ > @Observed can observe the properties of the first layer and needs a combination \ @ObjectLink to be effective. <br/ > @ObservedV2 does not have an observative capability per se, but simply represents that the current class can be observed and needs to be matched to \Trace if it is to observe its properties. Zenium
\Track \ \Trace |V1 Decorator\@Track is an accurate observation that can be used independently of @Observed. No precision observation of class properties is possible without use. <br/>V2\@Trace Decoration properties can be accurately tracked. Zenium
\ Watch \ Monitor \ Watch is used to monitor changes in V1 status variables and has the ability to monitor changes in the state variables themselves and their first tier properties. The observed change in the state variable triggers its \watch listening event. <br/> @Monitor is used to monitor changes in V2 status variables, with a combination \ @Trace, with deep listening capabilities. When the state variable changes several times in an event, the final result will be used to determine whether or not to trigger the \\@Monitor listening event. Zenium
\LocalStorage\global\@observedV2\@Trace|compatibility. Zenium
AppStorage |AppStorageV2 compatible. Zenium
PersistentStorage | PersistenceV2 | PersistentStorage Sustainability and AppStorage Compatibility, with PersistenceV2 Sustainability being used independently. Zenium

# Site Directory

1. [Paternity synchronisation] (#paternity synchronisation)
- 1.1 [V1 status variable synchronizes one-way and two-way between parent and child components] (#V1 status variable synchronizes one-way and two-way between parent and child components)
- 1.2 [V2 status variable synchronizes one-way, two-way synchronisation and initialization of parent-child components] (#V2 status variable synchronizes one-way, two-way synchronisation and initialization of parent-child components)
2. [Two-way sync across component levels] (# two-way sync across component levels)
- 2.1 [V1 status variable achieves two-way synchronization across components] (#V1 status variable achieves two-way synchronization across components)
- 2.2 [V2 status variable achieves two-way synchronization across component levels] (#V2 status variable achieves two-way synchronization across component levels)
3. [Observation of change in contented object properties] (#observation of change in contented object properties)
- 3.1 [V1 status variable achieves embedded object listening and attribute level updates] (#V1 status variable achieves embedded object listening and attribute level updates)
- 3.2 [V2 status variable achieves embedded object listening and attribute level updates] (#V2 status variable achieves embedded object listening and attribute level updates)
4. [State variable change listening] (# status variable change listening)
- 4.1 [V1 status variables change listening] (#V1 status variables change listening)
- 4.2 [V2 status variables are accurately monitored and obtained before and after the change] (#V2 status variables are accurately monitored and obtained)
- 4.3 [Synthetic listening of V2 state variables and live listening of wildcards] (#V2 status variables synchronized listening and live listening of wildcards)
- 4.4 [V2 status variable dynamic listening and de-hearing]
5. [Calculated Properties] (Calculated Properties)
- 5.1 [V2 status variable achieves self-calculation with a dependent driver] (#V2 status variable achieves self-calculation with a relying driver)
6. [Application of UI status storage and sharing] (Application of UI status storage and sharing)
- 6.1 [V1 status variable achieves page level and application level global sharing] (#V1 status variable achieves page level and application level global sharing)
- 6.2 [V2 status variable achieves application class global sharing] (#V2 status variable achieves application class global sharing)
7. [Sustained storage UI status] (# Durable storage UI status) I'm not sure.
- 7.1 [V1-state permanence] (#V1-state permanence)
- 7.2 [V2 status variable UR permanence] (#V2 status variable UI permanence)

---

# Father-son component status sync

The V1 state variable and the V2 status variable can synchronize the parent-child component.

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
`@State` `@Local` |
| Father to Son One-way | `@Prop` (can be modified locally but not synchronised) | `@Param` (prohibited direct modification, misfiled) |
| father and son two-way | `@Link` (direct two-way binding) | `@Param` + `@Event` (return mode) |
| Initialisation of | V1 Unresponsible | `@Param` + `@Once` (Camera Initial, Subsequent Unsync) |
Whether |XKEEP0ZX allows / `@Link` allows  `@Param` to be allowed and must be allowed locally by `@Event`; `@Param @Once`

---

# # # # V1 status variable to synchronize one-way and two-way between parent and child components

**Scene ID:** STATE SCENE V1 01

**Scene description:** emulation manufacturer ' s trade details page, parent component management commodity information (name, unit price, number of purchases, discount labels), consisting of two subcomponents: Commodity presentation cards (read only display names and discounts) and quantity selectors (can modify the quantity purchased). The parent component can be changed to trade names and discounts at any time to display the card as it is updated; the number selector changes the number and synchronizes it back to the parent component to calculate the total price.

** Solution:** Manage parent component state** ** ** `@State` ** ** `@Prop` un-sync read-only data** ** ** `@Link` Two-Sync to modify data**

```
Parent Component
Ideas -productName, discount - (@Prop Unidirectional) - ProfitInfoCard
│ Father change name/discount
  │
└ -count - (@Link two-way) ←→CounterSector
Subcomponent +/- → Sync to parent component → Total price update
Number of parent components reset
```

####1. Define parent component, manage commodity data using @state

```typescript
@Entry
@Component
struct ProductDetailPage {
/ @State Decoration: Father internal state, change trigger UI refresh
@state protectionName: string = 'smart phone'
  @State price: number = 2999
  @State count: number = 1
@statediscount: string = '80% time limit'

  build() {
    Column({ space: 15 }) {
/ / Parent Component Use @State Variable
Text (`Commodity Details ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

// @Prop Unidirectional Synchronization: read-only display, automatically updated when name and discount changes
      ProductInfoCard({ name: this.productName, discount: this.discount })

/ @Link DoubleSync: Number Selector can modify count and sync back to parent component
Text
        .fontSize(18)
      CounterSelector({ count: this.count })

/ / Parent Component Change@State, un-sync to ProjectInfoCard, double-sync to Contractor
      Row({ space: 10 }) {
Button ('change of name').onClick() = {this.productName = ' Flagphone'})
Button.onClick(()=> {This.discount= '2000 minus 100'}
Button (`replaced number').onClick()=> {this.count=1})
      }
    }
    .padding(20)
  }
}
```

Key points: The `@State` decoration variable is the data source of the parent component, which triggers its own UI to refresh and synchronizes to all subcomponents.

Commodity Information Display Component (read-only) - @Prop Unidirectional

```typescript
@Component
struct ProductInfoCard {
// @Prop Receives the values that parent components import, and automatically synchronizes here when parent components change
/ / Subcomponents are not allowed locally to reverse parent component data
  @Prop name: string = ''
  @Prop discount: string = ''

  build() {
    Column() {
Text (`trade name: {this.name} ')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`${this.discount}`)
        .fontColor(Color.Red)
        .fontSize(16)
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

Key points: `@Prop` creates a one-way sync between father and son. `productName` or `discount` are automatically synchronized when the parent component changes to `ProductInfoCard`, but `ProductInfoCard` cannot reverse the parent component data. Read-only presentation.

3. Commodity Number Selection Component - @Link Synchronize

```typescript
@Component
struct CounterSelector {
/ @Link Creates a two-way sync, the sub-component changes will synchronize back to the parent component
/ / @Link forbids local initialization and must be imported by parent components
  @Link count: number

  build() {
    Row({ space: 15 }) {
      Button('-')
        .onClick(() => {
          if (this.count > 1) this.count--
        })
      Text(`${this.count}`)
        .fontSize(24)
        .width(40)
        .textAlign(TextAlign.Center)
      Button('+')
        .onClick(() => {
          this.count++
        })
    }
  }
}
```

Key points: `@Link` creates a two-way sync. Subcomponent click +/- Modify `count` to synchronize changes to parent component and automatically update the total price of parent component. `count` is also synchronized with the sub-component when the parent changes the `count` by clicking on the "Replace Number".

# # # # # V2 status variable synchronises the one-way, two-way synchronisation and initialization of parent-child components

**Scene ID:** STATE SCENE V2 01

**Scene description:** Electrician Commodity Detailed Pages, Parent Component Management Commodity Information, Commodity Presentation Card Only, Quantity Selector to modify the quantity purchased.

** Solution:** DoubleSync**  **XKEEP0ZX Management Parent Component Status** + **`@Param` Un-Sync Read-only Data** ** **`@Param` + `@Event` Retort to achieve DoubleSync** + ** `@Once` InitialSync only once**

```
Parent Component
Ideas -ProductName, Discount - (@Param Unidirectional) - →V2ProducInfoCard
│ Father change name/discount
  │
Ideas -count - (@Param) -V2CounterSector
  │     ↑                             │
 (@Eventback)   (                                                                                                                                                                                                                                                     
+Subcomponent +/-→ @Event Retweet → Father Component Change Count  @ @Param Sync Back Subcomponent
Number of parent resets
  │
→ V2CategoryTag
Parent component recategorization
```

####1. Define parent component, manage commodity data using @Local

```typescript
@Entry
@ComponentV2
struct V2ProductDetailPage {
/ @Local Decoration: replace @state with V2
@LocalprojectName: string = 'smart phone'
  @Local price: number = 2999
  @Local count: number = 1
@Localdiscount: string = '80% time limit'
@LocalCategoryId: number = 101 // Commodity Category ID

  build() {
    Column({ space: 15 }) {
Text (`Commodity Details ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ / @Param Un-Sync: read-only presentation
      V2ProductInfoCard({ name: this.productName, discount: this.discount })

/ @Param + @Event DoubleSync: Number Selector
Text
        .fontSize(18)
      V2CounterSelector({
        count: this.count,
        onCountChange: (val: number) => { this.count = val }
      })

// @Once Initialize: class sign, subsequent CategoryId changes no longer synchronize
      V2CategoryTag({ categoryId: this.categoryId })

/ / Parent Component Change@Local, Sync to SubPart
      Row({ space: 10 }) {
Button ('change of name').onClick() = {this.productName = ' Flagphone'})
Button.onClick(()=> {This.discount= '2000 minus 100'}
Button (`replaced number').onClick()=> {this.count=1})
Button. onClick(()=> {This.categoryId=999})
      }
    }
    .padding(20)
  }
}
```

Key points: `@Local` replaces V1 with `@State`, which indicates the internal state of the component and does not allow for external initialization.

Commodity Information Display Component (read-only) - @Param Un-Sync

```ts
@ComponentV2
struct V2ProductInfoCard {
/ / @Param receives the values imported by parent components and direct modifications are not allowed in subcomponents (miscounting period)
  @Param name: string = ''
  @Param discount: string = ''

  build() {
    Column() {
Text (`trade name: {this.name} ')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`${this.discount}`)
        .fontColor(Color.Red)
        .fontSize(16)
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

Key points: `@Param` for V2 is more stringent than `@Prop` for V1, and direct changes to the `@Param` variable (miscounting period) are not allowed in subcomponents. Automatically synchronizes the parent component with a sub-component when it changes `productName` or `discount`.

3. Commodity Number Selection Component (modifiable) - @Param + @Event

```ts
@ComponentV2
struct V2CounterSelector {
/ @Param Receives the current value (read-only), which cannot be modified directly
  @Param count: number = 0
/ / @Event announces a callback, notifys parents of changes in data by callback Source
  @Event onCountChange: (val: number) => void = (val: number) => {}

  build() {
    Row({ space: 15 }) {
      Button('-')
        .onClick(() => {
          if (this.count > 1) {
/ Can't go straight to this.count -- through @Event
            this.onCountChange(this.count - 1)
          }
        })
      Text(`${this.count}`)
        .fontSize(24)
        .width(40)
        .textAlign(TextAlign.Center)
      Button('+')
        .onClick(() => {
          this.onCountChange(this.count + 1)
        })
    }
  }
}
```

Key points: `@Param` in V2 does not allow for direct modifications, and the parent must be informed by `@Event` in return to modify the data source and synchronize the data source back to the sub-component. V2 data flows are more universely traceable than the `@Link` direct two-way binding of V1.

####4 Type of target sign (scrap)-@Once only initializes sync once

```ts
@ComponentV2
struct V2CategoryTag {
/ @OnceSystem@Param Usage: only sync once at initialisation, subsequent parent changes no sync
/ / Undo @Param not allow local changes, can modify and trigger UI refresh locally
  @Param @Once categoryId: number = 0

  build() {
    Row() {
Text
        .fontSize(16)
        .padding(6)
        .backgroundColor('#e0e0e0')
        .borderRadius(4)
    }
  }
}
```

Key points: `@Once` must be matched with `@Param`. `categoryId = 101` is received from the parent component at the time of initialization, and the parent component then changes `categoryId` to 999 by clicking on the "Replacement", but ZXXKEEP4ZX will not be synchronized to update and display 101. `@Once` suits the scene that requires the initial "scrap" value and does not follow changes in data sources.

# Double-Sync across components

V1 state variable and V2 status variable can be synchronized in two directions across the component level

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
`@Provide` `@Provider()` |
Data on consumption
** Local initialization of offspring  ** Ban (before API 20)** Must ** Default value  **
| Support type | Basic type, class, array |
`@Provide('a')` / `@Consume('a')` `@Provider('a')` / `@Consumer('a')` |
Z `allowOverride` Parameter | Default allows renaming to automatically match recent ancestors
`@Component` | `@ComponentV2` |


## # # V1 status variable synchronizes in two directions across components

**Scene ID:** STATE SCENE V1 02

** scene description:** Following the application of to-dos, the root component maintenance tasks count, with one or more layers of unrelated components in the middle, and the bottom component needs to read and write the count directly, without having to transfer parameters from layer to layer.

** Solution:** Use **`@Provide` + `@Consume` for a two-way synchronization across the hierarchy**, free of the constraints of the parameter transfer mechanism, the variable of `@Provide` decorations in the root component is automatically available for all offspring components, and the next generation component is bound by a variable or aliases by `@Consume` to create a two-way synchronization.

1. Root component provides data

```ts
@Entry
@Component
struct ToDoPage {
/ @Provide Decoration variable count provided by root components to all offspring
  @Provide count: number = 0

  build() {
    Column() {
Button.
        .onClick(() => this.count += 1)

/ / Intermediate component, no transfer count
      ToDoDemo()
    }
  }
}
```

# # # 2. Intermediate components need not be passed

```ts
@Component
struct ToDoDemo {
  build() {
/ / No data transfer required at the middle level
    ToDoList()
  }
}

@Component
struct ToDoList {
  build() {
    Row({ space: 5 }) {
      ToDoItem()
      ToDoItem()
    }
  }
}
```

Key points: The intermediate-level components `ToDoDemo` and `ToDoList` do not need to state any parameters to transmit `count`, which automatically penetrates the data.

### # 3. Bottom component consumption data

```ts
@Component
struct ToDoItem {
@Consume binding the ancestral component by the same variable name
  @Consume count: number

  build() {
    Column() {
      Text(`count(${this.count})`)
      Button(`count(${this.count}), +1`)
        .onClick(() => this.count += 1)
    }
    .width('50%')
  }
}
```

Key points: `@Consume` does not allow for initialization from the outside, except for `@Provide`, which matches ancestral components by variable or aliases. The `@Consume` variable will be synchronized with the ancestral component.

---

## # # V2 status variable synchronizes in two directions across components

**Scene ID:** STATE SCENE V2 02

** scene description: ** To-do application scenario, root component maintenance state, bottom component required two-way synchronization across levels.

** Solution:** use **`@Provider` + `@Consumer` for a two-way synchronization across the hierarchy** (V2 Decorator), `@Provider` and `@Consumer` in V2 can only be used in `@ComponentV2` to create a two-way synchronization by matching ZXXKEEP5ZX.

Step 1: Root component provides data

```ts
@Entry
@ComponentV2
struct V2ToDoPage {
/ / Undefined liasName, using attribute name 'count ' as liasName
  @Provider() count: number = 0

  build() {
    Column() {
Button.
        .onClick(() => {
          this.count += 1
        })

/ / Intermediate component, no transfer count
      V2MiddleComp()
    }
  }
}
```

Step 2: Middle layer components

```ts
@ComponentV2
struct V2MiddleComp {
  build() {
    V2ToDoItem()
  }
}
```

Step 3: Substrate component consumption data

```ts
@ComponentV2
struct V2ToDoItem {
/ @Consumer Look up through the same liasName
  @Consumer() count: number = 0

  build() {
    Column() {
      Text(`count(${this.count})`)
      Button(`count(${this.count}), +1`)
        .onClick(() => {
          this.count += 1
        })
    }
  }
}
```

Keypoint: The `@Consumer` of V2 must be locally initialized (set default value) and used when no matching `@Provider` is found. V1's `@Consume` prohibits local initialization before API version 20.

---

# Observe changes in nested object properties

V1 state variable and V2 status variable can be observed for nested object properties

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
| `@Observed` + `@ObjectLink` (receiving the inner layer object of the molecule component to be dismantled) | `@ObservedV2` + `@Trace` (directly used in the parent component without having to dismantle the molecule component) |
| `@Observed` + `@ObjectLink` + `ForEach` (each required sub-component) | `@ObservedV2` + `@Trace` + `ForEach` (directly observed in the parent component)
| `@Track` Decoration Class Properties (undecorated properties cannot be used in UI) | `@Trace` Auto-Accuracy Updates
| Multilayer Embedded Observation | Layer-by-Stand Dismantling Molecular Component, `@ObjectLink` Each Layer Receives `@Trace` Supports Any Depth, Directly Modified or Refreshed
`@Observed` | No decoders for the outer layer

---

## # # V1 status variable updates embedded object listening and attribute levels

**Scene ID:** STATE SCENE V1 03

** Scene description:** Equiprator ' s order details page, Order (Order) contains the receiving address (Address) and list of goods (OrderItem[]). `@State` can only observe changes in the first layer and cannot directly observe changes in the properties of embedded objects (e.g., changing the street name of the receiving address, changing the price of a particular commodity). The `@Observed` + `@ObjectLink` component needs to be used to observe changes in deep properties and to use `@Track` to achieve a precise update of the properties.

** Solution:** Use **`@Observed` Decorated inner layer group** + **`@ObjectLink` to receive inner layer objects** + ** `@Track` in sub-components to provide an accurate update of the attribute level**

```
Parent Component
Ideas -order.address - (@ObjectLink) - AddressCard (observation of changes in address properties)
@Slate cannot observe changes.set  @ObjectLink can
  │
  └── order.items[] ──ForEach──→ OrderItemCard(@ObjectLink)
@State Unable to observe objects[i]. price change @ObjectLink
@Track Precision Update: Change price only
```

Defines the data class using @Observed Decoration Internal Class + @Track Decoration Observation Properties

```ts
@Observed
class Address {
@Trackpublic street: string = 1 Central Guanamura Avenue
@Trackpublic city: string = 'Beijing'
Public zipCode: string = '10080' // @Track, not available in UI

  constructor(street: string, city: string) {
    this.street = street
    this.city = city
    this.zipCode = '100080'
  }
}

@Observed
class OrderItem {
  @Track public name: string = ''
  @Track public price: number = 0
  @Track public quantity: number = 1
Public id: number = 0/ / Not @Track, not available in UI

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
    this.id = Math.floor(Math.random() * 10000)
  }
}

@Observed
class Order {
  public orderNo: string = 'ORD-20240101'
Public access: Address = new Address
  public items: OrderItem[] = []
}
```

Key points: The inner `Address` and `OrderItem` require `@Observed` decorations, and the outer `Order` requires `@Observed`. `@Track` decorations require precise observations of properties which, after being decorated by `@Track`, are only refreshed by UI components that use this variation; properties that are not `@Track` decorations cannot be used in UIs (misreporting when running), but can be used in event echoes.

Show subcomponents at 2. Receipt address - @ObjectLink observe changes in nested object properties

```ts
@Component
struct AddressCard {
/ @ObjectLink Receives @ObservedAddress Examples
/ / Can observe Address attribute changes, synchronized with data sources
  @ObjectLink address: Address

  build() {
    Column() {
Text (`Receiving address: {this.adcess.city} $ {this.adress.stream} ')
        .fontSize(18)
        .margin(10)

Button.
.onClick(()=> {this.address.stream= '88 Road to the Sun'})
Button.
.onClick(()=> {this.adcess.city= 'Shanghai'})
    }
    .padding(15)
    .backgroundColor('#f0f8ff')
    .borderRadius(8)
  }
}
```

Key points: `@ObjectLink` creates a two-way synchronization with data sources to observe changes in `address.street` and `address.city`. The `@ObjectLink` variable is read-only (the total value is not allowed) and can only modify its properties. `@State` in the parent component cannot directly observe changes in `order.address.street`, but subcomponents can be observed by passing the inner object to the `@ObjectLink` subcomponent.

3. Trade item display sub-components -

```ts
@Component
struct OrderItemCard {
/ @ObjectLink Receive OrderItem instance
/ OrderItem's properties of @Track Decoration can be accurately refreshed
  @ObjectLink item: OrderItem

  build() {
    Row() {
Text (`Commodities: ${this.item.name}} / /Just refresh when name changes
        .fontSize(16)
        .width(120)
Text when the price changes
        .fontSize(16)
        .width(80)
Text (`Quantity: {this.item.quatity}') / Quantity changes only
        .fontSize(16)
        .width(60)

Button.onClick(()=> {this.item.price+=10})
Button (`renamed').onClick()=> {this.item.name+= '-new'}
    }
    .padding(10)
    .margin({ bottom: 5 })
  }
}
```

Key points: The use of `@Track`, in conjunction with `@Observed` + `@ObjectLink`, addresses both the deep properties observation problem and the precise updating of the properties. When modifying `item.price`, only `Text(` unit price: ¥this.item.price}`)` Refresher, `Text(` Commodities: {this.item.name} `)` and `Text(` Number: {this.item.quantity} `)` will not be redundant.

# # # 4. Father component integration - @State observation level 1, @ObjectLink subcomponent observation depth

```ts
@Entry
@Component
struct OrderDetailPage {
  @State order: Order = new Order()

  aboutToAppear() {
    this.order.items = [
New OrderItem.
New OrderItem.
New OrderItem
    ]
  }

  build() {
    Column({ space: 15 }) {
Text
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ / Pass the inner layer object to @ObjectLink subcomponent to observe the changes in nesting properties
      AddressCard({ address: this.order.address })

/ ForEach +@ObjectLink: Changes in properties observed by sub-components per array
      ForEach(this.order.items,
        (item: OrderItem) => {
          OrderItemCard({ item: item })
        },
        (item: OrderItem): string => item.id.toString()
      )

/ / State can observe changes in the first tier (array push/pop)
Button.
.onClick(()=>{this.order.items.push(new OrderItem('Dataline', '29)))}

/ @state cannot observe changes in the second layer, but @ObjectLink subcomponents can
Button.
        .onClick(() => { this.order.items[0].price += 100 })
    }
    .padding(20)
  }
}
```

Key points: `@State` can only observe changes in the first tier: `order.address` replacement as a whole, `order.items` array additions and deletions can be observed. However, `order.address.street`, `order.items[i].price`, etc., changes in properties of the second layer, which cannot be observed directly by `@State`, need to be observed through `@ObjectLink` subcomponents.

---

## # # V2 status variable updates embedded object listening and attribute levels

**Scene ID:** STATE SCENE V2 03

**Scene description: **Etherer's order details page, which contains the receiving address and list of goods, requires observation of the properties of embedded objects and arrays.

** Solution:** Using **`@ObservedV2` Decoration Internal Category** + **`@Trace` Decoration properties to be observed**, observe multi-layer embedded properties directly in parent components without dismantling molecular components

```
parent component order: Order
  ├── order.address.street / order.address.city
@Trace Decoration → Direct observation changes → UI refresh
No need to remove molecular components.
  │
  └── order.items[i].name / order.items[i].price / order.items[i].quantity
@Trace Decoration →A direct observed change in array properties
@TraceSystemPhysical Update
  │
└-order.address.region.province
@Trace Supports Any Depth
```

####1. Defines the data class using @ObservedV2 +@Trace

```ts
@ObservedV2
class Region {
/ / Multilayer Embedded: Region as an inner object of Address
@Trace public protection: string = 'Beijing'
@Trace Public City: string = Beijing

  constructor(province: string, city: string) {
    this.province = province
    this.city = city
  }
}

@ObservedV2
class Address {
@Trace Public Street: string = 1 Central Guanamura Avenue
@Tracepublic region: Region = new region

  constructor(street: string, region: Region) {
    this.street = street
    this.region = region
  }
}

@ObservedV2
class OrderItem {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1
Public id: number = 0/ / Non-@Trace Properties

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
    this.id = Math.floor(Math.random() * 10000)
  }
}

class Order {
/ V2: No decorator for the outer layer
  public orderNo: string = 'ORD-20240101'
Public address: Address = new Address
  public items: OrderItem[] = []
}
```

Key points: V2 requires only `@ObservedV2` + `@Trace` on the inner layer, and the outer layer ZXXKEEP2ZX does not require any decorator. The `@Trace` Decoration attribute precision update capability (`@Track` equivalent to V1) will only be refreshed if the UI component using this change properties is used. For multilayer nesting (e. g. `Region` as the inner layer object of `Address`), use ZXXKEEP7ZX + `@Trace` only for the inner layer.

## ## 2. Observe changes in embedded properties directly in parent components (no need to remove molecular components)

```ts
@Entry
@ComponentV2
struct V2OrderDetailPage {
/ / order is the normal variable (non-state variable), but the internal @Trace properties are still visible
  order: Order = new Order()

  aboutToAppear() {
    this.order.items = [
New OrderItem.
New OrderItem.
New OrderItem
    ]
  }

  build() {
    Column({ space: 15 }) {
Text
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

/ / Directly use nesting properties, @Trace to make changes visible
Text (`This.order.adcess.region.province')
        .fontSize(18)
        .margin(10)

      Row({ space: 10 }) {
Button.onClick(()=> {this.order.address.stream= '88 Road to the Sun'})
Button.onClick(()=> {this.order.address.region.province= 'Shanghai'}
      }

/ ForEach + @Trace: Changes in the properties of arrays are directly visible and accurately updated
      ForEach(this.order.items, (item: OrderItem, index: number) => {
        Row() {
Text (`Commodity: ${item.name}} / /Just refresh when name changes
            .fontSize(16)
            .width(120)
Text when the price changes
            .fontSize(16)
            .width(80)
Text (`Quantity:${item.quantity}} / Quantity changes only
            .fontSize(16)
            .width(60)

Button (`replacement').onClick()=>
Button.onClick(()=>item.name+=`-new'})
        }
        .padding(10)
        .margin({ bottom: 5 })
      })

Button.
.onClick(()=>{this.order.items.push(new OrderItem('Dataline', '29)))}

/ / Directly modify deep embedded properties, UI to refresh
Button.
        .onClick(() => { this.order.items[0].price += 100 })
    }
    .padding(20)
  }
}
```

Key points: `order` in V2 is a general variable (non-state variable), but `order.address.street`, `order.address.region.province`, `order.items[i].price`, and `@Trace` decorative changes can directly trigger UI retrofit without having to use `@ObjectLink` as V1. The `@Trace` self-banded property level precision update capability. The UI renovation of `item.price` was only used when modifying `price`. For multilayer nesting (e.g. `order.address.region.province`), `@Trace` supports any in-depth observation, and the same scenario in V1 requires a layer-by-story disassembly molecular component.

---

# The state variable changes to listen

V1 and V2 state variables can both achieve a state change listening. Version V2 also provides `@SyncMonitor` simultaneous listening (support wildcards) and `addMonitor/clearMonitor` dynamic listening as extension capabilities

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
|XKEEP0ZX (decorative state variable, given callback method) |XKEEP1ZX (decorative recall method, specified listening variable) /`@SyncMonitor` (synchronous listening)
| listen to target number | only listen to individual state variables | monitor multiple state variables at the same time
| listen depth | only listen to state variables per se (one layer) | support deep attribute path (e.g. `'inner.num'`) |
Z Retrieving pre-change values
It's got to be nice.
`@Monitor` rectangular (triggered immediately); `@SyncMonitor` sync (triggered immediately for each change)
| Use range | only |`@Monitor/@SyncMonitor` in `@ComponentV2` and `@ObservedV2`; |
| Multivariate Shared Retrieval | Multiple Variables Tie the same return method name to distinguish between `propName` by `propName` Directly declare listening to multiple variables, `monitor.dirty` returns the change path |
| Dynamic Add/ Cancel | does not support | XKEEP0ZX Dynamic Add, `clearMonitor` Dynamic Cancel |

---

# # V1 status variable changes listening

**Scene ID:** STATE SCENE V1 04

** Scenario description:** Simulation of the shopping car page, automatic calculation of the total price when the number of commodities changes, recalculation of the amount paid after the discount when the list of shopping vehicles changes, and uniform determination of whether the conditions for full reduction are met when the number of different commodities changes.

** Solution:** Use **`@Watch` to listen to changes in state variables and trigger back-to-back** to support the use of `@Link` in combination with multiple variables to bind the same back-to-back distinction through `propName`

```
Shopping Car Page
Ideas - appleCount - (@onFruitChange) - → Unanimous echo
Ideas - OrangeCount - (@onFruitChange) - → Unified Echo
→ Changes in the number of apples/oranges onFruitChange →propName Distinguishing Source → Recosting Total Prices and Full Decline
  │
└ ─ CartSummary sub-component
@Link Double-Sync  @Watch Trigger → Recalculate Preferential Payment
```

####1. Parent component uses @watch listener status variable changes + multivariant shared echo

```ts
@Entry
@Component
struct ShoppingCartPage {
  @State totalQuantity: number = 0
  @State totalPrice: number = 0
  @State isDiscount: boolean = false

/ @watch Changes in listening status, multiple variables bound to the same way back First Name
  @State @Watch('onFruitChange') appleCount: number = 0
  @State @Watch('onFruitChange') orangeCount: number = 0
  @State shopBasket: PurchaseItem[] = []

/ @Watch echo: recalculates the total price and full reduction conditions when the number of apples or oranges changes
/ PropName Parameter Distinct which variable has changed
  onFruitChange(propName: string): void {
    this.totalQuantity = this.appleCount + this.orangeCount
    this.totalPrice = this.appleCount * 5 + this.orangeCount * 3
This.isDiscount = this.totalPrice > = 100 / / 100

    if (propName === 'appleCount') {
Console.info (`Change in number of apples, current: {this.appleCount}')
    } else if (propName === 'orangeCount') {
Console.info (`Orange number changes, current: {this.orangeCount}')
    }
  }

  build() {
    Column({ space: 15 }) {
Text (`Shopping Vehicle ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
Text (`total quantity: $ {this.totalQuantity} Total price: $ {this.totalPrice} ')
        .fontSize(18)
      if (this.isDiscount) {
Text!
          .fontColor(Color.Red)
          .fontSize(16)
      }

      Row({ space: 10 }) {
Button.
          .onClick(() => { this.appleCount++ })
Button.
          .onClick(() => { this.orangeCount++ })
      }

// @Link + @watch subcomponent
      CartSummary({ shopBasket: $shopBasket })

Button.
        .onClick(() => {
          this.shopBasket.push(new PurchaseItem(Math.round(100 * Math.random())))
        })
    }
    .padding(20)
  }
}
```

Key points: `@Watch` will not be called at the first initialization and will only be triggered if the subsequent state changes. Multiple state variables (`appleCount` and `orangeCount`) bind to the same callback method name `'onFruitChange'`, distinguishing by which variable has changed to achieve differentiated treatment from different sources.

####2 Sub-components with @Link + @watch

```ts
class PurchaseItem {
  public id: number
  public price: number

  constructor(price: number) {
    this.id = Math.floor(Math.random() * 10000)
    this.price = price
  }
}

@Component
struct CartSummary {
/ / @Link DoubleSync Shopping List, @Watch Monitor List Changes Trigger the echo
  @Link @Watch('onBasketUpdated') shopBasket: PurchaseItem[]
  @State totalPurchase: number = 0

  updateTotal(): number {
    let total = this.shopBasket.reduce((sum, i) => sum + i.price, 0)
    if (total >= 100) {
Total = 0.9 * total / / / 90% for 100
    }
    return total
  }

/ @Watch Echo: Recalculate the amount paid after the discount when the list changes
  onBasketUpdated(propName: string): void {
    this.totalPurchase = this.updateTotal()
  }

  build() {
    Column() {
      ForEach(this.shopBasket, (item: PurchaseItem) => {
Text (`Commodities Price: {item.price.toFixed(2)})
      })
Text
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Red)
    }
  }
}
```

Key points: `@Watch` can be used in combination with `@Link`. `@Link` creates a two-way sync to get the list of shopping vehicles, and `@Watch` triggers recalculating benefits after they are paid. `@Watch` returns the synchronised execution after a change in the status variable, and the `propName` is the change attribute string.

---

# # # V2 status variable change accurate listening and pre- and post-change values

**Scene ID:** STATE SCENE V2 04

**Scene description:** Simulation of a shopping car page, where changes in the number or price of goods require the automatic calculation of the total price and the acquisition of pre-change values (e.g., showing "prices change from ¥2999 to ¥3099)", changes in the properties of the object of the commodity require precise listening, and changes in the characteristics of the embedded specifications of the commodity need to trigger a reversal.

** Solution:** modified with **`@Monitor` listening status variables** to support the acquisition of pre- and post-change values, listening to ZXKEEP1Z-type properties changes and deep property path

```
Shopping car page
  ├── @Local quantity, price ──(@Monitor('quantity', 'price'))──→ onFieldChange
Number/price change → Monitor.ditty returns change path → Monitor.value() fetches pre- and post-value
Show "price from 2999 to 3099"
  │
  ├── Product(@ObservedV2) ──@Trace name, price──→ @Monitor('price') onPriceChange
@ Changes in commodity object properties  @ Class @Monitor Trigger → Get pre- and post-value log
  │
  └── product.specs.weight ──(@Monitor('product.specs.weight'))──→ onSpecsChange
Embedded specification properties change  @ Monitor supports deep path  @ Directly triggers the echo
```

###1. Defines the data class using @ObservedV2 @Trace +@Monitor

```ts
@ObservedV2
class ProductSpecs {
  @Trace public weight: string = '200g'
@Tracepubliccolor: string = 'Black'

  constructor(weight: string, color: string) {
    this.weight = weight
    this.color = color
  }
}

@ObservedV2
class Product {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1
Public Specs: ProductionSpecs = new Products

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
  }

/ @Monitor listening in @ObservedV2
// Get values before and after the change
  @Monitor('price')
  onPriceChange(monitor: IMonitor) {
Console.info.
  }
}
```

Key points: `@Monitor` can be used in the `@ObservedV2` decoration class to monitor changes in properties of `@Trace` decorations. Properties that are not decorated by `@Trace` cannot be monitored by `@Monitor`. `monitor.value()` can access pre- and post-change values (`before` and `now`), which are not available for V1 `@Watch`. The `@Watch` of V1 can only be used in `@Component`, and the `@Monitor` of V2 can be used in categories `@ComponentV2` and `@ObservedV2`.

###2 Use @Monitor to listen to multiple variables, take back-to-back values and deep attribute paths

```ts
@Entry
@ComponentV2
struct V2ShoppingCartPage {
  @Local quantity: number = 1
  @Local price: number = 2999
@Localproject:Producing = new product
  @Local changeLog: string = ''

/ / @Monitor listens to multiple variables at the same time to obtain values before and after changes
  @Monitor('quantity', 'price')
  onFieldChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      const before = monitor.value(path)?.before
      const now = monitor.value(path)?.now
This.changeLog +=`${path} from ${before} to ${now}\n`
    })
  }

/ @Monitor listen to deep attribute path
  @Monitor('product.specs.weight')
  onSpecsChange(monitor: IMonitor) {
This.changeLog += `Specific weight from ${monictor.value()? .before} to $’monictor.value()?now}\n`
  }

  build() {
    Column({ space: 15 }) {
Text (`Shopping Vehicle ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

Text (`Commodities: ${this.product.name} Price: ${this.product.price} Number: ${this.quantity}
        .fontSize(18)

Text
        .fontSize(20)
        .fontColor(Color.Red)

      Row({ space: 10 }) {
Button ('Quantity +1').onClick(() = > This.quantity+})
Button. onClick(()=> {this.price+=100})
Button.onClick(()=> {this.project.specs.weather= '300g'})
      }

/ / Show Change Logs, Show Back and Back Values
Text (`Change Record: \this.changeLog})
        .fontSize(14)
        .fontColor('#666666')
        .maxLines(5)
    }
    .padding(20)
  }
}
```

Key points: `@Monitor` of V2 has a fundamental difference with `@Watch` of V1: (1) `@Monitor` Decoration Retortation Method, which directly states the variable name of the listening, while `@Watch` Decoration State Variables and specifies the callback method; (2) `@Monitor` can monitor multiple variables at the same time, and `monitor.dirty` returns the attribute path list of the change; (3) ZXXKEEP6ZX may obtain the value of the change (ZXXKEEP7ZX); (4) `@Monitor` supports the deep attribute path (e.g. ZXXKEEP9ZX), and `@Watch` of V1 can only monitor changes in the state variable itself and cannot listen to embedded attributes.

---

# # # Synchronize listening to V2-status variables # # Synchronize listening and listening to wildcards

**Scene ID:** STATE SCENE V2 05

** scene description:** Simulation of the shopping car page, which requires a synchronized and immediate reversal of the number of goods or price changes (e.g. each change is triggered immediately at the time of successive price revisions, rather than only once after all changes have been completed), and a trigger-state alert is required for any change in the properties of the object of the shopping car.

** Solution:** modified using **`@SyncMonitor` Synchronized listening status variables** to support the acquisition of pre- and post-change values, wildcard fuzzy listenings and in-depth listenings

```
Shopping car page
@Localquatity, price - (@SyncMonitor','price') - → on FieldChange
│ Volume/price changes → Promptly triggers the echo → Synchronizes the front and back values
@Monitor triggers only once after the event, @SyncMonitor triggers every change
  │
Ideas -Produtt (@ObservedV2) - @SyncMonitor ('price') - → on PriceChange
│ Commodity price changes → triggers an introvert immediately → get the log before and after
  │
CartData - @SyncMonitor ('cartData.*') - → Common Handheld
Any change in the identity of the shopping car
```

####1. Defines the data class using @ObservedV2 @Trace + @SyncMonitor

```ts
@ObservedV2
class CartData {
  @Trace public totalQuantity: number = 0
  @Trace public totalPrice: number = 0
  @Trace public isDiscount: boolean = false
Public Note: string = '/// Not @Trace, not listening

/ @SyncMonitor listens in class @Trace Properties Change
/ / Synchronization: each attribute change triggers immediately instead of waiting for the event to end
  @SyncMonitor('totalPrice')
  onTotalPriceChange(monitor: IMonitor) {
Console.info.
  }
}

@ObservedV2
class Product {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
  }

/ / @SyncMonitor listens to price changes in Project class, synchronise to trigger the echo
/ Distinguished from @Monitor: Multiple price changes in the same incident, every time immediately triggered
  @SyncMonitor('price')
  onPriceChange(monitor: IMonitor) {
Console.info.
  }
}
```

Key points: The use of `@SyncMonitor` is similar to that of `@Monitor` in the class, and all listen to changes in the properties of `@Trace` decorations. The core difference lies in the timing of the rotation: `@SyncMonitor` triggers the echo immediately after the change in properties, each time the same event changes in properties; `@Monitor` is triggered by a step after the end of the status change function, and multiple changes are triggered only once in the same event. Properties that are not decorated by `@Trace` cannot be monitored by `@SyncMonitor`.

Use @SyncMonitor Synchronized and Apparel Listening

```ts
@Entry
@ComponentV2
struct SyncMonitorCartPage {
  @Local quantity: number = 1
  @Local price: number = 2999
@Localproject:Producing = new product
  @Local cartData: CartData = new CartData()
  @Local changeLog: string = ''

/ @SyncMonitor Synchronizes the number and price of listening changes: Every change triggers the echo immediately
Different from @Monitor: If price changes from 2999 to 3099 and then 3199
// @SyncMonitor returns 2 times (2999:3099, 3099:3199) each time a pre- and post-value is obtained immediately
// @Monitor, only 1 call back (2999:3199), triggered after the event
  @SyncMonitor('quantity', 'price')
  onFieldChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      const before = monitor.value(path)?.before ?? 0
      const now = monitor.value(path)?.now ?? 0
      this.changeLog += `${path}: ¥${before} → ¥${now}\n`
    })
    this.cartData.totalQuantity = this.quantity
    this.cartData.totalPrice = this.price * this.quantity
    this.cartData.isDiscount = this.cartData.totalPrice >= 100
  }

/ @SyncMonitor
/ / 'cartData.*' listen to cartData object 's total grant or whatever @Trace property changes
  @SyncMonitor('cartData.*')
  onCartDataChange(monitor: IMonitor) {
/ / wildcard listening, before and now are undefined
Console.info.
  }

  build() {
    Column({ space: 15 }) {
Text (`Shopping Vehicle ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

Text
        .fontSize(18)

Text (`Total price: ¥this.cartData.totalPrice}$ {this.cartData.isdiscount? ' 100 plus 9% discount!':'}
        .fontSize(18)

      Text(this.changeLog)
        .fontSize(14)
        .fontColor(Color.Gray)

      Row({ space: 10 }) {
Button ('Quantity +1').onClick(() = > This.quantity+})
Button (`Price + 100').onClick()=> {this.price+=100})
      }

      Row({ space: 10 }) {
Button ('Commodity Price + 100').onClick(()=> {This.product.price+=100}
Button ( 'Commodity Price + 100').onClick(()=> {this.product.price+=100}
      }
    }
    .padding(20)
  }
}
```

Key points:

(1) Differences between the core behaviour of `@SyncMonitor` and `@Monitor`: ZXXKEEP2ZX triggers the echo immediately after a change in the state variable, each time a change occurs in the same event (if the price changes from 2999 to 3099 consecutively to 3199, `@SyncMonitor` returns 2 times: 2999:3099, 3099; 3099:3199); ZXXXKEEP4ZX is triggered by an odd step after the event treatment function, and multiple changes are triggered only once (price changes from 2999 to 3199, and only once: 2999:2999: 2999: 2999: 2999: 2999:399). `@SyncMonitor` should be used to respond to each change in real time.

(2) `@SyncMonitor` and `@Monitor` both support the wildcard `'*'`: Add at the end of the path any `*` changes in the ZXXKEEP4ZX properties of the listenable object or any changes in the arrays to facilitate migration from V1 `@Watch` to V2. `@SyncMonitor` uses `*` (e.g. `@SyncMonitor('cartData.*')`) directly in the path; `@Monitor` from API 26.0.0 supports the `enableWildcard` configuration by `MonitorDecoratorOptions` property (e. g. ZXXKEEP12ZX), `enableWildcard` default value is `true`. `before` and `now` were both ZXXKEEP18ZX when they were bugged by a match. The wildcard can only appear at the end of the path and cannot appear at the beginning or in the middle (e. g. `*.prop`, `arr.*.prop` is invalid).

---

# # V2 status variable dynamic listening and detached listening

**Scene ID:** STATE SCENE V2 06

**Scene description:** Simulation of the Sports and Fitness Data Monitor page, requiring dynamic increase of heart rate listening backs when users start their exercise (configuring synchronous listening to achieve real time heart rate alerts), elimination of listening at the end of the exercise, and monitoring of different data indicators for different motor models.

** Solution: ** Use **`addMonitor` Dynamic Add Listen** + **`clearMonitor` Dynamic Interception** to support the configuration of synchronous listening and mass listening of array paths

```
Campaign Monitoring Page
- About ToAppear - - addMonitor, ['distance','dration'] - - →
Add listening to WorkutData case dynamics when components appear
  │
Ideas - Start exercise - addMonitor
→ is Synchronous: true real time alarm
  │
{\cHFFFFFF}{\cH00FFFF}ClarMonitor
Dynamically clear the heart rate.
```

####1. Defines data class and dynamic listening back

```ts
import { UIUtils } from '@kit.ArkUI'

@ObservedV2
class WorkoutData {
@Trace public information: number = 0// distance (m)
@Trace public development: number = 0/ / / length (sec)
@Trace public calories: number = 0// calorie

/ / addMonitor 's callback method: must be named and not an anonymous function
  onWorkoutChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
Console.info (`motion data ${path} from ${monitor.value(path)? .before} to ${monitor.value(path)? .now}
    })
  }

  constructor() {
// Add listening with addMonitor dynamic in class construction functions
/ / Pass-in array paths to multiple properties
    UIUtils.addMonitor(this, ['distance', 'duration'], this.onWorkoutChange)
  }
}
```

Key points: `addMonitor` dynamically adds listening echoes to the run, and does not share the same echo in all instances as the `@Monitor` decorations. The `addMonitor` callback function must be named by a method and cannot be an anonymous function. ZXKEP3ZX supports the one-time listening of multiple properties to the array path (e.g. ZXKEP4ZX).

Use addMonitor dynamic add listening and clearMonitor dynamic detached in 2.

```ts
@Entry
@ComponentV2
struct DynamicMonitorPage {
  @Local heartRate: number = 72
  @Local isWorkoutActive: boolean = false
  workoutData: WorkoutData = new WorkoutData()

/ addMonitor's return method: must be named
  onHeartRateChange(monitor: IMonitor) {
    const before = monitor.value('heartRate')?.before ?? 0
    const now = monitor.value('heartRate')?.now ?? 0
Console.info
    if (now > 150) {
Console.info. `)
    }
  }

  aboutToAppear(): void {
/ addMonitor dynamic add listening: add listening to workoutData cases when components appear
/ Note: addMonitor only supports @observedV2 and @componentV2 examples
    UIUtils.addMonitor(this.workoutData, ['distance', 'calories'], this.workoutData.onWorkoutChange)
  }

  build() {
    Column({ space: 15 }) {
Text (`motion data monitoring ' )
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

Text (`heart rate: {this.heartRate} $ {this.isWorkoutActive? ' in exercise': 'in rest')
        .fontSize(18)

Text (`This.workoutData.distance')
        .fontSize(18)

// Start/termination: dynamic add/clean heart rate listening
Button.
        .onClick(() => {
          if (!this.isWorkoutActive) {
/ / Start movement: addMonitor dynamic & heart rate sync listening
/ isSynchronous: true configured for simultaneous listening, and heart rate change triggers the echo immediately
            UIUtils.addMonitor(this, 'heartRate', this.onHeartRateChange, { isSynchronous: true })
            this.isWorkoutActive = true
          } else {
/ End exercise: clearMonitor dynamically clear the heart rate to listen
/ ClearMonitor can only delete the echo added by addMonitor, cannot delete @Monitor
            UIUtils.clearMonitor(this, 'heartRate', this.onHeartRateChange)
            this.isWorkoutActive = false
          }
        })

Button ('heartrate + 10').onClick()=> {this.heartRate+=10}
Button (`range +100m'). onClick(()=> {This.workoutData.distance+=100})
    }
    .padding(20)
  }
}
```

Key points:

(1) `addMonitor` / `clearMonitor` Dynamic Interception: `addMonitor` Add a listening echo to the dynamic while running, and `clearMonitor` Dynamic Cancel. You need to import `UIUtils` (`import { UIUtils } from '@kit.ArkUI'`). Unlike the `@Monitor` Decorator, ZXXKEP7ZX can add a different wiretap to the different cases and can be added or cancelled depending on the circumstances during running.

(2) `addMonitor` supports the `isSynchronous` parameter configuration synchronous listening: ZXXKEEP2ZX acts like `@SyncMonitor` (syncly triggers back-to-back for each change), and ZXXKEEP4ZX (default) acts like ZXXKEEP5ZX (speech triggers, multiple changes triggers only once). `isSynchronous` is valid only for the first time and cannot be changed after.

(3) `clearMonitor` can only delete the echoes added by `addMonitor` and cannot delete the echoes of `@Monitor` or `@SyncMonitor`. You can transfer the specific callback function to delete the specified listening (`clearMonitor(target, path, callback)`), or you can also delete all `addMonitor` additions (`clearMonitor(target, path)`) to this path without the callback function. The `addMonitor` callback function cannot be an anonymous function and must be named by method.

---

# Compute Properties

Only V2 state variable achieves computational properties

# # # V2 status variable achieves auto-calculation based on a driver

**Scene ID:** STATE SCENE V2 07

**Scene description:** Replicater ' s shopping car page, which contains several commodities (each with a unit price and quantity), requires the automatic calculation of the subtotal of each commodity, the total purchaser ' s price and the satisfaction of full discounts, the recording of a change log when the total price changes, and the transmission of the calculation to the sub-component for presentation.

**Solution:** Calculate properties using **`@Computed` Decoration getter method**, only once when the status variable changes

```
Shopping car page
  ├── Product(@ObservedV2) ──@Trace quantity──→ @Computed subtotal
│ Subtotal per commodity = quarterity x unit Price, counted only once when relying on change
  │
Ideas - @LocalshuppingBasket - @Compued - → totalPrice
│ totalPrice = the sum of all quantity changes
  │
Ideas - TotalPrice - @Computed - QualifyForDiscount
QuasifesForDiscount = totalPrice > = 100, chain-dependent automatic solvency
  │
TotalPrice, qualifiesForDiscount - (@Param) - CartSummary subcomponent
@Computed Results Initial subcomponent @Param
  │
  └── @Monitor('totalPrice') ──→ onTotalChange
@Computed Properties can be monitored by @Monitor to get pre- and post-change values
```

###1. Defines a commodity data class using @ObservedV2 @Trace +@Computed

```ts
@ObservedV2
class Product {
  @Trace public quantity: number = 0
  public unitPrice: number = 0

  constructor(quantity: number, unitPrice: number) {
    this.quantity = quantity
    this.unitPrice = unitPrice
  }

/ @Computed Decoration in @ObservedV2
/ / Recalculate automatically when relying on @Trace property changes, with a read-only result
  @Computed
  get subtotal(): number {
    return this.quantity * this.unitPrice
  }
}
```

Key points: `@Computed` can be used in the `@ObservedV2` decoration class to trigger recalculations when dependent `@Trace` properties change. `subtotal` relies only on `quantity` (`unitPrice`, non-`@Trace`, changes do not trigger recalculations) and the result is read-only and not allowed. Changes in properties not subject to `@Trace` decoration will not trigger `@Computed` recalculation.

###2 Father component uses @Computed to calculate the total price and the reduced condition @Monitor

```ts
@Entry
@ComponentV2
struct ShoppingCartPage {
  @Local shoppingBasket: Product[] = [new Product(1, 20), new Product(5, 2)]

/ @Computed Decoration getter method in components, automatically recalculating when relying on changes
/ / Multiple UI Quote TotalPrice only once to read the cache value
  @Computed
  get totalPrice(): number {
    return this.shoppingBasket.reduce(
      (acc: number, item: Product) => acc + item.subtotal, 0
    )
  }

/ @Computed Support Chain Dependence: qualifiesForDiscount dependent totalPrice
/ totalPrice Change Auto-recost
  @Computed
  get qualifiesForDiscount(): boolean {
    return this.totalPrice >= 100
  }

// @Computed Decoration properties can be monitored by @Monitor
  @Monitor('totalPrice')
  onTotalChange(monitor: IMonitor) {
Console.info.
  }

  build() {
    Column() {
Text (`Shopping Car'). FontSize(24). FontWeight (FontWeight.Bold)

      ForEach(this.shoppingBasket, (item: Product) => {
        Row() {
Text (`Unit price: {item.unitPrice}.fontSize(16)
          Button('-').onClick(() => { if (item.quantity > 0) item.quantity-- })
Text (`Quantity: ${item.quantity}} `). FontSize(16)
          Button('+').onClick(() => { item.quantity++ })
Text (`Sub-total: ¥item.subtotal}`).fontSize(16).fontColor (Color.Red)
        }
        Divider()
      })

// @computed results can start with subcomponent @Param
      CartSummary({ total: this.totalPrice, qualifiesForDiscount: this.qualifiesForDiscount })
    }
    .padding(20)
  }
}
```

Key points:

(1) `@Computed` decorates the getter method in components, relying on `@Local` variables or changes in `@Trace` properties. Even multiple references to ZXKEP3ZX in UI calculates and reads the cache value only once.

(2) `@Computed` Support Chain Dependence: `qualifiesForDiscount` relies on `totalPrice`, and `qualifiesForDiscount` automatically recalculates when `totalPrice` changes. Calculating the attribute chain dependence solves it sequentially.

(3) The properties of the `@Computed` decoration may be monitored by `@Monitor`. `totalPrice` Changes `@Monitor('totalPrice')` is triggered by the `monitor.value()` to obtain values before and after the changes.

(4) `@Computed` results in the initial `@Param` of the sub-component, which synchronizes the parent-child component data.

Subcomponent 3. Receive @Param with @Computed

```ts
@ComponentV2
struct CartSummary {
  @Param total: number = 0
  @Param qualifiesForDiscount: boolean = false

  build() {
    Row() {
Text (`total price: ¥this.total}.fontSize(20).fontWeight (FontWeight.Bold)
      if (this.qualifiesForDiscount) {
Text (`90% discount! ' ). FontColor (Color. Red). FontSize (16)
      }
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

Key points: `@Computed` calculations feed sub-components through `@Param`. `totalPrice` Recalculates `qualifiesForDiscount` Recalculates `@Param` Sync Update Subcomponent UI.

---

# Apply UI status storage and sharing

Both V1 and V2 state variables are available for application level global status sharing. V1 provides a LocalStorage capability, and V2 does not have a dedicated page storage scheme.

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
| Application Level Global Storage |XKEEP0ZX + `@StorageLink` (bi-way)/`@StorageProp` (uni-way)|`AppStorageV2.connect` (bi-sync `@Trace` property) |
| Page Level Storage  `LocalStorage` + `@LocalStorageLink` (two-way)/`@LocalStorageProp` (one-way) | Unearmarked Page Level Storage Scheme |
| Support data type | Basic type, class, object, array, Map, Set, Date | Only class type (not basic type) |
|Key Match (string key) |conect Match (type constructor or specified key) |
| Observation properties | Observable class properties change  `@Trace` properties change triggers sync, non-`@Trace` properties change does not trigger UI refresh |
| Sharing across pages | Sharing multiple pages through the same AppStorage single case | Multipage to access the same reference via connect

---

## # V1 status variable to share the page level with the application level

**Scene ID:** STATE SCENE V1 05

** scene description: ** Following the IM application, the session list page displays unread messages and current chat objects, and clicks on the chat details page to send messages and switch chat objects, with real-time synchronization between the two pages. Chat details page inside, the draft input box changes the draft content, and the top status bar reads only the draft status and chat object names, which are shared only in the current chat page.

** Solution:** Use **`AppStorage` + `@StorageLink` / `@StorageProp` to achieve application level global sharing**  **XKEEP3ZX ** `@LocalStorageLink` / `@LocalStorageProp`**

```
Instant Communications Application (multipage scene)
AppStorage: Sharing across pages
@StorageLink ('currentContact') - two-way - + Chat Details Page
│ Toggle chat objects from any page
@StorageLink ('unreadCount') - Two-way - + Chat Details Page
│ Read messages → Reduce unread numbers → Sync all pages
@StorageProp ('currentContact') - Unidirectional - → Chat Status Bar (read-only)
│
└ - Page Level (LocalStorage): shared only in chat details pages
Ideas - @LocalStorageLink ('draftText') - Two-way - → Draft Input Box (modifiable)
│ Enter Draft → Synchronizes the LocalStorage status bar update
Ideas - @LocalStorageProp('draftText') - One-way - → Chat Status Bar (read draft only)
The status bar does not return local changes, but the LocalStorage changes will overwrite local
└ - The LocalStorage release with the page when the page is destroyed and the draft does not remain global
```

###1. Initialize AppStorage Application

```ts
// Initializing application level global status at application entrance
AppStorage.setOrCreate
AppStorage.setOrCreate('unreadCount', 0)
```

Key points: `AppStorage` is an application-level single case created at application start-up, with all pages sharing the same example. `setOrCreate` creates or updates properties, and all components bound to this key are synchronized.

####2. Session List Page - Apply a two-way sync (@StorageLink)

```ts
@Entry
@Component
struct ChatListPage {
Create two-way sync with AppStorage
/ / Changes will synchronize back to AppStorage and other components bound to the same key will be updated
@StorageLink ('currentContact')
  @StorageLink('unreadCount') unreadCount: number = 0
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

Text (`Current Chat: {this.currentContact}')
          .fontSize(18)
Text
          .fontSize(18)

        Row({ space: 10 }) {
Button (`toggle chat objects'). onClick(()=> {this.currentContact= 'Ming'})
Button. onClick(()=> {This.unreadCount=0})
        }

Button.
          .onClick(() => { this.pageStack.pushPathByName('ChatDetail', null) })
      }
      .padding(20)
    }
  }
}
```

Key points: The session list page uses `@StorageLink` to synchronize application-level data in a two-way fashion, changes ZXXKEEP1ZX or ZXXKEEP2ZX and synchronizes back to AppStorage, and the component bound to the same key in the chat details page is updated.

####3 Chat details page - Application level two-way + page level sharing

```ts
/ / Create page level LocalStorage instance, shared only in chat details pages
let chatStorage: LocalStorage = new LocalStorage()
chatStorage.setOrCreate('draftText', '')

@Entry(chatStorage)
@Component
struct ChatDetailPage {
/ / Application Level Two-way Synchronization
@StorageLink ('currentContact')
  @StorageLink('unreadCount') unreadCount: number = 0
/ / Page Level DoubleSync
  @LocalStorageLink('draftText') draftText: string = ''
  pageStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

// Application-level data presentation
Text
          .fontSize(20)
Text
          .fontSize(20)

// Page-level data presentation
Text
          .fontSize(20)

/ Chat status bar (read-only presentation)
        ChatStatusBar()

        Row({ space: 10 }) {
Button. onClick(() > {this.currentContact= 'Little Red'})
Button. onClick(()=> {This.unreadCount=0})
Button ('Input Draft').onClick()=> {this.draftText += 'Hello'}
        }

Button
          .onClick(() => { this.pageStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
    })
  }
}
```

Key points: `@StorageLink` (application level) and `@LocalStorageLink` (page level) can be used both on the same page. `@Entry(chatStorage)` allocates the LocalStorage instance to the root component of the page, and all subcomponents are automatically granted access to the example. When the page is destroyed, LocalStorage is released with the page and the draft data will not remain in the global picture.

###4 Chat status sub-component - @StorageProp Unidirectional @LocalStorageProp Unidirectional

```ts
@Component
struct ChatStatusBar {
/ @StorageProp Unidirectional Sync: AppStorage Change AutoSync, Local Change Not Return Write
@StorageProp('currencontact')
  @StorageProp('unreadCount') unreadCount: number = 0
/ / @LocalStorageProp Unidirectional: LocalStorting Changes AutoSync Write
  @LocalStorageProp('draftText') draftText: string = ''

  build() {
    Row() {
      Text(`${this.currentContact}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
Text (`Unreaded$ {this.unreadCount} ')
        .fontSize(14)
        .fontColor(Color.Red)
Text
        .fontSize(12)
        .fontColor(Color.Gray)
    }
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

Key points: `@StorageProp` Creates a one-way sync with AppStorage, suitable for read-only displays. Local changes will not synchronize back to AppStorage, but AppStorage changes will override local changes. `@LocalStorageProp` creates a one-way sync with LocalStorage, which is the same behavior. The status bar only needs to display the data and does not need to modify the data source, so use one-way sync.
---

# # # V2 status variable achieves application class global sharing

**Scene ID:** STATE SCENE V2 08

** scene description:** Instant communication application, session list pages and chat details pages shared chat data across pages.

**Solution:** Use **`AppStorageV2.connect` to achieve application level global mass sharing**

```
Instant Communications Application (multipage scene, V2)
AppStorageV2: share across pages
Ideas - Chatstate (@ObservedV2) - connect - a single global case
@Trace currentContact, unreadCount changes trigger UI refresh + global sync
│   │
Ideas - @Localchatstate - connect - session list page
@ Toggle chat objects/marks read  @Trace Properties Change →AppStorageV2 Sync →Page Yes.
│   │
@  Local Chatstate   -confect   → Chat details page
│Connect same class → Get the same object reference → 2-way sync
│
└ - Page level: V2 Unearmarked Page Level Storage Scheme (no LocalStorage counterpart)
Use @Local administration for local status on the page without a page-level sharing mechanism similar to the LocalStorage
```

####1. Define chat data class

```ts
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
class ChatState {
@Trace public currentContact: string = 'No Selected'
  @Trace public unreadCount: number = 0
// Non-@Trace Properties: Changes do not trigger UI refresh, but are synchronized back to AppStorageV2
  public lastActiveTime: string = ''

  constructor(currentContact?: string, unreadCount?: number) {
This. currentContact = currentContact?
    this.unreadCount = unreadCount ?? 0
  }
}
```

Key points: AppStorageV2 only supports class type, not basic type (string, number, boolean). The properties change for the `@Trace` decoration triggers UI refreshing and cross-assembly; non-ZXKEEP1Zx properties change sync to AppStorageV2 but do not trigger UI refreshing.

####2 Session List Page - Apply global sharing (connect)

```ts
@Entry
@ComponentV2
struct V2ChatListPage {
Create or get Chatstate objects in AppStorageV2
  @Local chatState: ChatState = AppStorageV2.connect<ChatState>(
    ChatState, () => new ChatState()
  )!
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

/ / Modify @Trace Properties, UI Refresh + Global Sync
Text (`Current Chat: {this.chatstate.currentContact}')
          .fontSize(18)
Text
          .fontSize(18)

        Row({ space: 10 }) {
Button ( 'toggle chat objects'). onClick(()=> {this.chatstate.currentContact= 'Ming'})
Button. onClick(()=> {this.chatstate.unreadcount=0})
        }

Button.
          .onClick(() => { this.pageStack.pushPathByName('ChatDetail', null) })
      }
      .padding(20)
    }
  }
}
```

Key points: `AppStorageV2.connect` creates or acquires global shared objects, `@Local` receives references. The `@Trace` property `currentContact` or `unreadCount` has been modified to automatically update all components of the same key. When connect does not specify the key, the type constructor is used as the key by default.

####3 Chat details page - Application level sharing

```ts
@ComponentV2
struct V2ChatDetailPage {
/ connect Same Chatstate, get the same object references
  @Local chatState: ChatState = AppStorageV2.connect<ChatState>(
    ChatState, () => new ChatState()
  )!
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

/ / Application level data: sync across pages
Text
          .fontSize(20)
Text
          .fontSize(20)

        Row({ space: 10 }) {
Button. onClick(()=> {this.chatstate.currentContact= 'Small Red'})
Button. onClick(()=> {this.chatstate.unreadcount=0})
        }

Button
          .onClick(() => { this.pathStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
```

Key points: Chat details page access to the same `connect` as `ChatState` for the same object references, and ZXXKEEP2ZX properties change two-way sync. V2 ** There is no dedicated page-level storage scheme** and no V1-like `LocalStorage`+`@LocalStorageLink/@LocalStorageProp` mechanism is available. The local state of the page (e.g., draft text, emoticon panel switches, etc.) cannot be automatically shared among sub-components stored at the page level. It needs to be managed manually using parent-child component communications (ZXKEEP5Z+`@Event`) or cross-level communications (`@Provider`+`@Consumer`).

---

# Enduring storage of UI status

The V1 state variable and the V2 status variable are both UI permanent. V1 uses PersistentStorage to perpetuate attributes in AppStorage, and V2 uses PersistenceV2 to sustain @Trace properties of the @ObservedV2 class.

**V1 v. V2**

| Capacity | V1 achieve | V2 achieve |
|------|---------|---------|
| `PersistentStorage.persistProp` / `persistProps` + `@StorageLink` / `@StorageProp` `PersistenceV2.connect` / `globalConnect` + ZXKEEP6ZClass Properties
** Enduring nested object ** does not support** (cannot detect changes in nested object properties) | `@Type` Decorator labels the nested class type to ensure successful serialization/ backsequencing
| Batch Endurance  `persistProps` Battling declare multiple `@Trace` properties of multiple key | class
| `AppStorage` + `@StorageLink` Synchronize `connect` / `globalConnect` across the page
| Non-observation properties |XKEEP0ZX Observable class properties change and persist
| Storage Path | Modeule Level (More module may not agree) |`connect` Modeule Level / ZXXKEEP1ZX Application Level (Recommended) |
| Number, string, boolean, enum, Map, Set, Date |API 23 is only of a class type; API 23+ supports group type |
| Call Order  Z must start with `persistProp` and then access AppStorage |XKEEP1ZX / `globalConnect` to autoprocess reading and writing order |

---

# # V1 status variable to sustain UI status

**Scene ID:** STATE SCENE V1 06

**Scene description:** Simulates the music player application, sets the main play page and sets the page-sharing player configuration (volume, play mode, theme colour, lyrics display switch), which is maintained when the application is activated again after the application has been withdrawn. Play mode indicator reads only the current mode. Attention needs to be paid to the call order and data size limits of the PersistentStorage.

** Solution:** Endurance with **`PersistentStorage` + `AppStorage` + `@StorageLink` / `@StorageProp`**

```
Music Player Application (multipage scene)
├-Application level (AppStorage + PersistentStorage): Share across pages + Last
@StorageLink ('volume') - Two-way - → Home Play Page + Setup Page
│ Changes the volume of any page
│ Resume from disk after restart
│   │
@StorageLink ('playMode') - Two-way - → Home Play Page + Setup Page
│ Switch play mode → Endurance → Resume
│   │
@StorageLink ('themeColor') - Two-way - Setup Page
│ │ Toggle theme color → Endurance → Recovery after restart
│   │
@StorageLink ('showLyrics')
♪ Bang, bang ♪
│   │
@StorageProp ('playMode') - Unidirectional - → Play mode indicator (read-only)
│ Set Page Switch Mode → Indicator is automatically updated and local changes are not returned Write
│
- Attention.
Idea - Must access AppStorage first (or lose last permanence)
└ - Durable data recommended less than 2kb to avoid frequent changes in large data
```

# # # 1. Initialization Endurance Properties

```ts
/ / must be called after UI initialization has been successful (loadContent echo)
/ / paperProps Batch Endurance Multiple Properties
PersistentStorage.persistProps([
  { key: 'volume', defaultValue: 50 },
  { key: 'playMode', defaultValue: 'loop' },
  { key: 'themeColor', defaultValue: '#FF0000' },
  { key: 'showLyrics', defaultValue: true }
])
```

Key points: `persistProps` may declare multiple persistent properties in bulk. When calling, ask if there is a disk that corresponds to the key, and if there is a disk, write to AppStorage; if there is no, write to AppStorage and last to disk. The call must be made after UI has been successfully initialized (`loadContent` in return), before the call could lead to a lasting failure. You can also use `persistProp` as a separate and persistent individual attribute.

####2 Main Play Page - @StorageLink Synchronization Data

```ts
@Entry
@Component
struct MusicPlayerPage {
Create two-way sync with AppStorage
/ / Changes will sync back to AppStorage → PersistentStorage
  @StorageLink('volume') volume: number = 50
  @StorageLink('playMode') playMode: string = 'loop'
  @StorageLink('themeColor') themeColor: string = '#FF0000'
  @StorageLink('showLyrics') showLyrics: boolean = true
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColor)

Text (`play mode: ${this.playMode} Volume: ${this.volume}')
          .fontSize(18)

/ / Play mode indicator (read-only sub-components)
        PlayModeIndicator()

        Row({ space: 10 }) {
Button('s volume +10').onClick()=> {this.volume+=10})
Button('toggle mode'). onClick() = >
            this.playMode = this.playMode === 'loop' ? 'shuffle' : 'loop'
          })
        }

Button.
          .onClick(() => { this.pageStack.pushPathByName('MusicSettings', null) })
      }
      .padding(20)
    }
  }
}
```

Key points: `@StorageLink` creates a two-way synchronization with AppStorage, changes `volume` or ZXXKEEP2ZX and syncs back to AppStorage, PersistentStorage automatically writes changes to disk. Apply to start again after exit, `persistProps` writes AppStorage from disk restoration, and the component reads the last saved value through `@StorageLink`.

Play mode indicator - @StorageProp Unsync read-only presentation

```ts
@Component
struct PlayModeIndicator {
/ @StorageProp Unidirectional Sync: AppStorage Change AutoSync, Local Change Not Return Write
  @StorageProp('playMode') playMode: string = 'loop'
  @StorageProp('themeColor') themeColor: string = '#FF0000'

  build() {
    Row() {
Text (`Current pattern: {this.playMode}')
        .fontSize(14)
        .fontColor(this.themeColor)
        .fontWeight(FontWeight.Bold)
    }
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

Key points: `@StorageProp` creates a one-way sync with AppStorage for a read-only presentation. After setting the page to modify `playMode`, AppStorage changes are automatically synchronized to the indicator; however, local changes to the indicator do not synchronize back to AppStorage and do not trigger permanence.

###4 Setup Page - Multipage Sharing Lasting Data

```ts
@Component
struct MusicSettingsPage {
/ / @StorageLink DoubleSync: Auto Durable after Change, Shared across Pages
  @StorageLink('volume') volume: number = 50
  @StorageLink('playMode') playMode: string = 'loop'
  @StorageLink('themeColor') themeColor: string = '#FF0000'
  @StorageLink('showLyrics') showLyrics: boolean = true
  pageStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

Text
          .fontSize(18)
        Row({ space: 10 }) {
Button('s volume +10').onClick()=> {this.volume+=10})
Button. Oncrick(()=> {this.volume -=10})
        }

Text (`play mode: ${this.playMode}')
          .fontSize(18)
        Row({ space: 10 }) {
Button ('cycle').onClick(()=> {this.playMode= 'loop'})
Button (`random').onClick() = { This.playMode = 'shuffle'})
Button.onClick(()=> {this.playMode= 'single'})
        }

Button.
          .onClick(() => {
            this.themeColor = this.themeColor === '#FF0000' ? '#0000FF' : '#FF0000'
          })

Button.
          .onClick(() => { this.showLyrics = !this.showLyrics })

Button
          .onClick(() => { this.pageStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
    })
  }
}
```

Key points: Set the page to synchronise `@StorageLink` with AppStorage in both directions, and modify any settings for automatic duration. `@StorageLink`, which binds the main playpage to the same key, will be synchronized by AppStorage for any change. Apply to start again after exit, all settings are restored from disk.

####5 Attention - order of call and data limitations

```ts
/ / Error: Access AppStorage first and then last, loss of last saved value
let volume = AppStorage.setOrCreate('volume', 50)
PersistentStorage.persistProp('volume', 50)
/ AppStorage.setOrCreate will overwrite the value on disk with 50

/ / Correct: last to cover as needed
PersistentStorage.persistProps([
  { key: 'volume', defaultValue: 50 },
  { key: 'playMode', defaultValue: 'loop' }
])
/ / Read the permanence value, overwrite as needed
if ((AppStorage.get<number>('volume') ?? 0) > 100) {
// Reset to 50 if lasting volume exceeds 100
  AppStorage.setOrCreate('volume', 50)
}
```

Key points: `PersistentStorage.persistProp` or `persistProps` must first be called, then access AppStorage, otherwise the last persistent value will be lost. Durable data are recommended to be less than 2 kb, avoiding the perpetuation of large-scale data with frequent changes. PersistentStorage writes the disk to synchronize with UI threads, and a large number of data are locally read and written to affect UI rendering performance. PersistentStorage does not support nested objects (object arrays, object properties are objects, etc.), because the frame cannot detect changes in embedded object values in AppStorage.

---

# # V2 status variable to sustain UI status

**Scene ID:** STATE SCENE V2 09

** scene description: ** Simulates the music player application, where the player configuration contains embedded balance setup (low, high, acoustic balance) and needs to be maintained when restarting after application. The main play page and the settings page share persistent data through globalConnect, and non-@Trace properties need to be manually saved.

** Solution: ** Endurance of state with **`PersistenceV2.connect` / ZXKEEP1Zx**, in conjunction with **`@Type` Decorator to process the serialization of embedded objects**

```
Music Player Application (multipage scene, V2)
Ideas - PlayerConfig (@ObservedV2) - GlobalConnect - Zero Persistence
@Trace volume, playMode, theyeColor, show Lyrics modify auto-permanence
@Type (EqualizerSettings)
@Equalizer. BassLevel /TrebleLevel / Balance
@LastPlayTime  @Trace  @PersistV2.save() Manual Endurance
│
Ideas - @Localconfig - confect - → Homeplay Page
@Modify Volume/Model  @Trace Change Automatic Endurance + Global Sync
│
@Localconfig - globalConnect -  @ Settings Page
│globalConnect same key → for the same reference → two-way sync + automatic permanence
│
└-- Call Time: Must call condition/globalConnect after initial UI
```

####1. Defines the configuration data class, using @ObservedV2 +@Trace @Type

```ts
import { PersistenceV2, Type } from '@kit.ArkUI'

@ObservedV2
class EqualizerSettings {
  @Trace public bassLevel: number = 5
  @Trace public trebleLevel: number = 3
@trade public balance: number = 0/ -10 to 10
}

@ObservedV2
class PlayerConfig {
  @Trace public volume: number = 50
  @Trace public playMode: string = 'loop'
  @Trace public themeColor: string = '#FF0000'
  @Trace public showLyrics: boolean = true
/ / Embedded objects must be modified with @Type to ensure sequencing/ backsequencing is successful
  @Type(EqualizerSettings)
  @Trace public equalizer: EqualizerSettings = new EqualizerSettings()
// Non-@Trace Properties: Changes do not trigger automatic permanence
  public lastPlayTime: string = ''
}
```

Key points: The parameters for `@Type` specify the type constructor used for inverse sequence. If `@Type` is not applied, the embedded object will be sequenced into an ordinary JSON object and cannot be restored to the correct class of example when recalculated, resulting in the failure of the `equalizer.bassLevel` attribute access. Only changes in the properties of `@Trace` decorations can trigger automatic permanence, and changes in non-`@Trace` properties (such as `lastPlayTime`) do not trigger UI refreshing and automatic permanence. V1's PersistentStorage does not support endurance of embedded objects, and V2 solves the problem by `@Type`.

####2 Main Play Page - Connect Endurance and Multipage Sharing

```ts
@Entry
@ComponentV2
struct V2MusicPlayerPage {
Create or retrieve PlayerConfig objects in PersistenceV2
  @Local config: PlayerConfig = PersistenceV2.connect(
    PlayerConfig, () => new PlayerConfig()
  )!
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.config.themeColor)

Text (`play mode: {this.config.playMode} Volume: {this.config.volume}')
          .fontSize(18)
Text (`Blank: {this.config.eqalizer.busLevel}
          .fontSize(16)

        Row({ space: 10 }) {
Button('s +10'). onClick(()=> {This.config.volume+=10})
Button('toggle mode'). onClick() = >
            this.config.playMode = this.config.playMode === 'loop' ? 'shuffle' : 'loop'
          })
        }

Button.
          .onClick(() => { this.pageStack.pushPathByName('V2MusicSettings', null) })
      }
      .padding(20)
    }
  }
}
```

Key points: `PersistenceV2.connect` creates or restores data from disk, `@Local` receives references. `connect` at first start-up creates new examples and lasts for `defaultCreator`; restores the last saved value from disk at restart. Automatically lasting to disk when `@Trace` properties (e.g. `volume`, `playMode`) are modified. `connect` uses a module level storage path, multiple module scenes suggest `globalConnect`.

###3 Settings Page - GlobalConnect Transmodule Endurance (Recommended)+ Non-@Trace Manual Save

```ts
import { contextConstant } from '@kit.AbilityKit'

@ComponentV2
struct V2MusicSettingsPage {
/ /globalConnect uses application level storage path to cross Modeule security (recommended)
  @Local config: PlayerConfig = PersistenceV2.globalConnect({
    type: PlayerConfig,
    key: 'playerConfig',
    defaultCreator: () => new PlayerConfig(),
Other Organiser
  })!
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
Text
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

Text
          .fontSize(18)
        Row({ space: 10 }) {
Button('s +10'). onClick(()=> {This.config.volume+=10})
Button ('volume-10').onClick(()=> {This.config.volume -=10})
        }

Text (`play mode: {this.config.playMode} ')
          .fontSize(18)
        Row({ space: 10 }) {
Button.onClick(()=> {this.config.playMode= 'loop'})
Button (`random').onClick()=> {this.config.playMode= 'shuffle'})
Button.onClick(()=> {this.config.playMode= 'single'})
        }

Button.
          .onClick(() => {
            this.config.themeColor = this.config.themeColor === '#FF0000' ? '#0000FF' : '#FF0000'
          })

Button.
          .onClick(() => { this.config.showLyrics = !this.config.showLyrics })

/ / Balancer Settings (set objects, @Type to ensure serialization/re-sequence success)
Text (`Assence: {this.config.eqalizer.bassLevel}
          .fontSize(16)
        Row({ space: 10 }) {
Button (`Bloody+1').onClick(()=> {This.config.eqalizer. bassLevel+=1})
Button (`high +1').onClick()=> {this.config.eqalizer.trebleLevel+=1})
        }

/ / Non-@Trace Properties Need manual saving
Button.
          .onClick(() => {
            this.config.lastPlayTime = new Date().toLocaleTimeString()
/ / Non-@Trace property needs to be called manually
            PersistenceV2.save(PlayerConfig)
          })

Text
          .fontSize(14)
          .fontColor(Color.Gray)

Button
          .onClick(() => { this.pathStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
```

Key points:

(1) `globalConnect` uses the application level storage path to avoid the problem of data discrepancies between the `connect` level path and the multimodule scene. `globalConnect` is recommended to replace `connect`. Supports the setting of encryption levels (`areaMode`), defaulted at EL2, set to EL1-EL5.

(2) Embedded objects `equalizer` can be correctly sequenced/re-sequenced after `@Type(EqualizerSettings)` has been marked. When modifying `equalizer.bassLevel` or `trebleLevel`, as they are `@Trace` properties, they automatically trigger the permanence of the entire `PlayerConfig` object.

(3) Non-`@Trace` property `lastPlayTime` will not be modified to trigger automatic permanence and ZXXKEEP2ZX will need to be called upon for manual permanence. You can also use `PersistenceV2.save('playerConfig')` to specify key for manual persistence.

(4) `PersistenceV2.keys()` returns the key of all PersistenceV2, including all the key of the Modeule level and application level storage path.

(5) Two pages get the same `PlayerConfig` object references from `globalConnect` the same key `'playerConfig'`, and `@Trace` properties change in two-way synchronization and automatic permanence. Apply to start again after exit, the value of all `@Trace` properties is restored from disk.

### 4.@Type

@Type
|------|---------------|------|
Number, string, boolean
Z Properties are custom class type  ** ** Must**  Z Specified constructor `@Type` when inverse
| Properties are Array, Map, Set, Date | does not need (API 23+) | built-in type autoprocessing
| Customized class  ** ** Must** ** class properties per layer require `@Type` |

```ts
/ Correct Usage: Embedded Object Layer by Layer@Type
@ObservedV2
class EqualizerSettings {
  @Trace public bassLevel: number = 5
}

@ObservedV2
class PlayerConfig {
  @Type(EqualizerSettings)
  @Trace public equalizer: EqualizerSettings = new EqualizerSettings()
}
```

Key points: `@Type` is used in conjunction with `@Trace`, `@Type` ensures the correct sequence/reverse sequence, and `@Trace` ensures that changes in properties are detectable and automatically persistent. `@Type` may only be used in a class of `@ObservedV2` decorations and not in a class of custom components or `@Observed` decorations. Simple types (string, Nuber, Bolean) and tectonic functions are not supported.
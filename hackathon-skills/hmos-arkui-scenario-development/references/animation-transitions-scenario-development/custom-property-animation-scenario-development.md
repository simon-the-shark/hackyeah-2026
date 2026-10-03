# Custom attribute animation case set

# Apply scene

* Reissued for technical reasons.
|---|---|---|
|Tab indicator slides | `@AnimatableExtend` drive two width + transport | width separately is layout property, standard `.animation()` cannot drive, must expand |
| Multi-Element Synchronization |XKEEP0ZX Custom Type + Multiple `@AnimatableExtend` | Multiple visual elements share the same data source, one-value-drive all |
| `ChartData` array `AnimatableArithmetic` | stand-alone plug-in value for each column, and the margin varies naturally over different transition periods

# Core Animation API Enumeration Reference

# @AnistableExtend

| Feature | Description |
|---|---|
`Column`, `Row`, `Text`, `Image`, etc.
| Parameter Type | Support base type `number` and support the custom type for achieving `AnimatableArithmetic<T>`
Z Animation Drive | State changes automatically frame by frame after binding `.animation()`
| The properties defined by  `.animation()` need to follow the `.animation()` given curve and duration after their call

Interface Method

Method
|---|---|---|
`plus()` |`(rhs: T) => T` | Current value plus target value |
Z`subtract()` |`(rhs: T) => T` | Current value minus target value (calculating margin) |
Z`multiply()` |`(scale: number) => T` | Current value multiplied by the plug-in factor (0~1) |
Z `equals()` | `(rhs: T) => boolean` | to determine whether the two values are equal (to determine the end of the animation) |

> ** Design principle: ** Custom animated type contains only `number` fields that require participation in frame-by-frame. The properties (ZXKEEP1Z, `Resource`, etc.) of the non-value interpolation values of colours should not be placed in the type and be separated into separate ZXXKEEP3ZX variables.

# # Curve numeric count value (authentic animation is common)

| | |
|---|---|---|
Z `Curve.EaseInOut` | Slow-Quick-Slow, two-end slow motion | Tab indicator slides, weather deformation, column pattern switching |

---

# scene 1: Underlined tab

** scene description:** Like today ' s headline Tab bar, when clicking on a different label, the bottom underlined indicator smooths down to the lower of the corresponding label, with the width of the line simultaneously changing by frame, toggle with the hand slide.

** Solution:** Use **`@AnimatableExtend(Column)` Extension `width` frame-by-frame** ** **`@AnimatableExtend(Row)` Extension `translate` Migration** ** ** ** `.animation()` Invisible Animation** ** ** ** **`onAreaChange` Measurement of the width of Tab column**

Step 1: Define Two

```ts
@AnimatableExtend(Column)
function animatableIndicatorWidth(w: number) {
  .width(w)
}

@AnimatableExtend(Row)
function animatableTranslateX(x: number) {
  .translate({ x: x })
}
```

Key points: `animatableIndicatorWidth` changes in frame-by-frame layout of `animatableIndicatorWidth` with `number` type driver for Column; `width` shift of ZXXKEEP4ZX for `animatableTranslateX` driver Row. Two decoders act on different components to achieve animate the underlined width + position.

### Step 2: measure width + calculate offset

```ts
Row() {
  ForEach(this.tabs, (tab: string, index: number) => {
    Column() { Text(tab) }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTab = index
        if (this.tabBarWidth > 0) {
          let tabWidth = this.tabBarWidth / this.tabs.length
          this.indicatorOffsetX = tabWidth * index
        }
      })
  })
}
.width('100%')
.onAreaChange((_oldArea: Area, newArea: Area) => {
  this.tabBarWidth = newArea.width as number
  let tabWidth = (newArea.width as number) / this.tabs.length
  this.indicatorOffsetX = tabWidth * this.currentTab
})
```

Key points: `onAreaChange` obtains the actual width of the Tab bar upon completion of the first layout, which calculates the equal width of each Tab and the initial deviation of the underline.

Step 3: Underline indicator - two @animateExtend

```ts
Stack() {
  Row() {
    Column() {}
      .animatableIndicatorWidth(this.indicatorWidth)
      .height(3)
      .borderRadius(2)
      .backgroundColor('#007dff')
      .animation({ duration: 300, curve: Curve.EaseInOut })
  }
  .width(this.tabBarWidth > 0 ? this.tabBarWidth / this.tabs.length : '25%')
  .justifyContent(FlexAlign.Center)
  .animatableTranslateX(this.indicatorOffsetX)
  .animation({ duration: 300, curve: Curve.EaseInOut })
}
.width('100%')
.alignContent(Alignment.Start)
```

Key points:
- Inner layer Column controls the actual width of the underlined through `animatableIndicatorWidth`
- Outer Row controls the horizontal offset of the Tab grid by `animatableTranslateX`
- Two `.animation()` bound to drive frame-by-frame plug-in after each `@AnimatableExtend` call

---

scene 2: weather icon deformation

** scene description:** Simulates weather app, clicks on different weather types (clair/mud/rain/negative), icons such as solar radius, cloud transparency, raindrop transparency, transitions through `@AnimatableExtend` frame-by-frame plug-in smooth-conforming, synchronized back-to-back colour transitions.

** Solution:** Use **`AnimatableArithmetic` with `number` field only ** Non-plug-in data such as ZXKEEP2Z** ** independent `WeatherStyle` management color** ** ** ** Multiple `@AnimatableExtend` drive different elements** ** ** `.animation()` hidden animation**

> ** Design principle:** Split data into two class - `WeatherAnimData` fields containing only `number` fields (`sunRadius`, `cloudOpacity`, `rainOpacity`) with participation in frame-by-frame plug values, achieving ZXXKEEP5ZX interfaces; ZXXKEEP6ZX fields containing non-value plugin values such as colour, temperature, name, etc., are managed separately as regular class. This way the `@AnimatableExtend` function receives only `WeatherAnimData` and does not misread non-insertible fields.

Step 1: Define two class -- animable data separated from animated data

```ts
/ Animable data: contains only number fields and achieves animable Arisetic
class WeatherAnimData implements AnimatableArithmetic<WeatherAnimData> {
  sunRadius: number = 30
  cloudOpacity: number = 0
  rainOpacity: number = 0

  constructor(sunRadius: number = 30, cloudOpacity: number = 0, rainOpacity: number = 0) {
    this.sunRadius = sunRadius
    this.cloudOpacity = cloudOpacity
    this.rainOpacity = rainOpacity
  }

  plus(rhs: WeatherAnimData): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius + rhs.sunRadius,
      this.cloudOpacity + rhs.cloudOpacity,
      this.rainOpacity + rhs.rainOpacity
    )
  }

  subtract(rhs: WeatherAnimData): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius - rhs.sunRadius,
      this.cloudOpacity - rhs.cloudOpacity,
      this.rainOpacity - rhs.rainOpacity
    )
  }

  multiply(scale: number): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius * scale,
      this.cloudOpacity * scale,
      this.rainOpacity * scale
    )
  }

  equals(rhs: WeatherAnimData): boolean {
    return this.sunRadius === rhs.sunRadius &&
           this.cloudOpacity === rhs.cloudOpacity &&
           this.rainOpacity === rhs.rainOpacity
  }
}

/ / Non-animated data: colour, temperature, name, etc., normal class does not perform interfaces
class WeatherStyle {
  bgColor1: string = '#87CEEB'
  bgColor2: string = '#E0F0FF'
  temp: string = '26°'
Name: string = 'Sky'
  icon: string = '☀️'
}
```

Key points:
- ** `WeatherAnimData` All ZXXKEEP1ZX**: `plus/subtract/multiply` accurate numerical operation for each field, no problem of type mixing
- **`WeatherStyle` does not fulfil `AnimatableArithmetic`**: `string` fields such as colours cannot be numeric plug-in, transitioning through direct grant + `.animation()` hidden animation in stand-alone class
- The parameter type of the `@AnimatableExtend` function after split is `WeatherAnimData`. The translation period eliminates the possibility of misreading ZXXKEEP2ZX fields

Step 2: Status and weather configuration

```ts
@State animData: WeatherAnimData = new WeatherAnimData(30, 0, 0)
@State style: WeatherStyle = new WeatherStyle()
@State weatherIndex: number = 0

/ / Weather Configuration Group: Each group contains both animable and non-animable data
private weatherConfigs: [WeatherAnimData, WeatherStyle][] = [
[new Weather AnimData (30, 0, 0), {bgColor1: '#87CEEB', bgColor2: '#E0FFF', temp: '26°', name: 'Cool', icon: 'Pyle'],
[new Weather AnimData (30, 0.6, 0), {bgColor1: '#B0C4DE', bgColor2: '#D6EAF8', Temp: '22°', name: 'Max', icon: 'Cyle'],
[new Weather AnimData (0, 0.8, 1), {bgColor1: '#778899', bgColor2: '#B0C4DE', Temp: '18°', name: 'rain', icon: 'shyle'],
[new WeatherAnimData (0, 1, 0), {bgColor1: '#A9A9', bgColor2: '#D3D3', Temp: '15°', name: 'Face', icon: 'Cyle'],
]
```

Step 3: Define

```ts
@AnimatableExtend(Column)
function animatableSunSize(data: WeatherAnimData) {
  .width(data.sunRadius > 0 ? data.sunRadius * 2 : 0)
  .height(data.sunRadius > 0 ? data.sunRadius * 2 : 0)
  .borderRadius(data.sunRadius > 0 ? data.sunRadius : 0)
}

@AnimatableExtend(Column)
function animatableCloudOpacity(data: WeatherAnimData) {
  .opacity(data.cloudOpacity)
}

@AnimatableExtend(Row)
function animatableRainOpacity(data: WeatherAnimData) {
  .opacity(data.rainOpacity)
}
```

Key points: The parameter for each `@AnimatableExtend` is `WeatherAnimData` (sole `number`) and only `number` fields are read in the function. Frame-by-frame call `subtract → multiply` when the median is reached, and each field is the result of an exact value plug-in.

## # Step 4: Toggle weather - Animated data grant trigger plugin, not animated data separately

```ts
switchWeather(index: number) {
  this.weatherIndex = index
  let [animData, style] = this.weatherConfigs[index]

/ / Animable data: Auto-Framework-by-Fix
  this.animData = animData

/ / Non-animation data: directly assigned, transitioned from .animation() hidden animations on components
  this.style = style
}
```

Key points: After `this.animData = animData` is given, the frame calls the frame-to-scope plugin for old `WeatherAnimData` and new `WeatherAnimData`. `this.style = style` is an ordinary object grant, and colour changes are processed by `.animation()` on Stack.

Step 5: UI Layout - @AnimableExtend Drive Icon, .animation() Driver Background Colour

```ts
Stack() {
/ SunSunSize Drive
  Column() {}
    .animatableSunSize(this.animData)
    .linearGradient({ angle: 135, colors: [['#FFD700', 0], ['#FFA500', 1]] })
    .shadow({ radius: 20, color: '#FFD70066' })
    .animation({ duration: 600, curve: Curve.EaseInOut })

// Cloud - animateCloudOpacity Drive
  Column() {}
    .width(60).height(30).borderRadius(15)
    .backgroundColor('#ffffff')
    .animatableCloudOpacity(this.animData)
    .animation({ duration: 600, curve: Curve.EaseInOut })

/ / Raindrop  animatable RainOpacity driver
Row({space: 10}){/* Raindrop Element*/}
    .animatableRainOpacity(this.animData)
    .animation({ duration: 600, curve: Curve.EaseInOut })
}
.width('100%').height(280)
.linearGradient({
  angle: 180,
  colors: [[this.style.bgColor1, 0], [this.style.bgColor2, 1]]
})
.animation({duration: 600, curve: Curve. EaseInout}) // Background hidden animation
```

Key points:
- ** Three `@AnimatableExtend` bound to the same ZXKEEP1Z**: a total plug-in value for ZXXKEEP2ZX, with a median of three functions per frame, solar dimensions, cloud transparency, raindrop transparency
- ** Background colour binding `this.style` + ZXKEEP1Z**: `WeatherStyle` does not participate in `AnimatableArithmetic` operation, `.animation({ duration: 600 })` allows `linearGradient` to smooth the colour transition

---

Scene 3: Chart Data Switch

** scene description: ** Simulates the data viewer and clicks to switch different data sets (receivers/users/orders), the column height is smoothed to new values by `ChartData` frame-by-scope plug-in of the custom type.

** Solution:** ** The `AnimatableArithmetic<ChartData>` interface** ** `@AnimatableExtend(Column)` Extension ZXKEEP3Z** ** ** `.animation()` driver height change**

Step 1: Define ChartData Customly Define Animable Type

> ** Design principles:** Custom animated types** contain only `number` fields ** that require participation in frame-by-frame plugs. The properties (ZXKEEP1Z, `Resource`, etc.) of the non-value interpolation values of colours should not be placed into the type, and separate `@State` variables should be managed separately, avoiding the return of ZXXKEEP4ZX to process meaningless originals.

```ts
class ChartData implements AnimatableArithmetic<ChartData> {
  values: number[] = []

  constructor(values: number[]) {
    this.values = values
  }

  plus(rhs: ChartData): ChartData {
    let newValues: number[] = []
    for (let i = 0; i < this.values.length; i++) {
      newValues.push(this.values[i] + rhs.values[i])
    }
    return new ChartData(newValues)
  }

Subtract(rhs: ChartData): ChartData {/ * Corresponding element minus */ }
Multiply (rhs: number): ChartData {/ * All elements multiplied by coefficient*/ }
equals (rhs:chartData): Boolean {/ * Element by Element */ }
}
```

Key points:
- Each element of the `values` array participates independently in the interpolation. Animation frames do `ChartData` as a whole.
- When `@State animatableData: ChartData` status changes, frame automatically inserts a value to ChatData
-** Does not contain `color` fields**: colour is an unvalueable `string` type, column colour driven by a separate `@State chartColor` in step 4

Step 2: High

```ts
@AnimatableExtend(Column)
function animatableBarHeight(h: number) {
  .height(h)
}
```

Step 3: ForEach — bindable Data.values

```ts
Row() {
  ForEach([0, 1, 2, 3, 4, 5, 6], (index: number) => {
    Column() {
      Column() {}
        .width(24)
        .borderRadius({ topLeft: 4, topRight: 4 })
        .backgroundColor(this.chartColor)
        .animatableBarHeight(this.animatableData.values[index] * 2)
        .animation({ duration: 500, curve: Curve.EaseInOut })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .height(200)
  })
}
.width('100%')
.height(200)
.alignItems(VerticalAlign.Bottom)
```

Key points:
- `animatableData.values[index] * 2` - Take the value of the corresponding index from the `ChartData` array of values multiplied by the coefficient to the height of the column
- Animated frame-by-frame calculation of the median of `ChartData`, `values[index]` for each frame is changing, driving ZXXKEEP2ZX for a frame-by-frame update for Column
- All 7 columns share the same `animatableData` state, all columns synchronized smooth transitions at data set switching

Step 4: Toggle Data Set

```ts
switchDataSet(index: number) {
  this.animatableData = new ChartData([...this.dataSets[index].values])
  this.chartColor = this.dataSets[index].color
  this.selectedBar = -1
}
```

Key points: `new ChartData([...this.dataSets[index].values])` creates a new array with an open operator to ensure that ArkUI detects `values` reference changes. `chartColor` is assigned as a separate `@State string` value and does not participate in the `AnimatableArithmetic` operation. After `this.animatableData`, the frame calls `ChartData` for the old `ChartData` and the new ZXXKEEP7ZX.

---

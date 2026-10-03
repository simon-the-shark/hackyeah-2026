# Hand gesture type scene

# ZXKEEP0Zx TapGesture double-click zoom pictures

** Applicable scenario: ** Used when a specific function needs to be triggered by multiple quick clicks on the same component. For example, double-click magnifying/downsizing the picture in the picture viewer, or double-clicking the collection, double-clicking the praise, etc. `TapGesture` specifies the number of consecutive hits by `count` parameters. `count: 2` is a double-click response.

# That's what it takes #

1. ** Declared Zoom State**: `@State imageScaleInfo: ScaleModel` Saves current Zoom Values and Default Zoom Values
2. ** Double-click sign**: `.gesture(TapGesture({ count: 2 }).onAction(...))` on Image container (e. g. Stack)
3. **judges the current scaling up**: compare `scaleValue` with `defaultScaleValue` decides to zoom in or restore this execution
4.** Package animated transition status* *: Update with `runWithAnimation(() => { ... })` package `scaleValue` grant and `matrix` matrix to avoid mutation

```typescript
@Component
@Reusable
export struct ImageItemView {
  @Link isEnableSwipe: boolean;
  @State imageScaleInfo: ScaleModel = new ScaleModel(1.0, 1.0, 1.5, 0.3);
  @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy();
  @State imagePixelMap: image.PixelMap | null = null;
  @State fitWH: "width" | "height" | undefined = undefined;
  @State imageDefaultSize: image.Size = { width: 0, height: 0 };
  imageUri: string = "";
  imageWHRatio: number = 0;

  build() {
    Stack() {
      Image(this.imagePixelMap)
        .width(this.fitWH === "width" ? "100%" : undefined)
        .height(this.fitWH === "height" ? "100%" : undefined)
        .aspectRatio(this.imageWHRatio)
        .objectFit(ImageFit.Cover)
        .autoResize(false)
        .transform(this.matrix)
    }
    .gesture(
/ Double-click to switch image scaling
      TapGesture({ count: 2 })
        .onAction(() => {
          if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.defaultScaleValue) {
/ / amplified Zoom Double-click returned
            runWithAnimation(() => {
              this.isEnableSwipe = true;
              this.imageScaleInfo.reset();
              this.matrix = matrix4.identity().copy();
            });
          } else {
// Default Size Zoom Double-click Zoom Fit Screen
            runWithAnimation(() => {
              this.isEnableSwipe = false;
              const ratio = this.calcFitScaleRatio(this.imageDefaultSize, windowSizeManager.get());
              this.imageScaleInfo.scaleValue = ratio;
              this.matrix = matrix4.identity().scale({ x: ratio, y: ratio }).copy();
              this.imageScaleInfo.stash();
            });
          }
        })
    )
  }
}
```

---

# SCENE-02 PanGesture inertial slide

** Applicable scenario: ** Used when a self-defined component is required to achieve the inertial effect of continuing to slide and gradually slowing down after removal. For example, custom-defined drag-and-truck scenarios such as panels, suspension balls, canvassing, and system packaging components (List, Scroll, etc.) have their own inertial scrolls, but custom components need to be made manually through `PanGesture`.

**Accomplishment principle: **Sliding speed (ZXKEEP1Z/`velocityX`) on `onActionEnd` in the ZXKEEP0Z echo to calculate inertia distance by multiplying it with the decay factor and then to simulate physical inertia by moving the `animateTo` drive to the target position.

# That's what it takes #

1.** Declaration of position and deviation* *: `@State offsetX/offsetY` indicates the current shift, `@State positionX/positionY` records the last stop position
2. ** Configure PanGestureOptions**: `new PanGestureOptions({ direction: PanDirection.Up | PanDirection.Down })`
3. **PanGesture**: on component `.gesture(PanGesture(this.panOption).onActionStart(...).onActionUpdate(...).onActionEnd(...))`
4. **update phase based on historical position**: `this.offsetX = this.positionX + event.offsetX`
5. **end phase save final position**: write the current deviation to `positionX/positionY` as the next gesture benchmark
6. **Drive inertial animation**: `this.getUIContext().animateTo({ duration: 1000, curve: Curve.LinearOutSlowIn }, () => { this.offsetY += event.velocityY * 0.2 })`

```typescript
@Entry
@Component
struct InertialScrollExample {
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State positionX: number = 0;
  @State positionY: number = 0;
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Up | PanDirection.Down });

  build() {
    Column() {
      Text('PanGesture offset: \nX: ' + this.offsetX + '\n' + 'Y: ' + this.offsetY)
    }
    .height(200)
    .width(200)
    .padding(20)
    .border({ width: 3 })
    .margin(30)
// Move at point of origin with the upper left corner of the component
    .translate({
      x: this.offsetX,
      y: this.offsetY,
      z: 0
    })
    .gesture(
      PanGesture(this.panOption)
        .onActionStart(() => {
          console.info('Pan start');
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (event) {
/ / 1 Draging: Current position = Last stop + This drag offset
            this.offsetX = this.positionX + event.offsetX;
            this.offsetY = this.positionY + event.offsetY;
          }
        })
        .onActionEnd((event) => {
/ / 2 to record the final location of the release
          this.offsetX = this.positionX + event.offsetX;
          this.offsetY = this.positionY + event.offsetY;
          this.positionX = this.positionX + event.offsetX;
          this.positionY = this.positionY + event.offsetY;
/ 3 Take off hand velocity multiplied by inert distance by decay factor
          let ySpeed = event.velocityY;
/ / 4 animateTo + Decreasing curves drive inertial animation
          this.getUIContext().animateTo({
            duration: 1000,
Curve: Curve. LinearOutSlowIn, / //Slow and Simulate Physical Deviation
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
              console.info('play end');
            }
          }, () => {
This.offsety = this.offsety + ySpeed*0.2;//0.2 is the decay factor, which controls inertial distance
            this.positionY = this.positionY + ySpeed * 0.2;
          })
        })
    )
  }
}
```

---

# SCENE-03 PinchGesture

**Applicable scene: **Used when the two-finger scaling of the picture previewer is required. For example, the album looks at large graphics, chat pictures previews, and friend-circle photo browsing, where the user zooms through two fingers/opens the picture, and the picture zooms or shrinks on the basis of a two-finger centre point (i.e. "Hand hands" scaling).

**House of realization: ** Scaled through `matrix4.identity().scale()` matrix transformation, offset by `translate()` attribute. The core is to calculate the percentage location of the scaling centre and the additional deviations that occur when the scaling centre is not in the middle of the picture.

** Offset formula ( "Hand Hands" method):**

```
scale'    = lastScale * scale
offsetX'  = (lastOffsetX + offX) + (0.5 - centerX) * imageWidth * (1 - scale) * lastScale
offsetY'  = (lastOffsetY + offY) + (0.5 - centerY) * imageHeight * (1 - scale) * lastScale
```

- `scale`: Relative scaling of the gesture (starting with 1.0)
`lastScale`/`lastOffsetX`/`lastOffsetY`: Status at end of last gesture
- `offX`/`offY`: Diversion of this gesture
- `centerX`/`centerY`: Percentage location of zoom centres relative to pictures (`1 - evaluateCenter()`)

# That's what it takes #

1. ** Encapsulated Zoom Model**: definition of `ImageZoomModel` centrally managed `curScale/curOffsetX/curOffsetY/centerX/centerY` state
2. ** Calculated Zoom Centre**: `pinchGestureStart` call `evaluateCenter(pinchCenterX, pinchCenterY)` received percentage position and took reverse ZXXKEEP2ZX
3. **Change formula**: Update offset in `onScale()` by `offsetX' = (lastOffsetX + offX) + (0.5 - centerX) * imageWidth * (1 - effectiveScale) * lastScale`
4. **Scalding scaling ratio**: replace the original `effectiveScale = maxScale / lastScale` with `effectiveScale = maxScale / lastScale` participation offset calculation when exceeding `minScale/maxScale` to avoid drift after reaching the limit
5. ** Boundaries limit**: `pictureBoundaryRestriction()` Stressing offsets to ZXXKEEP1ZX, with pictures smaller than on screens and forced to centre
6. ** Save sign end**: `gestureEnd()` Write `cur*` to `last*` as the next sign benchmark, scale ZiZ to call ZXXKEEP3ZX when default
7.** Combination of cross-repeated gestures**: `GestureGroup(GestureMode.Exclusive, PinchGesture, PanGesture, TapGesture)`
8. **Sync Model to UI**: Call `syncState()` after every turnback to write back ZXXKEEP1ZX to @State

```typescript
import { matrix4 } from '@kit.ArkUI';

/ / 1 Zoom Model: Manage the scaling and offset calculations
export class ImageZoomModel {
  componentWidth: number = 0;
  componentHeight: number = 0;
  imageWidth: number = 0;
  imageHeight: number = 0;
  readonly minScale: number = 1.0;
  readonly maxScale: number = 5.0;
  readonly defaultScale: number = 1.0;
  curScale: number = 1.0;
  lastScale: number = 1.0;
  curOffsetX: number = 0;
  curOffsetY: number = 0;
  lastOffsetX: number = 0;
  lastOffsetY: number = 0;
  centerX: number = 0.5;
  centerY: number = 0.5;
  maxOffsetX: number = 0;
  minOffsetX: number = 0;
  maxOffsetY: number = 0;
  minOffsetY: number = 0;
  matrix: object = matrix4.identity().copy();
  isArriveBoundary: boolean = false;

/ / Core offset calculation: the zoom centre produces additional deviations when it is not in the middle of the picture
  onScale(scale: number, offX: number, offY: number): void {
    this.curScale = this.lastScale * scale;
    let effectiveScale = scale;
    if (this.curScale < this.minScale) {
      effectiveScale = this.minScale / this.lastScale;
      this.curScale = this.minScale;
    } else if (this.curScale > this.maxScale) {
      effectiveScale = this.maxScale / this.lastScale;
      this.curScale = this.maxScale;
    }
    this.curOffsetX =
      (this.lastOffsetX + offX) + (0.5 - this.centerX) * this.imageWidth * (1 - effectiveScale) * this.lastScale;
    this.curOffsetY =
      (this.lastOffsetY + offY) + (0.5 - this.centerY) * this.imageHeight * (1 - effectiveScale) * this.lastScale;
    this.isArriveBoundary = false;
  }

// Calculate the percentage location of the zoom centre relative to the picture
  evaluateCenter(centerX: number, centerY: number): [number, number] {
    let imgW = this.imageWidth * this.lastScale;
    let imgH = this.imageHeight * this.lastScale;
    let imgX = (this.componentWidth - imgW) / 2 + this.lastOffsetX;
    let imgY = (this.componentHeight - imgH) / 2 + this.lastOffsetY;
    let cX = Math.max(0, Math.min(1, (centerX - imgX) / imgW));
    let cY = Math.max(0, Math.min(1, (centerY - imgY) / imgH));
    return [cX, cY];
  }

  pinchGestureStart(event: GestureEvent): void {
    let center = this.evaluateCenter(event.pinchCenterX, event.pinchCenterY);
This.centerX = 1 -center[0]; / / Note to reverse and align with the offset formula
    this.centerY = 1 - center[1];
  }

  pinchGestureUpdate(event: GestureEvent): void {
    this.onScale(event.scale, event.offsetX, event.offsetY);
    this.matrix = matrix4.identity().scale({ x: this.curScale, y: this.curScale }).copy();
    this.evaluateOffsetRange();
    this.pictureBoundaryRestriction();
  }

  panGestureUpdate(event: GestureEvent): void {
    this.onScale(1.0, event.offsetX, event.offsetY);
    this.evaluateOffsetRange();
    this.pictureBoundaryRestriction();
  }

  gestureEnd(): void {
    this.lastScale = this.curScale;
    this.lastOffsetX = this.curOffsetX;
    this.lastOffsetY = this.curOffsetY;
    if (this.curScale <= this.defaultScale) {
      this.reset();
    }
  }

// Calculation of boundary ranges
  evaluateOffsetRange(): void {
    let sw = this.imageWidth * this.curScale;
    let sh = this.imageHeight * this.curScale;
    this.maxOffsetX = sw > this.componentWidth ? (sw - this.componentWidth) / 2 : 0;
    this.minOffsetX = -this.maxOffsetX;
    this.maxOffsetY = sh > this.componentHeight ? (sh - this.componentHeight) / 2 : 0;
    this.minOffsetY = -this.maxOffsetY;
  }

/ Boundary limits: prevent pictures from being towed out of visible areas
  pictureBoundaryRestriction(): void {
    if (this.curOffsetX > this.maxOffsetX) { this.curOffsetX = this.maxOffsetX; this.isArriveBoundary = true; }
    else if (this.curOffsetX < this.minOffsetX) { this.curOffsetX = this.minOffsetX; this.isArriveBoundary = true; }
    if (this.curOffsetY > this.maxOffsetY) { this.curOffsetY = this.maxOffsetY; }
    else if (this.curOffsetY < this.minOffsetY) { this.curOffsetY = this.minOffsetY; }
    if (this.imageWidth * this.curScale <= this.componentWidth) { this.curOffsetX = 0; }
    if (this.imageHeight * this.curScale <= this.componentHeight) { this.curOffsetY = 0; }
  }

  reset(): void {
    this.curScale = this.defaultScale; this.lastScale = this.defaultScale;
    this.curOffsetX = 0; this.curOffsetY = 0;
    this.lastOffsetX = 0; this.lastOffsetY = 0;
    this.centerX = 0.5; this.centerY = 0.5;
    this.matrix = matrix4.identity().copy();
  }

  initImageSize(rawW: number, rawH: number): void {
    if (this.componentWidth <= 0 || this.componentHeight <= 0) return;
    let ratio = Math.min(this.componentWidth / rawW, this.componentHeight / rawH);
    this.imageWidth = rawW * ratio;
    this.imageHeight = rawH * ratio;
  }
}

Page: PinchGesture + PanGesture + TapGesture
@Entry
@Component
struct ImageZoomPage {
  @State matrix: object = matrix4.identity().copy();
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State imageWidth: number = 0;
  @State imageHeight: number = 0;
  @State scaleValue: number = 1.0;
  private model: ImageZoomModel = new ImageZoomModel();

  build() {
    Column() {
      Stack() {
        Image($r('app.media.large_image'))
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
.transform(this.matrix) / /matrix4 matrix zoom
.translate({x: this.offsetX, y: this.offsetY} / / Offset
          .onComplete((event) => {
            if (event) {
              this.imageWidth = event.width;
              this.imageHeight = event.height;
              this.model.initImageSize(event.width, event.height);
            }
          })
      }
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Center)
      .onAreaChange((_old: Area, area: Area) => {
        this.model.componentWidth = Number(area.width);
        this.model.componentHeight = Number(area.height);
        if (this.imageWidth > 0 && this.imageHeight > 0) {
          this.model.initImageSize(this.imageWidth, this.imageHeight);
        }
      })
      .gesture(
        GestureGroup(GestureMode.Exclusive,
/ / Double-finger scaling
          PinchGesture({ fingers: 2, distance: 1 })
            .onActionStart((event: GestureEvent) => {
              this.model.pinchGestureStart(event);
            })
            .onActionUpdate((event: GestureEvent) => {
              this.model.pinchGestureUpdate(event);
              this.syncState();
            })
            .onActionEnd(() => {
              this.model.gestureEnd();
              this.syncState();
            }),
/ / Single-finger offset
          PanGesture({ fingers: 1, distance: 5 })
            .onActionUpdate((event: GestureEvent) => {
              this.model.panGestureUpdate(event);
              this.syncState();
            })
            .onActionEnd(() => {
              this.model.gestureEnd();
              this.syncState();
            }),
// Double-click Zoom/ Restore
          TapGesture({ count: 2 })
            .onAction((event: GestureEvent) => {
              if (event.fingerList && event.fingerList.length > 0) {
                this.model.doubleTap(event.fingerList[0].localX, event.fingerList[0].localY);
                this.syncState();
              }
            })
        )
      )
    }
    .width('100%')
    .height('100%')
  }

  private syncState(): void {
    this.matrix = this.model.matrix;
    this.offsetX = this.model.curOffsetX;
    this.offsetY = this.model.curOffsetY;
    this.scaleValue = this.model.curScale;
  }
}
```

---

# ZXKEEP0Z RotationGesture

** Applicable scenario: ** Used when an angle rotation of components by double-finger rotation is required. For example, the two-finger rotation of pictures, maps, etc. in the picture viewer. `RotationGesture` sets the trigger threshold through the `angle` parameter, and in turn `event.angle` obtains a real-time rotation angle, matching the ZXXKEEP3ZX matrix transformation.

# That's what it takes #

1. ** Declaration of rotation model**: `@State imageRotateInfo: RotateModel` Save `currentRotate/lastRotate/startAngle`
2. ** set trigger threshold**: `RotationGesture({ angle: this.imageRotateInfo.startAngle })` set a larger value (e.g. 20°) to avoid an error in finger shaking
3. **RotationGesture**: on component `.gesture(RotationGesture(...).onActionUpdate(...).onActionEnd(...))`
4. **update phase cumulative angle**: `angle = lastRotate + event.angle`, positive/negative minus/plus `startAngle` fix threshold to avoid starting Jump.
5.** Application of Z-axis rotation matrix**: `matrix4.identity().rotate({ x: 0, y: 0, z: 1, angle }).copy()` to avoid cumulative errors each time it is rebuilt from unit matrix
6. **end phase adsorption 90° multiple**: update the matrix in `simplestRotationQuarter(currentRotate)` and call `stash()` to save as next base

```typescript
@Component
export struct PicturePreviewImage {
  @State imageRotateInfo: RotateModel = new RotateModel();
  @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy();

  build() {
    Stack() {
      Image(this.imageUrl)
        .objectFit(ImageFit.Cover)
        .transform(this.matrix)
    }
    .gesture(
/ / 1 RotationGesture: Two-finger rotation pictures
      RotationGesture({ angle: this.imageRotateInfo.startAngle })
        .onActionUpdate((event: GestureEvent) => {
/ / Aggregation angle = last stop angle + this gesture angle degrees
          let angle = this.imageRotateInfo.lastRotate + event.angle;
/ Minus trigger threshold angle to avoid a picture jump when rotation starts Change
          if (event.angle > 0) {
            angle -= this.imageRotateInfo.startAngle;
          } else {
            angle += this.imageRotateInfo.startAngle;
          }
/ / 2 rotates through matrix4 around Z-axis
          this.matrix = matrix4.identity()
            .rotate({ x: 0, y: 0, z: 1, angle: angle })
            .copy();
          this.imageRotateInfo.currentRotate = angle;
        })
        .onActionEnd(() => {
/ 3 Unhand and absorb to the nearest 90° multiplier
          let rotate = simplestRotationQuarter(this.imageRotateInfo.currentRotate);
          runWithAnimation(() => {
            this.imageRotateInfo.currentRotate = rotate;
            this.matrix = matrix4.identity()
              .rotate({ x: 0, y: 0, z: 1, angle: rotate })
              .copy();
This.imageRotateInfo.stat(); / /saving the current angle as the next baseline
          });
        })
    )
  }
}
```

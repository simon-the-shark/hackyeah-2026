# Case of Custom Component (FrameNode) Set

# Functional points typically use scene comparison

| Self-defined competence | Typical use scenario | Core competencies | Not applicable
|-----------|------------|---------|-----------|
|DrawModifier (drawing) | Design Category App Gradual Border Buttons, External Photo Effects, Neon Lights, Chess Grid Background |DrawBehind/DrawFront Custom Drawing in Background and Foreground Layer | Changes Existing Properties, Replace Content Area |
|AttributeModifier (attributions) | Enterprise-level App Unified button style instruction (main/second/hazard/disabled 4-state) | Encapsulating multi-state style cross-file reuse, one example multi-component reuse | Custom drawing, dynamic gesture |
|GestureModifier (hand gesture) | Design Tool App Drag/Zoom/Rotation Mode Dynamically Switching Gesture |applyGesture Running Dynamics Switching Gesture Type | Static Gesture Tie |
|ContentModifier (ContentModifier) | global custom for the assembly button icon + text, CHeckbox collection toggle | applyContent replacement system component content area | changes properties only, superdraws |
|FrameNode (components) |JSON drive dynamic form, dynamic add/ remove form item running time | typeNode. Create/ remove node dynamic | structure determined by the compilation period |
|RenderNode (rendering) | electronic contract signing/fast-off handwritten signature in support of revocation/cleaning | rewrite method, invalidate() redraw frame by frame | low-frequency static drawing |
| BuilderNode (mixed) | News/Commodity Information Flow Advertisement, prefixed and filled in |BuilderNode.build Dynamic Construction Component Tree, rebuild() List of Lists of Structures Up Trees
XComponent (Surface) | Custom Drawing App Draws Graphics by SURFACE Type on Surface + LockCanvas/unlockCanvasAndPost | Static Photo Display

---

# scene I: Design class App button requires a gradient border + self-defined appearance such as light

**Scene Example Description**: In the Design Category App, buttons need to draw a unique gradient border + internal icon + self-defined appearance of external light effect that the system Button component cannot satisfy.

** Solution**: self-defining of components at the background and foreground levels using the DrawModifeier DrawBehind/drawFront method by drawing. Draws the gradient border and pattern background, draws external light and neon dizziness.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Attributemodifier | can only modify existing properties (colours/roundings, etc.) and cannot perform Canvas custom drawings
| ContentModifeier | is a replacement component content area, rather than superimpose custom drawing on the original component

```typescript
import { drawing } from '@kit.ArkGraphics2D';

// Gradient Border + External Light Modifier
class GradientBorderModifier extends DrawModifier {
  colors: number[][] = [
    [255, 255, 107, 107],  // #FF6B6B
    [255, 78, 205, 196],   // #4ECDC4
    [255, 85, 98, 112],    // #556270
  ];
  uiContext: UIContext;
  constructor(uiContext: UIContext) { super(); this.uiContext = uiContext; }

/ / DrawBehind: Draw gradient borders on the background layer
/ Note: consult. size returns vp, Canvas draws px, converts vp2px
  drawBehind(context: DrawContext): void {
    const wPx = this.uiContext.vp2px(context.size.width);
    const hPx = this.uiContext.vp2px(context.size.height);
    const borderW = this.uiContext.vp2px(3);
    const segW = context.size.width / this.colors.length;
// Top, Bottom Gradient
    for (let i = 0; i < this.colors.length; i++) {
      const brush = new drawing.Brush();
      brush.setColor({ alpha: this.colors[i][0], red: this.colors[i][1],
        green: this.colors[i][2], blue: this.colors[i][3] });
      context.canvas.attachBrush(brush);
      const leftPx = this.uiContext.vp2px(i * segW);
      const rightPx = this.uiContext.vp2px((i + 1) * segW);
      context.canvas.drawRect({ left: leftPx, top: 0, right: rightPx, bottom: borderW });
      context.canvas.drawRect({ left: leftPx, top: hPx - borderW, right: rightPx, bottom: hPx });
      context.canvas.detachBrush();
    }
/ / ... left and right border drawn in middle colour
  }

/ / DrawFront: Foreground layer mapping for exterior light (multilayer semi-transparent circle spreading outward)
  drawFront(context: DrawContext): void {
    const cx = this.uiContext.vp2px(context.size.width / 2);
    const cy = this.uiContext.vp2px(context.size.height / 2);
    const glowBrush = new drawing.Brush();
    for (let i = 5; i > 0; i--) {
      glowBrush.setColor({ alpha: 20, red: 78, green: 205, blue: 196 });
      context.canvas.attachBrush(glowBrush);
      context.canvas.drawCircle(cx, cy, this.uiContext.vp2px(30 + i * 6));
      context.canvas.detachBrush();
    }
  }
}

/ / Usage: bind to component by .drawmodifier()
Button
  .width(220).height(56).backgroundColor(Color.White)
  .drawModifier(new GradientBorderModifier(this.getUIContext()))
```

# DrawModifier method count

| Method | Level of drawing | Description |
|------|---------|------|
Z `drawBehind(context)` | Background Layer
Z `drawFront(context)` | Foreground layer | On the assembly foreground layer, above the component content |

# # drawing core object count

| Object | Role | Critical method |
|------|------|---------|
`drawing.Brush`| brush (fill) |XKEEP1ZX|
`drawing.Pen`  Z Brush (side) `setStrokeWidth()`, `setColor()`
`drawing.Path` PathPath `moveTo()`, `lineTo()`, ZXXKEEP3ZX|

# The principle of realization #

| Effects | Means of realization |
|------|---------|
| Gradient Border | Draw Coloured Border |
♪ External light ♪
Neon Lights DrawBehind Dark Background + DrawFront Multilayer Luminous Circle
DrawRect Draw Cells

---

# scene II: Enterprise-level App Encapsulated Unified Button Styles to support a four-state switch

** Example scenario description**: At the enterprise level App, a uniform set of button style specifications (main buttons/subbuttons/hazards buttons/disable), each of which has a different style under normal, pressured, focused, disabled, and style definitions require cross-file reuse and parameterization.

** Solution**: using the Attributemodifier\<ButtonAtribute\> encapsulating multi-state styles to achieve the four methods of apply NormalAttribute/applyPressedAttribute/applyFocusedAttribute/applyDisabledAttribute/applyDisabledAttribute, each status setting the corresponding colour/block/shading properties. A Modifeer example can be reused on a number of Buttons to support cross-file export.

| Alternatives | Reasons for impropriety |
|---------|------------|
@Styles
@Extend| only supports the extension of a specific component type with less flexibility than AttributeModifier|

```typescript
// Main Button Modiffier - Blue Filling, Four-State Styles
class PrimaryButtonModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#4A90D9')
      .fontColor(Color.White).borderRadius(24).border({ width: 0 })
      .shadow({ radius: 8, color: 'rgba(74, 144, 217, 0.3)', offsetY: 3 });
  }
  applyPressedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#357ABD')
      .fontColor(Color.White).borderRadius(24)
      .shadow({ radius: 2, color: 'rgba(74, 144, 217, 0.2)', offsetY: 1 })
      .scale({ x: 0.96, y: 0.96 });
  }
  applyFocusedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#4A90D9')
      .fontColor(Color.White).borderRadius(24)
      .border({ width: 2, color: '#1A5FB4' })
      .shadow({ radius: 12, color: 'rgba(74, 144, 217, 0.5)', offsetY: 3 });
  }
  applyDisabledAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#B0C4DE')
      .fontColor('rgba(255, 255, 255, 0.7)').borderRadius(24)
      .shadow({ radius: 0, color: 'rgba(0, 0, 0, 0)' }).opacity(0.6);
  }
}
```

# # Export cross-file with theme colour parameters

> The enterprise level scenario needs to be reused across the Modifuer file, and different business lines (main/hazard/success) revert to the same four-state logic only to change the theme colour. Below is the published version of the parametric guide, which is selected with the hard-coding version above.

```typescript
/ / Cross-file Export: The tectonic function receives the theme colour, the four-state colour is the theme colour Fan.
export class ThemeButtonModifier implements AttributeModifier<ButtonAttribute> {
  private themeColor: ResourceColor;
  constructor(themeColor: ResourceColor = '#4A90D9') {
    this.themeColor = themeColor;
  }

  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor)
      .fontColor(Color.White).borderRadius(24).border({ width: 0 })
      .shadow({ radius: 8, color: this.themeColor, offsetY: 3 });
  }
  applyPressedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor).opacity(0.85)
      .fontColor(Color.White).borderRadius(24)
      .shadow({ radius: 2, offsetY: 1 })
      .scale({ x: 0.96, y: 0.96 });
  }
  applyFocusedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor)
      .fontColor(Color.White).borderRadius(24)
      .border({ width: 2, color: this.themeColor })
      .shadow({ radius: 12, color: this.themeColor, offsetY: 3 });
  }
  applyDisabledAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor).opacity(0.6)
      .fontColor('rgba(255, 255, 255, 0.7)').borderRadius(24);
  }
}

/ / Following import of cross-files, the same Modifier class is repeated for different themes
import { ThemeButtonModifier } from './buttonModifiers';
= new ThemeButton Modiifier ('#4A90D9'); // main button
= new ThemeButton Modiifier ('#E74C3C'); // Hazardous button
```

Note
|------|------|
`export class` | definition plus export keyword to support other files import reuse |
The tectonic function receives `themeColor` | `this.themeColor` in a 4-D colour uniform reference, and re-enacts | in different lines with different colour values

```typescript
/ / Usage: one Modifier instance reuses to multiple Buttons
private primaryModifier: PrimaryButtonModifier = new PrimaryButtonModifier();

Button.
  .width(220).height(48)
  .attributeModifier(this.primaryModifier)

Button.
  .width(220).height(48).enabled(false)
.attribute Modifier (this.primaryModifier) // Reuse the same example
```

# Attribute Modifier #

| Method | Trigger timing | Typical change of style |
|------|---------|------------|
`applyNormalAttribute`| Normal
`applyPressedAttribute` | by pressure | by deepening background colour + scale (0.96) + dilution shadow |
`applyFocusedAttribute`| Focus | Add border border border + strengthen shadow
`applyDisabledAttribute`| Disable state | ash + less transparency + remove shadow |

---

# Scene III: Design tool App Painting elements to change gestures according to editing mode dynamics

**Scene Example Description**: Design Tool App, the graphic elements on the canvas need to change gesture behaviour according to the current editorial mode dynamic -- – Forced and drawn gestures under the selection mode, tied gestures under the scaling mode, rotated gestures under the rotation mode, and the type of gestures changed dynamically with the pattern.

** Solution**: Use the applicationGesture method of the GestureModifier interface and add different types of gesture processor (PanGestureHandler/PinchGestureHandler/RotationGestureHandler) to the current editorial mode dynamic. The handshake is effective for the next operation after the time of the gesture.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Static .gesture()| Directly bound gesture properties are static and cannot be dynamically changed while running
| Attribute Modifier | Attribute Modifier does not support the call for gesture setting

```typescript
enum EditMode { Drag, Scale, Rotate }

class ShapeGestureModifier implements GestureModifier {
  mode: EditMode = EditMode.Drag;
/ /Return function bound from the outside
  onDragUpdate: (offsetX: number, offsetY: number) => void = () => {};
  onScaleUpdate: (scale: number) => void = () => {};
  onRotateUpdate: (angle: number) => void = () => {};
/...other calls

  applyGesture(event: UIGestureEvent): void {
    if (this.mode === EditMode.Drag) {
      event.addGesture(new PanGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onDragUpdate(e.offsetX, e.offsetY); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    } else if (this.mode === EditMode.Scale) {
      event.addGesture(new PinchGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onScaleUpdate(e.scale); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    } else if (this.mode === EditMode.Rotate) {
      event.addGesture(new RotationGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onRotateUpdate(e.angle); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    }
  }
}

/ Usage: Update modifier.mode when switching mode by .gesturemodifier() binding
private shapeGestureModifier: ShapeGestureModifier = new ShapeGestureModifier();

Stack() {
Column(){/* Graphic content*/}
}
.translate({ x: this.shapeX, y: this.shapeY })
.scale({ x: this.shapeScale, y: this.shapeScale })
.rotate({ angle: this.shapeRotate })
.gestureModifier(this.shapeGestureModifier)

// Mode Switch
this.shapeGestureModifier.mode = EditMode.Scale;
```

# EditMode

It's all right.
|--------|-------------|---------|
`Drag` | PanGestureHandler
`Scale` | PinchGestureHandler | Double-finger scaling |
`Rotate` RotationGestureHandler

# GestureHandler type count

| Hand gesture processor | trigger condition | echo parameters |
|-----------|---------|---------|
`PanGestureHandler` |  Z  Z  Z
`PinchGestureHandler`
`RotationGestureHandler` ZEX ZERO

---

# scene IV: Component library fully customised Button content area is icon + text combination

**Scene Example Description**: A global customization of the content area of the system Button component is required in the assembly library - replace all Button's default text with a combination style of " Icon + Text" or add a custom collection to change content for Checkbox.

** Solution**: returns WrappedBuilder\[T]\, @Builder functions receive configuration types such as ButtonConfiguration or CheckBoxConfiguration using the ApplyContent method of ConstantModifer\[T]\, access to component status by config.label/config.pressed/config.selected/config.triggerChange.

| Alternatives | Reasons for impropriety |
|---------|------------|
| DrawModifeier | is superseding custom drawing without replacing original content
@Builder  @ needs to be replaced manually, ContentModifeer can be changed globally

```typescript
/ Button Content Custom: Icon + Text Group
class IconButtonModifier implements ContentModifier<ButtonConfiguration> {
  icon: string;
  iconColor: ResourceColor;
  constructor(icon: string, iconColor: ResourceColor) { this.icon = icon; this.iconColor = iconColor; }
  applyContent(): WrappedBuilder<[ButtonConfiguration]> {
    return wrapBuilder(buildIconButton);
  }
}

@Builder
function buildIconButton(config: ButtonConfiguration) {
  Row({ space: 8 }) {
    Text((config.contentModifier as IconButtonModifier).icon)
      .fontSize(18)
      .fontColor((config.contentModifier as IconButtonModifier).iconColor)
Text(config.label) / /config.label
      .fontSize(16)
.fontColor (config.pressed? '#357ABD':Color. Black) //config.pressed
  }.justifyContent(FlexAlign.Center)
}

/ Checkbox Content Custom: Collection Switch
/ Note: Modifier Custom Properties do not trigger refreshing, need to drive UI updates with config.selected
@Builder
function buildFavoriteCheckbox(config: CheckBoxConfiguration) {
  Row({ space: 6 }) {
Text(config.selected? '★: '☆') //config.selected
      .fontColor(config.selected ? '#F39C12' : '#999')
Text('repossession'). FontSize (14)
  }.onClick(() => {
/ /config.triggerChange trigger switch
  })
}

/ CHeckbox Collection Switched Modiffier: Enabled ContentModiffier<CheckBoxConfigration>
/ applyContent returns the wrapBuilder (buildFavoriteCheckbox), symmetrical to the IconButton Modifier structure
class FavoriteCheckboxModifier implements ContentModifier<CheckBoxConfiguration> {
  applyContent(): WrappedBuilder<[CheckBoxConfiguration]> {
    return wrapBuilder(buildFavoriteCheckbox);
  }
}

/ / Usage: binding by .contentmodifier()
Button.
  .width(220).height(48).borderRadius(24)
  .contentModifier(new IconButtonModifier('⬇', Color.White))

Checkbox({name: 'possession', group: 'favoriteGroup'})
  .select(this.favoriteOn)
  .contentModifier(new FavoriteCheckboxModifier())
```

No, no, no, no, no, no.

| Configuration type | Applicable component | Key properties/methods |
|---------|---------|------------|
| `ButtonConfiguration` | Button | `label` (text), `pressed` (whether or not to press), `contentModifier` (access to custom properties) |
|`CheckBoxConfiguration` |Checkbox |`selected` (optional status), `triggerChange(bool)` (trigger switch), `contentModifier` |

# ContentModiifier Key Constraints

* Reissued for technical reasons.
|------|------|
|Modifier Custom Properties do not trigger refreshing | like `isFavorited` does not drive UI updates, `config.selected` drives |
`config.contentModifier as XxxModifier`| Accessed Modifier Custom Properties in @Builder by Type
| One example can be reused | The same Modifeer example can be bound to multiple components of the same type |

---

# # scene five: dynamic forms generate/ remove form items from the JSON configuration running

**Scene Example Description**: Dynamic Form Pages need to generate form components (e.g. input boxes, switches, buttons) based on the JSON configuration that returns back to the backend, and to dynamically add or delete table items while running.

** Solutions**: Dynamic Node Management using NodeController + Frame Node + type Node. Create Node. Root packagings use type Node. Create Node (ctx, 'Column') to obtain a vertical flow layout, dynamically adding or deleting nodes through applicationchild/removechild. New/delete fields to directly operate single nodes without calling rebuld() and keep the remaining nodes as input.

| Alternatives | Reasons for impropriety |
|---------|------------|
@Builder | requires to determine the component structure during the compilation period and to generate different components types according to JSON dynamics when running
| Conditional rendering if/else | Dynamic display for fixed structure, fully dynamic node tree construction

```typescript
import { FrameNode, typeNode, NodeController, UIContext } from '@kit.ArkUI';

interface FormFieldConfig {
  type: 'TextInput' | 'Toggle' | 'Button';
  label: string;
  placeholder?: string;
}

class FormNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private uiContext: UIContext | null = null;
Private Field Nodes: Frame Node = [[]; / / Cache Node for delete location
  fields: FormFieldConfig[] = [];

  makeNode(uiContext: UIContext): FrameNode {
    this.uiContext = uiContext;
// Root packagings with Column type nodes: self-bound vertical flow layout, automatic weight when dynamic increase or deletion Line
    const root = typeNode.createNode(uiContext, 'Column');
    root.attribute.width('100%');
    this.rootNode = root;
    this.buildForm();
    return this.rootNode;
  }

// Create node of the corresponding type according to configuration
  createFieldNode(config: FormFieldConfig): FrameNode {
    if (config.type === 'Button') {
      const buttonNode = typeNode.createNode(this.uiContext!, 'Button');
ButtonNode.intilize (config.label); / /intilize settings initial
      buttonNode.attribute.backgroundColor('#4A90D9').borderRadius(8).height(40);
      return buttonNode;
    }
// Container Node
    const container = typeNode.createNode(this.uiContext!, 'Row');
    container.attribute.width('100%').padding({ /* ... */ });
// Tag Node
    const labelNode = typeNode.createNode(this.uiContext!, 'Text');
    labelNode.initialize(config.label);
    container.appendChild(labelNode);
/ / Enter Node
    if (config.type === 'TextInput') {
      const inputNode = typeNode.createNode(this.uiContext!, 'TextInput');
      inputNode.initialize({ placeholder: config.placeholder || '' });
      inputNode.attribute.backgroundColor('#F5F5F5').height(44).layoutWeight(1);
      container.appendChild(inputNode);
    } else if (config.type === 'Toggle') {
      const toggleNode = typeNode.createNode(this.uiContext!, 'Toggle');
      toggleNode.attribute.selectedColor('#4A90D9').width(48).height(24);
      container.appendChild(toggleNode);
    }
    return container;
  }

/ / Add field: only appendchild new node, not call rebuild, keep existing input
  addField(config: FormFieldConfig) {
    this.fields.push(config);
    if (this.rootNode) {
      const fieldNode = this.createFieldNode(config);
      this.rootNode.appendChild(fieldNode);
      this.fieldNodes.push(fieldNode);
    }
  }

/ Delete last field: remove Child only at the end node
  removeLastField() {
    this.fields.pop();
    if (this.rootNode) {
      const lastNode = this.fieldNodes.pop();
      if (lastNode) { this.rootNode.removeChild(lastNode); }
    }
  }
}

/ / Usage: NodeContainer Mount FrameNode Tree
NodeContainer(this.formController).width('100%')
```

Node type

| Node Type | Description of |initialize Parameter |attribute Key Method |
|---------|------|----------------|-------------------|
`Column` | Vertical layout container |
`Row` | Horizontal Layout Container |
`Text`| text component | text content
`TextInput`  Z input frame
`Toggle` | switch component
`Button` | Button Component | Button Text

# # FrameNode Operations List

| Method | Description of whether | triggers rebuild |
|------|------|----------------|
`appendChild(node)` | Add a new node after the last subnode
`removeChild(node)` | Delete the specified subnode | No, keep the rest of the node |
`clearChildren()` ZEQUIT ALL Subnodes

# Key constraints #

* Reissued for technical reasons.
|------|------|
| Root packagings shall be colloquially stacked by type Node.create Node (ctx, 'Column')
| Add/delete direct appendchild/removechild | do not call rebuild() and avoid re-establishing whole tree lost input status
| TypedFrameNode uses the.attribute.xx() | setting properties; initialize() sets the initial value |

---

# scene six: a handwritten signature on an electronic contract signing page draws a handwriting in real time

** Example description of the scene**: Electronic contract signing or express receipt page requiring the user to write a signature by hand on the screen and to draw a smooth handwriting in real time when the finger or touch pen drags and supports the cancellation of the previous step and the removal of the drawing board.

** Solution** using the RederNode rewrited draw method to record finger drag tracks (moveTo starting point, lineTo addition segment), Canvas.ttatchPen + canvas.drawPath to draw handwriting. Invalidate() triggers a frame-by-frame redraw bond. Mounted by Frame Node.getRenderNode().appendchild to NodeContainer.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Canvas Component | High-frequency writing performance is not as good as RenderNode |
|Image | Shows only static pictures and cannot respond to a user drag to draw real time

```typescript
import { FrameNode, NodeController, RenderNode, DrawContext, UIContext } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

class SignatureRenderNode extends RenderNode {
paths: drawing. Path[]=[[]; // / finished writing
currentPath: drawing.Path |nuld=nuld; // Current middle drawing

  draw(context: DrawContext) {
    const canvas = context.canvas;
    const pen = new drawing.Pen();
    pen.setStrokeWidth(3);
    pen.setColor({ alpha: 255, red: 33, green: 33, blue: 33 });
    canvas.attachPen(pen);
    for (const path of this.paths) { canvas.drawPath(path); }
    if (this.currentPath) { canvas.drawPath(this.currentPath); }
    canvas.detachPen();
  }

  startStroke(x: number, y: number) {
    this.currentPath = new drawing.Path();
This.curentPath.moveTo(x, y); / / starting point
This.invalidate(); / / Trigger heavy Paint
  }
  continueStroke(x: number, y: number) {
    if (this.currentPath) { this.currentPath.lineTo(x, y); this.invalidate(); }
  }
  endStroke() {
    if (this.currentPath) { this.paths.push(this.currentPath); this.currentPath = null; this.invalidate(); }
  }
undo() {this.paths.pop(); this.invalidate();}/ / Undo previous step
clear() {This.paths =[]; this.currentPath = null; this.invalidate();}// clear the drawing board
}

/ NodeController Mount RinderNode
class SignatureNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private renderNode: SignatureRenderNode | null = null;
  private uiContext: UIContext | null = null;

  makeNode(uiContext: UIContext): FrameNode {
    this.uiContext = uiContext;
    this.rootNode = new FrameNode(uiContext);
    this.renderNode = new SignatureRenderNode();
This.renderNode. frame = {x: 0, y: 0, width: 300, head: 250}; // unit vp
// Mount through Frame Node.getRenderNode().appendchild
    this.rootNode.getRenderNode()?.appendChild(this.renderNode);
    return this.rootNode;
  }

  aboutToResize(size: Size): void {
    if (this.renderNode) { this.renderNode.frame = { x: 0, y: 0, width: size.width, height: size.height }; }
  }

  vp2px(value: number): number {
    return this.uiContext ? this.uiContext.vp2px(value) : value;
  }
}

/ / Use: NodeContainer + onTouch to handle touch events
NodeContainer(this.signatureController)
  .width('100%').height(250)
  .onTouch((event: TouchEvent) => {
    const renderNode = this.signatureController.getSignatureRenderNode();
    if (!renderNode) return;
Const x = this.signatureController.vp2px (event.touches[0].x); //Path coordinates with px
    const y = this.signatureController.vp2px(event.touches[0].y);
    if (event.type === TouchType.Down) { renderNode.startStroke(x, y); }
    else if (event.type === TouchType.Move) { renderNode.continueStroke(x, y); }
    else if (event.type === TouchType.Up) { renderNode.endStroke(); }
  })
```

# drawing. Path method count

Methodology
|------|------|
`moveTo(x, y)`| Set the path starting point
`lineTo(x, y)` | Add a segment from last point to target point
`arcTo(...)`| Add arc path

# RenderNode core method count

Methodology
|------|------|
`draw(context: DrawContext)` | Rewrite this method for custom rendering
`invalidate()` zirconium triggers frame-by-frame redraw
`frame = { x, y, width, height }`| Set position and size (in Vp)|

# TouchType #

| Equation | Description | Counteraction |
|--------|------|---------|
`Down` ZEX ZEX Press your finger to start Stroke and start a new painting
`Move` X X X X X X X X
`Up` ZEX ZEX ZEX ZEX ZEX ZEX ZEX ZEX

---

# scene VII: Advertise in news/commodity flow, first step and then fill in

**Scene description**: Advertising entries in news/commodity information flows, the specific form of the advertisement (texts, videos, rotations) cannot be determined at the development stage and the corresponding advertising component needs to be created at the time of operation based on data dynamics from the server.

** Solution**: Pre-create and dynamically mount components using Builder Node + NodeController + NodeContainer. NodeContainer takes the place in the list item, Builder Node.build builds the graphic/video/roller advertising component tree according to WrappedBuilder dynamic, and calls rebuild() when the ad data arrives, re-returns to make Node displays on the tree, and achieves the dynamic creation of first place, after content.

| Alternatives | Reasons for impropriety |
|---------|------------|
|ForEach | compilation period needs to determine the component structure and cannot run to generate different types according to data dynamics
| Conditional Rendering | Branch is fixed during the compilation period and cannot respond to any type of dynamic content from the server

```typescript
import { BuilderNode, NodeController, FrameNode, UIContext } from '@kit.ArkUI';

interface AdData {
  type: 'image-text' | 'video' | 'carousel';
  title: string; description: string; images: string[]; loaded: boolean;
}

The // @Builder function defines different advertising forms
@Builder
function buildImageTextAd(params: AdData) {
  Column({ space: 8 }) {
    Row({ space: 12 }) {
Column().width(80).head(80). BackgroundColor ('#E0E0E0')// Photo place
      Column({ space: 4 }) {
        Text(params.title).fontSize(14).fontWeight(FontWeight.Bold)
        Text(params.description).fontSize(12).fontColor('#999').maxLines(2)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
/ ...advertisement label
  }.padding(12).backgroundColor('#FFFDE7').borderRadius(12)
}
/ ...buildVideoAd, BuildCarouselAd, builtLoatingAd similar

class AdNodeController extends NodeController {
  private builderNode: BuilderNode<[AdData]> | null = null;
  private adData: AdData;
  constructor(adData: AdData) { super(); this.adData = adData; }

  makeNode(uiContext: UIContext): FrameNode {
    if (this.builderNode == null) {
      this.builderNode = new BuilderNode(uiContext);
      this.buildAd();
    }
    return this.builderNode!.getFrameNode()!;
  }

  private buildAd() {
    let wrappedBuilder: WrappedBuilder<[AdData]>;
    if (!this.adData.loaded) {
wrappedBuilder = wrapBuilder (buildLoating Ad); / /
    } else if (this.adData.type === 'image-text') {
      wrappedBuilder = wrapBuilder(buildImageTextAd);
    } else if (this.adData.type === 'video') {
      wrappedBuilder = wrapBuilder(buildVideoAd);
    } else {
      wrappedBuilder = wrapBuilder(buildCarouselAd);
    }
This. builtNode! . built (wrappedBuilder, this.adData); / / Dynamic Build Component Tree
  }

/ / Server data call after arrival, rebuld() make Node
  updateAdData(adData: AdData) {
    this.adData = adData;
This. BuilderNode = null; / / Reset to rebuild
This.rebuild(); / / Notify NodeContainer make Node
  }
}

/ / Usage: NodeContainer position, update AdData tree after data arrival
private adController: AdNodeController = new AdNodeController({ /* loaded: false */ });

/ / Advertisements in NewsList
this.NewsCard(this.newsList[0])
NodeContainer (this.adController). width ('100%') / / take the lead
this.NewsCard(this.newsList[1])

// Simulate server data arrival
This.adController.updateAdData({ type: 'image-text', type: 'time-limited', /*loaded: true*/});
```

# Builder Node Core Method List

Methodology
|------|------|
`new BuilderNode(uiContext)`| Create BuilderNode Example |
Z `build(wrappedBuilder, params)` | Construct component tree according to WrappedBuilder dynamic
`getFrameNode()`| Retrieving the built-up FrameNode for Mounting |

NodeController core method count

Methodology
|------|------|
`makeNode(uiContext)` | returns FrameNode to NodeContainer and returns | on first and second
`rebuild()`| Notification NodeContainer Retrieving make Node, dynamic update

# AdData. type

@BuilderZen
|--------|-------------|---------|
`image-text` | builtImageTextAd
`video` | builtVideoAd
`carousel` BuildCarouselAd

---

# Scene 8: Custom Paint App Draw Graphics on XComponent Surface

**Scene Example Description**: In custom Drawing App, a canvas object (e. g. rectangle) is required to draw directly a graphic (e. g. rectangle) on XComponent Surface, without Native code.

** Solution**: Using the SURFACE type of XComponent, accessing the LockCanvas () of XComponentController through the LockCanvas () on Load echo, using Drawing. Brush to create painting setting colours, calling attachBrush/drawRect/detachBrush to draw graphics, and finally submitting drawing results to Surface through unlockCanvasAndPost.

| Alternatives | Reasons for impropriety |
|---------|------------|
| Canvas Component | Draw with CanvasRenderingContext2D, unable to directly operate Surface buffer zone
|Image | Shows static pictures only and cannot provide Surface for custom drawing

```typescript
import { common2D, drawing } from '@kit.ArkGraphics2D';

@Entry
@Component
struct XComponentPage {
  private xcController: XComponentController = new XComponentController();
  private bgColor: common2D.Color = { alpha: 255, red: 30, green: 30, blue: 50 };

/ / Draw rectangle: coordinates px, need to convert with vp2px
  private drawRect(r: number, g: number, b: number, a: number,
    left: number, right: number, top: number, bottom: number) {
constcanvas = this.xcController.lockCanvas(); / /get canvas objects
    if (canvas) {
canvas.clar(this.bgColor); / / Clear the previous frame before each drawing
      const brush = new drawing.Brush();
      brush.setColor({ alpha: a, red: r, green: g, blue: b });
      canvas.attachBrush(brush);
      canvas.drawRect({ left, right, top, bottom });
      canvas.detachBrush();
This.xcController.unlockCanvasAndPosts; / /Submit to Surface
    }
  }

  build() {
    XComponent({ type: XComponentType.SURFACE, controller: this.xcController })
      .onLoad(() => {
        const canvas = this.xcController.lockCanvas();
        if (canvas) { canvas.clear(this.bgColor); this.xcController.unlockCanvasAndPost(canvas); }
      })
.onDestroy(()=>{/* Cleanup Resources*/})
      .width('100%').height(350)
  }
}
```

# XComponentType Count

Equation values Description Applicable scene
|--------|------|---------|
Z `SURFACE` | Provide Surface for custom drawing
Z `COMPONENT` | Provides Native component embedded | Custom Native component |
`TEXTURE`| Provide Texture for GPU Rendering 3D Graphics, Game Images

# XComponentController

Methodology
|------|------|
| `lockCanvas()` | Retrieving Draging Canvas objects (returning Null means failure)
`unlockCanvasAndPost(canvas)` | Submits the drawing results to Surface Show |
`getXComponentSurfaceId()`

# Drawing Canvas core method count

Methodology
|------|------|
Z `clear(common2D.Color)` | Empty canvas (a frame must be removed before drawing)
`attachBrush(brush)` ZEX ZEKE
`drawRect({ left, right, top, bottom })` | Draws a rectangle (coordinate px) |
`detachBrush()`

# Key constraints #

* Reissued for technical reasons.
|------|------|
|DrawingCanvas coordinates are px | to convert vp2px() coordinates to px |
| Before drawing each time, clear the last frame to avoid remaining
| clear parameter is common2D. Color | alpha = 255, completely untransparent, completely clear canvas

---

# Customized module selection speed check

| Capability, core role, typical scene, critical limitations
|------|---------|---------|---------|
**DrawModiifier**  **DrawBehind/DrawFront Custom Drawing Gradient Borders, External Lighting, Neon Lights, Pattern Background  **context.size returns vp, Canvas needs px
**AttributeModiffer**  ** Encapsulated Multi-state Four-State Style  ** Enterprise-level Button (main/sub/hazard/disable)  @
**GestureModifier**  ** applicationGesture dynamically changing gestures  ** Design tool drag/scaling/rotation mode switch ** **GestureModifier** gesture switch effective at next operation
**ContentModiifier**  ** applyContent replaces content area  ** Button icon + text, CHeckbox collection toggle  ** custom properties do not trigger refreshing, use config driven |
**FrameNode**  ** typeNode. class Node Dynamic Node  ** JSON drive sheet, add or delete table item  ** Root container shall be used as Column type node
**RenderNode** Rewrite  **Draw Method RenderNode
**Builder Node**  ** build component tree dynamic | information flow ad, top-up content fill  ** rebuild() rebuild whole tree, lose state  **
**XCommponent**  **SURFACE + lockCanvas Draws  **Surface Draws Graphics with a Planted Object On Px Coordinates, clear |

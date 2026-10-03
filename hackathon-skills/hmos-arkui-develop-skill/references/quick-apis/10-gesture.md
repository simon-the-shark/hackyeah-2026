## 10. Gestures and Events


> **Component index**: `Basic gestures`, `Gesture groups`, `Gesture binding`, `Common events`, `Drag events`

### Basic Gestures

| Gesture | Constructor signature | Parameters |
|------|---------|------|
| **TapGesture** | `TapGesture(value?: number)` | `count?:1` `fingers?:1` |
| **LongPressGesture** | `LongPressGesture(options?)` | `fingers?:1` `repeat?:true` `duration?:500` |
| **PanGesture** | `PanGesture(options?)` | `fingers?:1` `distance?:5vp` `direction?:All` |
| **PinchGesture** | `PinchGesture(options?)` | `fingers?:2` `distance?:3vp` |
| **RotationGesture** | `RotationGesture(options?)` | `fingers?:2` `angle?:1deg` |
| **SwipeGesture** | `SwipeGesture(options?)` | `fingers?:1` `direction?:All` `speed?:100` |

### Gesture Groups

| Type | Signature | Description |
|------|------|------|
| **GestureGroup** | `GestureGroup(mode: GestureMode, ...gestures)` | Sequence/Parallel/Exclusive |

### Gesture Binding

| Method | Description |
|------|------|
| `.gesture(gesture, mask?)` | Bind a gesture (child component takes priority) |
| `.priorityGesture(gesture, mask?)` | Takes priority over the child component |
| `.parallelGesture(gesture, mask?)` | Runs in parallel with the child component |

### Common Events

| Event | Signature | Description |
|------|------|------|
| .onClick | `.onClick((event: ClickEvent) => void)` | Click; ClickEvent: {x,y,timestamp,target,source} |
| .onTouch | `.onTouch((event: TouchEvent) => void)` | Touch; TouchEvent: {touches,changedTouches,type} |
| .onHover | `.onHover((isHover, event) => void)` | Mouse hover |
| .onMouse | `.onMouse((event: MouseEvent) => void)` | Mouse event |
| .onKeyEvent | `.onKeyEvent((event: KeyEvent) => void)` | Key event |
| .onFocus | `.onFocus(() => void)` | Gains focus |
| .onBlur | `.onBlur(() => void)` | Loses focus |
| .onAppear | `.onAppear(() => void)` | Mount |
| .onDisappear | `.onDisappear(() => void)` | Unmount |
| .onAreaChange | `.onAreaChange((old, new) => void)` | Area change |
| .onSizeChange | `.onSizeChange((old, new) => void)` | Size change |
| .onVisibleChange | `.onVisibleChange((isVisible) => void)` | Visibility change |

### Drag Events

| Event | Signature | Description |
|------|------|------|
| .onDragStart | `.onDragStart((event) => CustomBuilder \| DragItemInfo)` | Drag starts |
| .onDragEnter | `.onDragEnter((event) => void)` | Drag enters |
| .onDragMove | `.onDragMove((event) => void)` | Move |
| .onDragLeave | `.onDragLeave((event) => void)` | Drag leaves |
| .onDrop | `.onDrop((event) => void)` | Drop |
| .onDragEnd | `.onDragEnd((event) => void)` | Ends |

---

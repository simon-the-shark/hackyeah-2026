## 9. Animation APIs


> **Component index**: `Property animation`, `Animation curves`, `Transition animation`, `Frame animation`

### Property Animation

| API | Signature | Parameter Description |
|-----|------|---------|
| **animateTo** | `animateTo(value: AnimateParam, event: () => void)` | Explicit animation |

> **Core semantics**: The `event` closure must contain a **state change** (such as `this.width = 200`); the framework automatically inserts a transition animation for state changes inside the closure. No state change inside the closure means no animation.
>
> **Recommended form**: `this.getUIContext()?.animateTo({ duration: 1000, curve: Curve.EaseOut }, () => { this.widthSize = 200 })`
>
> **Note**: Global animateTo has been deprecated since API 18; call it through `this.getUIContext().animateTo()` instead. Do not call animations in aboutToAppear/aboutToDisappear.
| **animateToImmediately** | `animateToImmediately(value: AnimateParam, event: () => void)` | Play immediately |
| **.animation** | `.animation(value: AnimateParam)` | Implicit property animation (chained) |
| **keyframeAnimateTo** | `keyframeAnimateTo(context, keyframes, options?)` | Keyframe animation |

> **Key constraint**: `.animation()` must be placed **after the property being animated**, and it applies to **all** property changes on that component, not only the preceding one. Add `.animation()` only at the end of the chain for properties that need animation, so unrelated changes are not animated.

**AnimateParam:**

| Parameter | Type | Default | Description |
|------|------|--------|------|
| duration | number | 1000 | Duration (ms) |
| curve | Curve \| ICurve | Ease | Curve |
| delay | number | 0 | Delay (ms) |
| iterations | number | 1 | Iteration count |
| playMode | PlayMode | Normal | Playback mode |
| tempo | number | 1.0 | Rate |
| direction | AnimationDirection | — | Direction |
| fill | FillMode | None | Fill mode |
| onFinish | () => void | — | Completion callback |

### Animation Curves

> **Note:** `curves.springCurve` requires **4 parameters** `(velocity, mass, stiffness, damping)`, for example `curves.springCurve(10, 1, 228, 30)`; do not pass only 2. `curves.easeInOut()` does not exist; use `curves.initCurve(Curve.EaseInOut)` for easing.
>
> **Namespace distinction**: `curves.*` (such as curves.springCurve) requires `import { curves } from '@kit.ArkUI'`; `Curve.*` (such as Curve.EaseInOut) is a global enum and does not require an import.

| Curve Type | Signature | Description |
|------|------|------|
| **Preset curves** | `Curve.Linear/Ease/EaseIn/EaseOut/EaseInOut/FastOutSlowIn/...` | 13 presets |
| **Bezier** | `Curve.cubicBezierCurve(x1,y1,x2,y2)` | Cubic Bezier |
| **Spring** | `curves.springCurve(velocity,mass,stiffness,damping)` | **Exactly 4 parameters required**; requires `import { curves } from '@kit.ArkUI'` |
| **Spring motion** | `Curve.springMotion(response?,dampingFraction?,velocity?)` | Physical spring motion |
| **Responsive spring** | `Curve.responsiveSpringMotion(response?,dampingFraction?,velocity?)` | Responsive |
| **Interpolating spring** | `Curve.interpolatingSpring(velocity,mass,stiffness,damping)` | Interpolating spring |
| **Custom** | `Curve.customCurve(interpolate: (t) => number)` | Custom |
| **Initialize curve** | `curves.initCurve(Curve.EaseInOut)` | Gets a preset curve instance |

### Transition Animation

| API | Signature | Description |
|-----|------|------|
| **.transition** | `.transition(value: TransitionEffect \| TransitionOptions)` | Appear/disappear transition |
| **TransitionEffect** | `.OPACITY / .SLIDE / .FADE / .MOVE / .ROTATE / .SCALE / .ASYMMETRIC / .IDENTITY` | Composable |

### TransitionEffect Composition

Chain multiple transition effects with `.combine()` and specify animation parameters with `.animation()`:

```typescript
// Combine multiple effects
TransitionEffect.OPACITY
  .combine(TransitionEffect.scale({ x: 0, y: 0 }))
  .combine(TransitionEffect.rotate({ angle: 90 }))
  .animation({ duration: 300, curve: Curve.Friction })

// Asymmetric transition (different appear and disappear effects)
TransitionEffect.asymmetric(
  TransitionEffect.scale({ x: 0, y: 0 }),  // Appear effect
  TransitionEffect.rotate({ angle: 90 })    // Disappear effect
)

// Slide in from an edge
TransitionEffect.move(TransitionEdge.END)  // TransitionEdge: TOP/BOTTOM/START/END
```

Available effects: OPACITY, SLIDE, scale({x,y}), rotate({angle}), opacity(value), translate({x,y}), move(TransitionEdge), asymmetric(appear, disappear)
Composition method: chain `.combine(otherEffect)` calls
Animation parameters: `.animation({ duration, curve, delay })` can be attached to any effect

| **.sharedTransition** | `.sharedTransition(id, options?)` | Shared-element transition |
| **.geometryTransition** | `.geometryTransition(id, options?)` | Geometry transition |
| **PageTransition** | `PageTransitionEnter / PageTransitionExit` | Page transition |

### PageTransition Usage

```typescript
// Page enter
PageTransitionEnter({ duration: 500, curve: Curve.EaseOut })
  .slide(SlideEffect.Right)

// Page exit
PageTransitionExit({ duration: 500, curve: Curve.EaseIn })
  .slide(SlideEffect.Left)
```

SlideEffect enum: Left / Right / Up / Down

### Frame Animation

| API | Signature | Description |
|-----|------|------|
| **Animator** | `animator.create({duration, easing, delay, fill, direction, iterations, begin, end})` | Create animation |
| **AnimatorResult** | `.play()` `.pause()` `.cancel()` `.reverse()` `.finish()` | Control methods |

---

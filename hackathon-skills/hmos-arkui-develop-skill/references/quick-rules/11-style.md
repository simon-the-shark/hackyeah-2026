## 11. Style and Theme Constraints

### @Extend
- **Global definitions only**.
- **Current file only**; export is unsupported.
- **Cannot mix with @Styles**.

### stateStyles
- Supports only **common attributes**; component-private attributes have no effect.
- Focus state is triggered through an external keyboard Tab/direction key, not nested scrolling controls.

### Blur Performance
- Real-time blur APIs render every frame and are expensive.
- Use effectKit static blur APIs for static scenes.

### clipShape
- The shape **fill property has no effect** with clipShape.

### Dark/Light Mode
- Dynamically reading colorMode through a function return value is unreliable.
- BuilderNode / ComponentContent must manually propagate environment changes with `updateConfiguration()`.

---

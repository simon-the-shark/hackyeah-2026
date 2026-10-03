## 4. State Management V2 Decorator Constraints

### @ObservedV2 / @Trace
- @ObservedV2 decorates a class; @Trace decorates observed properties.
- **V1 decorators cannot be used with @ObservedV2**.
- Deep observation requires @ObservedV2 + @Trace at every class level.

### @Local
- **Must be initialized inside the component**.
- External initialization is not allowed.

### @Param
- May be passed from the parent.
- Defaults to **one-way synchronization** (parent to child).
- Use @Event for two-way synchronization.

### @Once
- Receives a parameter only when the component is first created; later parent changes **are not applied**.

### @Event
- Sends child-to-parent callback notifications together with @Param.

### @Provider / @Consumer (V2)
- Pass data across component levels.
- @Provider injects; @Consumer consumes.

### @Computed (V2)
- Computed-property decorator with automatic caching.
- Recomputes only when a dependent @Trace property changes.

### @Monitor (V2) / addMonitor / clearMonitor
- addMonitor/clearMonitor targets **must be** an @ObservedV2 class with @Trace or a @ComponentV2 instance (error 130000).
- Callbacks **must be named functions**, not anonymous functions (error 130002).

### makeObserved
- Converts an ordinary object to a V2 observable object.
- **Does not support** collections or classes decorated with @Sendable.
- **Does not support** non-object values, undefined, or null.
- **Does not support** classes decorated with @ObservedV2.

### applySyncUpdates / flushUpdates / flushUIUpdates
- Manually trigger V2 state updates.
- After changing state on a non-UI thread, call one to refresh the UI.

---

## Common Errors

### Error 1: Reading IMonitor values incorrectly in an @Monitor callback
Use `mon.value<string>()?.now` or `.before`; `after` does not exist.

### Error 2: Multi-file Navigation routing
`@ComponentV2 export struct` supports cross-file exports and references. Use either a static custom route table with imports or the system route table with `router_map.json` and `pushPathByName()`.

**V2 navPathStack passing**: receive the parent value with @Param, not @Consume.

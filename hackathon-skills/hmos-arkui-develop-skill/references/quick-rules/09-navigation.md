## 9. Navigation and Routing Constraints

| Rule | Description |
|------|-------------|
| Router is not recommended | **Prefer Navigation** for richer animation, lifecycle, interception, and immersive behavior |
| Router stack limit is 32 | More than 32 pages produces **100003** |
| Default Navigation duration is uncontrolled | Spring duration varies by device; do not couple business logic to it |
| Disable default transitions for shared elements | geometryTransition must not be combined with the system transition |
| Navigation transition priority | customNavContentTransition takes priority over NavDestination transition |
| Missing builder | Unregistered pages produce **100005** |
| Missing NavDestination | Pages without NavDestination produce **100006** |
| Valid UIContext required | Invalid context may cause routing errors |
| Do not use inline push parameters | Declare an interface first, then pass a typed value |
| titleMode belongs to Navigation | NavDestination supports `.title()`, not `.titleMode()` |

## Common Errors
- Use Navigation + NavDestination instead of `@ohos.router`.
- Use one @Entry in a single-page app.
- Register destination builders before Navigation jumps.
- Replace deprecated pageTransition with Navigation transitions.
- Do not pass an inline object literal as `pushPath` param.

---

### Multi-file Navigation Routing
Keep pages in separate files. `@ComponentV2 export struct` supports cross-file exports. Use a static route table for simple projects or `router_map.json` with `pushPathByName()` for cross-module projects.

### Single-file Navigation Minimum Template
Register `navDestination` on Navigation; `titleMode` belongs on Navigation only.

---

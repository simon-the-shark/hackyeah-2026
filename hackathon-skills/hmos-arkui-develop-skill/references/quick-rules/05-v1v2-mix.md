## 5. V1/V2 Interoperability Constraints

| Rule | Description |
|------|-------------|
| V1 decorators cannot mix with @ObservedV2 | This restriction remains in force |
| V2 -> V1 decorator input is forbidden | V1 cannot directly receive an @ObservedV2 class through a decorator |
| V1 @Link requires a V1 state variable | V1 @Link follows its original initialization rules |
| V1 -> V2 requires enableV2Compatibility | Call `UIUtils.enableV2Compatibility()` when passing V1 state to V2 |
| V2 -> V1 requires makeV1Observed | Declare V1 state data first, then call `UIUtils.enableV2Compatibility(UIUtils.makeV1Observed())` |
| Call at V2 component construction | Avoid another call after whole-value assignment |
| No double proxying | Omitting enableV2Compatibility and makeV1Observed can cause double proxying |

## Common Errors
- **Using `@State` in `@ComponentV2`**: use V2 decorators such as @Local and @Param.
- **Using `@Local` in `@Component`**: use V1 decorators in @Component.
- **Using `@State` in an @ObservedV2 class**: V1 decorators cannot mix with @ObservedV2.
- **Passing values across V1/V2 without `enableV2Compatibility`**: compatibility bridging is required.
- **Root cause**: AI often misses the strict V1/V2 boundary and generates plausible but uncompilable mixed code.

---

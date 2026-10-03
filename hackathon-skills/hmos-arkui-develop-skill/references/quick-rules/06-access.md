## 6. Access Modifier Constraints

| Decorator | Allowed modifiers | Forbidden modifiers |
|----------|-------------------|--------------------|
| @State / @Prop / @Provide / @BuilderParam / regular variables | default/public/private (private blocks external initialization) | protected (struct has no inheritance) |
| @StorageLink / @StorageProp / @LocalStorageLink / @LocalStorageProp / @Consume | default/private | public / protected |
| @Link / @ObjectLink | default/public | **private** (external initialization is required) / protected |
| @Require + @State/@Prop/@Provide/@BuilderParam | default/public | **private** (contradicts @Require) / protected |
| All | — | **protected** (struct has no inheritance and produces a warning) |

## Common Errors
- **@State on component input**: use @Prop/@Param for inputs.
- **@Local on component input**: initialize @Local inside the component and use @Param for inputs.
- **@Prop on an internal variable**: @Prop is for component inputs.
- **@Param on an internal variable**: @Param is for component inputs.
- **Local @Link initialization**: `@Link count: number = 0` is forbidden.
- **Local @ObjectLink initialization**: local initialization is forbidden.
- **@ObjectLink on a simple type**: use @Prop for number/string/boolean.
- **External @Consume initialization**: @Consume cannot be initialized externally.

---

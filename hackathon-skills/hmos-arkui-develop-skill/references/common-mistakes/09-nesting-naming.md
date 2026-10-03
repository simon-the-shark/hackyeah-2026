## 9. Component Nesting and Naming Conflicts

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| Put a non-`ListItem` child directly inside `List` | List children must be wrapped in ListItem | Rule 14: layout container constraints |
| Put a non-`TabContent` child directly inside `Tabs` | Tabs children must use TabContent | Rule 14: layout container constraints |
| Put a non-`GridItem` child directly inside `Grid` | Grid children must use GridItem | Rule 14: layout container constraints |
| Name a component `Button`, `Text`, or `Image` | Conflicts with a system component name | Rule 1: custom component constraints |
| Name a variable `rerender` or `aboutToAppear` | Conflicts with framework reserved words | Rule 21: built-in reserved words |
| Name a member variable `id`, `width`, `margin`, etc. | Same name as a `CustomComponent` base-chain method causes a type-signature conflict → 10505001 | Rule 1: custom component constraints |

**Root cause**: AI does not understand container child-component constraints or the framework reserved-word list.

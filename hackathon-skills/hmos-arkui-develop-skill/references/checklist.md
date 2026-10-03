# ArkUI Code Review Checklist

> Each item identifies its `quick-rules/` section for quick lookup. The "Common Errors" section at the end of each file contains detailed patterns.

## Imports and Modules
- [ ] All imports use `@kit.*`; no `@ohos.*` paths (rule 20, error list 1)
- [ ] Imported symbols belong to the correct kit (rule 20, kit quick reference)
- [ ] No imported module is unused
- [ ] No required import is missing

## UIContext and Global Interfaces
- [ ] Global interfaces such as router, promptAction, AlertDialog, animateTo, and vp2px use `this.getUIContext()` (rule 19)

## State Management
- [ ] Every state variable declares a type (rules 3/4)
- [ ] Each decorator is used in the correct location (@State/@Local for internal state, @Prop/@Param for inputs)
- [ ] V1 and V2 state management are not mixed (rule 5)
- [ ] @Link / @ObjectLink have no local initialization (rule 3)

## Rendering Control
- [ ] ForEach / LazyForEach has a third key argument using business IDs rather than indexes (rule 7)

## build() Function
- [ ] build() has no local declarations, console.info, switch, or ternary expressions (rule 2)
- [ ] build() does not mutate state directly (rule 2)

## Navigation
- [ ] Navigation implements routing instead of Router (rule 9)
- [ ] Multi-page Navigation registers child pages

## Naming and Nesting
- [ ] Variable names avoid framework reserved words (rule 21)
- [ ] Component and variable names avoid built-in component and attribute names (rule 1)
- [ ] Component nesting follows restrictions, such as ListItem in List and TabContent in Tabs (rule 14)

## Evidence and Deprecation
- [ ] API parameters match quick-apis or search results; nothing was invented from memory
- [ ] Each key API has quick-apis confirmation or a search evidence path
- [ ] Deprecated interfaces such as CustomDialogController and pageTransition are not used
- [ ] Unverified APIs are marked "pending confirmation"
- [ ] Conflicting options include both a recommendation and an alternative

## Code Style (see `style-guide.md`)
- [ ] Component and variable names follow style-guide conventions (PascalCase/camelCase)
- [ ] Component order is state definitions -> properties -> private members -> lifecycle -> private methods -> build()
- [ ] Each chained method is on its own line; logic statements use semicolons and UI statements do not

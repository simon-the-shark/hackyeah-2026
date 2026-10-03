# Search Decision Strategy

## Core Principle
> **Design the solution first, then check uncertainty.** Do not search before design because you do not yet know what to search.

After design, process every API with the following two-level strategy:

## Basic -> Check Quick Reference
**Condition**: `references/quick-apis/` contains a complete card for the component.

**Action**: Read the category file and use the constructor signature, parameters, attributes, and events from the card.

**No extra search required for**:
- A quick-apis card containing the needed signature and parameters
- Basic layouts (Column/Row/Stack/Flex/Scroll)
- Basic components (Text/Button/Image/List/Grid)
- Basic V1 decorators (@State/@Prop/@Link)
- Verified sys.symbol / sys.color names

## Complex -> Use the Relevant Search Tool
**Condition**: any of the following applies:

| Scenario | Description |
|----------|-------------|
| Component absent from quick-apis | The table does not cover it |
| Insufficient card information | Parameters, events, or version information is missing |
| V2 decorator | @Local/@Param/@Provider/@Consumer/@Monitor/@Computed/@ObservedV2/@Trace |
| V2 component mechanism | @ComponentV2, @ReusableV2, V2 lifecycle |
| Navigation architecture | Navigation, NavDestination, NavPathStack |
| Lazy loading | LazyForEach, IDataSource, Repeat |
| Complex interaction | bindSheet, CustomDialog, gesture combinations, transition |
| Deprecated API replacement | Documentation must confirm the replacement |
| Uncertain callback type | AI often guesses incorrectly |
| Version compatibility | Confirm the minimum API version |

**Action**: For uncertain ArkTS language rules and non-UI APIs, call
`hmos-arkts-knowledge-retriever`:

```bash
python {hmos-arkts-knowledge-retriever}/scripts/search_docs.py --query "ArkTS topic or API"
```

For ArkUI components, decorators, navigation, and version-sensitive UI APIs, search the
DevEco documentation with `devecocli docs search <keyword>`, then read the selected result
with `devecocli docs read <document-id>`.

Confidence rules:
1. Documentation says "supported from API version X": high confidence
2. Documentation says "deprecated from API version X": must follow
3. No version information: uncertain; confirm separately

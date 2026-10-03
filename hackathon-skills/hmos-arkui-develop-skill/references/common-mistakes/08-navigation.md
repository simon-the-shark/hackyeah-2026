## 8. Navigation and Routing Errors

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| Use `@ohos.router` for page navigation | Navigation + NavDestination is recommended | Rule 9: navigation and routing constraints |
| Multiple pages each use `@Entry` | A single-Page application should have only one @Entry | Rule 1: custom component constraints; Rule 9: navigation and routing constraints |
| Navigation destination builder is not registered | Error code 100005 is reported | Rule 9: navigation and routing constraints |
| Use `pageTransition` for page transitions | pageTransition is deprecated; use Navigation transitions | Rule 8: animation constraints |

**Root cause**: AI tends to use the more "obvious" router API and does not know that Navigation is recommended.

## 21. Built-in Reserved Words

Avoid naming custom component methods after framework methods because name collisions can cause runtime failures. Names in the following list must not be reused:

```text
isRenderInProgress isInitialRenderDone runReuse_ paramsGenerator_ watchedProps recycleManager_ hasBeenRecycled_ preventRecursiveRecycle_ delayRecycleNodeRerender defaultConsume_ reconnectConsume_ providedVars_ ownObservedPropertiesStore__ aboutToBeDeleted rerender initialRender updateStateVars getUIContext getChildById addChild removeChild setParent getParent createLocalStorageLink createLocalStorageProp __mkRepeatAPI reuseOrCreateNewComponent freezeRecycledComponent unfreezeReusedComponent getRecyclePool hasRecyclePool resetStateVarsOnReuse observeComponentCreation queryNavDestinationInfo queryNavigationInfo queryRouterPageInfo getDialogController updateId scheduleDelayedUpdate
```

The complete framework-reserved identifier list remains available in the API reference.

### Common Errors
| Wrong | Correct | Description |
|-------|---------|-------------|
| Custom component named `Button`, `Text`, or `Image` | Use a unique name such as `MyButton` or `HomeText` | Conflicts with a system component |
| Variable named `rerender` or `aboutToAppear` | Add a suffix such as `rerenderValue` or `aboutToAppearFlag` | Conflicts with a framework reserved word |

---

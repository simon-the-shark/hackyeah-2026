## 13. @Observed / @ObjectLink Refresh Problems

AI often writes incorrect @Observed/@ObjectLink code, causing the **UI not to refresh** after nested object properties change. All @Observed "no refresh" problems fundamentally come from one mechanism: **@State/@ObjectLink proxies only the first object layer; changes to nested properties require the inner class to also be decorated with @Observed and a child-component @ObjectLink dependency**.

### Scenario 1: A Nested Object's Second-Level Property Does Not Refresh (Most Frequent)

@State can observe only first-level assignments; `this.cousin.child.childId` is second-level, so changing it does not refresh.

❌ Incorrect usage
```typescript
class Child { childId: number; constructor(id: number) { this.childId = id } }

class Cousin {
  child: Child;
  constructor(childId: number) { this.child = new Child(childId) }
}

@Entry
@Component
struct MyView {
  @State cousin: Cousin = new Cousin(30);
  build() {
    Column() {
      Text(`childId: ${this.cousin.child.childId}`)  // ❌ Does not refresh after clicking
      Button('change').onClick(() => { this.cousin.child.childId += 1; })
    }
  }
}
```

✅ Correct usage (add @Observed to the inner class and receive it with child-component @ObjectLink)
```typescript
@Observed
class Child { childId: number; constructor(id: number) { this.childId = id } }

class Cousin { child: Child; constructor(childId: number) { this.child = new Child(childId) } }

@Component
struct ViewChild {
   @ObjectLink child: Child;   // Receive the @Observed Child instance
  build() {
    Text(`childId: ${this.child.childId}`)  // ✅ Refreshes when childId changes
      .onClick(() => { this.child.childId += 1; })
  }
}

@Entry
@Component
struct MyView {
  @State cousin: Cousin = new Cousin(30);
  build() {
    Column() {
      ViewChild({ child: this.cousin.child })  // ✅ Render the inner object with a child component
    }
  }
}
```

> **Root cause**: @State cousin proxies only Cousin's first-level properties (replacement of parentId/cousinId/child as a whole). `child.childId` belongs to Child, so @State cannot observe it. After Child is decorated with @Observed, its property changes can be observed by @ObjectLink.

### Scenario 2: Assigning the Entire @ObjectLink Reports an Error

An @ObjectLink-decorated variable is read-only; assigning it as a whole reports `Cannot set property when setter is undefined` at runtime.

❌ Incorrect usage
```typescript
@Observed
class Info { count: number; constructor(c: number) { this.count = c } }

@Component
struct Child {
  @ObjectLink num: Info;
  build() {
    Text(`${this.num.count}`)
      .onClick(() => { this.num = new Info(10); })  // ❌ Runtime error
  }
}
```

✅ Correct usage (change properties in the child; replace the whole object in the parent)
```typescript
@Component
struct Child {
  @ObjectLink num: Info;
  build() {
    Text(`${this.num.count}`)
      .onClick(() => { this.num.count = 20; })  // ✅ Change a property; refreshes
  }
}

@Entry
@Component
struct Parent {
  @State num: Info = new Info(10);
  build() {
    Column() {
      Child({ num: this.num })
      Button('reset').onClick(() => { this.num = new Info(30); })  // ✅ Whole-object replacement in the parent
    }
  }
}
```

> **Root cause**: @ObjectLink is a reference pointer to the data source, and whole-object assignment breaks the synchronization chain. Property changes go through the proxy setter and trigger refresh; whole-object replacement must be done by the parent on the @State source.

### Scenario 3: With More Than Two Levels of Nesting, One @ObjectLink Cannot Observe Deeper Levels

@ObjectLink value: ParentCounter proxies only the first level of ParentCounter; `value.subCounter.counter` belongs to SubCounter and cannot be observed.

❌ Incorrect usage
```typescript
@Observed class SubCounter { counter: number; constructor(c: number) { this.counter = c } }
@Observed class ParentCounter { subCounter: SubCounter; constructor(c: number) { this.subCounter = new SubCounter(c) } }

@Component
struct CounterComp {
  @ObjectLink value: ParentCounter;
  build() {
    Text(`${this.value.subCounter.counter}`)  // ❌ Changing counter through setSubCounter does not refresh
      .onClick(() => { this.value.subCounter.counter = 10; })
  }
}
```

✅ Correct usage (split out another child component with @ObjectLink for the inner level)
```typescript
@Component
struct CounterComp {
  @ObjectLink value: ParentCounter;
  build() {
    Column() {
      Text(`${this.value.counter}`)
      CounterChild({ subValue: this.value.subCounter })  // ✅ Pass the inner level through a separate @ObjectLink
    }
  }
}

@Component
struct CounterChild {
   @ObjectLink subValue: SubCounter;   // Proxy the first level of SubCounter
  build() {
    Text(`${this.subValue.counter}`)  // ✅ Changing counter refreshes
      .onClick(() => { this.subValue.counter += 1; })
  }
}
```

> **Root cause**: @ObjectLink proxies only the properties of the class it directly receives. To observe N nested levels, use N @Observed classes and N levels of child-component @ObjectLink, with each level proxying one property layer.

### Scenario 4: Changing a Member in an @Observed Constructor Does Not Refresh

When the constructor runs, the instance has not yet been wrapped by a proxy. `this` points to the original object, so changes bypass the proxy and cannot be observed.

❌ Incorrect usage
```typescript
@Observed
class DataDownloader {
  state: number;
  constructor() {
    this.state = 0;
      setInterval(() => { this.state += 1; }, 2000);  // ❌ Changed in constructor; UI does not refresh
  }
}

@Entry @Component
struct Index {
  @State dataDownloader: DataDownloader = new DataDownloader();
  build() { Text(`state: ${this.dataDownloader.state}`) }
}
```

✅ Correct usage (constructor only initializes; move the timer to the component lifecycle)
```typescript
@Observed
class DataDownloader {
  state: number;
   constructor() { this.state = 0; }   // Initialization only
   startUpdate() { setInterval(() => { this.state += 1; }, 2000); }  // Change inside an ordinary method
}

@Entry @Component
struct Index {
  @State dataDownloader: DataDownloader = new DataDownloader();
   aboutToAppear() { this.dataDownloader.startUpdate(); }  // ✅ Proxy exists; changes are observable
  build() { Text(`state: ${this.dataDownloader.state}`) }
}
```

> **Root cause**: @Observed wraps the proxy only after `new` creates the instance. `this` in the constructor is the unproxied original object, so assignments change the source directly without notification. Modify it only after the state variable receives the instance and establishes the proxy. Likewise, arrow callbacks that capture `this` in the constructor do not refresh; move those assignments to an ordinary method.

### Scenario 5: LazyForEach + @ObjectLink Does Not Refresh After Replacing an Array Item

> ⚠️ **Classification**: This is fundamentally a combined **LazyForEach binding + @ObjectLink** problem, not purely an @Observed observation-boundary problem. Directly changing the internal dataSource array does not refresh because of LazyForEach (unrelated to @Observed); @Observed matters only for whether the new instance responds to later property changes after notification.

❌ Incorrect usage (directly change the internal dataSource array; LazyForEach is unaware)
```typescript
@Observed
class StringData { message: string; constructor(m: string) { this.message = m } }

Button('Replace first item').onClick(() => {
  this.data.dataArray[0] = new StringData('Hello 4');  // ❌ LazyForEach is not notified; no refresh
})
Button('Modify first item').onClick(() => {
  this.data.dataArray[0].message += '1';  // ❌ New instance is not bound to child @ObjectLink; still no refresh
})
```

✅ Correct usage (after replacement, trigger DataChangeListener.onDataChange through the DataSource notify method)
```typescript
Button('Replace first item').onClick(() => {
  this.data.dataArray[0] = new StringData('Hello 4');
  this.data.notifyDataChanged(0);   // ✅ Notify LazyForEach to rebind index 0
})
Button('Modify first item').onClick(() => {
  this.data.dataArray[0].message += '1';  // ✅ New instance has an @ObjectLink dependency; @Observed proxy intercepts the change and refreshes
})
```

> **Root cause (two layers)**:
> 1. LazyForEach does not observe internal dataSource array changes. DataSource must call a notify method (such as `notifyDataChanged`) to trigger `DataChangeListener.onDataChange`, or no refresh occurs. This is LazyForEach binding behavior and is unrelated to @Observed;
> 2. Whether the new instance responds to later property changes in the child depends on StringData being decorated with @Observed and the child establishing an @ObjectLink dependency.
>
> Distinguish `onDataChange` (a DataChangeListener interface method) from `notifyDataChanged` (a custom DataSource wrapper that iterates listeners and calls `listener.onDataChange`); developers call the latter. LazyForEach keys must also change with the data (for example, `index + item.message`), or notification may still not trigger rebuilding.

### Scenario 6: @ObjectLink Receives a Class Without @Observed and Does Not Refresh

If a class instance received by @ObjectLink is not decorated with @Observed (before API 19), property changes cannot be observed and a runtime warning is logged.

❌ Incorrect usage
```typescript
class Inner { value: string = 'inner'; }   // ❌ Missing @Observed

@Component
struct Child {
  @ObjectLink inner: Inner;   // Runtime warning: assigned value is not be decorated by @Observed
  build() {
    Text(`${this.inner.value}`)
      .onClick(() => { this.inner.value += '!'; })  // ❌ No refresh; @Watch does not trigger either
  }
}
```

✅ Correct usage (add @Observed to the inner class)
```typescript
@Observed
class Inner { value: string = 'inner'; }   // ✅ Add @Observed

@Component
struct Child {
  @ObjectLink inner: Inner;
  build() {
    Text(`${this.inner.value}`)              // ✅ Refreshes
      .onClick(() => { this.inner.value += '!'; })
  }
}
```

> **Root cause**: @ObjectLink observation depends on the observed class being decorated with @Observed (API 19+ can use makeV1Observed instead). Without decoration, property changes are not intercepted by a proxy and the framework prints a `FIX THIS APPLICATION ERROR` warning. Use `UIUtils.getTarget(obj) === obj` to determine whether an object is proxied (false means proxied and observable).

### Scenario 7: push/splice on Nested Array Properties Does Not Refresh

When an array property of an @State-decorated object (such as `project.milestones` or `milestone.tasks`) uses `push` to add items, it is neither a first-level assignment (the array reference is unchanged) nor an element-property change, so @State cannot observe it. Even with `@Observed class extends Array`, push remains unobservable unless a child component receives the array instance itself through @ObjectLink.

❌ Incorrect usage (push on an @State object's array property does not refresh)
```typescript
@Observed
class Task { id: number; done: boolean; constructor(id: number) { this.id = id; this.done = false } }

@Observed
class Project {
  tasks: Task[] = [];   // ❌ Ordinary array property
}

@Entry @Component
struct Page {
  @State project: Project = new Project();
  build() {
    Column() {
      ForEach(this.project.tasks, (t: Task) => Text(`${t.id}`), (t: Task) => t.id.toString())
      Button('add').onClick(() => {
        this.project.tasks.push(new Task(1));  // ❌ Project's first level is unchanged; push does not refresh
      })
    }
  }
}
```

✅ Correct usage (ObservedArray + child-component @ObjectLink receiving the array instance; both are required)
```typescript
@Observed
class Task { id: number; done: boolean; constructor(id: number) { this.id = id; this.done = false } }

@Observed
class ObservedArray<T> extends Array<T> {}   // ✅ Observable array

@Observed
class Project {
  tasks: ObservedArray<Task> = new ObservedArray<Task>();
}

// ✅ Child @ObjectLink receives the array itself (@Entry cannot use @ObjectLink, so extract a child component)
@Component
struct TaskListView {
  @ObjectLink tasks: ObservedArray<Task>;
  build() {
    ForEach(this.tasks, (t: Task) => Text(`${t.id}`), (t: Task) => t.id.toString())
  }
}

@Entry @Component
struct Page {
  @State project: Project = new Project();
  build() {
    Column() {
      TaskListView({ tasks: this.project.tasks })   // ✅ @ObjectLink receives the array; push refreshes locally
      Button('add').onClick(() => {
        this.project.tasks.push(new Task(1));  // ✅ Observed; ForEach refreshes locally
      })
    }
  }
}
```

> **Root cause**: @State project proxies only the first level of project (whole replacement of tasks). `project.tasks.push()` changes the array internals while the tasks reference remains unchanged, so the first level cannot observe it. For push to be observable, both conditions are required: 1. the array type is `@Observed class extends Array` (array mutation APIs are proxied); 2. a child component receives the array instance itself through @ObjectLink and establishes a dependency. Without either condition, push does not refresh.
>
> **Multiple nesting levels**: For tree data (Project -> Milestone -> Task), every array property needs ObservedArray plus a corresponding @ObjectLink child component at each bridge level.

### Scenario 8: Aggregate Values (Completed Count/Total Progress) Do Not Refresh

The parent displays an aggregate calculated from child properties (such as "Completed 2/5"); after a child's `done` changes, the parent's aggregate number does not update. @State/@ObjectLink cannot observe deep property changes, so the aggregate is not recalculated automatically.

❌ Incorrect usage (bind the aggregate directly to a computed expression; child-property changes do not refresh it)
```typescript
@Entry @Component
struct Page {
  @State project: Project = new Project();   // Project.tasks: ObservedArray<Task>
  build() {
    Column() {
      // ❌ Even if tasks[i].done changes through child @ObjectLink, this aggregate does not refresh
      Text(`Completed ${this.project.tasks.filter((t: Task) => t.done).length}/${this.project.tasks.length}`)
      TaskListView({ tasks: this.project.tasks })
    }
  }
}
```

✅ Correct usage (cache the aggregate in @State and manually recompute through a callback when a child changes)
```typescript
@Component
struct TaskListView {
  @ObjectLink tasks: ObservedArray<Task>;
  onTasksChange: () => void = () => {};   // Callback tells the parent to recompute
  build() {
    ForEach(this.tasks, (t: Task) => {
      TaskItem({ task: t, onToggle: (): void => { this.onTasksChange(); } })
    }, (t: Task) => t.id.toString())
  }
}

@Entry @Component
struct Page {
  @State project: Project = new Project();
  @State doneCount: number = 0;   // ✅ @State caches the aggregate
  private recompute() {
    this.doneCount = this.project.tasks.filter((t: Task) => t.done).length;
  }
  aboutToAppear() { this.recompute(); }
  build() {
    Column() {
      Text(`Completed ${this.doneCount}/${this.project.tasks.length}`)   // ✅ doneCount is @State and refreshes
      TaskListView({ tasks: this.project.tasks, onTasksChange: (): void => { this.recompute(); } })
    }
  }
}
```

> **Root cause**: @State project proxies only the first level, so the parent cannot observe deep changes to `tasks[i].done`. Even if child @ObjectLink changes done and refreshes itself, the parent's `tasks.filter(...)` expression is not reevaluated. Store the aggregate in @State and recompute it manually through a callback (onToggle -> onTasksChange -> recompute) when a child changes. V2 @ObservedV2/@Trace can automatically observe deep changes and eliminate the manual callback.

### Other Frequent Scenarios

| Scenario | Incorrect | Correct |
|------|------|------|
| **Replacing an item in a ForEach object array** | After `this.infos[0] = new Info()`, the key is unchanged, Child is not rebuilt, @ObjectLink still points to the old instance, and property changes do not refresh | Include a changing field in the key so ForEach recognizes the changed item and rebuilds Child |
| **Resetting data with an ordinary array** | `this.childList = [new Child(1), ...]` (ordinary Child[] assigned to an @Observed class variable); the new array is not observable | Assign `let temp = new ChildList()` (`@Observed` class extending Array), or use `makeV1Observed` |
| **Changing state in a synchronous callback** | Direct assignment in a synchronous render callback such as `onComplete` triggers "state changed during render" and the current refresh is ignored | Use `setTimeout` to make the assignment asynchronous |

### Troubleshooting Approach (Five Steps from `troubleshooting-state-manage.md`)

When @Observed does not refresh, check in this order:

1. **Are dependencies collected?** Check whether the state variable is read in build (inspect dependencies with ArkUI Inspector).
2. **Did the value really change?** Log the value before and after assignment.
3. **Is the assignment observable?** Use `UIUtils.getTarget(obj) === obj` to determine whether the object is proxied (false = proxied and observable); for @ObservedV2, check whether the property has @Trace.
4. **Are the data source and synchronized object connected?** Check whether ForEach/LazyForEach breaks the chain after replacing an item (compare references with `util.getHash`).
5. **Did the component update function run?** Check whether state was changed in a render callback, causing the current refresh to be ignored.

**Root cause summary**: The core of @Observed refresh failures is the "observation boundary": the first level is proxied by @State/@ObjectLink, and **each additional nesting level requires another @Observed + @ObjectLink child component**. Other frequent traps outside observation boundaries are constructor changes, unnotified LazyForEach replacements, whole-object @ObjectLink assignment, nested-array insertion/removal (Scenario 7), and aggregates not maintained manually (Scenario 8). See Section 3, the @Observed/@ObjectLink entry in `quick-rules/03-state-v1.md`, for the complete rules.

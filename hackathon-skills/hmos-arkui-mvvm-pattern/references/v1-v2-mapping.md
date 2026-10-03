# V1/V2 Array Update Behavior Differences

This is the most important behavioral difference between V1 and V2, and the easiest pitfall to encounter when refactoring a V1 project.

## Behavior Comparison

| Operation | V1 ordinary array `T[]` | V1 `@Observed extends Array` | V2 `@Trace` |
|------|---------------------|------------------------------|-------------|
| `arr.push(item)` | **No update** | Updates | Updates |
| `arr.splice(i, 1)` | **No update** | Updates | Updates |
| `arr = [...arr, item]` | Updates | Updates | Updates |
| `arr[i].prop = newVal` | First-level observation | First-level observation | Deep observation |

## V1 Array Update Solutions

```typescript
// ✓ Option 1: subclass Array with @Observed (recommended; used in official examples)
@Observed
export class ThingViewModelArray extends Array<ThingViewModel> {}

@Observed
export default class TodoListViewModel {
  @Track public things: ThingViewModelArray = new ThingViewModelArray();
  // push/splice can be used directly
}

// ✓ Option 2: replace the entire array
addTask(task: TaskViewModel) {
  this.tasks = [...this.tasks, task];
}
removeTask(task: TaskViewModel) {
  this.tasks = this.tasks.filter(t => t !== task);
}
```

In V2, arrays decorated with `@Trace` support push/splice directly and require no extra handling.

## V1/V2 Decorator Pairing Rules

Do not mix V1 and V2 decorators in the same component:

```typescript
// ✓ V1 set
@Component + @State/@Prop/@Link/@ObjectLink + @Observed + @Track

// ✓ V2 set
@ComponentV2 + @Local/@Param/@Event + @ObservedV2 + @Trace
```

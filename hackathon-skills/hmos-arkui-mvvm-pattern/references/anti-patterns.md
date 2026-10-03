# Architecture Anti-Pattern Checklist

- Anti-pattern 1: View directly accesses Model
- Anti-pattern 2: ViewModel depends on View
- Anti-pattern 3: V1/V2 mixing
- Anti-pattern 4: Page layer contains business logic

## Anti-pattern 1: View Directly Accesses Model

**Smell**: The View component directly imports a Model file, or `new ModelClass()` appears in the View.

```typescript
// ✗ Incorrect
import { TaskModel } from '../model/TaskModel';

@ComponentV2
struct TaskView {
  task: TaskModel = new TaskModel();  // Direct Model dependency

  build() {
    Text(this.task.name)
  }
}
```

**Fix**: Access it indirectly through the ViewModel.

```typescript
// ✓ Correct
import { TaskViewModel } from '../viewmodel/TaskViewModel';

@ComponentV2
struct TaskView {
  @Param task: TaskViewModel = new TaskViewModel();  // ViewModel dependency

  build() {
    Text(this.task.name)
  }
}
```

## Anti-pattern 2: ViewModel Depends on View

**Smell**: The ViewModel imports UI components or holds a View reference.

```typescript
// ✗ Incorrect
@ObservedV2
class TaskViewModel {
  view: TaskView;  // Lower layer depends on upper layer
  dialog: CustomDialogController;  // ViewModel holds a UI reference
}
```

**Fix**: Notify the upper layer through a callback.

```typescript
// ✓ Correct
@ObservedV2
class TaskViewModel {
  @Trace name: string = '';
  onNameChanged: (name: string) => void = () => {};

  updateName(newName: string) {
    this.name = newName;
    this.onNameChanged(newName);  // Notify the upper layer
  }
}
```

## Anti-pattern 3: V1/V2 Mixing

**Smell**: V1 and V2 decorators appear in the same component.

```typescript
// ✗ V1 component uses a V2 decorator
@Component
struct MyComponent {
  @Local count: number = 0;  // V1 components cannot use @Local
}

// ✗ V2 component uses a V1 decorator
@ComponentV2
struct MyComponent {
  @State count: number = 0;  // V2 components cannot use @State
}
```

**Fix**: Use a complete matching set. See the full mapping in [v1-v2-mapping.md](v1-v2-mapping.md).

```typescript
// ✓ V1 set
@Component + @State/@Prop/@Link/@ObjectLink + @Observed

// ✓ V2 set
@ComponentV2 + @Local/@Param/@Event + @ObservedV2
```

## Anti-pattern 4: Page Layer Contains Business Logic

**Smell**: Data processing, state calculation, or API calls appear in the Page component.

```typescript
// ✗ Page contains business logic
@Entry
@Component
struct TaskPage {
  @State tasks: TaskModel[] = [];

  aboutToAppear() {
    http.createHttp().request('https://api.example.com/tasks', (err, data) => {
      this.tasks = JSON.parse(data.result as string);
    });
  }

  build() {
    List() {
      ForEach(this.tasks.filter(t => !t.isDone), (task) => { /* ... */ })
    }
  }
}
```

**Fix**: The Page only assembles components.

```typescript
// ✓ Correct
@Entry
@Component
struct TaskPage {
  @State viewModel: TaskListViewModel = new TaskListViewModel();

  aboutToAppear() {
    this.viewModel.loadTasks();  // Delegate to ViewModel
  }

  build() {
    TaskListView({ viewModel: this.viewModel })
  }
}
```

## Quick Scan Checklist

| # | Check | How to inspect |
|---|--------|---------|
| 1 | Does a View file import a file from model/? | `grep -r "from.*model/" views/` |
| 2 | Does a ViewModel file import a UI component? | `grep -r "@Component\|struct.*build()" viewmodel/` |
| 3 | Are V1/V2 decorators mixed? | Check for `@Local/@Param` inside `@Component` and `@State/@Prop/@Link` inside `@ComponentV2` |
| 4 | Does the Page contain data-processing logic? | Check methods outside `build()` in the Page struct |
| 5 | Do V1 array push/splice operations trigger updates? | See the array behavior differences in [v1-v2-mapping.md](v1-v2-mapping.md) |

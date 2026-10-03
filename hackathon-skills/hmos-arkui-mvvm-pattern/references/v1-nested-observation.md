# V1 Nested Class Observation Patterns

> Source: [@Observed and @ObjectLink](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-observed-and-objectlink)

## Core Problem

`@State` / `@Prop` / `@Link` **observe only first-level changes**. The UI does not refresh when a deeply nested property changes.

```typescript
// ✗ Text in Index does not refresh when this.bag.book.name changes
@State bag: Bag = new Bag(new Book('JS'));

build() {
  Text(`${this.bag.book.name}`)  // bag.book is the first level; name is the second
    .onClick(() => {
      this.bag.book.name = 'TS';  // @State cannot observe this
    })
}
```

## Solution: @Observed + @ObjectLink

**Rule**: use `@Observed` for nested objects and receive them with `@ObjectLink` in child components.

```
@State observes outer-level changes (first level)
      ↓ pass to child component
@ObjectLink + @Observed observe nested changes (any level)
```

## Scenario 1: Nested Objects

```typescript
@Observed
class Book {
  public name: string;
  constructor(name: string) { this.name = name; }
}

@Observed
class Bag {
  public book: Book;
  constructor(book: Book) { this.book = book; }
}

// Child component: receive the nested object with @ObjectLink
@Component
struct BookCard {
  @ObjectLink book: Book;  // observes name changes

  build() {
    Column() {
      Text(`${this.book.name}`)  // refreshes when name changes
        .onClick(() => { this.book.name = 'C++'; })
    }
  }
}

@Entry
@Component
struct Index {
  @State bag: Bag = new Bag(new Book('JS'));

  build() {
    Column() {
      Text(`${this.bag.book.name}`)   // ✗ does not refresh here (second level)
      BookCard({ book: this.bag.book })  // ✓ refreshes here (@ObjectLink)
    }
  }
}
```

## Scenario 2: Arrays of Objects

Each array element is an `@Observed` object, received individually by child components with `@ObjectLink`.

```typescript
@Observed
class Info {
  public id: number;
  public info: number;
  constructor(info: number) { this.id = nextID++; this.info = info; }
}

@Component
struct Child {
  @ObjectLink info: Info;  // observes properties of one array item

  build() {
    Button(`info = ${this.info.info}`)
      .onClick(() => { this.info.info += 1; })
  }
}

@Entry
@Component
struct Parent {
  @State arrA: Info[] = [new Info(0), new Info(0)];

  build() {
    Column() {
      ForEach(this.arrA,
        (item: Info) => { Child({ info: item }) },
        (item: Info): string => item.id.toString()
      )
    }
  }
}
```

## Scenario 3: Two-Dimensional and Observable Arrays

Declare an `@Observed` subclass of `Array` so operations such as `push` and `splice` can be observed.

```typescript
@Observed
class ObservedArray<T> extends Array<T> {}

// Common MVVM pattern
@Observed
export class ThingViewModelArray extends Array<ThingViewModel> {}

@Component
struct Item {
  @ObjectLink itemArr: ObservedArray<string>;

  build() {
    Row() {
      ForEach(this.itemArr, (item: string, index: number) => {
        Text(`${index}: ${item}`)
      }, (item: string) => item)
    }
  }
}

@Entry
@Component
struct IndexPage {
  @State arr: Array<ObservedArray<string>> = [
    new ObservedArray<string>('apple'),
    new ObservedArray<string>('banana'),
  ];

  build() {
    Column() {
      ForEach(this.arr, (itemArr: ObservedArray<string>) => {
        Item({ itemArr: itemArr })
      })
      Button('push')
        .onClick(() => { this.arr[0].push('strawberry'); })  // ✓ observable
    }
  }
}
```

## Scenario 4: Multiple Nested Levels

**Rule**: each nested level needs a child component and `@ObjectLink`.

```typescript
@Observed
class SubCounter {
  public counter: number;
  constructor(c: number) { this.counter = c; }
}

@Observed
class ParentCounter {
  public counter: number;
  public subCounter: SubCounter;
  constructor(c: number) {
    this.counter = c;
    this.subCounter = new SubCounter(c);
  }
}

// First level: observe ParentCounter properties
@Component
struct CounterComp {
  @ObjectLink value: ParentCounter;

  build() {
    Column() {
      Text(`${this.value.counter}`)
        .onClick(() => { this.value.counter++; })
      // Pass the nested value to a dedicated child component
      CounterChild({ subValue: this.value.subCounter })
    }
  }
}

// Second level: observe SubCounter properties
@Component
struct CounterChild {
  @ObjectLink subValue: SubCounter;

  build() {
    Text(`${this.subValue.counter}`)
      .onClick(() => { this.subValue.counter += 1; })
  }
}
```

## @ObjectLink Restrictions

| Restriction | Description |
|------|------|
| No local initialization | `@ObjectLink obj: MyClass = new MyClass()` → compilation error |
| Variable is read-only | `this.obj = newObj` → runtime error; `this.obj.prop = val` → allowed |
| Cannot coexist with `@State` | `@ObjectLink` and `@State` cannot be used in the same component |
| Does not support primitive types | `@ObjectLink count: number` → compilation error; use `@Prop` instead |

## @Prop vs @ObjectLink

| Feature | `@Prop` | `@ObjectLink` |
|------|---------|---------------|
| Data transfer | Deep copy (one-way) | Reference (two-way) |
| Does a change affect the source? | No | Yes |
| Can it be initialized locally? | Yes | No |
| Can it be assigned as a whole? | Yes | No |
| Use case | Read-only display or a local editable copy | Two-way synchronization |

## @Observed Notes

- **Property changes in a constructor do not trigger UI updates**: constructor assignments bypass the proxy.
- **Do not use a timer in a constructor to change properties**: call a method from `aboutToAppear` instead.
- **`@Observed` changes the prototype chain**: do not combine it with other class decorators on the same class.

```typescript
// ✗ A constructor change does not trigger an update
@Observed
class RenderClass {
  waitToRender: boolean = false;
  constructor() {
    setTimeout(() => { this.waitToRender = true; }, 1000)  // does not update
  }
}

// ✓ Change it in the component
@Observed
class RenderClass {
  public waitToRender: boolean = false;
}

@Entry
@Component
struct Index {
  @State data: RenderClass = new RenderClass();

  aboutToAppear() {
    setTimeout(() => { this.data.waitToRender = true; }, 1000)  // updates
  }
}
```

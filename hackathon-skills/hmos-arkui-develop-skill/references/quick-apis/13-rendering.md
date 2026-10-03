## 13. Rendering Control

| Syntax | Signature | Description |
|------|------|------|
| **if/else** | `if (condition) {} else if {} else {}` | Conditional rendering |
| **ForEach** | `ForEach(arr, (item, index?) => void, keyGen?)` | Iterative rendering |
| **LazyForEach** | `LazyForEach(dataSource, (item, index?) => void, keyGen?)` | Lazy iterative rendering |
| **Repeat** | `Repeat\<T\>(arr)` | API 12+ V2 rendering control |

**Repeat method chain:**

| Method | Signature | Description |
|------|------|------|
| .each | `.each((ri: RepeatItem\<T\>) => void)` | Render each item |
| .key | `.key((item, index) => string)` | Generate key |
| .virtualScroll | `.virtualScroll(options?)` | Virtual scrolling |
| .template | `.template(name, itemGen, options?)` | Templating |
| .cachedCount | `.cachedCount(value: number)` | Cached count |
| .totalCount | `.totalCount(value: number)` | Total count |
| .onRequestItem | `.onRequestItem((index, key) => void)` | Request data |

---

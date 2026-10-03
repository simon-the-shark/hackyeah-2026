## 7. Rendering Control Constraints

### ForEach
| Rule | Description |
|------|-------------|
| Must be paired with a container | Generated components must be valid children of the parent container |
| **Do not include index in keys** | This can produce unexpected rendering and poor performance |
| Keys must be unique | Duplicate keys cause rendering errors |
| Default key generation has performance risks | `index + '__' + JSON.stringify(item)` can consume substantial memory |
| JSON.stringify can fail | Non-serializable values such as bigint can cause jscrash |
| Avoid mixing with LazyForEach | Do not mix them in one scrolling container |
| Prefer LazyForEach/Repeat for many children | ForEach may stutter with large data sets |
| Avoid replacing with equal-content items | Unchanged keys can prevent data changes from rendering |
| Use unique IDs for object data | This keeps keys unique and stable |

### LazyForEach
| Rule | Description |
|------|-------------|
| Only specific containers support lazy loading | List, ListItemGroup, Grid, Swiper, and WaterFlow |
| Only one LazyForEach per container | Do not combine it with ListItem, ForEach, or another LazyForEach |
| **Each iteration creates exactly one child** | The child generator has one root component |
| Keys must be unique and stable | Duplicate or changing keys cause rendering errors |
| Use DataChangeListener for updates | Reassigning the first dataSource argument is invalid; state changes do not refresh a state-backed dataSource |
| Generate a new key to refresh | onDataChange must produce a key different from the old key |
| Child dimensions are required | Missing height or width can disable lazy loading |
| Prefer Repeat | Repeat uses V2 state management and is recommended for migration |

### Repeat (V2)
| Rule | Description |
|------|-------------|
| Use only in @ComponentV2 | — |
| Supports virtualScroll / nonVirtualScroll | virtualScroll works with List/Grid/WaterFlow/Swiper |
| Set cachedCount for virtualScroll | Set it on the scrolling container, not the Repeat chain |
| Pass totalCount for virtualScroll | `virtualScroll({ totalCount: arr.length })` |
| key() must be unique | — |
| Recommended | More convenient and efficient than ForEach/LazyForEach |

### if/else
| Rule | Description |
|------|-------------|
| Conditional rendering is transparent | Parent child restrictions still apply through branches |
| Each branch must create a component | An empty builder is a syntax error |
| Branch changes do not preserve state | Lift state to the parent |
| Do not mutate application state in conditions | Constructor expressions must not change state |

## Common Errors
- Missing the third key-generator argument to ForEach.
- Using an index as a key.
- Reassigning a state-backed LazyForEach dataSource; use DataChangeListener.
- Using LazyForEach inside Scroll; use List/Grid/WaterFlow/Swiper.

---

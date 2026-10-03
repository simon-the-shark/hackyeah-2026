## 6. ForEach / LazyForEach Errors

| ❌ Common AI error | Reason | Rule section |
|--------------|------|---------|
| `ForEach(this.list, item => { ... })` omits the third parameter | Missing a key generator causes rendering errors | Rule 7: rendering control constraints |
| `ForEach(this.list, ..., (item, index) => index)` uses the index as the key | Index keys cause incorrect rendering and poor performance | Rule 7: rendering control constraints |
| `LazyForEach` uses a state variable as dataSource and reassigns it | Reassigning dataSource causes errors; DataChangeListener is required | Rule 7: rendering control constraints |
| `LazyForEach` is placed inside Scroll | LazyForEach is valid only in List/Grid/WaterFlow/Swiper | Rule 7: rendering control constraints |

**Root cause**: AI does not understand ForEach/LazyForEach keying or data-update rules.

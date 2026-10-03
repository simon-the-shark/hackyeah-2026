## 14. Layout Container Constraints

### List / Grid / WaterFlow / Swiper
- LazyForEach requires child dimensions; otherwise lazy loading may fail.
- Avoid using ForEach and LazyForEach in one container.
- cachedCount can improve lazy-loading performance.

### Flex
- Check the default flexWrap value and main-axis alignment.
- Deep nesting may hurt performance.

### RelativeContainer
- Configure anchor rules correctly; center/middle require anchor and align.

### Scroll
- Watch for scrolling conflicts in nested scrolling.

### Common Errors
| Wrong | Correct | Description |
|------|---------|-------------|
| Non-ListItem child in `List` | Wrap it in `ListItem` | List accepts ListItem direct children only |
| Non-TabContent child in `Tabs` | Use `TabContent` | Tabs accepts TabContent direct children only |
| Non-GridItem child in `Grid` | Use `GridItem` | Grid accepts GridItem direct children only |

---

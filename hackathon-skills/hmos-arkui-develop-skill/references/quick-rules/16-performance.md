## 16. Performance and Stability Constraints

| Rule | Description |
|------|-------------|
| **Do not change state in build() UI descriptions** | This can cause infinite rerender loops or performance loss |
| Network image syncLoad | Avoid synchronous loading stalls when many network images are used |
| Unregister callbacks | **Unregister promptly** when components are destroyed to avoid leaks |
| AnimatorResult cleanup | Delayed cleanup can leak memory |
| Prefer Repeat/LazyForEach for long lists | ForEach performs poorly with large data sets |
| Component reuse | Use @Reusable/@ReusableV2 with LazyForEach |
| @Track precise updates | @Track can reduce unnecessary rerenders |
| Component freezing | Use freezefreezeV2 to freeze inactive components |

---

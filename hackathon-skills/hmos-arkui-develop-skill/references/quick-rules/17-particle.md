## 17. Particle Animation Constraints

| Rule | Description |
|------|-------------|
| emitRate limit | **Above 5000** severely hurts performance; keep it below 5000 |
| Use lifetime = -1 carefully | Infinite-lifetime particles can severely hurt performance |
| Image particles do not support SVG | Image particles **do not support SVG or color configuration** |
| src cache | Reuse cached resources when src is unchanged; use distinct src values when switching dynamically |
| Automatic pause | Particle animation **pauses automatically** when the screen is off or the app is backgrounded |

---

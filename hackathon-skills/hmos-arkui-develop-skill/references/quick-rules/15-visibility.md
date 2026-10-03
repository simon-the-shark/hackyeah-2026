## 15. Visibility and Window Constraints

| Rule | Description |
|------|-------------|
| onVisibleAreaChange | Visibility is limited by parent bounds; it is calculated every frame, so **use sparingly** |
| nodeRenderState | **Avoid** for list items because nodes are recycled; prefer page- or Tab-level monitoring |
| Render state is not visibility | ABOUT_TO_RENDER_IN enters the render pipeline but may be covered by another component |

---

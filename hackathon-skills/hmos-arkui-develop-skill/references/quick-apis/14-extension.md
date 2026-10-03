## 14. Custom Extensions

### Modifier Family

| Modifier | Signature | Description |
|----------|------|------|
| **AttributeModifier** | `class M implements AttributeModifier { applyNormalAttribute(instance) }` | Dynamic attribute modification |
| **AttributeUpdater** | `class M extends AttributeUpdater { ... }` | High-performance attribute updates |
| **DrawModifier** | `class M implements DrawModifier { drawBehind?() drawContentBelow?() drawAbove?() }` | Custom drawing |
| **GestureModifier** | `class M implements GestureModifier { applyGestureType() setGestureEnabled() }` | Dynamic gestures |
| **ContentModifier** | `class M implements ContentModifier { applyContent(column) }` | Custom content |

### Custom Nodes

| Node | Signature | Description |
|------|------|------|
| **FrameNode** | `FrameNode(uiContext)` | Frame node |
| **RenderNode** | `new RenderNode()` | `.draw()` `.setBackgroundColor()` `.setOpacity()` `.setPosition()` `.setSize()` `.appendChild()` `.removeChild()` |
| **BuilderNode** | `new BuilderNode(uiContext, options?)` | `.build(builder, args?)` |
| **NodeController** | `class M extends NodeController { makeNode(uiContext) }` | Used with NodeContainer |

---

## 12. Extension Capability Constraints

### DrawModifier
- **One instance may be assigned to one component only**.
- **Do not** call drawModifier inside attributeModifier.

### GestureModifier
- **Custom components are unsupported**.
- **Do not** call gestureModifier inside attributeModifier.

### AttributeUpdater
- **One object may be associated with one component only**.
- Simultaneous updates of one attribute overwrite each other.

### NodeContainer
- Supports custom FrameNode and BuilderNode root nodes only.
- System component proxy nodes cannot mount successfully.

### Single-parent node rule
- A node **can have one parent only**.
- Remove it from the old parent before adding it to a new one.

### FrameNode
- Declarative system FrameNodes **cannot be modified** (100021).
- Unmounted nodes **cannot be operated on** (106203).

---

## 8. Animation Constraints

| Rule | Description |
|------|-------------|
| Position/size animation is expensive | width/height/position trigger layout recalculation; **prefer scale** |
| Use onFinish carefully | It may fire immediately when developer transitions or UIAbility backgrounding ends |
| Use animateToImmediately carefully | It bypasses vsync; **use animateTo normally** |
| keyframeAnimateTo lacks spring curves | springMotion / responsiveSpringMotion / interpolatingSpring are unsupported |
| Spring duration is automatic | Developer duration is **ignored** |
| springCurve is not recommended | It maps a physical spring to a fixed duration |
| transition versus property animation | Use transition for appearing/disappearing components and property animation for persistent components |
| Parent components need transition | Every parent needs a transition for child disappearance transitions |
| pageTransition is deprecated | Use Navigation and Modal transitions |
| @AnimatableExtend parameter types | Only number, string, Color, and unions are allowed |
| Card animation limit | Maximum duration is **1000ms** |
| AnimatorResult cleanup | Destroy it at the appropriate time to avoid leaks |

---

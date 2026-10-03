# Gear/keyboard interaction event # Route entrance

# The routing tree

```
Enter gesture/keyboard interactive scene
│
Ideas - Step 1: Default access to GESTURE-01
Note: The binding of gestures is a prerequisite for their validity, and any interaction of gestures requires confirmation of the method of binding.
│   │
│ - Check for need for simultaneous access to GESTURE-02
│
Ideas - Step 2: Does the API use involve specific gesture types?
│   │
│ Trigger signal (either hit or route):
• API keyword: TapGesture / LongPressGesture / PanGesture /
│   │      PinchGesture / RotationGesture / SwipeGesture / onClick / onTouch
│ Interactive meaning: click / double click / long press / drag / squeeze / rotate / slide
• Scene feature: Add the above-mentioned gestures to the component or need to know specific gestures API
│ Parameter Configuration and Revert Events (onActionStart / onActionUpdate / onActionEnd)
│   │
│ - Any signal hit → Route to GESTURE-02 (Performance type API)
GESTURE-02 not required
Step 3
│
Ideas - Step 3: Does it involve gesture combinations (multiple gestures)?
│   │
│ Trigger signal (either hit or route):
• API keyword: GestureGroup / GestureMode / Security / Parallel / Export
• Interactive meaning: multiple gestures / sign combinations / sequential gestures / parallel gestures / crosscut gestures /
│ Long drag / also rotate scaling / hand gestures
• Situation characteristics: multiple gestures need to be sequenced, simultaneously triggered, or mutually exclusive
│   │
Ideas - Any signal hit.
GESTURE-03
Step 4
│
Idea - Step 4: Does it involve hand gesture/touch incident response control, or gesture conflict and dynamic control?
│   │
│ Trigger signal (either hit or route):
· API Keywords: HitTest Behavior / restoneRegion / onTouchIntercept /
│   │      HitTestMode（Block / None / Transparent / BLOCK_HIERARCHY /
│   │      BLOCK_DESCENDANTS）/ onChildTouchTest / onGestureCollectIntercept /
│   │      monopolizeEvents / onGestureJudgeBegin /
│   │      shouldBuiltInRecognizerParallelWith / onGestureRecognizerJudgeBegin /
│   │      onTouchTestDone / preventBegin / GestureRecognizer /
│   │      GestureJudgeResult / GestureMask.IgnoreInternal / ScrollableTargetInfo
│ Interactive intent: mask penetrating / event intercept / touch hot zone / father-son gesture / multi-level gesture /
│Show competition / Event overwhelming / Stop scrolling / Widening the range of hits / gesture conflict /
│ System gesture capture / multi-touch conflict / gesture interception / gesture overtow / suspension/
│ Embedded Scroll / Disable zooming / Hand gesture exclusive / Dynamic rejection of gestures / Stop sign recognition
• Scene characteristics: both the father-son component binds the gesture/incident to control the response; mask/cover selective penetration;
│ Expansion of the clickable area; custom gestures conflict with system gestures; mostly, multiple responses operated simultaneously;
│ Responsiveness of dynamic control gestures; signature recognition of subcomponents for parent component management; prevention of specific type of gesture recognition
│   │
Imagination - Any signal hit, by GESTURE-04.
GESTURE-04
│
└-Performance:
• GESTURE-01 (coupling) > GESTURE-02 (gap type) > GESTURE-03 (gap combination) > GESTURE-04 (hand events response control and conflict management)
• When multiple hits occur at the same time, enter in order of priority, and binding is a prerequisite for the performance of gestures
```

# Site Index

# GESTURE-01 Handbanding scene

```yaml
scene_id: ARKUI-02-A
scene name: gesture binding and priority
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-bind.md
```

##GESTURE-02 gesture type scene

```yaml
scene_id: ARKUI-02-B
scene name: gesture type API use
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-type.md
```

##GESTORE-03 gesture combination scene

```yaml
scene_id: ARKUI-02-C
scene name: GestureGroup
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-group.md
```

#GESTURE-04 Gear Incident Response Control and Conflict Management

```yaml
scene_id: ARKUI-02-D
scene name: gesture event response control and conflict management
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-control.md
```

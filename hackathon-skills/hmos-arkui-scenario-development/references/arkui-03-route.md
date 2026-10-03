# State management # Route entrance

# Route target #

When you enter `ARKUI-03`, you continue to judge whether the user problem is a state management basis, a V1/V2 mix or a state variable-related extension capability, and read the corresponding resource files. The sub-situations are not mutually exclusive; mixing problems usually require simultaneous reading of the basis for using and mixing documents.

Output proposal:

```yaml
parent_scene: ARKUI-03
Primary sub scene: Core subscene ID
Secondary sub senses: [Other neutron scene ID]
next_scene_refs:
- The fate of the leaf document path
```

# The routing tree

```text
Enter state management scene
│
Ideas-Step 1: Create Candidates
Ideas - Do not maintain sub-situation description in decision tree; all specific descriptions below refer to the "situation index"
Ideas - extract decorators from user tips, codes, error reporting, data streams, state sources, listening/calculating demand and migration signals
Ideas - indent signals to match all sub-scenes Set
│ - Clear decorator, state API, synergetic/transfer expression, etc.
│
Idem - Step 2: Confirm state boundary with applies whon
│ - Check each candidate's subscene to see if applies whon covers the real-state source, data flow and synchronised/interview borders
Ideas - Multiple applies whon are all preserved at the same time, and base use, mixing and expansion can be hit simultaneously
│ - When not explicitly mixed, migrated or bridged, not only V1/V2 keywords should be used to select a mixer
│
Idea-Step 3: Fix Error With Not applies whon Medium
Idea - If not applies wen indicates that the problem is not a state management, back to the parent or other level 1 scene
Idea - to reduce the mix to subdary sub senses if the mix is a background check and non-core claim
│ - Select the base state in the scene index to use the scene round when the father's scene has been struck but the child's scene is not clear Bottom
│
Ideas - Step 4: Assisting decision-making at the decision-making stage with data
Ideas - REQ: Read dictums.REQ Clear state version, state source, data flow, listening/calculating, durability and migration range
Ideas - DEV: Read decisions.DEV Determine decorator selection, inter-component transfer, cross-level sharing, application status or bridging
Ideas-FIX: Read studies.FIX Checks for detectability, paternity/cross-level links, listening clean-up, refreshing timing and cross-boundary
│ - VAL: Read decisions.VAL to create synchronous, listening, computing, durability, mixing and pre- and post-move verification items
│
└ - Step 5: Read hit resources
Ideas--primary sub scene takes the core of the problem and applications whon's most complete subsituation
Ideas - secondary sub senses
Ideas - collection by neutron scene
└--resource refs read all of the multiple documents; mixed or inter-version bridge scenes must read the underlying document at the same time
```

# Site Index

###ARKUI-03-01 Status Management V1&V2 Use

```yaml
scene name: state management V1&V2
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./state-management/state-management-v1v2-scenario-development.md
intent_signals:
  - "@State" / "@Prop" / "@Link" / "@Provide" / "@Consume"
  - "@Watch" / "@Local" / "@Param" / "@Event" / "@Monitor"
- "@Computed" / "@ObservedV2" / "@Trace" / Status Management / V2 Status Management
applies_when:
- Need to transfer and share status data between components
- V1 status management is required (@state/@Prop/@Link/@Provide/@Consume)
- V2 status management required (@Local/@Param/@Event/@Monitor/@Compued)
- We need to listen to a change in state and carry out a callback.
not_applies_when:
- In conjunction with V1 and V2 status management (as part of ARKUI-03-02)
- Not state management (other scenes)
decisions:
  REQ:
- Confirm status management version: V1 (@state/@Prop/@Link)vs V2 (@Local/@Param/@Event)
- Identification of data flows: one-way/two-way binding of parent-son components, cross-level transmission
- Identification of listening needs: need for changes in listening status
  DEV:
-V1 scenario: @State (in-component) + @Prop (Paternity One-way) @Link (Paternity Two-way) + @Provide/ @Consume (cross-level)
-V2 Program: @Local (in-component) + @Param (Paternity) + @Event (Paternity) + @Monitor (Interception Change) + @Computed
- Select strategy: new project recommended V2, existing project selected on a needs basis
  FIX:
- Check for decorator versions: V1 and V2 decorators cannot be mixed with the same components
- Checks data flow: @Prop One-way/ @Link Both-way correct
- Checking @watch/ @Monitor echo: correct listening changes
  VAL:
- Status Synchronization: Is the parent-child component correctly synchronized?
- Listening back-to-back verification: whether the back-to-back triggers correctly when the state changes
```

## ARKUI-03-02 status management mix and migration

```yaml
scene name: state management mix
phase_tags: [REQ, DEV, FIX, VAL]
resource_refs:
  - ./state-management/state-management-v1v2-scenario-development.md
  - ./state-management/state-management-mixed-scenario-development.md
intent_signals:
- State management mix / V1V2 mix
- Decorator conflict.
applies_when:
- V1 and V2 status management needs to be used simultaneously in projects
- Compiling or running problems due to mixing of V1/V2 status management
not_applies_when:
- Use only V1 or V2 status management (as in ARKUI-03-01)
- Not state management (other scenes)
decisions:
  REQ:
- Determination of a mixed range: which components use V1 and which use V2
- Identification of compatible boundaries: data transfer programme between V1/V2 components
  DEV:
- Segregation principle: not to mix V1 and V2 decorations within the same component tree hierarchy
- Bridge: as a bridge for cross-version data by @Provide/@Consume or AppStorage/AppStorageV2
  FIX:
- Check for decorator mix: whether the same component mixed V1/V2 decorator
- Check data transmission: correct data transfer between V1 and V2 components
- Check the observation mechanism: @ObservedV2 + @Trace
  VAL:
- Mixed verification: correct transmission of data between V1/V2 components
```

## ARKUI-03-03 state management extension capability

```yaml
scene name: status management related extension
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./state-management/state-management-relative-scenario-development.md
intent_signals:
  - UIUtils / makeObserved / canBeObserved / getTarget / addMonitor / clearMonitor
  - applySync / flushUpdates / flushUIUpdates / Environment / "$$" / "!!"
- Properties Animation / Custom Component Freeze / "@Builder Refresh" / Cycle Rendering
applies_when:
- Need to use state variable assistive interfaces to determine, convert, listen or synchronize state
- Need for access to system environment variables or application level environmental status
- Need to use two-way binding syntax sugar, non-empty assertion or state-driven animation
- Need to address custom component freezes, @Builder refreshing or recycle rendering and status updates
not_applies_when:
- Just basic V1/V2 status transfer (from ARKUI-03-01)
- involving V1/V2 mixed, inter-version bridge (as part of ARKUI-03-02)
decisions:
  REQ:
- Determines the type of extension: UIUtils / Envirronment/ Double-direction syntax / Status Drive Animation / Reuse Freeze / Builder Refresh / Cycle Rendering
- Determine whether there is a need for mandatory synchronized refreshing or cross-level listening changes
- Determines whether the status update affects the re-use, freeze, condition or recycling of components
  DEV:
- UIUtils makeObserved/canBeObserved/getTarget/addMonitor/clarMonitor/applySync/flushUpdates/flushUIupdates
- Use Environment Access System Environmental Variables or Global Environmental State
- Use $$$$/!! Syntax: handle two-way binding and non-empty scenes
- State-driven animation, freezing of components, @Builder refreshing, circular rendering organization change
  FIX:
- Check the state-aided interface to see if the caller is visible and listens are cleared in time
- Check if the synchronized refreshing interface is overused or leads to an unusual timing of the refreshing
- Check if Environment, $,!
- Checking attribute animations, freezing components, Builder and refilling borders
  VAL:
- Status-assisted interface listening, synchronizing and cleaning authentication
- System Environment Variable Update and UI Refresh Validation
- Double-direction semantic sugar, attribute animation, freezing/re-use and circular rendering
```

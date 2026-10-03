# Hackathon Brief

The user owns the decisions recorded here. Unresolved fields may remain blank
until the current work depends on them.

## Pitch

**User problem:** Older people need simple ways to ask for help, maintain daily
medication routines, and stay connected while retaining independence. Guardians
need timely notice of a safe-area exit or SOS and understandable wellbeing updates.

**Desired demonstration:** A senior leaves a designated home area, an alert
reaches the guardian, and the guardian can contact them. A prominent SOS button
provides a second route to help. Medication reminders and a local wellbeing
check-in demonstrate everyday support.

**Lead challenge theme:** Human-Centric Technology, supported by Intelligent
Experiences through planned on-device AI. Medication 3D references provide a
secondary Spatial Experiences element if implemented.

**Distinctive platform capability:** Positioning and system notifications for
safety and reminders; phone/watch interaction for accessible SOS. Local inference,
camera scanning, calling, and 3D rendering are additional planned integrations.
At least one real platform integration must be verified in the final demo.

## Target

- Platform: OpenHarmony / Oniro
- API level: 20 or later
- Device type: Senior phone, senior smartwatch (primary intended SOS device),
  and guardian phone
- Validation target: OpenHarmony or Oniro phone emulator first; compatible watch
  emulator/device support must be established before claiming watch delivery

## Intended User Flow

1. Configure a senior/guardian relationship, designated home area, trusted
   contacts, and medication schedule using synthetic demo data.
2. Show the senior's simple home screen and current monitoring status.
3. Detect leaving the home area; send an event to the backend and show the
   resulting guardian alert once the separate integration is available.
4. Trigger SOS from the phone or supported watch; show sending/delivery state
   and let the guardian open the alert and call the senior.
5. Show a medication reminder, its reference model, and a taken/skipped action;
   demonstrate barcode-assisted entry with a known sample medication.
6. Record a wellbeing check-in and, when local inference is verified, generate
   an on-device summary for explicit sharing with the guardian.

## Acceptance Checks

- [ ] A functional core user flow runs on an emulator or compatible device.
- [ ] A real platform, device, or system capability is demonstrated.
- [ ] Setup, build, installation, and launch instructions are reproducible.
- [ ] Safe-area exit and SOS create distinct alerts with honest delivery states.
- [ ] Medication reminders and trusted-contact calling work on the target.
- [ ] Barcode entry and a medication 3D reference are demonstrated or explicitly
  recorded as incomplete.
- [ ] Watch SOS is verified on a compatible target or explicitly shown as simulated.
- [ ] On-device AI execution is evidenced, or the unavailable/simulated state is disclosed.
- [ ] A working `.hap`, demo recording, architecture summary, and AI disclosure are supplied.

## Scope Boundaries

- Core product: Safe-area monitoring on phone/watch, SOS (watch first as a UX
  goal), medication schedule/reminders, barcode scanning, medication 3D
  references, trusted contacts with easy dialing, and a local wellbeing assistant
  with guardian reporting. `MOBILE_PLAN.md` stages delivery by feasibility.
- Nice to have: Guardian-defined trips (v1), learned frequent routes and
  deviation warnings (v2), voice interaction, and fall detection.
- Separate ownership: Backend storage, event processing, and push infrastructure
  are handled by another agent. Mobile integration remains a dependency.
- Out of scope for this hackathon: Clinical diagnosis, medication prescribing,
  and a guaranteed emergency-response service.
- Planned simulations: Deterministic location traces, local guardian alert
  fixtures, barcode fixtures, and watch input when hardware is unavailable.
  Every simulated source must be visibly labelled. A local alert fixture does
  not establish remote push delivery or background geofencing support.

## First-Minute Narrative

“A simple companion helps an older person remain independent and keeps their
guardian informed. Here is the senior's home screen. They leave the designated
area: the guardian sees an alert and can call them. If they need help immediately,
they use SOS, ideally on their wrist. The same companion helps with medication
and a private daily wellbeing check-in.” Show any simulated inputs explicitly;
extend the recording with medication and AI only when those flows are implemented.

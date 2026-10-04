# Hackathon Brief

The user owns the decisions recorded here. Unresolved fields may remain blank
until the current work depends on them.

## Pitch

**User problem:** Older people need simple ways to ask for help, maintain daily
medication routines, and stay connected while retaining independence. Guardians
need timely notice of a safe-area exit or SOS and understandable wellbeing updates.

**Desired demonstration:** A senior leaves a designated home area, an alert
reaches the guardian, and the guardian can contact them. A prominent SOS button
provides a second route to help. Medication reminders and a wellbeing check-in
chat demonstrate everyday support.

**Lead challenge theme:** Human-Centric Technology, supported by Intelligent
Experiences through an AI wellbeing check-in chat (OpenAI models called by the
backend). Medication 3D references provide a secondary Spatial Experiences
element.

**Distinctive platform capability:** Positioning and system notifications for
safety and reminders; phone/watch interaction for accessible SOS. Microphone
recording and audio playback for the spoken check-in, camera scanning, calling,
and 3D rendering are additional integrations.
At least one real platform integration must be verified in the final demo.

## Target

- Platform: HarmonyOS
- API level: 20 or later
- Device type: Senior phone, senior smartwatch (primary intended SOS device),
  and guardian phone
- Validation target: DevEco Studio HarmonyOS phone emulator first; compatible watch
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
6. Have a short spoken wellbeing conversation with the assistant (hands-free:
   no buttons while talking). When it ends, the backend writes a summary that
   is sent to the guardian; only the guardian reads it; the senior sees
   that it was sent.

## Acceptance Checks

- [x] A functional core phone flow has recorded API 24 emulator E2E checks.
- [x] Location Kit integration and system dialer hand-off are recorded on the emulator.
- [ ] Setup, build, installation, and launch instructions are reproducible.
- [x] Safe-area exit and SOS create distinct alerts; acknowledgement/cancellation
  states were re-tested in the phone E2E fix pass.
- [x] Scheduled medication reminder delivery across background/restart is verified;
  dose actions and trusted-contact dialer hand-off already have recorded checks.
- [x] Barcode entry and a medication 3D reference are demonstrated or explicitly
  recorded as incomplete.
- [x] Watch SOS is verified end to end on a emulator, but complete pairing/SOS/sensor ingestion remains unverified.
- [x] The absence of a verified full spoken AI conversation on a target is disclosed.
- [ ] A working `.hap`, demo recording, architecture summary, and AI disclosure are supplied.

## Scope Boundaries

- Core product: Safe-area monitoring on phone/watch, SOS (watch first as a UX
  goal), medication schedule/reminders, barcode scanning, medication 3D
  references, trusted contacts with easy dialing, and a wellbeing assistant
  with guardian reporting. `MOBILE_PLAN.md` stages delivery by feasibility.
- Changed by user decision (2026-10-03): the wellbeing assistant is a chat with
  OpenAI models through the backend instead of on-device inference. The senior
  can write or speak (speech is transcribed by OpenAI and replies can be read
  aloud). When the chat ends, a summary report goes to the guardian
  automatically; the guardian sees the summary, not the conversation.
- Changed by user decision (2026-10-04): the check-in is voice only and hands-free.
  The phone streams the microphone to the backend, which relays it to the OpenAI
  Realtime model (`gpt-realtime-2.1-mini`); the model's voice-activity detection
  decides when the senior has finished speaking, so nothing has to be pressed.
  Typing and push-to-talk were removed from the senior screen.
- Added by user decision (2026-10-03): the guardian sees the watch's own
  location and the senior's heart rate from the watch, with an alert when it
  stays outside a set range. Informational only, never a diagnosis.
- Nice to have: Guardian-defined trips (v1), learned frequent routes and
  deviation warnings (v2), voice interaction beyond the check-in chat, and fall
  detection.
- Separate ownership: Backend storage, event processing, and push infrastructure
  are handled by another agent. Mobile integration remains a dependency.
- Out of scope for this hackathon: Clinical diagnosis, medication prescribing,
  and a guaranteed emergency-response service.
- Planned simulations: Deterministic location traces, local guardian alert
  fixtures, barcode fixtures, and watch input when hardware is unavailable. The
  wellbeing check-in has no simulation: without an OpenAI key it shows as
  unavailable.
  Every simulated source must be visibly labelled. A local alert fixture does
  not establish remote push delivery or background geofencing support.

## First-Minute Narrative

“A simple companion helps an older person remain independent and keeps their
guardian informed. Here is the senior's home screen. They leave the designated
area: the guardian sees an alert and can call them. If they need help immediately,
they use SOS, ideally on their wrist. The same companion helps with medication
and a daily wellbeing chat whose summary reaches the guardian.” Show any
simulated inputs explicitly.

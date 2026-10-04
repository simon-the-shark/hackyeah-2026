# Mobile Implementation Plan

## Goal And Current State

Build an accessible elderly-care companion for HarmonyOS using ArkTS,
ArkUI, and the Stage model. The senior uses a phone and, where supported, a
smartwatch; the guardian uses a phone. Human-Centric Technology leads the pitch.

This is a plan, not an implementation report. The current application is a
starter. The recorded successful build uses compile/target API 24 with API 20
compatibility; API 23 installation and a subsequent build remain unverified.
No new platform API or dependency is selected by this document.

Backend development is owned by the parallel backend agent. This plan covers
mobile UX, local logic, platform adapters, and integration requirements only.

## Delivery Priorities

P0 is the first end-to-end safety demo. P1 completes the requested daily-care
experience; these features remain product scope even if feasibility limits the
hackathon delivery. P2 contains the user's nice-to-haves.

| Priority | Feature | First deliverable | Dependency / completion condition |
| --- | --- | --- | --- |
| P0 | Phone geofencing | One configured home circle; inside/outside/unknown status; exit event | Real location and background behavior verified separately from trace replay |
| P0 | Phone SOS | Always-reachable button, event creation, visible send state | Guardian receives event through integrated backend; local fixture is demo-only |
| P0 | Guardian alerts | Alert list/detail, timestamp, source, contact action | Confirm remote push support and integrate backend delivery |
| P0 | Watch SOS and geofencing feasibility | Establish target, connectivity, and build path early | Watch is the primary intended SOS surface; unsupported hardware is a disclosed gap |
| P1 | Watch implementation | Large SOS control, status feedback, safe-area monitoring | Compatible runtime/device; establish whether phone relay is required |
| P1 | Watch heart rate for the guardian | Watch reads heart rate, shares a trend and one alert per sustained out-of-range episode; guardian screen with watch location | Wearable sensor and permission on target; informational only, never a medical assessment; emulator data labelled simulated |
| P1 | Medication schedule | Add/edit medication and times; reminders; taken/skipped/snoozed | Verified local scheduling, persistence, and restart behavior |
| P1 | Barcode entry | Scan known code, show candidate, confirm before saving | Camera/decoder support and catalog; manual entry for unknown codes |
| P1 | Medication 3D reference | View/rotate a bundled model associated with a demo medication | Verified renderer, licensed asset; clearly identify generic models |
| P1 | Easy contacts | Large predefined contact cards and system voice-call handoff | Calling support; emulator can verify handoff without proving a real call |
| P1 | AI wellbeing chat and reporting | Hands-free spoken check-in; summary sent to the guardian when it ends | OpenAI key on the backend; microphone streaming and playback verified on the target |
| P2 | Planned trips, v1 | Guardian defines destination/route and time window; deviation warning | Route definition and reliable location input |
| P2 | Learned routines, v2 | Suggest frequent routes from consented history; guardian confirms | Sufficient history and evaluated false-alert behavior |
| P2 | Voice interaction | Voice contact selection (the check-in chat already accepts speech) | Verify speech support; always retain touch controls |
| P2 | Fall detection | Sensor feasibility spike before implementation | Real watch sensors and false-positive evaluation; never infer success from mock data |

“Do not leave the house” means a designated safe-area alert, not precise indoor
door-crossing detection. Position accuracy may require a larger home radius.
Decide and demonstrate this limitation with real location samples.

## Roles And Screens

Use senior and guardian roles within the existing phone app for the first demo;
two emulator instances can exercise the roles independently. Separate app
packages are not required until deployment or pairing needs justify them.

### Senior Phone

- Home: SOS, next medication, contact shortcut, wellbeing check-in, and explicit
  location/network/monitoring status. SOS must remain usable without AI.
- SOS status: immediate activation, clear queued/sending/accepted/failed state,
  retry and call-contact actions. If cancellation is added, send a cancellation
  update rather than silently removing an already transmitted alert.
- Medication: schedule, detail/reference model, reminders and dose actions.
- Contacts: recognizable names, large call buttons; “voice” initially means a
  voice call. Speech-controlled selection is the optional voice feature.
- Wellbeing: a short check-in chat with the assistant by voice or text; when it
  ends, the summary sent to the guardian is shown, with the option to remove it.
- Setup/status: permissions, relationship/pairing, safe area, and demo mode.

### Guardian Phone

- Overview: senior's latest known status and last update, not an unqualified
  “safe” indicator when monitoring is unavailable.
- Alert list/detail: SOS or area exit, event time, device source, location
  freshness/accuracy when available, acknowledgement, and call action.
- Care setup: home circle, trusted contacts, medication schedule.
- Wellbeing reports: AI-written check-in summaries, clearly labelled, with the
  attention level and ratings in words; never the conversation itself.
- Watch & vitals: the watch's own last location (with age, accuracy, distance
  from home), its battery, the latest heart rate with its age, a 6-hour trend
  and the latest heart-rate alert. Simulated data is labelled; no diagnosis.
- P2 trip editor: intended route/destination, expected time, deviation state.

### Watch

- Primary screen: prominent SOS and clear activation/delivery feedback.
- Secondary: monitoring/connection status and, if time permits, next medication.
- Decide whether location is measured by the watch or relayed from the phone.
  Never present phone-derived location as independently verified watch location.
- If a watch target is unavailable, provide a labelled watch interaction
  simulation on the phone for the demo; do not count it as watch verification.
- Implemented as a separate `watch` entry module (`deviceTypes: ["wearable"]`):
  6-digit pairing, SOS, its **own** location heartbeat (`measuredBy: "watch"`),
  and heart rate via Sensor Service Kit (`SensorId.HEART_RATE`,
  `ohos.permission.READ_HEALTH_DATA`). The watch talks to the backend directly
  (no phone relay), and only while the app is in the foreground. Health Service
  Kit and Wear Engine were ruled out: they need a HUAWEI ID and service approval,
  and do not run on the wearable emulator.

### Accessibility

Large readable text, generous touch targets, high contrast, simple labels,
screen-reader descriptions, and status communicated with text as well as color.
Avoid gesture-only actions. Check larger font settings and one-handed SOS use.

## Mobile Architecture

Keep the existing `entry` module. Introduce boundaries only as they become useful:

- `pages`: senior/guardian screens and navigation.
- `components`: shared accessible controls and status displays.
- `models`: safe area, location sample, care event, medication/dose, contact,
  check-in, and guardian summary.
- `services`: geofence state machine, SOS orchestration, medication scheduling,
  persistent outgoing-event queue, and wellbeing summarization.
- `platform`: verified location, notification, storage, camera, calling, and
  inference wrappers.
- `providers`: remote care integration and clearly labelled deterministic demo
  provider using the same application-level operations.

The UI calls services; services use platform/provider boundaries. Keep geofence
transitions, medication occurrence logic, and retry behavior testable without
ArkUI or hardware. Add a watch module only after establishing target support.

## Core Behavior

### Safe-Area Monitoring

1. Store one center and radius; reject invalid coordinates or unusable radius.
2. Consume timestamped location samples with source and accuracy information.
3. Treat missing, stale, or insufficiently accurate samples as unknown. They
   must not silently reset an active alert or establish that someone is safe.
4. Use configurable hysteresis and consecutive valid samples/dwell time to
   avoid repeated alerts from boundary jitter. Choose thresholds from actual
   target testing, not arbitrary claims of precision.
5. Emit one exit event per transition, preserve state across restarts, and
   re-arm only after confirmed re-entry. Define startup-outside behavior as one
   initial outside alert rather than assuming an earlier crossing was observed.
6. Persist the event before transmission. Show monitoring unavailable when the
   platform cannot sustain background location.

### SOS And Delivery

- Create a stable event ID, event time, senior/device reference, source, and
  optional last-known location with age/accuracy; sending must not wait for GPS.
- Persist locally, retry transient failures with bounded backoff, and preserve
  IDs across retries so the eventual integration can deduplicate events.
- Separate queued, sending, server-accepted, guardian-delivered (only if
  confirmed), and guardian-acknowledged states. A successful request is not proof
  of a visible guardian notification.
- Offline UI explains that help has not yet been notified and exposes trusted
  contact calling. Never depend on LLM availability for this path.

### Medication

- Store name, user-confirmed dose/instructions, schedule/time zone, optional
  barcode, and reference asset. Do not infer a prescription from a barcode.
- A scanned code identifies a catalog candidate, not dosage or proof of correct
  medicine. Unknown or ambiguous codes lead to manual confirmation/entry.
- Use stable dose-occurrence IDs for taken/skipped/snoozed records. Check duplicate
  taps, restart recovery, clock/time-zone changes, and edited schedules.
- A model is an illustrative reference, not reliable pill identification.
  Display an image/text fallback if rendering is unavailable.

### Wellbeing Check-in Assistant

Changed by user decision (2026-10-03): the assistant is a chat with OpenAI
models called by the backend, not on-device inference. The API key lives only
on the server; the app never talks to OpenAI directly.

- The senior's Wellbeing tab opens a short spoken check-in (user decision
  2026-10-04: voice only, hands-free). The assistant asks about mood, energy,
  sleep, pain and worries, one short question at a time, in the senior's
  language. The phone streams 24 kHz PCM from Audio Kit `AudioCapturer`
  (`ohos.permission.MICROPHONE`) over a WebSocket to the backend, which relays
  it to the OpenAI Realtime model; replies come back as audio and play through
  `AudioRenderer`. The model's voice-activity detection decides when the senior
  has finished, so nothing is pressed while talking. The microphone is muted
  while Carely speaks (half-duplex), so a loudspeaker without echo cancellation
  cannot make her interrupt herself; "Let me talk" stops her. The transcript is
  shown as text.
- Before starting, the screen says that a summary goes to the guardian, that
  the guardian does not see the conversation, that replies come from an AI
  assistant that cannot give medical advice, and where SOS is.
- When the assistant has said goodbye (or the senior presses Finish, or the
  chat is idle for 20 minutes) the backend writes a structured summary
  (mood/energy/sleep/pain, things mentioned, attention level, 2-4 sentences)
  and sends it to the guardian automatically. The conversation itself is
  deleted from the server; only the guardian reads the summary; the senior
  sees that it was sent.
- Safety: the assistant never diagnoses or advises on medication. If the senior
  describes an emergency it tells them to press SOS or call 112 and the app
  shows a large SOS button; it never sends an SOS itself. A possible emergency
  raises one informational `wellbeing` alert for the guardian.
- Without an OpenAI key the voice check-in is shown as unavailable; there is no
  scripted fallback.
- Guardian: Wellbeing reports list and detail (summary, ratings in words,
  attention, how the senior answered), a local notification for each new
  report while the app is open, and an Overview row. AI-written content is
  always labelled and called not a medical assessment.
- Evaluate with synthetic conversations for factuality, missing topics,
  unsupported medical advice, emergency wording and malformed output. Record
  real latency on the target once a key is configured.

## Platform Feasibility Gates

Before implementing an unfamiliar API, consult current official HarmonyOS
documentation and record supported API level, Public versus Full SDK,
permissions, device support, and foreground/background restrictions. Confirm
behavior on the actual emulator or device. HarmonyOS Push Kit is the selected
remote alert transport (backend sender implemented, live delivery unverified);
other HarmonyOS Kits are not assumed until verified.

| Capability | Question to resolve | Honest demo fallback |
| --- | --- | --- |
| Location/geofencing | Location source, accuracy, background lifecycle and restart support? | Labelled trace replay plus separate real location check |
| Remote alerts | What push transport works on this image, including app terminated? | Labelled local fixtures; foreground refresh is not push |
| Local reminders | Scheduling while backgrounded/restarted and permission behavior? | In-app reminder explicitly labelled foreground-only |
| Watch | Supported device profile, packaging, location, network or phone relay? | Labelled phone-hosted watch simulation. Docs/SDK check: full `wearable` Stage apps are supported (separate entry module, no overlapping device types); Location Kit and Sensor Service Kit are available on wearable, geofencing is not; the DevEco wearable emulator simulates GPS and heart rate. Runtime on the emulator: see `AI_WORKFLOW.md` |
| Barcode | Public camera/decoder support and catalog availability? | Barcode fixture/manual entry, not a claimed live scan |
| 3D | Public renderer, asset formats, memory and licensing? | Static reference marked as such |
| Calling/voice | System dial handoff and optional speech availability? | Show contact number if calling unsupported |
| AI check-in | OpenAI key configured on the backend; microphone streaming and audio playback on the target? | Explicit gap: the check-in shows as unavailable |
| Fall sensing | Sensors, sampling/background access, and reliable evaluation? | Defer; synthetic trigger is not fall detection |

Fallbacks support development, but at least one real platform capability must
still be visibly verified for submission. Prefer verified local reminders and
location as early candidates. Do not add permissions or native dependencies
until the relevant capability is selected and justified.

## Backend Coordination: Mobile Needs Only

The backend now implements these needs; its API contract is
`backend/README.md`. The original list of needs is kept for reference:

- Identity/pairing: identify senior, guardian, and source device and obtain the
  allowed relationship/configuration.
- Configuration: read/update safe area, trusted contacts, medication schedule,
  and later trip definitions; agree conflict/version behavior.
- Events: submit SOS/exit and any cancellation updates with stable IDs and
  timestamps; agree retry/deduplication and acknowledgement semantics.
- Guardian delivery: registration if the chosen transport requires it, incoming
  alert payload, deep-link target, alert refresh, and acknowledgement operation.
- Reports: check-in chat sessions whose summaries the backend sends to guardians,
  and guardian report reads.
- Errors: agreed handling of unauthorized access, expired pairing, validation
  errors, temporary outages, and offline recovery.

Use synthetic fixtures behind the demo provider while backend work proceeds.
No private endpoints or credentials belong in repository examples. Remote
integration acceptance remains pending until both mobile roles run end to end.

## Implementation Sequence

1. **Feasibility and baseline:** verify installed SDK/build, boot phone target,
   check location/reminders/push/watch/microphone support, and record each
   gate's evidence. Confirm mobile integration needs with backend owner.
2. **Accessible safety slice:** role navigation, senior home/SOS, guardian alerts,
   persistent event queue, home-circle state machine, deterministic trace replay.
   Exit: repeatable local SOS and exit-alert scenarios with visible demo labels.
3. **Real platform and integration:** location, lifecycle handling, notifications,
   backend provider, and calling. Implement watch safety slice when target is
   available. Exit: document exactly which real delivery/background paths pass.
4. **Daily care:** schedule/persistence/reminders, barcode-assisted entry, bundled
   3D reference, contacts. Exit: demonstrate one complete medication flow.
5. **Wellbeing:** hands-free spoken check-in, automatic guardian report, guardian
   report screens. Exit: a real spoken conversation on the target or an explicit gap.
6. **Stretch and handoff:** only after core paths work, add planned trips before
   learned routes; assess voice/falls. Record demo, verified installation/launch
   commands, architecture, AI disclosures, and outstanding limitations.

## Verification And Demo

### Meaningful Logic Tests

- Geofence: inside → outside, boundary jitter, re-entry, startup outside, stale
  samples, poor accuracy, and restored state without duplicate exit events.
- Events: offline SOS, restart with queued event, retries with same ID, duplicate
  guardian receipt, server acceptance versus guardian acknowledgement.
- Medication: occurrence deduplication, snooze, edits, time-zone changes, restart.
- AI: summary grounded in the conversation, missing topics, malformed output and
  unavailable assistant; SOS never depends on the assistant.

### Runtime Checks

- Denied/revoked permissions; no location fix; network disconnect/reconnect.
- Foreground, background, termination and restart for monitoring/reminders/push;
  record restrictions rather than assuming a foreground success generalizes.
- Two phone instances/roles with real integration; watch standalone/relay and
  disconnect behavior if a supported watch is available.
- Large fonts, screen reader, repeated SOS taps, unknown barcode, missing asset.
- Spoken check-in on the target: microphone permission, streaming, playback,
  end-of-speech detection for slow speakers, reply latency and the summary.

### Deterministic Demo Script

1. Load synthetic senior/guardian, home circle, contacts, and one medication.
2. Show current monitoring state; run a labelled inside → outside trace if real
   movement cannot be reproduced. Open the guardian exit alert.
3. Trigger SOS on a real supported watch or phone; show honest delivery state and
   guardian contact action. Clearly label any local alert simulation.
4. Show a real platform reminder, dose action, known barcode and 3D reference
   where implemented; disclose any fixtures/static fallbacks.
5. Have a spoken wellbeing conversation and show the summary the guardian
   receives. Show one failure path, such as an offline queued SOS.

Completion evidence: build output and `.hap` location, installation/launch steps,
target/API details, test results, video, real-versus-simulated capability list,
and updated `AI_WORKFLOW.md`. None of these product checks has passed yet.

# Technical Stack

## Fixed

- Language: ArkTS
- UI: ArkUI
- Application model: Stage
- Platform: HarmonyOS (`runtimeOS: "HarmonyOS"`)
- Compile API: API 24
- Target API: API 23
- IDE: DevEco Studio
- Build: hvigor
- Device tooling: HDC
- UI iteration: Previewer
- Runtime verification: DevEco Studio HarmonyOS emulator
- Documentation MCP: Context7

## Selected Product And Planned Capabilities

Status updated 2026-10-04. Selected APIs are distinct from runtime validation;
Recorded results are in the AI work log.

- Elderly-care companion; scope and priorities are in `../archive/MOBILE_PLAN.md`.
- Senior and guardian phone experiences; a standalone foreground-only watch
  module with SOS, location reporting and heart-rate episode detection. Phone
  geofencing is implemented; independent watch geofencing is not a verified feature.
- Implemented platform adapters: positioning, background execution,
  notifications/reminders, camera/barcodes, calling, local persistence, 3D
  rendering, and microphone streaming/PCM playback (Audio Kit `AudioCapturer`
  and `AudioRenderer`) plus a Network Kit WebSocket for the wellbeing check-in.
- AI: the spoken wellbeing check-in uses the OpenAI Realtime model, proxied by
  the backend, and the Responses API for the guardian summary; see
  `../backend/README.md`. No model runs on the device.
- Two roles share the phone `entry` module; the watch has a separate `watch`
  module with non-overlapping wearable device types.
- Watch: a separate `watch` entry module for `wearable` devices in the same
  bundle. It uses Location Kit, Sensor Service Kit (heart rate,
  `READ_HEALTH_DATA`), Network Kit and ArkUI round-screen components
  (`ArcSwiper`), and talks to the backend directly after 6-digit pairing.
- Backend: Hono + Drizzle ORM + PostgreSQL in `../backend/`; guardian alerts
  currently use foreground polling and local notifications. A HarmonyOS Push
  Kit sender exists but live remote delivery is unverified.

## Remaining Validation And Decisions

- Real typed and spoken greetings are recorded, but a full real-model spoken
  check-in, summary and emergency tools on a target are unverified. The default
  mini Realtime model has not received a systematic conversation evaluation.
- Public SDK declarations and permissions were checked during implementation;
  phone background/screen-lock survival and battery consumption still need
  target-device checks.
- Watch runtime on a real device; the watch currently assumes its own network
  connection (no phone relay) and runs monitoring only in the foreground.
- Live HarmonyOS Push Kit delivery: the backend sender is implemented but has
  not been verified against a real AppGallery Connect project or emulator.
- Actual barcode decoding and native 3D rendering on a supported target. The
  catalog is synthetic and the model is a generic demo reference; see
  [`ASSET_PROVENANCE.md`](ASSET_PROVENANCE.md) for unresolved asset permissions.
- Voice control beyond the check-in chat, and fall-detection feasibility.

## SDK Compatibility Note

The project compiles with the HarmonyOS SDK `6.1.1(24)` bundled with
DevEco Studio, targets `6.1.0(23)`, and declares `6.0.0(20)` (API 20, the hackathon minimum) as its
compatible SDK.

## Deferred unless needed

- C++
- React Native
- ArkUI-X
- privileged/Full SDK APIs

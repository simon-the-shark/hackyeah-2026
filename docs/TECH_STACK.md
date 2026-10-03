# Technical Stack

## Fixed

- Language: ArkTS
- UI: ArkUI
- Application model: Stage
- Platform: HarmonyOS (`runtimeOS: "HarmonyOS"`)
- Development API: API 24
- IDE: DevEco Studio
- Build: hvigor
- Device tooling: HDC
- UI iteration: Previewer
- Runtime verification: DevEco Studio HarmonyOS emulator
- Documentation MCP: Context7

## Selected Product And Planned Capabilities

- Elderly-care companion; scope and priorities are in `../MOBILE_PLAN.md`.
- Senior and guardian phone experiences; smartwatch SOS and safe-area monitoring
  subject to compatible target verification.
- Planned platform integrations: positioning, background execution,
  notifications/reminders, camera/barcodes, calling, local persistence, 3D
  rendering, and on-device inference.
- Start with two roles in the existing phone app for the demo; decide watch
  packaging after checking its actual SDK/device support.
- Backend: Hono + Drizzle ORM + PostgreSQL in `../backend/`; guardian alerts
  are sent through HarmonyOS Push Kit.

## Not Selected Or Verified Yet

- Local LLM model, runtime, quantization, licensing, and device resource budget.
- Public SDK support, API levels, permissions, and background restrictions for
  each planned platform integration.
- Watch target, phone relay versus independent connectivity, and pairing method.
- Live HarmonyOS Push Kit delivery: the backend sender is implemented but has
  not been verified against a real AppGallery Connect project or emulator.
- Barcode catalog and 3D asset source/licensing.
- Optional voice recognition and fall-detection feasibility.

## SDK Compatibility Note

The project compiles and targets the HarmonyOS SDK `6.1.1(24)` bundled with
DevEco Studio and declares `6.0.0(20)` (API 20, the hackathon minimum) as its
compatible SDK.

## Deferred unless needed

- C++
- React Native
- ArkUI-X
- privileged/Full SDK APIs

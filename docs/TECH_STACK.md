# Technical Stack

## Fixed

- Language: ArkTS
- UI: ArkUI
- Application model: Stage
- Platform: OpenHarmony / Oniro
- Development API: API 24
- IDE: DevEco Studio
- Build: hvigor
- Device tooling: HDC
- UI iteration: Previewer
- Runtime verification: OpenHarmony/Oniro emulator
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
- Backend and database decisions belong to the parallel backend workstream.

## Not Selected Or Verified Yet

- Local LLM model, runtime, quantization, licensing, and device resource budget.
- Public SDK support, API levels, permissions, and background restrictions for
  each planned platform integration.
- Watch target, phone relay versus independent connectivity, and pairing method.
- Remote push mechanism available on the selected OpenHarmony/Oniro image.
- Barcode catalog and 3D asset source/licensing.
- Optional voice recognition and fall-detection feasibility.

## SDK Compatibility Note

The challenge guide recommends compiling against API 23. The installed DevEco
Studio SDK supports `6.1.1(24)` as its compile SDK, so this project compiles
and targets API 24 while declaring API 20 as its minimum supported API level.

## Deferred unless needed

- C++
- React Native
- ArkUI-X
- privileged/Full SDK APIs

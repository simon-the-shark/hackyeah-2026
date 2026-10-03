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

## Not selected yet

- product concept
- AI provider/model
- backend
- database
- device capabilities
- distributed architecture
- physical-device requirements

## SDK Compatibility Note

The challenge guide recommends compiling against API 23. The installed DevEco
Studio SDK supports `6.1.1(24)` as its compile SDK, so this project compiles
and targets API 24 while declaring API 20 as its minimum supported API level.

## Deferred unless needed

- C++
- React Native
- ArkUI-X
- external backend
- privileged/Full SDK APIs

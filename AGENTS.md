# Fixed Technical Scope

The product concept has not been selected yet, but the core development stack is fixed.

## Hackathon Submission

The submission must run on an OpenHarmony, HarmonyOS, or Oniro emulator or a
compatible physical device, build into a working `.hap`, and visibly use or
improve at least one platform, device, or system capability. The selected
concept must lead with Intelligent Experiences, Spatial Experiences, or
Human-Centric Technology.

Maintain reproducible setup, build, installation, and launch instructions.
The final public repository must not contain credentials, signing secrets,
personal data, tokens, or private endpoints.

Required deliverables are tracked in the root `README.md`,
`HACKATHON_BRIEF.md`, and `AI_WORKFLOW.md`. Treat
`https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/hackathon_challenge.md`
as the authoritative challenge statement.

## Platform

Use:

- OpenHarmony / Oniro
- ArkTS
- ArkUI
- Stage model
- Empty Ability project structure

Target OpenHarmony 6.1 / API 23 for current development unless a documented
compatibility reason requires another API level.

The hackathon requires API 20 or later.

Do not switch to:

- React Native,
- ArkUI-X,
- Flutter,
- Android application architecture,
- iOS application architecture,
- C++ as the primary application layer,

unless an accepted technical decision explicitly requires it.

C/C++ may be introduced later only for a concrete native capability or library
that cannot reasonably be implemented in ArkTS.

---

# Development Environment

The primary development environment is:

- DevEco Studio
- OpenHarmony SDK
- ArkTS toolchain
- hvigor
- HDC
- Previewer
- OpenHarmony/Oniro emulator

Use Previewer for fast ArkUI iteration.

Use an emulator or compatible physical device to verify actual application
behavior, lifecycle, permissions and platform integrations.

A successful Previewer render alone is not proof that a feature works on the
target platform.

---

# Documentation and MCP Usage

Context7 MCP is available for retrieving current library documentation.

Use Context7 when:

- working with third-party dependencies,
- checking current package APIs,
- verifying unfamiliar external library usage,
- generated code depends on a specific library version.

For OpenHarmony, Oniro, ArkTS and ArkUI platform APIs, prefer current official
OpenHarmony or Oniro documentation as the source of truth.

Do not assume that an API from:

- HarmonyOS,
- Android,
- TypeScript,
- a third-party library,

exists or behaves identically in OpenHarmony.

Before using an unfamiliar platform API:

1. verify it against current official documentation,
2. verify its supported API level,
3. verify permissions,
4. verify whether it is Public SDK or Full SDK,
5. then implement it.

Never invent platform API names.

---

# Dependency Policy

Keep dependencies minimal.

Prefer:

1. OpenHarmony platform APIs,
2. ArkTS standard capabilities,
3. small well-maintained external libraries only when they provide clear value.

Before adding a dependency:

- explain why it is needed,
- check whether the platform already provides the capability,
- verify current documentation using Context7 when applicable,
- avoid abandoned or unnecessarily large dependencies.

Do not introduce infrastructure for hypothetical future needs.

---

# Architecture Policy

Keep application code primarily in ArkTS.

Prefer simple boundaries such as:

- pages — screens
- components — reusable ArkUI components
- models/domain — application data and logic
- services — application-level capabilities
- platform — wrappers around OpenHarmony APIs
- providers — external integrations when required

Do not create these directories merely for architecture aesthetics.
Create them only when the implementation needs the separation.

Keep business logic out of large ArkUI components where practical.

Wrap complicated platform integrations so they can be mocked during testing.

---

# Emulator-First Policy

Every core demo path should run on the emulator whenever reasonably possible.

If a selected concept later depends on:

- camera input,
- sensors,
- location,
- multiple devices,
- hardware peripherals,
- external AI services,

design an explicit deterministic demo/test path where practical.

Mocks and simulations must be clearly identified as simulations.

Do not present simulated platform functionality as verified hardware behavior.

---

# Build Verification

After meaningful platform or configuration changes, verify the build.

Prefer the project's existing hvigor configuration rather than introducing a
parallel build system.

Use HDC when command-line interaction with an emulator or physical device is
needed.

Never claim:

- build success,
- installation success,
- emulator success,
- device success,

without actually verifying it.

---

# AI Transparency

At the start of an AI-assisted session, read `AI_WORKFLOW.md` and record any
new model, coding agent, MCP server, or agent skill before substantive work.
Update its work log after material work and before handoff. Keep descriptions
public-safe and record validation, failures, limitations, and lessons learned.

If AI is part of the product, document the model or service, inference flow,
data handling and privacy, failure behavior, and evaluation approach.

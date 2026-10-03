# Product Guidelines

> **Note:** These are the baseline guidelines for HarmonyOS development. They will be refined and expanded during the interactive project setup.

## Architectural Principles
- **Clean Architecture:** Strict separation of concerns between Domain, Data, and Presentation layers. The Domain layer must remain independent of external frameworks.
- **Dependency Rule:** Dependencies must only point inwards. The Domain layer should not know about the Data or Presentation layers.
- **Single Responsibility:** Each module, class, and function should have one clear responsibility to ensure maintainability.

## Development Workflow
- **Build Verification (required):** Run focused compile checks during implementation. Run the complete build/sign/device pass at an application-changing phase boundary. Repeat it only when packaging, signing, or runtime behavior may have changed.
- **Focused Tests (recommended):** Test business logic and critical user flows when the risk or acceptance criteria justify it. Do not add tests for wording-only or isolated styling changes without a regression risk.
- **Continuous Integration (recommended):** Keep the project buildable at meaningful phase boundaries; do not run unrelated full-project checks for low-risk work.

## ArkTS Development Standards
*Based on HarmonyOS application development concepts.*
- **Declarative UI:** Build UIs using the declarative syntax. Decompose complex views into smaller, reusable custom components (`@Component`) to maintain a clean UI tree.
- **State Management:** Use the correct decorators for data flow:
    - `@State` for internal component state.
    - `@Prop` for one-way synchronization from parent.
    - `@Link` for two-way synchronization.
    - `@Provide` / `@Consume` for cross-component communication.
- **UIAbility Lifecycle:** Manage application entry points and lifecycle events (Create, Foreground, Background, Destroy) within the `UIAbility` context properly.
- **Strict Typing:** Leverage TypeScript's static typing to prevent runtime errors. Avoid using `any` unless absolutely necessary.

## Code Standards
- **Naming Conventions:** Follow HarmonyOS/ArkTS official naming conventions (CamelCase for classes/structs, lowerCamelCase for variables/functions).
- **Documentation:** Document public APIs and complex logic when it improves reuse or handover. Do not add comments that merely restate code.

## Visual & UX Standards
- **Consistency:** UI components should follow the project's established design patterns.
- **Responsiveness:** Components should be designed to handle multiple device types (phone, wearable) as specified in the project configuration.

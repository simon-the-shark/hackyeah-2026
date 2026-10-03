# HarmonyOS Clean Architecture Guide

## Overview
This is the proposed default structure for HarmonyOS application features. It is
not applied automatically: before the first development track, show it to the
user and ask whether they accept, want to modify, or reject it. Apply these
rules only after explicit user acceptance, and record that decision in the
project's product brief or track plan.

## Layers

### 1. Domain Layer (Core)
- **Role:** Contains the business logic and entities.
- **Dependencies:** NONE. Must be pure ArkTS/TypeScript.
- **Components:**
  - **Entities:** Data models representing business objects.
  - **Use Cases:** Specific business actions (e.g., `GetTaskStatsUseCase`).
  - **Repository Interfaces:** Contracts defining data access methods.
  - **Required location:** `entry/src/main/ets/domain/` with `entities/`,
    `usecases/`, and `repositories/` subdirectories as needed.

### 2. Data Layer (Infrastructure)
- **Role:** Handles data retrieval and storage.
- **Dependencies:** Domain Layer.
- **Components:**
  - **Repository Implementations:** Concretions of Domain interfaces.
  - **Data Sources:** API clients, local database (RelationalStore/Preferences).
  - **Mappers:** Convert "Data Models" (JSON/DB) to "Domain Entities".
  - **Required location:** `entry/src/main/ets/data/` with `datasources/`,
    `repositories/`, and `mappers/` subdirectories as needed.

### 3. Presentation Layer (UI)
- **Role:** Displays data and handles user interaction.
- **Dependencies:** Domain Layer.
- **Components:**
  - **ViewModels:** Manages UI state and executes Use Cases.
  - **ArkUI Components:** Declarative UI using `@Component`, `@State`, `@Link`.
  - **Required location:** `entry/src/main/ets/presentation/` with `pages/`,
    `components/`, and `viewmodels/` subdirectories as needed. Generated
    `pages/Index.ets` may remain the entry page, but feature UI should be split
    into these locations as it grows.

### Proposed Project Shape (User Confirmation Required)

```text
entry/src/main/ets/
  domain/
    entities/
    usecases/
    repositories/       # interfaces only
  data/
    datasources/         # Preferences, RelationalStore, network, etc.
    repositories/        # implementations of domain interfaces
    mappers/
  presentation/
    pages/
    components/
    viewmodels/
  entryability/          # platform lifecycle only
```

If accepted, tests belong under the module's test source set and must exercise
domain logic without importing ArkUI or data-source implementations. If rejected,
use the user's chosen structure and document its dependency boundaries instead.

## Rules
If the user accepts this structure:

1. **Dependency Rule:** Source code dependencies can only point inwards: Presentation -> Domain <- Data.
2. **Separation:** A page or component must not import Preferences, RelationalStore, network clients, or concrete data repositories. It calls a ViewModel/use case instead.
3. **Repository Rule:** Repository interfaces live in Domain; implementations live in Data. Presentation depends on the interface or use case, never the implementation.
4. **State:** Use ArkTS decorators (`@State`, `@Prop`) strictly for UI state. Business logic state belongs in the ViewModel or Domain.
5. **Ability Rule:** `entryability/` owns lifecycle and window loading only; it must not contain feature logic.
6. **Review Rule:** Before closing a track, inspect imports against this shape and document any justified exception in the track log.

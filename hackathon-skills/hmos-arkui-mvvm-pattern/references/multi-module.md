# MVVM Architecture for Multi-Module Projects

## Official Three-Layer Architecture

```text
/application
├── common/                  # Shared capabilities; may be split into HAR/HSP modules
│   ├── common-model/        # Shared data entities and Repository
│   ├── common-base/         # Lowest-level infrastructure
│   ├── common-ui/           # Shared UI components
│   └── common-util/         # Shared data and constants
├── features/                # Feature modules
│   ├── feature-auth/        # Login and registration
│   ├── feature-cart/        # Shopping cart
│   ├── feature-order/       # Orders
│   └── feature-shared/      # Cross-feature business logic
└── products/                # Product customization
    ├── default/             # Phone/tablet Entry HAP
    └── wearable/            # Wearable Entry HAP
```

### Layer Responsibilities

| Layer | Module type | Responsibility | Typical content |
|---|---|---|---|
| Product customization | Entry HAP | Device adaptation, page entry, feature assembly | Index, MainAbility, device layouts |
| Feature | HAR/HSP/Feature HAP | Independent business features with ViewModel + View | Login, cart, order |
| Shared feature | HAR/HSP | Cross-feature business logic without Model | Price calculation, permissions, filtering |
| Shared capability | HAR/HSP | Models, Repository, and infrastructure | UserModel, networking, common components |

### Model Placement

Keep a Model in `feature/model/` when only one feature uses it. Put a Model in `common-model/` when multiple features use it. Shared Models avoid duplicated API structures and feature dependency cycles. Feature-specific Models should not be promoted.

### Common Module Strategy

Split `common` by responsibility as the project grows: `common-model` for entities and Repository, `common-base` for networking/storage/logging, `common-ui` for stateless UI components, and `common-data` for constants and types. Start with one common module and split only when needed.

### Dependency Direction

```text
products  →  features  →  common-model  ↘
                       →  common-ui     → common-base
                       →  common-data  ↗
                  ↕
          feature → feature-shared → common-model → common-base
```

Products must not depend horizontally on other products. Features must not directly depend on other features. `feature-shared` must not depend on feature modules. Common modules must not depend on upper layers.

## HAR vs HSP

| Dimension | HAR (static shared library) | HSP (dynamic shared library) |
|---|---|---|
| Compilation | Compiled into each consumer; independent instances | Shared at runtime; one instance |
| App size | Larger due to copies | Smaller due to sharing |
| Loading | No runtime loading overhead | Small first-load overhead |
| State sharing | Not shared between HAP instances | Shared within one process |
| Use case | Independent stateless features | Shared capabilities requiring common state |

If one HAR is referenced by both HAP and HSP, its singleton is not shared across loading contexts. Use HSP when singleton identity matters.

## MVVM Mapping

```text
Product customization layer ── no MVVM layer; assembly only
Feature layer                ── ViewModel + View + feature-specific Model
Shared capability layer     ── shared Model + Repository + common View components
```

ViewModel always stays inside its feature, not in `common` or `feature-shared`.

## Cross-Module State

For V2, define global UI state in `feature-shared` and share it with `AppStorageV2.connect`. For V1, let the products layer coordinate feature ViewModels through callbacks. Keep pure data entities in `common-model`.

## Cross-Module Navigation

Use `Navigation` and a route table. Each feature registers its routes; navigation should not directly import the target page.

```typescript
NavDestinationMap: Record<string, () => void> = {
  'AuthLogin': () => import('../../../features/feature-auth/views/LoginPage'),
  'CartDetail': () => import('../../../features/feature-cart/views/CartDetailPage'),
}
```

## Multi-Device Deployment

Use one Entry HAP for similar devices, or separate Entry HAPs when device UIs differ substantially. ViewModel logic can be shared across devices while Views remain device-specific. Use responsive layouts, qualified resource directories, `canIUse()` checks, and centralized product-level navigation.

## Common Errors

| Error | Consequence | Correct approach |
|---|---|---|
| Direct feature dependency | Dependency cycle and build failure | Move shared logic to `feature-shared` and Models to `common-model` |
| Reverse dependency from `feature-shared` | Dependency cycle | Make `feature-shared` depend on no feature |
| Model in `feature-shared` | Duplicated Models | Put shared Models in `common-model` |
| Business logic in products | Products becomes a god module | Products only assembles and bridges |
| HAR singleton expected across HAP/HSP | Independent instances | Use HSP when singleton identity is required |
| Wearable page depends on phone page | Horizontal product dependency | Move shared Views to features or common |

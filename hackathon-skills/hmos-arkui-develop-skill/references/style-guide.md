# ArkUI Code Style Guide

## Naming
### Component Names
Use meaningful PascalCase names such as `UserProfileCard` and `ProductListItem`; avoid `Card1` and `Item`.

### Variable Names
Use meaningful camelCase names such as `isLoading`, `userName`, and `itemCount`; avoid `flag`, `str`, and `num`.

### Private Members
Use the `private` modifier and do not prefix names with underscores.

## Code Structure
### Component Order
Use this order: state definitions -> property definitions -> private members -> lifecycle methods -> private methods -> computed getters -> build().

### Import Order
Use standard library -> third-party libraries -> local modules -> type definitions.

## Comment Rules
### File Comments
Document the component purpose, supported features, author, and date.

### Method Comments
Document the operation, parameters, return value, and thrown errors.

### Complex Logic Comments
Comment non-obvious UI sections such as search fields, lazy-loaded lists, and loading indicators.

## Formatting
### Indentation and Spaces
Use two-space indentation.

### Chained Calls
Put each method on its own aligned line.

### Blank Lines
Separate state definitions, properties, private members, lifecycle methods, private methods, and build() with blank lines.

## Type Annotations
### Required Type Annotations
Annotate state variables and method return types, for example `@State count: number = 0` and `private handleClick(): void`.

### Optional Parameter Types
Use `?` for optional properties and callbacks, such as `subtitle?: string` and `onItemClick?: (item: DataItem) => void`.

## Code Organization
### Component Decomposition
Split large views into small components or @Builder methods such as `Header`, `SearchBar`, `UserList`, and `LoadingIndicator`.

### Error Handling
Use try-catch-finally for asynchronous work, log the error, expose error state, and always clear loading state.

## Complexity
### Single Responsibility
Each component should have one responsibility. Extract avatar, card, statistics, and action sections when a component grows too broad.

### Method Length
Keep methods short and readable. A build() method with hundreds of lines should be decomposed.

## Code Style
### Semicolons
Use semicolons for imports, declarations, assignments, and logic calls. Do not use semicolons after declarative UI statements or chained UI attributes.

**Principle**: logic statements require semicolons; declarative UI statements do not.

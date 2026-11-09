# Feature-First Clean Boundaries

This document defines the target architecture for `ai_engineering_bazaar`.

## Goals

- Keep the codebase feature-oriented.
- Make dependency direction explicit and enforceable.
- Preserve the current Flutter stack: `flutter_bloc`, `go_router`, manual JSON models.
- Support incremental migration without breaking the existing app.

## Top-Level Ownership

```text
lib/
  app/               # Composition root, app shell, router, bootstrap
  core/              # Cross-cutting primitives, errors, logging abstractions
  infrastructure/    # Storage, HTTP, environment, external adapters
  shared/            # Reusable UI and helpers, plus the content and record kernels (shared/content, shared/record)
  features/          # Business capabilities
  generated/         # Generated localization files
  l10n/              # ARB files
```

## Dependency Rules

Allowed imports:

```text
app -> features
app -> shared
app -> infrastructure
app -> core

features -> shared
features -> infrastructure
features -> core

shared -> core
infrastructure -> core
infrastructure -> shared/content/domain
infrastructure -> shared/record/domain
```

Forbidden imports:

```text
feature_a -> feature_b
features -> app (except app/router/app_routes_constants)
shared -> features
shared -> app
shared -> infrastructure
core -> shared
core -> features
infrastructure -> features/presentation
infrastructure -> shared (except shared/content/domain and shared/record/domain)
```

## Feature Structure

Each feature owns its navigation, state, and data contracts.

```text
features/<feature>/
  data/
  domain/
  application/
  presentation/
  navigation/
```

Notes:

- `domain/` stays Flutter-free when possible.
- `application/` contains `Bloc`, `Cubit`, use-case orchestration, and feature coordinators.
- `presentation/` contains pages and feature-local widgets.
- `navigation/` exposes route builders for the app router.
- `data/` contains external models and repository implementations.

## App Responsibilities

`app/` is the only place that may compose concrete implementations for the whole application.

Examples:

- Router composition
- Global providers
- Content and record bootstrap
- Shell layout
- Theme and localization bootstrap

`app/` must not contain feature business rules.

## Shared vs Core

Use `shared/` for reusable UI and for the two kernels every feature reads:

- design system components
- dialogs
- generic widgets
- generic UI helpers
- the content and record kernels: entities, parsers, codecs, reducers, selectors, repository interfaces and their blocs; their domain/ folders import no Flutter and no I/O

Use `core/` only for primitives that should not depend on Flutter UI concerns:

- error types
- result wrappers
- logging contracts
- small common types

Do not place theme, routes, widgets, or screens under `core/`.

## Routing Rules

- `app/router` owns route composition.
- Each feature exposes its own routes from `features/<feature>/navigation/`.
- Redirect functions must stay pure and free of data loading side effects.
- Route builders must not create repositories directly.

## State Management Rules

- UI should never instantiate repositories directly.
- Feature pages should depend on feature application state only.
- Shell state is app-level.
- Feature state remains inside the feature module.

## Migration Strategy

- Prefer additive migration first.
- New code must target the new folders.
- Legacy folders may temporarily re-export new modules during migration.
- Delete legacy implementations only after imports have been redirected.

## Review Checklist

- Does the file live under the correct owner?
- Does the import direction respect the rules?
- Is UI free from direct repository creation?
- Is the route owned by a feature or by app shell?
- Is reusable UI placed under `shared/` instead of feature folders?

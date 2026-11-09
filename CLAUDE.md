# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter BLoC Advance Template - a production-ready Flutter application using BLoC pattern for state management. Supports Android and iOS.

- **Flutter:** 3.47.7 | **Dart SDK:** ^3.13.5 | **FVM** is used for Flutter version management
- **Line width:** 120 characters (configured in `analysis_options.yaml`)

## Common Commands

```bash
# Dependencies
fvm flutter pub get

# Run locally
fvm flutter run --target lib/main/main_local.dart

# Run production
fvm flutter run --target lib/main/main_prod.dart

# Analysis & formatting
fvm dart analyze
fvm dart fix --apply
fvm dart format . --line-length=120

# Tests
fvm flutter test
fvm flutter test test/path/to/specific_test.dart          # single test file
fvm flutter test --coverage                                # with coverage
# Android JVM tests of the native Sentry scrubber (JDK 17; a Flutter Android build, such as
# fvm flutter build apk --config-only --target lib/main/main_prod.dart, writes the Gradle wrapper)
cd android && ./gradlew :app:testDebugUnitTest -Ptarget=lib/main/main_prod.dart

# Localization code generation (after editing ARB files)
fvm dart run intl_utils:generate
fvm dart format lib/generated --line-length=120   # intl_utils writes 80 columns; CI checks 120

# Build
fvm flutter build apk --release --target lib/main/main_prod.dart
```

## Architecture

This project follows a **Feature-First Clean Architecture**. Every development MUST follow this modular approach.

### Project Structure

```
lib/
├── app/                    # Application foundation
│   ├── router/             # Centralized routing configuration
│   └── configuration/      # Global environment setup, logging, storage
├── features/               # Modular business features
│   └── <feature_name>/
│       ├── application/    # BLoCs & Use Cases (Business Logic)
│       ├── data/           # Repositories & Models (Data Layer)
│       ├── navigation/     # Feature-specific route definitions
│       └── presentation/   # Pages & Widgets (UI Layer)
├── shared/                 # Shared foundation across features
│   ├── design_system/      # Theme, typography, color tokens, atoms
│   ├── models/             # Cross-feature models/entities (e.g., UserEntity)
│   ├── utils/              # Generic utility functions
│   └── widgets/            # Reusable components (buttons, forms, etc.)
├── generated/              # Auto-generated localization (do not edit)
├── l10n/                   # ARB translation files
└── main/                   # Entry points (main_local.dart, main_prod.dart)
```

### Developing a Feature

- **Strict Isolation:** Features should not import from other features' internal directories (e.g., `features/user/presentation`).
- **Shared Access:** Cross-feature logic or models MUST be moved to `shared/`.
- **Clean Boundaries:** Each feature module is self-contained. Use Case (Application) layer should only depend on Repository (Data) interfaces.

## BLoC Pattern

Every feature follows: **Event → BLoC → State → UI**
- BLoCs use `Equatable` for state equality.
- Local UI state can be handled within the page, but business logic MUST be in BLoCs.

### `Bloc` vs `Cubit`

- Use **`Cubit`** when every interaction is an atomic, fire-and-forget call and the event stream adds no value (no debouncing, no concurrency policy, no historical event payload needed).
- Use **`Bloc`** when events carry meaningful payload, when an `EventTransformer` (debounce, restartable, droppable) is needed, or when the event log itself is valuable for replay/observability.
- Default to `Bloc` for any new feature touching network requests or user input streams; reach for `Cubit` only after confirming none of the above apply.

### State Modeling — MAIN RULE

**Default to sealed state hierarchies** that leverage Dart 3's `sealed` modifier and exhaustive `switch` expressions. The compiler enforces handling of every state variant; UIs render via pattern matching.

```dart
// State (a sketch; the template's UserListBloc it came from is removed)
sealed class UserListState extends Equatable {
  const UserListState();
}
final class UserListInitial extends UserListState { /* ... */ }
final class UserListLoading extends UserListState { /* ... */ }
final class UserListLoaded extends UserListState {
  const UserListLoaded({required this.users});
  final List<UserEntity> users;
  @override List<Object?> get props => [users];
}
final class UserListDeleteSuccess extends UserListState { /* ... */ }
sealed class UserListFailure extends UserListState {
  const UserListFailure({required this.errorCode});
  final AppErrorCode errorCode; // shown via errorCode.resolve(context); the raw message only goes to the log
  @override List<Object?> get props => [errorCode];
}
final class UserListLoadFailure extends UserListFailure { /* ... */ }
final class UserListDeleteFailure extends UserListFailure {
  const UserListDeleteFailure({required super.errorCode, required this.users});
  final List<UserEntity> users; // the list stays on screen while the failure is shown
  @override List<Object?> get props => [errorCode, users];
}

// UI
BlocBuilder<UserListBloc, UserListState>(
  builder: (context, state) => switch (state) {
    UserListInitial() || UserListDeleteSuccess() => const SizedBox.shrink(),
    UserListLoading() => const Loading(),
    UserListLoaded(:final users) || UserListDeleteFailure(:final users) => UserList(users),
    UserListLoadFailure(:final errorCode) => ErrorBanner(errorCode.resolve(context)),
  },
);
```

**Use single-state + status enum only when** one of these is genuinely true:

1. **Concurrent state access:** UI must render data from one state while reacting to another (e.g., show the previously loaded list while an error banner appears for the latest refresh attempt).
2. **Transactional snapshot:** State carries a coherent bundle whose fields all evolve together (search query + filters + pagination + result set) and splitting them into sealed variants would lose meaning.
3. **Form persistence:** Thin form/CRUD wrapper where status changes but form fields persist across all states, AND no genuine state machine exists underneath.

When in doubt, prefer sealed and split the BLoC instead of growing the single state.

**UI consumers** use `switch (state) { ... }` expressions, NOT `if (state is X) ... else if (state is Y)`. Reach for `BlocSelector` only when narrowing to a slice of a variant's fields — not for type discrimination.

**Why this rule (short version):** Compile-time exhaustive matching catches forgotten states at build time; impossible-state combinations (e.g. `loading=true && error="…"`) become unrepresentable; the `copyWith` null-clearing class of bugs disappears because variants carry only their own fields. Bloc creator [Felix Angelov](https://github.com/felangel/bloc/issues/1726) treats both patterns as valid; we pick sealed because Dart 3's modifiers + switch expressions tilt the trade-off decisively in its favor for this codebase.

## Logging

- Acquire loggers via `AppLogger.getLogger('Name')` (`lib/core/logging/app_logger.dart`).
- Use SLF4J-style parameterized substitution: `_log.debug('msg: {}', [arg])` — **not** string interpolation (`_log.debug('msg: ${arg}')`).
  - Parameterized form skips `toString()` when the log level is disabled — faster, and avoids accidentally stringifying secrets carried on events with `stringify = true`.
- `AppLogger` masks email addresses as `[REDACTED_EMAIL]` and credentials (passwords, OTP codes, tokens, `Bearer` values) as `[REDACTED]` in every line it prints, and masks the credential keys of a `Map` or `List` argument (`maskEmails`, `maskSecrets` and `scrubBodyKeys` in `lib/core/security/sensitive_data_scrubber.dart`, the one policy every exit uses).
- Never put a secret into a log message, a log argument or an exception message; a class that holds one prints `[REDACTED]` in its `toString` (`test/architecture/log_secrets_test.dart` guards the first rule).
- BLoC lifecycle transitions are logged centrally by `AppBlocObserver` (`lib/core/logging/app_bloc_observer.dart`). Do **not** override `onTransition` inside BLoCs.

## Environments

- `main_local` and `main_prod` differ only in their `Environment` (`lib/infrastructure/config/environment.dart`); Sentry starts only in prod with a `SENTRY_DSN` define.

## Adding a New Feature

1. Create a new directory under `lib/features/<feature_name>/`.
2. Define models and repository implementations in `data/`.
3. Add Use Cases and BLoCs in `application/`.
4. Define feature-specific routes in `navigation/`.
5. Implement pages and feature-specific widgets in `presentation/`.
6. Register the feature routes in `lib/app/router/app_router.dart`.
7. Add translations to `lib/l10n/`, run `fvm dart run intl_utils:generate`, then `fvm dart format lib/generated --line-length=120`.
8. Write tests mirroring the feature structure under `test/features/<feature_name>/`.

## Testing

- `test/flutter_test_config.dart` is the global bootstrap (auto-discovered by `flutter test`). It runs once per isolate — binding init, `AppLogger.configure`, `EquatableConfig.stringify`, mocktail `registerAllFallbackValues()` — and registers a global per-test `setUp`/`tearDown` that calls `TestEnv.reset()`.
- The bootstrap also clears `rootBundle` before and after every test, including in files that opt out of `TestEnv.reset()`: an asset `Future` cached by one `testWidgets` resumes its awaiters only in that test's finished `FakeAsync` zone, so without the reset the later tests of a file never got their asset responses (see "The asset cache" in `docs/testing-architecture.md`).
- The global reset is `TestEnv.reset()` (`test/support/test_env.dart`).
- A test file that installs its own `MethodChannel` / `SharedPreferences` mock opts out of the global reset with `setUpAll(() => TestEnv.autoReset = false);` (isolated per file). Example: `test/infrastructure/storage/local_storage_test.dart`.
- **Test doubles** — reach for a `mocktail` mock first; drop to a hand-fake only for genuine stateful behavior:
  - **mocktail mock (default):** the `Mock*` classes in `test/mocks/mock_classes.dart`, for interface doubles configured with `when(...)` / `verify(...)` (repository / use-case / BLoC).
  - **handwritten fake:** a private `_Fake*` / `_Memory*` class next to the test when it needs real stateful behavior (in-memory store, throw-on-Nth-call, selective/sequenced failures, return-driven branching). These are **purpose-built per test** — same-named fakes in different files are not duplication; do not force them into shared "god" fakes.
- **Pumping:** `pumpAndSettle()` only when animations finish; its `Duration` arg is the per-pump interval (not a timeout) — prefer the bare form. For continuous animations (spinner/shimmer) use `pump(Duration)`, never `pumpAndSettle`.
- Full test structure, per-layer patterns, and guard tests: see `docs/testing-architecture.md`.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Engineering Bazaar mobile: the AI Engineering Bazaar course as a reader for Android and iOS (`dev.lokumai.bazaar`, Dart package `ai_engineering_bazaar`).
The course opens offline from a bundled snapshot of the site's content bundle and refreshes when the site publishes a newer one; both tracks (For Engineers and For Everyone); progress stays on the device in the web's record format, and the app imports and exports the web's file.
The web repo (lokumai/ai-engineering-bazaar) is the only producer of content.

- **Flutter:** 3.47.7 | **Dart SDK:** ^3.13.5 | **FVM** is used for Flutter version management
- **Line width:** 120 characters (configured in `analysis_options.yaml`)

## Common Commands

```bash
# Dependencies
fvm flutter pub get

# Run locally (CONTENT_BASE_URL is required: https, with a trailing slash; any https preview of the site works)
fvm flutter run --target lib/main/main_local.dart --dart-define=CONTENT_BASE_URL=https://ai-bazaar.lokum.dev/

# Run production (content from https://ai-bazaar.lokum.dev/)
fvm flutter run --target lib/main/main_prod.dart
# a release that sends crash reports adds --dart-define-from-file=sentry_dsn.json (gitignored, README Privacy)

# Analysis & formatting
fvm flutter analyze
fvm dart fix --apply
fvm dart format . --line-length=120

# Tests
fvm flutter test test/path/to/specific_test.dart          # single test file (no heavy needed)
heavy fvm flutter test --coverage                         # the whole suite
heavy fvm flutter test --tags golden --update-goldens     # regenerate goldens after an intended visual change
heavy fvm flutter test integration_test -d <device>       # device tests (emulator, simulator or phone)

# The gate every commit passes
heavy bash -c 'fvm dart format . --line-length=120 --set-exit-if-changed && fvm flutter analyze && fvm flutter test --coverage && scripts/check_coverage.sh coverage/lcov.info 90'

# Android JVM tests of the native Sentry scrubber (JDK 17; a Flutter Android build, such as
# fvm flutter build apk --config-only --target lib/main/main_prod.dart, writes the Gradle wrapper)
cd android && ./gradlew :app:testDebugUnitTest -Ptarget=lib/main/main_prod.dart

# Localization code generation (after editing intl_en.arb)
fvm dart run intl_utils:generate
fvm dart format lib/generated --line-length=120   # intl_utils writes 80 columns; CI checks 120

# Content snapshot (generated: never edit assets/content/ or test/fixtures/record_conformance/v1.json)
fvm dart run tool/refresh_content_snapshot.dart --base-url https://ai-bazaar.lokum.dev/ --content-version <contentVersion>
fvm dart run tool/generate_tokens.dart   # after every snapshot refresh; never edit bazaar_tokens.g.dart

# Synthetic content fixture (after a change under test/fixtures/content/src/)
fvm dart run tool/build_content_fixture.dart

# Builds
heavy fvm flutter build apk --release --target lib/main/main_prod.dart
heavy fvm flutter build appbundle --release --target lib/main/main_prod.dart
heavy fvm flutter build ios --no-codesign --target lib/main/main_prod.dart   # macOS with Xcode
```

## Architecture

This project follows a **Feature-First Clean Architecture** with two shared kernels.
Every development MUST follow this modular approach.

### Project Structure

```
lib/
  main/main_local.dart, main_prod.dart        entry points
  app/
    app.dart                                    MaterialApp.router; mounts the router when ContentBloc and RecordBloc are ready,
                                                under the opening, behind Welcome's steps on the first launch
    bootstrap/                                  boot order, Sentry gate, CONTENT_BASE_URL check (main_local)
    di/app_dependencies.dart, app_scope.dart    the only place infrastructure is constructed; providers
    dev_console/                                dev console; debug only
    router/app_router.dart                      route table; not_found_page.dart
    shell/bazaar_shell.dart                     ShellRoute scaffold: status strip, bar (back, level hue and title on level and
                                                module pages; empty on the tabs), thin lattice band, bottom navigation of icons
                                                with small names (Home, Catalog, the Caravan's camel, Quiz, Settings;
                                                shared/design_system/widgets/caravan_icon.dart)
  core/                                         logging, security scrubber, analytics interface
  infrastructure/
    config/environment.dart                     AppConfig with contentBaseUrl
    analytics/                                  Sentry start, native channel, scrubbers
    content/                                    FileContentRepository, BundledContent, ContentHttp, object store
    storage/record/file_record_repository.dart  record files under Application Support/record/
    storage/flags/file_flag_store.dart          the app's own flags under Application Support/flags/ (Welcome seen)
    storage/text/file_text_store.dart           one text file of the app's own, written atomically (quiz/scores.json)
    backup/platform_backup_gateway.dart         file_picker behind IBackupGateway
    app_icon/app_icon_channel.dart              the app icon's native channel (MainActivity.kt, AppDelegate.swift)
  shared/
    content/domain/                             Track, entities, ContentParser, exceptions, IContentRepository, the search's
                                                word rules (search_text.dart)
    content/application/                        ContentBloc
    content/presentation/                       block and inline renderers, diagram, logo and image widgets, quiz_slot.dart,
                                                the marks of the words searched (text_find.dart)
    record/domain/                              constants, envelope, normaliser, instant, writer, reducers, selectors, ports
    record/application/                         RecordBloc, curriculumFor
    record/presentation/record_write_notice.dart  the write-failure line shared by the reader and Settings
    quiz_scores/                                QuizScore and its file shape, IQuizScoreStore, QuizScoresBloc (plan 1W): the
                                                app's own quiz scores, never in the record
    app_icon/                                   BazaarIcon (the robot app icons, on dark or cream), AppIconCubit, its store and
                                                switch ports: the icon on the home screen and the opening's colours;
                                                presentation/: AppIconRow and AppIconChoices, which Settings shows
    robot_level/                                RobotLevelCubit: the pocket model's level, which unlocks the app icons
    theme/                                      ThemeChoiceCubit (light or dark; the phone's until chosen), IThemeStore, appearance_name.dart:
                                                the choice kept on the device, never in the record
    track/                                      TrackCubit; TrackSwitch, the segmented control the pages of a track place
    navigation/bazaar_paths.dart                route paths and the track switch mapping
    navigation/web_links.dart                   contentBaseUrl for shared widgets and features
    navigation/reader_target.dart               a module page's heading and words searched, passed as the route's extra
    navigation/tab_switch.dart                  marks a move to another tab, whose pages come in and go out at once
    design_system/                              bazaar_tokens.g.dart (generated), bazaar_theme.dart, fonts, diagram frame ink
    design_system/widgets/                      lattice band, level hue and key, completion dial, segment meter, card, section
                                                rule, segmented control, the readable width that holds a tablet's page to a
                                                phone's measure
    utils/external_link.dart                    openExternalLink, the only importer of url_launcher
    utils/app_orientations.dart                 portrait on a phone, every orientation on a tablet
  features/
    home/                                       Home at `/`: continue card, the modules after it, practice, offline note
    catalog/                                    catalog root at `/sheets` with the progress (stats, dials, completion marks,
                                                legend), the search over the module documents, and the level page (Cards)
    reader/                                     ModuleReaderBloc, reader page, contents sheet, planned and not-written views
    quiz/                                       QuizCubit, the quiz card, the full-screen quiz, the Quiz tab at `/quiz` and a
                                                module's quiz at `/quiz/<level>/<module>`
    settings/                                   track, language, the app icon page, the data (DataBloc, data line, quarantine notice, dialogs),
                                                content status, Check for updates, licences, debug dev-console button
    welcome/                                    the opening (WelcomeSting, the agent), WelcomeBloc, its store port and the
                                                first-launch steps (language and track, then the story the app passes in)
    about/                                      the story of the Bazaar from the bundle (AboutBloc), told as a film over the
                                                whole screen: at `/settings/about`, outside the shell, and Welcome's last step
    guide/                                      How the bazaar works, at `/settings/guide`
    caravan/                                    the Caravan tab at `/caravan`, coming soon until the bundle carries
                                                the web's timeline
  l10n/intl_{en,tr,fa}.arb, generated/          every string in all three languages (generated/ is never edited)
tool/                                           refresh_content_snapshot.dart, generate_tokens.dart, build_content_fixture.dart,
                                                render_app_icons.dart (fvm flutter test tool/render_app_icons.dart)
assets/content/                                 index.json, api_index.json, objects/<sha256> (the bundled snapshot, generated)
assets/fonts/                                   Vazirmatn-Regular.ttf, Vazirmatn-Bold.ttf, OFL.txt; Fraunces.ttf, Fraunces-Italic.ttf, OFL-Fraunces.txt
assets/brand/, assets/welcome/, assets/about/   the Lokum logo, the Welcome art and the story's scenes, each with its SOURCE.md
integration_test/                               device tests
```

### The two shared kernels

- `lib/shared/content` holds the bundle entities, the consumer parser and `ContentBloc`; `lib/infrastructure/content` implements its repository over the bundled snapshot and the object store.
- `lib/shared/record` is a pure-Dart port of the web's record code and `RecordBloc`; `lib/infrastructure/storage/record` implements its repository over files.
- `lib/shared/content/domain/` and `lib/shared/record/domain/` import no Flutter (`package:flutter/`, `dart:ui`) and no I/O (`dart:io`).
- Only `lib/app/di/` constructs infrastructure.
- `WebLinks` (`lib/shared/navigation/web_links.dart`) carries `contentBaseUrl` to shared widgets and features; `AppScope` provides it, because shared code may not import `AppConfig`.
- The `QuizBuilder` typedef lives in `lib/shared/content/presentation/quiz_slot.dart`; the router passes the quiz feature's panel, because the reader may not import the quiz feature.

### Layering

`test/architecture/import_guard_test.dart` enforces these rules:

- `core/` imports nothing from `shared/`, `features/`, `infrastructure/` or `app/`.
- `shared/` imports nothing from `features/`, `app/` or `infrastructure/`.
- A feature imports no other feature and nothing from `app/` (the one known exception is `app/router/app_routes_constants`).
- `infrastructure/` imports nothing from `features/` or `app/`, and nothing from `shared/` except `shared/content/domain` and `shared/record/domain`.
- The two kernel domain folders import no Flutter and no I/O.

### Developing a Feature

- **Strict Isolation:** a feature imports no other feature's directories.
- **Shared Access:** cross-feature logic or models MUST move to `shared/`.
- **Clean Boundaries:** each feature module is self-contained and maps the kernels' state to widgets.

## D111: the app maps data to widgets

The app may count and sum values the bundle publishes for display (a level's module count, a sum of `minutes`, `MODULE n OF N`).
It never derives a fact the bundle does not carry (a word count, a checklist index, a module's topics).
Such a need becomes a proposed web change, not app code.

## BLoC Pattern

Every feature follows: **Event -> BLoC -> State -> UI**
- BLoCs use `Equatable` for state equality.
- Local UI state can be handled within the page, but business logic MUST be in BLoCs.

### `Bloc` vs `Cubit`

- Use **`Cubit`** when every interaction is an atomic, fire-and-forget call and the event stream adds no value (no debouncing, no concurrency policy, no historical event payload needed): `TrackCubit` (the current track, in memory for the session, For Engineers at start) and `QuizCubit`.
- Use **`Bloc`** when events carry meaningful payload, when an `EventTransformer` is needed, or when the event log itself is valuable: `ContentBloc` (a refresh is `droppable`), `WelcomeBloc` (it asks storage), `RecordBloc` (every event runs in one queue, so writes, erases and undos never overlap; it owns the 10 s undo window, A42) and `ModuleReaderBloc`.
- Default to `Bloc` for any new feature touching storage, network requests or user input streams; reach for `Cubit` only after confirming none of the above apply.

### State Modeling: MAIN RULE

**Default to sealed state hierarchies** that leverage Dart 3's `sealed` modifier and exhaustive `switch` expressions.
The compiler enforces handling of every state variant; UIs render via pattern matching.

```dart
// lib/features/reader/application/reader_state.dart
sealed class ReaderState extends Equatable { const ReaderState(); }
final class ReaderLoading extends ReaderState { /* ... */ }
final class ReaderWritten extends ReaderState {
  const ReaderWritten({required this.doc, required this.entry, required this.moduleCount});
  final ModuleDoc doc;
  final ModuleEntry entry;
  final int moduleCount;
  @override List<Object?> get props => [doc, entry, moduleCount];
}
final class ReaderPlanned extends ReaderState { /* doc with a draft and no body, entry, moduleCount */ }
final class ReaderNotWritten extends ReaderState { /* entry: the For Everyone version is not written */ }
final class ReaderNotFound extends ReaderState { /* ... */ }
final class ReaderFailed extends ReaderState { /* code: ContentErrorCode */ }

// UI
BlocBuilder<ModuleReaderBloc, ReaderState>(
  builder: (context, state) => switch (state) {
    ReaderLoading() => const Loading(),
    ReaderWritten(:final doc, :final entry, :final moduleCount) => WrittenView(doc, entry, moduleCount),
    ReaderPlanned(:final doc, :final entry, :final moduleCount) => PlannedView(doc, entry, moduleCount),
    ReaderNotWritten(:final entry) => NotWrittenView(entry),
    ReaderNotFound() => const NotFoundView(),
    ReaderFailed(:final code) => ContentErrorView(code),
  },
);
```

**Use single-state + status fields only when** one of these is genuinely true, and name the exception in the class comment:

1. **Concurrent state access:** UI must render data from one state while reacting to another.
2. **Transactional snapshot:** state carries a coherent bundle whose fields all evolve together, and splitting them into sealed variants would lose meaning.
   `RecordReady` is this exception: the record, its write state, the quarantine notice, the write gate and the erase undo evolve together and are shown together.
3. **Form persistence:** thin form wrapper where status changes but form fields persist across all states, and no genuine state machine exists underneath.

When in doubt, prefer sealed and split the BLoC instead of growing the single state.

**UI consumers** use `switch (state) { ... }` expressions, NOT `if (state is X) ... else if (state is Y)`.
Reach for `BlocSelector` only when narrowing to a slice of a variant's fields, not for type discrimination.

**Why this rule:** compile-time exhaustive matching catches forgotten states at build time; impossible-state combinations become unrepresentable; the `copyWith` null-clearing class of bugs disappears because variants carry only their own fields.

## Record rules

The record is the web's, byte for byte; `lib/shared/record` ports the web's code and the conformance fixture pins it.

- The app writes a completion and its removal in the current track's map (the completion event carries the track, A35), the active day, and `meta.lastExport` after a confirmed save (A19).
- The app writes a checklist tick and its removal under `sheets[key].checklist["<index>"]` (web D129).
- The app never writes `prefs`, dwell or `reachedEnd`; it keeps them as it read them.
- Files live under Application Support: `record/record.json`, `record/record-quarantine.json` and `record/record.json.tmp`.
  A write goes to `record.json.tmp` with a flush, then is renamed over `record.json`; a leftover `.tmp` is ignored at launch.
- A malformed or newer record is set aside with its bytes in `record-quarantine.json` and reads as empty.
- Days are the UTC day of the instant, as the web's `toISOString`, never the device's local day.
- `asInstant` is a strict grammar, not `DateTime.tryParse` (A20).
- Parsing re-keys every object the web rebuilds from a template into the template's key order (A21).
- Restoring a file closes an open reset undo; the erase word is accepted trimmed and in any case (A33); the dialog also takes the word in the interface's language (`erase_word`: SİL, حذف), Turkish i's folded as one.
- `test/fixtures/record_conformance/v1.json` is generated by the snapshot tool and never edited; `test/shared/record/conformance_test.dart` is the authority, and export bytes equal the web's.

## Object store

- The bundled snapshot is `assets/content/index.json`, `assets/content/api_index.json` and `assets/content/objects/<sha256>`.
- Downloaded content lives under the cache directory in `content/`: `objects/<sha256>`, `indexes/<contentVersion>.json`, the `current` pointer and the `pending` pointer of a refresh under way. A start keeps the pending refresh's index and objects, so a refresh cut off by closing the app goes on where it stopped.
- Every object is checked against its sha256 on every read.
- A refresh adopts only a strictly later `publishedAt` and never leaves a mixed set; a cache not later than the bundled snapshot is deleted at startup.
- A sha256 mismatch on a downloaded object is `RefreshFailed(checksum)`, retried at the next cold start (A25).
- `revision.hash` is validated as `^[0-9a-f]{4,40}$` (A24).

## Snapshot tool and token generator

- `tool/refresh_content_snapshot.dart` reads the site's `api/v1/` at a given `contentVersion` and writes `assets/content/` and `test/fixtures/record_conformance/v1.json`.
- `tool/generate_tokens.dart` reads the snapshot's `tokens.json` and writes `lib/shared/design_system/bazaar_tokens.g.dart`; `tokens_generated_test` compares them.
- Both outputs are committed and never edited by hand; run the tool and commit what it writes.

## Copy register

Reader-visible copy follows the web's register (A12), and `test/architecture/arb_copy_register_test.dart` holds `intl_en.arb` to it:

- no exclamation mark, no first person (except the label `Keep my data`);
- none of: easy, easily, just, simply, simple, quick, quickly, please, sorry, oops, whoops, valid, invalid, praise words or "you forgot";
- an unwritten module is `Planned`; a module is `complete` or `completed`, never signed off; a `module`, never a sheet.

## Logging

- Acquire loggers via `AppLogger.getLogger('Name')` (`lib/core/logging/app_logger.dart`).
- Use SLF4J-style parameterized substitution: `_log.debug('msg: {}', [arg])`, **not** string interpolation (`_log.debug('msg: ${arg}')`).
  - Parameterized form skips `toString()` when the log level is disabled: faster, and avoids accidentally stringifying secrets carried on events with `stringify = true`.
- `AppLogger` masks email addresses as `[REDACTED_EMAIL]` and credentials (passwords, OTP codes, tokens, `Bearer` values) as `[REDACTED]` in every line it prints, and masks the credential keys of a `Map` or `List` argument (`maskEmails`, `maskSecrets` and `scrubBodyKeys` in `lib/core/security/sensitive_data_scrubber.dart`, the one policy every exit uses).
- Never put a secret into a log message, a log argument or an exception message; a class that holds one prints `[REDACTED]` in its `toString` (`test/architecture/log_secrets_test.dart` guards the first rule).
- BLoC lifecycle transitions are logged centrally by `AppBlocObserver` (`lib/core/logging/app_bloc_observer.dart`). Do **not** override `onTransition` inside BLoCs.

## Environments

- `main_local` and `main_prod` differ only in their `Environment` (`lib/infrastructure/config/environment.dart`) and their content base URL.
- `main_local` requires `CONTENT_BASE_URL`; the app allows no cleartext traffic, and a content request times out after 30 s (A32, A43).
- Sentry starts only in prod with a `SENTRY_DSN` define, and sends crash reports, hangs, the app start, release-health sessions and Report a problem (the owner, 2026-11-13; `docs/store-privacy.md`): no navigator observer, since a route carries a module key, and `sentryBeforeSendTransaction` drops every transaction but the app start; automatic session tracking on in `configureSentryOptions` and in `NativeSentry.kt` (on Android the Dart option does not reach the native SDK). Dart events and feedback, and on Android the native SDK's events and breadcrumbs, are scrubbed; on iOS the native SDK records only app hangs and sessions of its own (`configureNativeSdkStart`). A change to what Sentry sends changes `docs/store-privacy.md`, the iOS privacy manifest, `privacy_crash` and the site's privacy note. The DSN comes from the gitignored `sentry_dsn.json` (`--dart-define-from-file=sentry_dsn.json`) and is never committed.

## Adding a New Feature

1. Create a new directory under `lib/features/<feature_name>/`.
2. Read content and the record through the shared kernels' blocs; a feature adds infrastructure only through `lib/app/di/`.
3. Add BLoCs or Cubits in `application/`.
4. Define feature-specific routes in `navigation/` and register them in `lib/app/router/app_router.dart`.
5. Implement pages and feature-specific widgets in `presentation/`.
6. Add strings to `lib/l10n/intl_en.arb`, `intl_tr.arb` and `intl_fa.arb` under the copy register, run `fvm dart run intl_utils:generate`, then `fvm dart format lib/generated --line-length=120`.
7. Write tests mirroring the feature structure under `test/features/<feature_name>/`, with the accessibility checks of `test/support/accessibility.dart` on every page.

## Testing

- `test/flutter_test_config.dart` is the global bootstrap (auto-discovered by `flutter test`): binding init, `AppLogger.configure`, `EquatableConfig.stringify`, mocktail `registerAllFallbackValues()`, the `rootBundle` reset before and after every test, and a per-test `TestEnv.reset()` (`test/support/test_env.dart`).
- A test file that installs its own `MethodChannel` mock opts out of the reset with `setUpAll(() => TestEnv.autoReset = false);`.
- Tests read the synthetic content fixture (`test/fixtures/content/`, `FixtureAppDependencies` and `testContentBaseUrl` in `test/support/content_fixture.dart`), never a fact of the real course; `content_facts_not_restated_test` guards it.
- **Test doubles:** a `mocktail` mock first (`test/mocks/mock_classes.dart`); a private `_Fake*` or `_Memory*` class next to the test only for genuine stateful behaviour; `MockClient` for HTTP.
- **Pumping:** `pumpAndSettle()` only when animations finish; for a spinner use `pump(Duration)`.
- Every page runs the accessibility guidelines under `bazaarPlatforms` and text scale 2.0 (the reader 3.0).
- Full test structure, per-layer patterns, guard tests and device tests: `docs/testing-architecture.md`.

## Machine resources

Every build, full test suite, gate chain, and anything that starts an emulator, simulator or browser runs through `heavy` (`~/.local/bin/heavy`), one full gate at a time.
Exit 137 under `heavy` is the memory cap: report it and run less at once; never raise the cap or bypass `heavy`.
A single test file or a quick probe does not need it.

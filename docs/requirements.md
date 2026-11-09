# Requirements

What the AI Engineering Bazaar mobile reader must do, and the rules every change is held to.
Each requirement names where it comes from, so a question about it goes to the right place.
The work still to do is in [plan.md](plan.md).

## 1. Sources

The spec and the plan PR #1 was built from are kept outside this repository (PR #1, Q1).
This file collects what is binding from the sources that are in reach:

| Source | Holds |
| --- | --- |
| `CLAUDE.md` | The rules of this repository: architecture, BLoC, record, object store, copy register, logging, environments, `heavy` |
| `docs/feature-first-clean-boundaries.md` | Folder ownership and the allowed import directions |
| `docs/testing-architecture.md` | How the suite is built and what each guard test holds |
| PR #1 description | Acceptance criteria (spec 4.2), decisions A1 to A45, proposed web changes, owner follow-ups |
| Web repo `kia-context/specs/MANIFESTO.md` section 7 | One course, two apps (D111) |
| Web repo `kia-context/specs/ARCHITECTURE.md` section 13 | The content bundle contract (`src/lib/bundle/schema.ts`) |
| Web repo `kia-context/logs/BRAINSTORM.md` | D89 (the bundle), D111 (parity), D112 (WebP images), D113 (only content is multilingual) |

When two sources disagree, the web repo's decisions win on what the product does, and `CLAUDE.md` wins on how this code is written.

## 2. Product rules

- **R1 One course, two apps (D111).** The app may look different from the website; its content, logic and behaviour are the same. A reader gets the same content and a similar experience on both.
- **R2 The web is the only producer of content (D89).** The app reads the JSON bundle the web build publishes under `api/v1/` and maps each node to a widget.
- **R3 Derive nothing (D111, `CLAUDE.md`).** The app may count and sum values the bundle publishes (a module count, a sum of `minutes`, `MODULE n OF N`). It never computes a fact the bundle does not carry. A missing fact becomes a proposed web change, not app code.
- **R4 No account.** Progress stays on the device. There is no sign-in, no server state and no sync.
- **R5 Only content is multilingual (D113).** Menus, labels and navigation stay English. The bundle carries English, Turkish and Persian documents; v1 shows English only (D89).
- **R6 Android and iOS only.** No web, macOS, Linux or Windows platform folders (`platform_folders_test`).

## 3. Functional requirements

### Content and refresh

- **R10** The first launch opens offline, from the snapshot bundled under `assets/content/`.
- **R11** At every cold start, and on Check for updates, the app asks the site for a newer bundle. It adopts only a strictly later `publishedAt` and never leaves a mixed set of files.
- **R12** Every object is checked against its sha256 on every read. A mismatch on download is `RefreshFailed(checksum)`, retried at the next cold start (A25).
- **R13** A downloaded cache that is not later than the bundled snapshot is deleted at startup.
- **R14** If major version 1 is no longer published, the app reports that it needs an update.
- **R15** An unknown block or inline type renders as a newer-version row with Open on the web; unknown fields are ignored (A23).
- **R16** Content is fetched over https only; a request fails after 30 s without data (A32, A43).

### Tracks and navigation

- **R20** Both tracks, For Engineers and For Everyone, with a track switch in the bar. The current track lives in memory for the session and starts at For Engineers (A11).
- **R21** Routes follow the web's paths: `/`, `/everyone/sheets`, `/sheets/<level>`, `/courses/<level>/<module>`, their `/everyone` forms, `/profile` and `/settings` (A9).
- **R22** No outside link or intent chooses the first page; deep linking is off (A5, final review).
- **R23** The bottom navigation holds Catalog, Progress and Settings.

### Catalog

- **R30** The catalog root mirrors the web's Overview: one section per level, its modules, `Planned` for an unwritten module.
- **R31** The level page mirrors the web's Cards view with the full filter bar: Level and Status (A10, A45).
- **R32** Length is shown in minutes only, until the web publishes a word count (proposed web change 1).

### Reader

- **R40** A module renders in the web's order: title, minutes, prerequisites, objectives, body, completion, pager, quiz, footer.
- **R41** Diagrams, figures, logos, tables, code, callouts and quotes render; diagrams follow the device's light or dark mode, with labels in the bundled Vazirmatn face (D89).
- **R42** A contents drawer lists the depth-2 sections of a written module.
- **R43** A planned module shows its schedule of parts; a For Everyone module with no document shows the not-written view.
- **R44** Captions read `FIG. n · Title` and `TBL. n · Title` (A14); task-list boxes are read-only (A16).

### Quiz

- **R50** For Engineers modules with a quiz show it one question at a time; the first pick is final; results list every question.
- **R51** The quiz writes nothing to the record.

### Progress and the record

- **R60** The record is the web's, byte for byte. `lib/shared/record` ports the web's code, and `test/shared/record/conformance_test.dart` with `test/fixtures/record_conformance/v1.json` is the authority.
- **R61** The app writes only a completion and its removal in the current track's map, the active day, and `meta.lastExport` after a confirmed save (A19, A35). It keeps `prefs`, checklist ticks, dwell and `reachedEnd` as it read them.
- **R62** Days are the UTC day of the instant. `asInstant` is a strict grammar (A20).
- **R63** Writes are atomic: `record.json.tmp` with a flush, then a rename.
- **R64** A malformed or newer record is set aside in `record-quarantine.json` and reads as empty; the progress page shows a notice with Save a copy and Delete it.
- **R65** Back up writes the web's export file; restore reads the web's export, refuses a newer schema, and asks before replacing a non-empty record.
- **R66** Reset needs the word ERASE, shows the counts and the backup line, deletes the record files, and can be undone for 10 s (A42).
- **R67** The record is included in the device backup, and the erase screen says so (D89).

### Settings

- **R70** Settings shows the content version, the published day, the source (bundled or downloaded), the refresh status, Check for updates and the licences.
- **R71** Debug builds also show the developer console button (A6).

## 4. Engineering requirements

### Architecture

- **R80 Feature isolation.** Every feature lives in its own folder under `lib/features/<feature>/` (`application/`, `presentation/`, `navigation/`). A feature imports no other feature and nothing from `app/` except `app/router/app_routes_constants`. Some duplication is accepted to keep features apart.
- **R81** Logic used by more than one feature moves to `lib/shared/`. The two kernels are `lib/shared/content` and `lib/shared/record`; their `domain/` folders import no Flutter and no I/O.
- **R82** Only `lib/app/di/` constructs infrastructure. `infrastructure/` imports nothing from `features/` or `app/`.
- **R83** `test/architecture/import_guard_test.dart` enforces R80 to R82.

### State

- **R90** Every feature follows Event, BLoC, State, UI. Use `Cubit` only when no event payload, transformer or event log is needed.
- **R91** States are sealed hierarchies rendered with exhaustive `switch`. A single state with status fields needs one of the three named exceptions in `CLAUDE.md`.

### Quality

- **R100 Accessibility.** Every page passes the four accessibility guidelines on Android and iOS, at text scale 2.0 (the reader at 3.0). Tap targets are 48 on Android and 44 on iOS (A28). Colour is never the only signal.
- **R101 Copy register.** Reader-visible strings live in `lib/l10n/intl_en.arb` and follow the web's register (A12): no exclamation mark, no first person, none of the banned words; `Planned`, `complete`, `module`.
- **R102 Privacy.** Sentry runs only in prod with `SENTRY_DSN`, sends crash reports only, and is scrubbed (A5). No secret in a log.
- **R103 Tests.** No test asserts a fact of the real course; tests use the synthetic fixture under `test/fixtures/content/`.
- **R104 The gate.** Every commit passes format at 120, analyze, the full suite and coverage of at least 65 %, run through `heavy`.
- **R105 Generated files.** `assets/content/`, `test/fixtures/record_conformance/v1.json`, `lib/shared/design_system/bazaar_tokens.g.dart` and `lib/generated/` are never edited by hand.

## 5. Out of scope for v1

- Turkish and Persian content in the app (the bundle already carries it, D89).
- Accounts, sync and any server state.
- A theme or language menu; the app follows the device's light or dark mode.
- Level hues in the catalog and the level meter's segment gauge (PR #1 design choices).

## 6. Acceptance

PR #1 met the 16 acceptance criteria of spec 4.2; its description maps each to its tests.
The items it left to the owner are in [plan.md](plan.md).

# Plan

Where the mobile reader stands and what comes next.
The rules each step is held to are in [requirements.md](requirements.md).
The project is at the demo stage: the reader works end to end, and a store release comes after the steps below.

## Status

| Phase | State |
| --- | --- |
| 0. The reader (PR #1, merged as a03bf37) | Done |
| 1. Small fixes in the reader | Next |
| 2. Parity with the website | Planned |
| 3. Owner follow-ups from PR #1 | Planned |
| 4. Web changes the app needs | Proposed, for the web repo's owner |
| 5. Release | Later |

## Phase 0: the reader (done)

PR #1 turned the template into the reader: offline snapshot and refresh, both tracks, catalog, level page, reader, quiz, progress with backup, restore and reset, settings.
2096 tests, 93 % coverage, CI green at the merge.

## Phase 1: small fixes in the reader

Each fix lands test first, through the gate, in its own commit.

- [ ] **1.1 Table rows.** The parser checks `align` against `head` but not each row's length (`lib/shared/content/domain/content_parser.dart`), and Flutter's `Table` asserts on rows of unequal length. Reject such a table as a format error, or pad the row, as the web does.
- [ ] **1.2 Logo errors.** `LogoView` has no `errorBuilder`, unlike `DiagramView`, so a logo SVG that does not parse is not caught. Show nothing or the unreadable line.

## Phase 2: parity with the website (D111)

The website keeps moving; content reaches the app through the bundle, but a new page or menu needs app code.

- [ ] **2.1 Caravan (web M62).** The web added `/caravan/` as a fourth bar destination after Progress; it says only "Under maintenance." with a link to the catalog. Decide with the owner whether the app shows it now. If yes: a new feature folder `lib/features/caravan/`, a route, a bottom navigation entry, its strings in `intl_en.arb`, tests with the accessibility checks.
- [ ] **2.2 Refresh the bundled snapshot.** The bundled snapshot is contentVersion `c535b551...` (published 2026-11-09 00:15 UTC). Since then the web published WebP images (D112) and new content. Run `tool/refresh_content_snapshot.dart`, then `tool/generate_tokens.dart`, and check that the contract test still passes (WebP decodes).
- [ ] **2.3 Watch the web's decisions.** Read `kia-context/logs/BRAINSTORM.md` and `PROGRESS.md` for new decisions that change behaviour, and add each to this plan.

## Phase 3: owner follow-ups from PR #1

- [ ] **3.1** Decide on the twelve unused template components under `lib/shared/design_system/components/`: delete them, or build on them.
- [ ] **3.2** Dispatch the device tests once: `gh workflow run device_tests.yml --ref main`.
- [ ] **3.3** iOS checks on a Mac: diagrams, logos, the animated WebP and fonts; the file picker; device tests on a simulator.
- [ ] **3.4** Scrub the iOS native Sentry SDK's own events, as `NativeSentry.kt` does on Android, or say so in the privacy text.
- [ ] **3.5** Set `TZ` on the CI test job, so a day printed in the local zone is caught.
- [ ] **3.6** Decide on the Android import picker's MIME filter (`application/json` greys out files a provider labels otherwise).
- [ ] **3.7** Decide whether the licences page also carries the course content's licence.
- [ ] **3.8** Reader performance on a real low-end Android device.

## Phase 4: web changes the app needs

PR #1 lists 13 proposed web changes; none is opened on the web yet (Q2).
The ones that unlock app features:

- [ ] **4.1** A word count per track document, for the catalog's Length and the reader's facts line.
- [ ] **4.2** A checklist index per task item, so the app can show the record's ticks.
- [ ] **4.3** The first parts of a planned module in the index, so a planned card can show its Description.
- [ ] **4.4** Drop the empty Mermaid `<rect>` elements that draw a dot above every node label.
- [ ] **4.5** Rewrite the six logos that a renderer without CSS draws wrong.

The rest (register fixes, contrast fixes, conformance cases) are listed in the PR #1 description.

## Phase 5: release

- [ ] **5.1** Release signing: an upload keystore, `key.properties` kept out of git, and CI secrets. Release builds are signed with the debug key today (`android/app/build.gradle.kts`).
- [ ] **5.2** Store listings, the privacy text and the data safety answers (see 3.4).
- [ ] **5.3** Version and changelog for the first release.

## How each step is done

1. A branch per step, from `main`.
2. New features go in their own folder under `lib/features/`, apart from every other feature (R80).
3. Tests first, mirroring the feature under `test/features/`.
4. The gate through `heavy` before every commit.
5. Small commits, then a pull request with the checks green.

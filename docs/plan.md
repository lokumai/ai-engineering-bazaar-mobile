# Plan

Where the mobile reader stands and what comes next.
The rules each step is held to are in [requirements.md](requirements.md).
The project is at the demo stage: the reader works end to end, and a store release comes after the steps below.

## Status

| Phase | State |
| --- | --- |
| 0. The reader (PR #1, merged as a03bf37) | Done |
| 1. The redesign | In review (one pull request, `feature/redesign`) |
| 2. Small fixes in the reader | Planned |
| 3. Parity with the website | Planned |
| 4. Owner follow-ups from PR #1 | Planned |
| 5. Web changes the app needs | Proposed, for the web repo's owner |
| 6. Release | Later |

## Phase 0: the reader (done)

PR #1 turned the template into the reader: offline snapshot and refresh, both tracks, catalog, level page, reader, quiz, progress with backup, restore and reset, settings.
2096 tests, 93 % coverage, CI green at the merge.

## Phase 1: the redesign

The app takes the look of the team's mobile mockup: [Bazaar Mobil Taslak](https://claude.ai/artifact/4YZcwzuafAdcpsfGwWryp4), six phone screens (Welcome, Home, Catalog, Reader, Quiz, Progress) on the site's tokens.
The mockup decides the look; the requirements decide what the app shows and does (D111).

### Decisions taken

- **English UI.** The mockup's Turkish copy is rewritten in English (D113: only content is multilingual).
- **Foundation first.** The shared design pieces and the shell come first, then one screen at a time.
- **Two new features:** Home (`lib/features/home/`) and Welcome (`lib/features/welcome/`).
- **Mockup parts the requirements do not allow are replaced or dropped:**

| In the mockup | Rule it breaks | In the app |
| --- | --- | --- |
| "Section 3 of 8, 37 %, 15 min left" on Home | R61: the app writes no reading position | The next module not yet completed (`nextUnsigned`) |
| A word count in the reader | R3: the bundle carries no word count | Minutes only, until web change 5.1 |
| Saved quiz scores ("Quiz 4/5", "quizzes taken") | R51: the quiz writes nothing; the record has no quiz field | The score shows on the quiz's results only |
| Theme and text-size buttons in the bar | v1 follows the device's mode and text scale | Dropped |
| Search in the bar | The bundle carries no search data | Dropped; a later web change if wanted |
| "8 modules downloaded" | The whole course ships in the app | A true line: the course is on the device and reads offline |
| A reading progress bar in the reader | None, if it is only the scroll position on screen | Kept, drawn from the scroll position, never saved |

- **The quiz opens over the reader**, full screen, with no route of its own: routes follow the web's (A9). The reader still never imports the quiz feature; the router passes it through the `QuizBuilder` slot (A38).
- **The track switch moves from the bar into the pages** (Home, Catalog, Reader) as one shared segmented control, with the same behaviour: it opens the same page in the other track.
- **Welcome shows on the first launch only.** Whether it was seen is kept in a small app file under Application Support, never in the record (the record stays the web's, R60).

### Steps

The whole phase lands in one pull request on one branch, so that a review sees the redesign as a whole.
Inside it each step is one or more commits, each with its code and its tests together, in the order below.
Every commit passes the gate with the goldens regenerated and the accessibility checks (text scale 2.0, the reader 3.0).

- [x] **1A Design foundation** (`lib/shared/design_system/`): the lattice band under the bar; a level hue per level from the generated category tokens; the completion dial; the level key square; the arch and leaf card shapes; the section rule with the dashed line. Each piece with its own widget test and golden.
- [x] **1B Shell** (`lib/app/shell/`): the bar with the logo and the title, the band under it, a four-item bottom navigation (Home, Catalog, Progress, Settings). The track switch leaves the bar and becomes the shared segmented control (`lib/shared/`).
- [x] **1C Home** (`lib/features/home/`, new): a route at the app's start; the continue card (the next module not completed in the current track, with its level and minutes); the level list with a dial and a count per level; the offline line. Its own bloc or pure mapping, its own tests.
- [x] **1D Catalog** (`lib/features/catalog/`): level chips with their hue; the status chips keep the web's five filters (All, Ready, Planned, Completed, Not completed), not the mockup's three, since the filters are behaviour (R31); module cards with number, title, Description, Length and Requires, and the completion disc; the level header with its segment meter.
- [x] **1E Reader** (`lib/features/reader/`): back in the shell's bar over every pushed page; the level and number over the title; the contents as a bottom sheet instead of the end drawer; the reading progress bar; the track switch, kept on every reader state as the bar kept it; the completion row; the quiz card; the pager stacked with the next module first.
- [x] **1F Quiz** (`lib/features/quiz/`): a card in the reader with the web's title ("Questions on this module") opens the quiz full screen over the reader; every behaviour of the web's quiz is kept (Previous, Next, the verdict, the recap that returns to a question, Back to the questions, Start over); the results add a score dial and Back to the module.
- [x] **1G Progress** (`lib/features/progress/`): track tabs; stats that the record carries (modules completed in the shown track, and the active days: the record's `days`, the days on which anything was written); level cards with hue and dial, their modules listed; the data line kept whole (Back up, Restore, Reset with its undo, the set-aside notice).
- [x] **1H Settings** (`lib/features/settings/`): not in the mockup; restyled in the same language with the same content.
- [x] **1I Welcome** (`lib/features/welcome/`, new): the gate with its lamps and five of the cast, with their motion, stopped under reduced motion; "Enter the bazaar"; shown once, by a file flag under Application Support (`lib/infrastructure/storage/flags/`). The web draws the gate and the cast as inline SVG its renderer cannot draw here, so they are drawn to WebP once (`assets/welcome/SOURCE.md`, MIT).

### Changed along the way

- **Home is `/` and the For Engineers catalog `/sheets`**, the web's own paths. Decision A9 had put the catalog at `/` while the app had no Home; `/courses` now redirects to `/sheets`.
- **The segmented control wraps** its segments onto more lines when the labels do not fit, so a large text scale never hides one.

## Phase 2: small fixes in the reader

The fixes land together in one pull request; each fix is its own commit, test first, through the gate.

- [ ] **2.1 Table rows.** The parser checks `align` against `head` but not each row's length (`lib/shared/content/domain/content_parser.dart`), and Flutter's `Table` asserts on rows of unequal length. Reject such a table as a format error, or pad the row, as the web does.
- [ ] **2.2 Logo errors.** `LogoView` has no `errorBuilder`, unlike `DiagramView`, so a logo SVG that does not parse is not caught. Show nothing or the unreadable line.
- [x] **2.3 A test that fails on a slow runner.** `test/shared/content/application/content_bloc_test.dart` waited 100 ms for a refresh over the real file repository, and on CI the last state came later in three runs of PR #2. Done in PR #2: the test waits for the refresh's last state, with a 30 s timeout.

## Phase 3: parity with the website (D111)

The website keeps moving; content reaches the app through the bundle, but a new page or menu needs app code.

- [ ] **3.1 New pages reach the app on their own (web M62, Caravan).** The web added `/caravan/` to its bar after Progress; the page says only "Under maintenance." with a link to the catalog. Decided: a page the web adds to its bar appears in the app without an app release.
  - Today the web's bar is written in its code (`src/components/shell/MainNav.tsx`) and the bundle does not carry it, so the app cannot see a new page. Web change 5.7 publishes it.
  - The app gets one feature for such pages, `lib/features/pages/`: one route, `/<slug>`, drawn from the bundle's entry (title, path, state). A page under maintenance shows its title, "Under maintenance." and the link to the catalog, as the web does.
  - The bottom navigation shows the bundle's extra pages after Progress, as the web's bar does; Settings stays the last item.
  - Until 5.7 is published, the app ships Caravan as the one known entry, so it matches the web now; the bundle's list replaces it as soon as it is there.
  - A page that later gets real content (the trends timeline) gets its own feature, like every other page.
- [ ] **3.2 Refresh the bundled snapshot.** The bundled snapshot is contentVersion `c535b551...` (published 2026-11-09 00:15 UTC). Since then the web published WebP images (D112) and new content. Run `tool/refresh_content_snapshot.dart`, then `tool/generate_tokens.dart`, and check that the contract test still passes.
- [ ] **3.3 Watch the web's decisions.** Read `kia-context/logs/BRAINSTORM.md` and `PROGRESS.md` for new decisions that change behaviour, and add each to this plan.

## Phase 4: owner follow-ups from PR #1

- [ ] **4.1** Decide on the twelve unused template components under `lib/shared/design_system/components/`: delete them, or build the redesign on them (Phase 1A).
- [ ] **4.2** Dispatch the device tests once: `gh workflow run device_tests.yml --ref main`.
- [ ] **4.3** iOS checks on a Mac: diagrams, logos, the animated WebP and fonts; the file picker; device tests on a simulator.
- [ ] **4.4** Scrub the iOS native Sentry SDK's own events, as `NativeSentry.kt` does on Android, or say so in the privacy text.
- [ ] **4.5** Set `TZ` on the CI test job, so a day printed in the local zone is caught.
- [ ] **4.6** Decide on the Android import picker's MIME filter (`application/json` greys out files a provider labels otherwise).
- [ ] **4.7** Decide whether the licences page also carries the course content's licence.
- [ ] **4.8** Reader performance on a real low-end Android device.

## Phase 5: web changes the app needs

PR #1 lists 13 proposed web changes; none is opened on the web yet (Q2).
The ones that unlock app features:

- [ ] **5.1** A word count per track document, for the catalog's Length and the reader's facts line.
- [ ] **5.2** A checklist index per task item, so the app can show the record's ticks.
- [ ] **5.3** The first parts of a planned module in the index, so a planned card can show its Description.
- [ ] **5.4** Drop the empty Mermaid `<rect>` elements that draw a dot above every node label.
- [ ] **5.5** Rewrite the six logos that a renderer without CSS draws wrong.
- [ ] **5.6** If the redesign's dropped parts are wanted later: saved quiz results in the record, and search data in the bundle. Each is a web decision first.
- [ ] **5.7** The bar's pages in the bundle: path, title and state (`live` or `maintenance`) of each destination, so a new page reaches the app with no app release (3.1).

The rest (register fixes, contrast fixes, conformance cases) are listed in the PR #1 description.

## Phase 6: release

- [ ] **6.1** Release signing: an upload keystore, `key.properties` kept out of git, and CI secrets. Release builds are signed with the debug key today (`android/app/build.gradle.kts`).
- [ ] **6.2** Store listings, the privacy text and the data safety answers (see 4.4).
- [ ] **6.3** Version and changelog for the first release.

## How each step is done

1. One branch and one pull request per phase, from `main`, however many commits it takes.
2. New features go in their own folder under `lib/features/`, apart from every other feature (R80).
3. Tests first, mirroring the feature under `test/features/`.
4. The gate through `heavy` before every commit.
5. Small commits inside the branch, then a pull request with the checks green.

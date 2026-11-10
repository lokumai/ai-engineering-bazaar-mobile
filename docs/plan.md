# Plan

Where the mobile reader stands and what comes next.
The rules each step is held to are in [requirements.md](requirements.md).
The project is at the demo stage: the reader works end to end, and a store release comes after the steps below.

## Status

| Phase | State |
| --- | --- |
| 0. The reader (PR #1, merged as a03bf37) | Done |
| 1. The redesign | Done (PR #3); review round 4 (1AF to 1AM) in review on `feature/review-round-4` |
| 2. Small fixes in the reader | Done: 2.3 in PR #2, 2.1 and 2.2 on `feature/review-round-4` |
| 3. Parity with the website | 3.2, 3.3 and 3.4 done on `feature/phase-3`; 3.1 waits for web change 5.7 |
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

### Review round 1: the first run on the emulator (2026-11-09)

The owner ran 1A to 1I on the Android emulator. These steps land on the same branch and in the same pull request, each as its own commit through the gate.
Three of them change a decision taken above or a requirement; those are marked, and the requirement is updated in the same commit.

- [x] **1J Status bar icons.** The clock and the system icons are drawn dark on the navy bar and can hardly be read. The bar sets light icons (`SystemUiOverlayStyle`) in both themes.
- [x] **1K Welcome, redrawn.** The Welcome screen looked poor on the phone next to the mockup's. It now follows the mockup's layout: the gate cropped to its centre in a 400 high frame with a light in its arch, the two hanging lamps at the corners (drawn to WebP from the mockup, `assets/welcome/SOURCE.md`), the people standing across the gate's foot, and the mockup's headline in English ("AI engineering, written by the people who build it."). The lamps drop and swing to rest once; nothing keeps moving. The mockup's serif display face is not used, since the web downloads no font (`src/app/layout.tsx`, M16).
- [x] **1L The track is asked once.** *Changes the decision "the track switch moves into the pages".* The For Engineers and For Everyone switch took room on Home, the catalog and the reader, though most readers choose once.
  - Welcome asks for the track after Enter the bazaar, with the web's line for each track (`src/app/page.tsx`). The choice is kept as two file flags under Application Support (`track-chosen`, `track-everyone`), never in the record.
  - The switch is gone from Home, the catalog, the level page and the reader; each page names its track in a small label. Settings has a Reading section where the track changes.
  - A link into the other track still opens that track for the run, without changing the choice.
  - Welcome's flag is now `welcome-2-seen`, so a reader who saw the first Welcome sees the new one, and the track question, once.
- [x] **1M Back follows the pages the reader opened.** The back button in the bar went to the previous step of the path, not to the previous page: someone reading a module expects back to return to that module.
  - The places that called `context.go` replaced the history: the level chips, the catalog link in a module's text (`link_actions.dart`), and See what is written For Everyone (`not_written_view.dart`). They now push, so back returns to the page they were on.
  - The level chips are a filter: from the catalog root a level is pushed; on a level page the chosen level takes the page's place, so back skips the levels tried; All returns to the root below when there is one.
  - Only the bottom navigation, and the recovery links of a page that was not found, start the history again.
  - `test/app/router/back_history_test.dart` holds the paths.
- [x] **1N Status filters.** *Changes 1D and R31.* The status chips (All, Ready, Planned, Completed, Not completed) add little, and Planned least of all. Done: the status row and the count are gone. Then, on the owner's second look, the level chips went too: the catalog root shows the levels as buttons, each opening its modules under it, in the redesign's look. A planned module still shows its Planned tag on its card. The web keeps its filters; this is a known difference from the web, recorded in the requirements.
- [x] **1O "Not responding" on the emulator.** Android sometimes showed the "isn't responding" dialog (Wait or Close app).
  - Found: the emulator's records (`adb shell dumpsys dropbox`) hold two ANRs since the morning, both of the emulator's own Phone app (`com.android.phone`), at 17:18, as the emulator booted ("failed to complete startup"). The reader has no ANR and no crash on record.
  - The reader skips about 0.7 s of frames twice at a cold start of a debug build, as a debug build does while it compiles; an ANR needs a 5 s stall.
  - Closed with no code change. If the dialog comes back, note the app name it shows; if it is Bazaar, read `adb shell dumpsys dropbox --print data_app_anr` and reopen this step.
- [x] **1P Home, Catalog and Progress overlap.** Up next on Home works well, but the three tabs showed nearly the same thing: the levels with a count and a dial. Each tab gets one job:
  - [x] **Home:** what to read now. Up next, the two written modules not completed after it, and a link to the catalog; no level list.
  - [x] **Catalog:** everything there is to read. The levels as buttons that open their modules (1N).
  - [x] **Progress:** what has been done. It keeps its stats, its levels with their dials and modules, and the data line; with the dials gone from Home and the catalog, it is the one tab that shows them.
- [x] **1Q Three languages.** *Changes D113 ("only content is multilingual") and R5.* The web publishes every written module in English, Turkish and Persian; the app showed English only, and its interface stayed English whatever the content.
  - Settings' Reading section chooses the language: English, Türkçe or فارسی, each named in its own language. Before a choice the app takes the device's language when it has it, English otherwise. The choice is kept as a file flag under Application Support (`language-<code>`), never in the record.
  - The interface follows the language: every string is in `intl_tr.arb` and `intl_fa.arb`; Persian lays the app out right to left, code blocks stay left to right.
  - The reader opens a module's document in the language; a module with no such document opens in English, and a change of language reopens the module in the new one.
  - The track names come from the app's strings, since the bundle names the tracks in English only.
  - Known gap: the bundle's index gives module and level titles, summaries and blurbs in English only, so the catalog, Home and the Quiz tab list them in English. The web would have to publish them per language (Phase 5).


### Review round 2: the first launch, again (2026-11-09)

The owner ran the app from a clean install. Each step lands on the same branch and pull request, as its own commit through the gate.

- [x] **1R A thinner bar.** The navy bar looked tall and empty. It is thinner (48). A badge naming the track and the language was tried at its end, then taken out on the owner's look; the bar holds the logo and the name only. The track line on Home, the catalog and the level page is gone too.
- [x] **1S Welcome, livelier and whole.** The scene reaches the top of the screen under the status bar, so the white strip and the lattice no longer cut it off. It enters in steps: the light in the gate opens, the people step in one after the other, the lamps drop and swing; under reduced motion it is still. The second step asks for the language as well as the track.
- [x] **1T The first landing is the catalog.** Up next means little to someone who has read nothing. After Welcome the app opens the catalog; every later launch opens Home.
- [x] **1U Progress shows the current track.** The track is chosen once and changed in Settings, so Progress drops its track tabs and shows the current track only.
- [x] **1V A module completed For Engineers counts For Everyone.** *Changes the record's use, not its format.* Completing a module For Engineers also completes its For Everyone version, when that is written; the reverse does not hold, and undoing For Engineers leaves For Everyone as it is.
- [x] **1X A guide on the first launch.** Someone new to the app does not know what it holds. After the language and the track, Welcome shows How the bazaar works once: the levels, the short modules, marking what is finished, and the course kept on the device offline. Open the catalog ends Welcome; only then is it recorded as seen.
- [x] **1Y The gate plays as the app opens.** *Changes 1I and 1S.* Three Welcome screens were too many, and the first was a page with a button only to go on. The gate, the lamps and the people now play on every launch while the content and the record load (1.8 s), then the scene grows and fades into the app; there is no button. A first launch goes from it straight to the language and the track, then the guide (1X). The scene's lingering life of 1S is gone with the page.
- [x] **1Z The gate is an animation only, and the bar is on every screen.** The opening gate still looked like a page. It now has no words, no mark and no button: the gate stands in the middle of the screen with its top and foot melting into the page ground, the lamps drop, the people step in, the light comes up, and then the reader walks in, the gate growing towards the light in its arch as it fades (0.7 s). The steps of the first launch (the language and the track, the guide) wear the cobalt bar like every page after them; the bar moved to `lib/shared/design_system/widgets/bazaar_bar.dart`.
- [x] **1AA A full-screen bazaar opening.** *Changes 1Y and 1Z.* The gate in the middle of the screen was not a full-screen opening. The opening now fills the screen on the bar's navy: a bazaar arch draws itself from the apex down in red and cream voussoirs, the tiled wall comes up around it in a ripple, the lattice band runs out along the threshold, the two lamps drop on their cords and swing, the light comes up inside the arch with the Lokum logo in it, and the people step onto the threshold (2.2 s). Then the reader walks in: the arch grows past the screen's edges and the app is there inside it (0.75 s). It plays on every launch. The Android launch screen (12+ with no icon) and the iOS launch screen are the same navy, so there is no white flash and no Flutter logo before it. The gate picture (`assets/welcome/gate.webp`) is no longer drawn (removed in 1AE).
- [x] **1W Quiz scores.** The owner would like the app to show how each quiz went (on the Quiz tab since 1AC). The web keeps no quiz score and the record has no field for one (R51). amirkia answered on 2026-11-10: the site keeps no user data (zero data retention), so the web will not add scores, and keeping them on the device in the app is fine. Built in review round 4:
  - Each quiz keeps its last score, its best and the one before the last, in `quiz/scores.json` under Application Support (`lib/shared/quiz_scores`, `QuizScoresBloc`). Never in the record (R60) nor the backup file, which are the web's.
  - No words on the Quiz tab and Home: each level has the catalog's dial of how many of its quizzes were taken, and each taken quiz a meter of its last score, one segment per question, the right ones green and the wrong ones red (the meter, not the dial, so the two read apart). The best is on the results and in what a screen reader says. A quiz once answered all right gets the catalog's check in place of the question mark and leaves Home's practice.
  - The results show the attempt before and the best.
  - Home's Practise again puts a quiz never finished first, then the lowest last score, then the most recent.
  - Settings' Reset erases the scores with the record, and its undo brings them back.

### Review round 3: Progress inside the catalog, and quizzes to practise (2026-11-10)

The owner proposed these on 2026-11-10 and settled them the same day: the opening stays (1AA), Progress goes into the catalog, and the fourth tab becomes Quiz. They land on the same branch and pull request.

- [x] **1AB Progress inside the catalog.** The catalog shows each module's completion with the progress page's marks and dials, and the progress page is gone.
  - Each level is an arch card in its hue with its number, title, length and the dial of its completed modules. A tap opens its modules; each written module has the mark that completes it, and a planned one has the dashed Planned mark. The rest of the row opens the reader.
  - The modules completed in the track and the active days stand at the top of the catalog, and the legend of the marks at its foot.
  - Back up, Restore and Reset, the set-aside record notice and the write notice moved to Settings, under Your progress (`lib/features/settings/`). They are R-requirements and stay as they were. The reader's write notice now opens Settings.
  - A For Everyone reader loses nothing: the catalog of the current track carries what Progress showed since 1U.
  - Home's line for a reader who has completed every module now leads to the catalog.
- [x] **1AC A Quiz tab in place of Progress.** The fourth bottom item is Quiz, at `/quiz`. It lists each module's quiz, grouped by level, and opens the full-screen quiz (2F) at `/quiz/<level>/<module>` without going through the reader; Done closes it. Only For Engineers documents carry a quiz, so the tab lists those, and tells a For Everyone reader where the questions come from. The web has no quiz page (A9); these routes are the app's own.
- [x] **1AD Practice on Home.** Under the modules after the next one, Home offers Practise again: the quizzes of the three modules completed last in the current track, the most recent first, each opening the quiz full screen. The record keeps when each module was completed, so the order is the record's own. Since 1W the order favours the quizzes not taken and those that went worst.
- [x] **1AE The unused gate picture is gone.** With the opening settled, `assets/welcome/gate.webp` is removed. The lamps and the people stay: the opening draws them.

### Review round 4: the bar, room to read and the icon (2026-11-10)

The owner looked at the app on the emulator again on 2026-11-10 and asked for these. They land with Phase 2 in one pull request.

- [x] **1AF Settings says less.** The notes under Language and under the track are gone; each heading says enough. The track's heading is Audience (Turkish Anlatım, Persian مخاطب).
- [x] **1AG Diagrams stay light.** In dark mode the diagrams turned dark while the photos did not. Diagrams are now drawn in their light version in both modes, as photos are (R41).
- [x] **1AH A quieter top.** The navy bar, its logo and the app's name are gone.
  - The strip behind the status bar and the bar are on the page's ground, with status icons that read on it, over a thinner lattice band (10; first 8, made 10 on the owner's look).
  - The four tabs, Home, Catalog, Quiz and Settings, show nothing in the bar.
  - A level's page and a module's page show the back button, a rounded square in the level's hue and the page's name at the bar's end.
  - The bar is 40 high with or without the back button. A version with no bar row, only the band and a floating back button, was built for comparison and dropped on the owner's look.
- [x] **1AI Room to read.** On a module page the bar, the band and the bottom navigation slide away while the reader scrolls down and come back on a scroll up, at the top and at the end. They stay while a screen reader runs and move at once under reduced motion. The reading bar now follows every scroll step, not only changes of the page's size, so it moves smoothly.
- [x] **1AJ The app icon.** The striped gate: the bazaar arch with the lattice band's stripes inside, on white like other apps. Android has an adaptive icon with a monochrome layer for themed icons (Android 13+). iOS has light, dark and tinted versions in one 1024 icon (iOS 18); not yet checked on a Mac. The sources are in `assets/brand/app_icon/`.
- [x] **1AK The Quiz tab folds like the catalog.** Each level is an arch card in its hue with its number, title and count of quizzes; a tap opens its quizzes under it and a second tap closes them. The level of the next module to read starts open (1AL).
- [x] **1AL The level of the next module starts open.** On the catalog and the Quiz tab the level of the next module to read starts open, and the others closed. What the reader opens or closes stays while the app runs, through a tab change and back, and a new launch starts again from the next module (`CatalogFoldCubit`, `QuizFoldCubit`, in memory only). A level the reader has not touched follows the next module as modules are completed.
- [x] **1AM Less text on the tabs.** Catalog, Quiz and Settings lose their heading, which repeated the tab's name, and the Quiz tab its description; a For Everyone reader still sees why the quizzes are For Engineers ones. The catalog loses its stats (modules completed, active days): the level dials say it.

## Phase 2: small fixes in the reader

The fixes land together in one pull request; each fix is its own commit, test first, through the gate.

- [x] **2.1 Table rows.** The parser checks `align` against `head` but not each row's length (`lib/shared/content/domain/content_parser.dart`), and Flutter's `Table` asserts on rows of unequal length. Reject such a table as a format error, or pad the row, as the web does. Done: the row is padded with empty cells or cut to the head, as GFM does. The current snapshot has no such table.
- [x] **2.2 Logo errors.** `LogoView` has no `errorBuilder`, unlike `DiagramView`, so a logo SVG that does not parse is not caught. Show nothing or the unreadable line. Done: a logo that does not parse keeps its square of space, as a missing one does.
- [x] **2.3 A test that fails on a slow runner.** `test/shared/content/application/content_bloc_test.dart` waited 100 ms for a refresh over the real file repository, and on CI the last state came later in three runs of PR #2. Done in PR #2: the test waits for the refresh's last state, with a 30 s timeout.

## Phase 3: parity with the website (D111)

The website keeps moving; content reaches the app through the bundle, but a new page or menu needs app code.

- [ ] **3.1 New pages reach the app on their own (web M62, Caravan; D115 to D117, About).** Waiting for web change 5.7 (owner, 2026-11-10): the bar now holds two pages, Caravan (no longer under maintenance: the shadow play on sample data) and About, and neither page's content is in the bundle, so the plan below is revisited when 5.7 lands. The web added `/caravan/` to its bar after Progress; the page says only "Under maintenance." with a link to the catalog. Decided: a page the web adds to its bar appears in the app without an app release.
  - Today the web's bar is written in its code (`src/components/shell/MainNav.tsx`) and the bundle does not carry it, so the app cannot see a new page. Web change 5.7 publishes it.
  - The app gets one feature for such pages, `lib/features/pages/`: one route, `/<slug>`, drawn from the bundle's entry (title, path, state). A page under maintenance shows its title, "Under maintenance." and the link to the catalog, as the web does.
  - The bottom navigation shows the bundle's extra pages after Quiz, as the web's bar does; Settings stays the last item.
  - Until 5.7 is published, the app ships Caravan as the one known entry, so it matches the web now; the bundle's list replaces it as soon as it is there.
  - A page that later gets real content (the trends timeline) gets its own feature, like every other page.
- [x] **3.2 Refresh the bundled snapshot.** The bundled snapshot was contentVersion `c535b551...` (published 2026-11-09 00:15 UTC). Since then the web published WebP images (D112) and new content. Run `tool/refresh_content_snapshot.dart`, then `tool/generate_tokens.dart`, and check that the contract test still passes. Done: contentVersion `cac0bf8e...` (published 2026-11-10 12:43 UTC), with Key Terms (D118), A2A and six new images. The snapshot went from 38 MB to 17 MB and the arm64 release APK from 52 MB to 32 MB; the tokens did not change.
- [x] **3.3 Watch the web's decisions.** Read `kia-context/logs/BRAINSTORM.md` and `PROGRESS.md` for new decisions that change behaviour, and add each to this plan. Read on 2026-11-10, D114 to D122:
  - D112 (WebP images), D118 (Key Terms at the end of every written For Engineers module) and new content reach the app with the snapshot (3.2); Key Terms renders as any other section, in the three languages.
  - D115, D116, D117: the web's bar now holds Caravan, a real page on sample data (the shadow play), and About, the story of the Bazaar; neither is in the bundle. Decided with the owner: wait for 5.7, see 3.1.
  - D122: the owner's identity and a privacy note on the site. The app gets its own, see 3.4.
  - D114 (a block's menu), D119 and D120 (search engines) and D121 (assessment in Microsoft Forms, outside the site) change nothing in the app.
  - Read again before each phase; the next decision after D122 starts the next read.
- [x] **3.4 The owner and a privacy note in Settings (web D122).** Settings, under About, opens Privacy and legal (`/settings/privacy`): the privacy note is the app's own, since the app is not the site (it downloads the course from the site on GitHub Pages, keeps progress, quiz scores and settings on the device, and names crash reports only in a build that sends them); the owner as the web prints it (trade name, MERSİS no., address, email, phone; `lib/features/settings/domain/site_owner.dart`, copied from the web's `SITE_OWNER`, since the bundle does not carry it); and the web's note on third-party marks and images, worded without "we" for the copy register. A change on the web's `SITE_OWNER` is a change in the app.

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
- [ ] **5.8** Module and level titles, summaries and blurbs per language in the index, so the catalog, Home and the Quiz tab list them in the reader's language (1Q).

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

# Changelog

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
The app began as a copy of the flutter_bloc_advance template; the template's history stays in git (`git show 1277105:CHANGELOG.md`).

## [Unreleased]

### Added

- App icon in Settings, under Appearance: six colourings of the striped agent, shown as pictures: Noir (the default), Ink, Night gold, Night sea, Dark and Cream. The chosen one becomes the icon on the home screen (on Android once the app is left; on iOS the phone confirms it) and the opening plays in its colours, on its ground; the launch screen takes its ground too (on Android 13 and later and on iOS, from the launch after the change). Welcome's first step has the App icon row as well.
- Welcome's first step ends in Start learning, which opens the app, with the story button under it; the first launch opens Home, as every launch does.
- Appearance in Settings and on Welcome's first step: Light or Dark. The app opens dark until the reader chooses, whatever the phone's setting, and keeps the choice on the device.
- Module titles in the reader's language, as the web publishes them (web D139): in the catalog, a level page, Home, the Quiz tab, a quiz and the bar over a module. A module with no title in the language keeps the English one; summaries and level names stay English, as on the web.
- A link on Privacy and legal to the site's privacy note, which covers the app too (web D138).
- The iOS privacy manifest: the app tracks nothing, and lists what a release with the Sentry DSN sends, linked to no one.
- Sentry in a release built with the DSN (`sentry_dsn.json`, kept out of git): crash reports, hangs, how long the app took to open, and release-health sessions, scrubbed on the device; Sentry keeps no IP address. Privacy and legal says so.
- Report a problem in Settings, in a release with the Sentry DSN: the reader writes what went wrong and sends it to Sentry, with no name or email asked.
- On iOS a tap on the status bar takes the page in front back to its top, a module included.
- On an iPad or another tablet the pages keep a phone's measure in the middle of the screen, and the app turns to landscape.
- The word count beside the minutes, under a module's title, in a level page card's Length, in the catalog's rows and in Home's modules after the next one, in the reader's language, as the web page prints it (web D128).
- A module's checklist is live: a box ticks and unticks, and the tick is kept in the progress where the web keeps it, so a backup carries it both ways (web D129).
- The story of the Bazaar in Turkish and Persian, as the web publishes it (web D132).
- A replay button over an animated recording in a module, beside the full-screen mark, and full screen in its top corner, which plays it again from its start (web D136).
- The LokumAI mark heads the Modules subsection of a module's References in place of its compass, as on the site (web D135).
- A search field at the head of the catalog: the words typed find module titles, section headings and prose in the reader's language, and levels by their name and blurb, Turkish and Persian written as the web's search finds them, a Persian prefix or suffix typed apart included. The hits are grouped by module, and each opens its module at its section with the words marked, code in a line and the parts of a joined Persian word included, and a bar under the module's bar steps from one mark to the next, scrolling to the mark itself. Closing the bar leaves the page where it is. The search stays while another tab is open.
- A photo or an animated image in the reader opens full screen on a tap, where it zooms, pans and turns with the phone, as a diagram does.
- A module opens where the reader left it, from another tab, from Home and on a new launch; Home's card goes on with the module left last, with how far it was read. The place is kept on the device apart from the progress, and Reset erases it.
- Your path on Home: each level with a bar of its modules completed, in its hue.
- The bottom navigation is a low row of icons, each with its name small under it: the open tab filled, the others outlined. A camel in the middle opens the Caravan, which says it is coming soon until the web's timeline reaches the content bundle.
- The story of the Bazaar, read from the content bundle (web D125), told as a short film over the whole screen on the web's dusk-to-dawn grounds: the gate and the title, each section with the web's scene playing from its start and its words rising in turn, then the motto at dawn. It moves on by itself, a tap goes on or back, and holding pauses it. Told on the first launch from the story button under Start learning, its last button Start learning, and in Settings under About, beside How the bazaar works.
- Privacy and legal in Settings: what the app does with data, the owner as the registry has it, and the note on third-party marks and images (web D122).
- The AI Engineering Bazaar reader for Android and iOS, with the application id `dev.lokumai.bazaar`.
- A bundled snapshot of the site's content bundle under `assets/content/`, so the course opens offline on the first launch. It is the bundle of 2026-11-13 (`22bbb6fa`), with the web's WebP images, Key Terms, the story of the Bazaar, a quiz on both tracks and module titles in every language.
- A refresh that adopts a strictly later content bundle from the site, checked by sha256, and never leaves a mixed set.
- Both tracks, For Engineers and For Everyone, with a track switch on the pages of a track.
- Three languages, English, Turkish and Persian, chosen in Settings: the interface and the module documents follow the choice, Persian right to left, and a module not yet translated opens in English.
- A full-screen bazaar opening on every launch, on the bar's navy: the arch draws itself, the tiled wall, the lamps, the light with the Lokum logo and the people come in, then the reader walks through the arch into the app. The launch screens are the same navy. The first launch then asks for the language and the track, tells the story of the Bazaar, and lands on the catalog.
- Home at `/`: the next module to read, the modules after it, the quizzes of the modules completed last to practise again, and the offline note.
- The catalog root at `/sheets` with the reader's progress in it: a dial per level, and in each level's modules a mark to complete a module or the Planned mark, with a legend. The level page. The web's filters are left out.
- The module reader in the web's order, with diagrams, figures, logos, tables, code, callouts, the contents sheet and a
  reading bar.
- The module quiz, opened full screen from a card in the reader, and the Quiz tab, which lists every module's quiz in a card per level that opens and closes, as the catalog does, and opens a quiz without the reader.
- The data line in Settings: back up to a file, restore from a file, reset with a 10 second undo, and the set-aside record. An undo keeps what was completed, ticked or scored in its 10 seconds, and undoes all of the reset or none of it. A backup larger than the app keeps is refused with a note, rather than restored until the next start. The app has no progress page of its own: the catalog shows the progress.
- Progress kept on the device in the web's record format, held to the web's conformance fixture.
- Quiz scores kept on the device apart from the record: a dial of the quizzes taken per level and a meter of the last score per quiz on the Quiz tab and Home, the one before on the results, practice on Home led by the quizzes not taken or with the lowest score. Reset erases them with the record.
- Settings with the content status, Check for updates, the licences and a debug-only dev console button.
- The redesign after the team's mobile mockup: a bar on the page's ground over a thin lattice band, naming a level's page
  and a module's with the level's hue, level hues, dials and meters, and a four-item bottom navigation.
- On a module page the bar, the band and the bottom navigation slide away while reading down and come back on a scroll up.
- The app icon, the striped gate, with an Android themed icon and iOS dark and tinted versions.
- Device tests under `integration_test/` and a workflow that runs them on demand.

### Changed

- The opening is the striped secret agent: it stands still in the middle of the screen, then the camera flies into it and its stripes rush past as ribbons onto the app, 1.45 s, on the page colour of the theme.
- The app icon is the striped secret agent on the dark page colour, one icon for every phone theme.
- The launch screens are the dark page colour whatever the phone's theme.
- Welcome's first step fits a phone with no scrolling; the line under its title is gone.
- The Caravan tab says the Caravan is coming soon, over a scene of a caravan walking in at dusk, instead of under maintenance.
- A picture in a module is decoded at the size it is drawn, which takes less memory and opens a module faster; it looks the same, and full screen still shows it whole.
- The back arrow in the bar goes to the page the page was opened from, Home, Quiz, a level or another module, as Android's back and the iOS edge swipe do; it no longer goes to the catalog.
- Another tab opens at once, with no transition, as tabs change on iOS and Android; the page left no longer shows through for a moment. A page opened inside a tab, a module or a level, comes in with the platform's own transition, sliding in from the side on iOS, where the edge swipe goes back, and zooming in on Android.
- A completed module opens at its top: completing it drops the place it was left at, and none is kept while it stays completed.
- The catalog search's keyboard goes away on a tap elsewhere and on a drag through the hits, as iOS has no back key; iOS's own sheets follow the app's languages.
- Android's back on the first page of Catalog, the Caravan, Quiz or Settings goes Home; it leaves the app from Home.
- Persian pages put a table's cells, the edge of a notice and the Planned band on their right, as the site does.
- A cache that cannot be cleaned up, or an object in it that cannot be read, no longer stops the course from opening: the bundled snapshot opens, and the object reads as missing.
- A quiz score from before a content update changed the quiz's length is dropped when the quiz is opened.
- Choices of language and track made in quick succession are kept in the order made.

- A For Everyone reader takes the quiz of each module written For Everyone, under its title there, on the Quiz tab, in Home's practice and at the module's end: a module has one quiz on both tracks (web D137). The note that the questions come with the For Engineers modules is gone.
- The back arrow on a module goes to the catalog of its track, found as it was left with its search, and no longer to the page before: a module opened from Home and found again from the Catalog tab went back to Home. A link to a section, or a search hit, keeps its heading at the top while pictures above it load.
- A Turkish or Persian module shows what it teaches in its own language, where the site has translated it (web D124).
- A diagram opens full screen at a tap, to zoom and turn it; a mark in its corner says so.
- The mark after an external link is a small arrow in the text's colour, no longer a colour emoji.
- Catalog and Quiz open on their names; Home's quiz list is "Quizzes to practise"; the data actions in Settings are buttons, Back up, Restore and Reset on one line, their names shortened to fit in every language; the level's title follows the back arrow in the bar.
- Headings are set in Fraunces, the web's display face; the text stays in the sans.
- Lists stand on the page with a hairline between rows instead of a card each; the levels are washed in their hues, and the chosen track and language are a light wash instead of a solid block.
- The app identity: `dev.lokumai.bazaar`, "Bazaar" under the icon and "AI Engineering Bazaar" as the title.
- The Dart package name is `ai_engineering_bazaar`.
- The template palettes are replaced by the Bazaar theme, built from design tokens generated from the snapshot.
- Diagrams are drawn in their light version in both themes, as photos are.
- A table row longer or shorter than its head is cut or padded to the head, as GFM does.
- A logo that does not parse keeps its square of space, as a missing one does.

### Removed

- The bazaar gate opening, with its lamps, its people on the threshold and its walk through the arch.
- The web, macOS, Linux and Windows platforms.
- Sonar.
- Login, users, accounts, OIDC and the mock API.
- Local storage, the lifecycle check and theme switching.
- The analytics route observer.

### Fixed

- Persian headings are set in Vazirmatn's own bold face rather than a thickened regular one.
- A broken link in a module says it could not be opened instead of failing, links open only on the web, mail and the phone, and a download from the site is capped at 32 MB.
- The reset asks for the word in the interface's language: SİL in Turkish, حذف in Persian. ERASE still works in every language.
- The catalog's search no longer stays on reading after a module could not be read, and Check for updates no longer stays disabled after an unexpected error.
- Settings no longer stays busy after an error during a backup, a reset or an undo, and a restore is called done only once the progress took the file.
- A content update cut off by closing the app goes on where it stopped at the next launch, rather than downloading everything again.
- A module that cannot be read offers Try again instead of only asking for a restart, and the reader's loading spinner is named for a screen reader.
- A second reset while Undo is still offered no longer empties the undo: Undo brings back the progress from before the first.
- A reset that fails part way leaves the progress on the device, not only on the screen.
- An unexpected error at launch no longer leaves the app on its loading page: the course says it cannot be opened, or the progress opens read-only and is never written over.
- Capitals follow the language: Turkish "Sıradaki" is "SIRADAKİ", not "SIRADAKI".
- The two GitHub links on Privacy and legal are in Turkish and Persian; Turkish reads "%40 okundu" and "Güncellemeleri kontrol et" everywhere.
- In Persian a quiz verdict's coloured edge is on the right, where its line starts.

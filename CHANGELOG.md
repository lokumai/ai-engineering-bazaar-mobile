# Changelog

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
The app began as a copy of the flutter_bloc_advance template; the template's history stays in git (`git show 1277105:CHANGELOG.md`).

## [Unreleased]

### Added

- The AI Engineering Bazaar reader for Android and iOS, with the application id `dev.lokumai.bazaar`.
- A bundled snapshot of the site's content bundle under `assets/content/`, so the course opens offline on the first launch.
- A refresh that adopts a strictly later content bundle from the site, checked by sha256, and never leaves a mixed set.
- Both tracks, For Engineers and For Everyone, with a track switch on the pages of a track.
- Three languages, English, Turkish and Persian, chosen in Settings: the interface and the module documents follow the choice, Persian right to left, and a module not yet translated opens in English.
- A full-screen bazaar opening on every launch, on the bar's navy: the arch draws itself, the tiled wall, the lamps, the light with the Lokum logo and the people come in, then the reader walks through the arch into the app. The launch screens are the same navy. The first launch then asks for the language and the track, shows How the bazaar works once, and lands on the catalog.
- Home at `/`: the next module to read, the modules after it, the quizzes of the modules completed last to practise again, and the offline note.
- The catalog root at `/sheets` with the reader's progress in it: the modules completed and the active days, a dial per level, and in each level's modules a mark to complete a module or the Planned mark, with a legend. The level page. The web's filters are left out.
- The module reader in the web's order, with diagrams, figures, logos, tables, code, callouts, the contents sheet and a
  reading bar.
- The module quiz, opened full screen from a card in the reader, and the Quiz tab, which lists every module's quiz in a card per level that opens and closes, as the catalog does, and opens a quiz without the reader.
- The data line in Settings: back up to a file, restore from a file, reset with a 10 second undo, and the set-aside record. The app has no progress page of its own: the catalog shows the progress.
- Progress kept on the device in the web's record format, held to the web's conformance fixture.
- Quiz scores kept on the device apart from the record: dials of the last score and of the quizzes taken on the Quiz tab, the one before on the results, practice on Home led by the quizzes not taken or with the lowest score. Reset erases them with the record.
- Settings with the content status, Check for updates, the licences and a debug-only dev console button.
- The redesign after the team's mobile mockup: a bar on the page's ground over a thin lattice band, naming a level's page
  and a module's with the level's hue, level hues, dials and meters, and a four-item bottom navigation.
- On a module page the bar, the band and the bottom navigation slide away while reading down and come back on a scroll up.
- The app icon, the striped gate, with an Android themed icon and iOS dark and tinted versions.
- Device tests under `integration_test/` and a workflow that runs them on demand.

### Changed

- The app identity: `dev.lokumai.bazaar`, "Bazaar" under the icon and "AI Engineering Bazaar" as the title.
- The Dart package name is `ai_engineering_bazaar`.
- The template palettes are replaced by the Bazaar theme, built from design tokens generated from the snapshot.
- Diagrams are drawn in their light version in both themes, as photos are.
- A table row longer or shorter than its head is cut or padded to the head, as GFM does.
- A logo that does not parse keeps its square of space, as a missing one does.

### Removed

- The web, macOS, Linux and Windows platforms.
- Sonar.
- Login, users, accounts, OIDC and the mock API.
- Local storage, the lifecycle check and theme switching.
- The analytics route observer.

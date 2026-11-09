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
- Home at `/`: the next module to read, the levels with their completion, and the offline note.
- The catalog root at `/sheets`, with the levels as buttons that open their modules, and the level page. The web's filters are left out: each card says whether it is planned or completed.
- The module reader in the web's order, with diagrams, figures, logos, tables, code, callouts, the contents sheet and a
  reading bar.
- The module quiz, opened full screen from a card in the reader.
- The progress page for the chosen track, and the data line: back up to a file, restore from a file, reset with a 10 second undo, and the set-aside record.
- Progress kept on the device in the web's record format, held to the web's conformance fixture.
- Settings with the content status, Check for updates, the licences and a debug-only dev console button.
- The redesign after the team's mobile mockup: the logo bar, the lattice band, level hues, dials and meters, and a
  four-item bottom navigation.
- Device tests under `integration_test/` and a workflow that runs them on demand.

### Changed

- The app identity: `dev.lokumai.bazaar`, "Bazaar" under the icon and "AI Engineering Bazaar" as the title.
- The Dart package name is `ai_engineering_bazaar`.
- The template palettes are replaced by the Bazaar theme, built from design tokens generated from the snapshot.

### Removed

- The web, macOS, Linux and Windows platforms.
- Sonar.
- Login, users, accounts, OIDC and the mock API.
- Local storage, the lifecycle check and theme switching.
- The analytics route observer.

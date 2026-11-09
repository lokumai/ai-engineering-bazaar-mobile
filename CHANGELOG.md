# Changelog

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
The app began as a copy of the flutter_bloc_advance template; the template's history stays in git (`git show 1277105:CHANGELOG.md`).

## [Unreleased]

### Added

- The AI Engineering Bazaar reader for Android and iOS, with the application id `dev.lokumai.bazaar`.
- A bundled snapshot of the site's content bundle under `assets/content/`, so the course opens offline on the first launch.
- A refresh that adopts a strictly later content bundle from the site, checked by sha256, and never leaves a mixed set.
- Both tracks, For Engineers and For Everyone, with a track switch in the bar.
- The catalog root and the level page, with the Level and Status filters.
- The module reader in the web's order, with diagrams, figures, logos, tables, code, callouts and the contents drawer.
- The module quiz.
- The progress page with one tab per track, and the data line: back up to a file, restore from a file, reset with a 10 second undo, and the set-aside record.
- Progress kept on the device in the web's record format, held to the web's conformance fixture.
- Settings with the content status, Check for updates, the licences and a debug-only dev console button.
- Device tests under `integration_test/` and a workflow that runs them on demand.

### Changed

- The app identity: `dev.lokumai.bazaar`, "Bazaar" under the icon and "AI Engineering Bazaar" as the title.
- The Dart package name is `ai_engineering_bazaar`.
- The template palettes are replaced by the Bazaar theme, built from design tokens generated from the snapshot.

### Removed

- The web, macOS, Linux and Windows platforms.
- Sonar.
- Login, users, accounts, OIDC and the mock API.
- Local storage, the lifecycle check, locale switching and theme switching.
- The analytics route observer.
- The Turkish strings.

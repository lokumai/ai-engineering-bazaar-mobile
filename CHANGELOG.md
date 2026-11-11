# Changelog

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
The app began as a copy of the flutter_bloc_advance template; the template's history stays in git (`git show 1277105:CHANGELOG.md`).

## [Unreleased]

### Added

- A search field at the head of the catalog: the words typed find module titles, section headings and prose in the reader's language, Turkish and Persian written as the web's search finds them. The hits are grouped by module, and each opens its module at its section with the words marked, and a bar under the module's bar steps from one mark to the next.
- A photo or an animated image in the reader opens full screen on a tap, where it zooms, pans and turns with the phone, as a diagram does.
- A module opens where the reader left it, from another tab, from Home and on a new launch; Home's card goes on with the module left last, with how far it was read. The place is kept on the device apart from the progress, and Reset erases it.
- Your path on Home: each level with a bar of its modules completed, in its hue.
- The bottom navigation is a low row of icons, each with its name small under it: the open tab filled, the others outlined. A camel in the middle opens the Caravan, which says it is under maintenance until the web's timeline reaches the content bundle.
- The story of the Bazaar, read from the content bundle (web D125), told as a short film over the whole screen on the web's dusk-to-dawn grounds: the gate and the title, each section with the web's scene playing from its start and its words rising in turn, then the motto at dawn. It moves on by itself, a tap goes on or back, and holding pauses it. Told first on the first launch, before the language and the track, and in Settings under About, beside How the bazaar works.
- Privacy and legal in Settings: what the app does with data, the owner as the registry has it, and the note on third-party marks and images (web D122).
- The AI Engineering Bazaar reader for Android and iOS, with the application id `dev.lokumai.bazaar`.
- A bundled snapshot of the site's content bundle under `assets/content/`, so the course opens offline on the first launch. It is the bundle of 2026-11-10 (`c03b9e70`), with the web's WebP images, Key Terms and the story of the Bazaar.
- A refresh that adopts a strictly later content bundle from the site, checked by sha256, and never leaves a mixed set.
- Both tracks, For Engineers and For Everyone, with a track switch on the pages of a track.
- Three languages, English, Turkish and Persian, chosen in Settings: the interface and the module documents follow the choice, Persian right to left, and a module not yet translated opens in English.
- A full-screen bazaar opening on every launch, on the bar's navy: the arch draws itself, the tiled wall, the lamps, the light with the Lokum logo and the people come in, then the reader walks through the arch into the app. The launch screens are the same navy. The first launch then tells the story of the Bazaar, asks for the language and the track, and lands on the catalog.
- Home at `/`: the next module to read, the modules after it, the quizzes of the modules completed last to practise again, and the offline note.
- The catalog root at `/sheets` with the reader's progress in it: a dial per level, and in each level's modules a mark to complete a module or the Planned mark, with a legend. The level page. The web's filters are left out.
- The module reader in the web's order, with diagrams, figures, logos, tables, code, callouts, the contents sheet and a
  reading bar.
- The module quiz, opened full screen from a card in the reader, and the Quiz tab, which lists every module's quiz in a card per level that opens and closes, as the catalog does, and opens a quiz without the reader.
- The data line in Settings: back up to a file, restore from a file, reset with a 10 second undo, and the set-aside record. The app has no progress page of its own: the catalog shows the progress.
- Progress kept on the device in the web's record format, held to the web's conformance fixture.
- Quiz scores kept on the device apart from the record: a dial of the quizzes taken per level and a meter of the last score per quiz on the Quiz tab and Home, the one before on the results, practice on Home led by the quizzes not taken or with the lowest score. Reset erases them with the record.
- Settings with the content status, Check for updates, the licences and a debug-only dev console button.
- The redesign after the team's mobile mockup: a bar on the page's ground over a thin lattice band, naming a level's page
  and a module's with the level's hue, level hues, dials and meters, and a four-item bottom navigation.
- On a module page the bar, the band and the bottom navigation slide away while reading down and come back on a scroll up.
- The app icon, the striped gate, with an Android themed icon and iOS dark and tinted versions.
- Device tests under `integration_test/` and a workflow that runs them on demand.

### Changed

- The back arrow on a module goes to the catalog of its track, found as it was left with its search, and no longer to the page before: a module opened from Home and found again from the Catalog tab went back to Home. A link to a section, or a search hit, keeps its heading at the top while pictures above it load.
- A Turkish or Persian module shows what it teaches in its own language, where the site has translated it (web D124).
- A diagram opens full screen at a tap, to zoom and turn it; a mark in its corner says so.
- The mark after an external link is a small arrow in the text's colour, no longer a colour emoji.
- Catalog and Quiz open on their names; Home's quiz list is "Quizzes to practise"; the data actions in Settings are buttons, Reset on its own line; the level's title follows the back arrow in the bar.
- Headings are set in Fraunces, the web's display face; the text stays in the sans.
- Lists stand on the page with a hairline between rows instead of a card each; the levels are washed in their hues, and the chosen track and language are a light wash instead of a solid block.
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

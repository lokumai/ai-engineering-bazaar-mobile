# AI Engineering Bazaar mobile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The AI Engineering Bazaar course as an app for Android and iOS.
It reads the course offline from a bundled snapshot of the site's content bundle, `https://ai-bazaar.lokum.dev/api/v1/`, and refreshes it when the site publishes a newer one.
Both tracks are in it: For Engineers and For Everyone.
The interface and the modules are in English, Turkish and Persian (right to left); a module not yet translated opens in English.
Progress stays on the device, in the web's record format, and the app imports and exports the web's file.
There is no account, no analytics and no advertising.

The web repo, [lokumai/ai-engineering-bazaar](https://github.com/lokumai/ai-engineering-bazaar), is the only producer of content.
The app maps what the bundle publishes to widgets and derives no fact the bundle does not carry (D111); a missing fact is a change proposed to the web.

## Status

Version `1.0.0+1`, before the first store release.
What is done and what is left: [docs/plan.md](docs/plan.md).
What the app must do: [docs/requirements.md](docs/requirements.md).
What changed: [CHANGELOG.md](CHANGELOG.md).

## Requirements

- [fvm](https://fvm.app/) with Flutter 3.47.7 (Dart ^3.13.5); every command below runs through `fvm`.
- JDK 17 for Android.
- Xcode on macOS for iOS.

## Run

```shell
fvm flutter pub get
fvm flutter run --target lib/main/main_local.dart --dart-define=CONTENT_BASE_URL=https://ai-bazaar.lokum.dev/
```

Any https preview of the site works as `CONTENT_BASE_URL`.
`main_local` refuses to start without it, or with a base that is not https or lacks the trailing slash.
The app allows no cleartext traffic, so use the live site or an https preview rather than a local http server.

```shell
fvm flutter run --target lib/main/main_prod.dart
```

`main_prod` uses `https://ai-bazaar.lokum.dev/`.

### On your own iPhone

Connect the phone to the Mac, trust the Mac on the phone and turn on Developer Mode (Settings, Privacy and Security, after Xcode has paired with the phone once).
In Xcode, give the Runner target your own team and a bundle identifier of your own under Signing and Capabilities; keep that change local.
Then run from the Mac's own Terminal, since signing reads the login keychain, which a remote shell cannot open:

```shell
fvm flutter run --release -d <device id> --target lib/main/main_prod.dart
```

`xcrun devicectl list devices` names the device id.
An app signed with a free Apple ID runs for seven days.

## Content

The app opens the bundled snapshot, then checks the site at every launch and from Check for updates in Settings.
A newer bundle is downloaded in the background, each file checked by its sha256, and is used only once every file is on the device, so a lost connection never leaves a mixed set and reading never waits on the network.
A download cut off by closing the app goes on where it stopped at the next launch.

### Refresh the snapshot

```shell
fvm dart run tool/refresh_content_snapshot.dart --base-url https://ai-bazaar.lokum.dev/ --content-version <hex>
```

The tool writes `assets/content/` (the snapshot) and `test/fixtures/record_conformance/v1.json` (the record conformance fixture).
Both are its output and are committed; never edit them by hand.

### Regenerate the tokens

```shell
fvm dart run tool/generate_tokens.dart
```

Run it after every snapshot refresh.
It writes `lib/shared/design_system/bazaar_tokens.g.dart` from the snapshot's `tokens.json`, and `tokens_generated_test` fails when the two differ.

## Strings

Every string of the interface is in `lib/l10n/intl_en.arb`, `intl_tr.arb` and `intl_fa.arb`.
After editing them:

```shell
fvm dart run intl_utils:generate
fvm dart format lib/generated --line-length=120
```

## Tests

```shell
fvm flutter test                                         # the whole suite
fvm flutter test test/path/to/specific_test.dart         # one file
fvm flutter test --tags golden --update-goldens          # regenerate the goldens
fvm flutter test integration_test -d <device>            # device tests on an emulator, simulator or phone
```

The `Device tests` workflow runs the device tests on an Android emulator and an iOS simulator when it is dispatched.
How the suite is built and how to add to it: [docs/testing-architecture.md](docs/testing-architecture.md).

The gate every commit passes:

```shell
fvm dart format . --line-length=120 --set-exit-if-changed && fvm flutter analyze && fvm flutter test --coverage && scripts/check_coverage.sh coverage/lcov.info 90
```

CI runs the same steps, then builds the release APK and app bundle, runs the Android JVM tests and builds iOS without signing.
The coverage check fails below 90% of the hand-written lines, and when there is no coverage file to read.

### Heavy commands

On the maintainers' machine every build, full test suite, gate chain, and anything that starts an emulator, simulator or browser runs through `heavy`, a local wrapper that puts the command in a shared memory and CPU cap, one full gate at a time: for example `heavy fvm flutter test`.
Exit 137 is that cap, so run less at once and never raise it.
Elsewhere, run the commands as they are.

## Privacy

The app collects no personal data.
The site's privacy note covers the app too: <https://ai-bazaar.lokum.dev/legend/#privacy>.
Sentry starts only in a prod build with a `SENTRY_DSN` define, and no build sets one yet.
With one, it sends crash reports and nothing else: no release-health sessions, no performance traces, no route names.
The app scrubs every crash report on Android and every Dart crash report on iOS; on iOS the native SDK's own crash events and breadcrumbs leave the device as that SDK records them.

## Licences

The app is under the MIT License, see [LICENSE](LICENSE).
Vazirmatn (regular and bold), the diagram font and the Persian headings' face, is under the SIL Open Font License, see [assets/fonts/OFL.txt](assets/fonts/OFL.txt).
Fraunces, the face of the app's headings, is under the same licence, see [assets/fonts/OFL-Fraunces.txt](assets/fonts/OFL-Fraunces.txt).
The course content is under the web repo's licence.

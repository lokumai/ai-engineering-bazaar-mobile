# AI Engineering Bazaar mobile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The AI Engineering Bazaar course as an app for Android and iOS.
It reads the course offline from a bundled snapshot of the site's content bundle, `https://ai-bazaar.lokum.dev/api/v1/`, and refreshes it when the site publishes a newer one.
Both tracks are in it: For Engineers and For Everyone.
Progress stays on the device, in the web's record format, and the app imports and exports the web's file.
There is no account.

The web repo, [lokumai/ai-engineering-bazaar](https://github.com/lokumai/ai-engineering-bazaar), is the only producer of content.
The app maps what the bundle publishes to widgets and derives no fact the bundle does not carry (D111); a missing fact is a change proposed to the web.

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
Sentry starts only in prod and only with a `SENTRY_DSN` define; it sends crash reports and nothing else: no release-health sessions, no performance traces, no route names.
The app scrubs every crash report on Android and every Dart crash report on iOS.
On iOS the native SDK's own crash events and breadcrumbs leave the device as that SDK records them, unscrubbed.

## Refresh the snapshot

```shell
fvm dart run tool/refresh_content_snapshot.dart --base-url https://ai-bazaar.lokum.dev/ --content-version <hex>
```

The tool writes `assets/content/` (the snapshot) and `test/fixtures/record_conformance/v1.json` (the record conformance fixture).
Both are its output and are committed; never edit them by hand.

## Regenerate the tokens

```shell
fvm dart run tool/generate_tokens.dart
```

Run it after every snapshot refresh.
It writes `lib/shared/design_system/bazaar_tokens.g.dart` from the snapshot's `tokens.json`, and `tokens_generated_test` fails when the two differ.

## Tests

```shell
fvm flutter test                                         # the whole suite
fvm flutter test test/path/to/specific_test.dart         # one file
fvm flutter test --tags golden --update-goldens          # regenerate the goldens
fvm flutter test integration_test -d <device>            # device tests on an emulator, simulator or phone
```

The `Device tests` workflow runs the device tests on an Android emulator and an iOS simulator when it is dispatched.
How the suite is built and how to add to it: [docs/testing-architecture.md](docs/testing-architecture.md).

## Heavy commands

Every build, full test suite, gate chain, and anything that starts an emulator, simulator or browser runs through `heavy`, one full gate at a time.
`heavy` puts the command in a shared memory and CPU cap; exit 137 is that cap, so run less at once and never raise it.
A single test file or a quick probe does not need it.

The gate every commit passes:

```shell
heavy bash -c 'fvm dart format . --line-length=120 --set-exit-if-changed && fvm flutter analyze && fvm flutter test --coverage && scripts/check_coverage.sh coverage/lcov.info 65'
```

CI runs the same steps, then builds the release APK and app bundle, runs the Android JVM tests and builds iOS without signing.

## Licences

The app is under the MIT License, see [LICENSE](LICENSE).
Vazirmatn, the diagram font, is under the SIL Open Font License, see [assets/fonts/OFL.txt](assets/fonts/OFL.txt).
Fraunces, the face of the story's headings, is under the same licence, see [assets/fonts/OFL-Fraunces.txt](assets/fonts/OFL-Fraunces.txt).
The course content is under the web repo's licence.

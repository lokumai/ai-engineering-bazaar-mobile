# Development

How to run, test and maintain the app, moved here from the README (2026-11-19). The rules the code is held to are in [CLAUDE.md](../CLAUDE.md); how the suite is built is in [testing-architecture.md](testing-architecture.md).

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
How the suite is built and how to add to it: [testing-architecture.md](testing-architecture.md).

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


## Release

The version is in `pubspec.yaml`: the name before the `+` is what the stores show, and the number after it goes up by one at every upload to either store.

### Android

The upload key lives outside the repo, with a copy kept where the maintainers keep their secrets; Google Play holds the app's signing key itself (Play App Signing).
`android/key.properties` points at it and is kept out of git:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=<the keystore's password>
keyAlias=upload
keyPassword=<the key's password>
```

Without the file a bundle build stops with a message, since a bundle signed with the debug key is refused by Google Play; a release APK, which `flutter run --release` installs, is signed with the debug key. CI, which sets `CI=true`, still builds a bundle with the debug key to check that it builds.

`scripts/run_build.sh` and `scripts/run_fvm_build.sh` stop when `sentry_dsn.json` is missing, so no release goes out that reports no crashes, and when the working tree has uncommitted changes, so a store build is a commit CI saw; they run the gate, then build the APK and the bundle, and change no source.

```shell
fvm flutter build appbundle --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json
```

The bundle is `build/app/outputs/bundle/release/app-release.aab`.

### iOS

Archive in Xcode on the Mac, with the team's account signed in: `fvm flutter build ipa --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json`, then upload `build/ios/ipa/*.ipa` with Transporter or from Xcode's Organizer.

Then give Sentry the build's symbols, so an app hang reported by iOS shows the app's own frames by name rather than as addresses (Dart crash reports do not need them):

```shell
SENTRY_AUTH_TOKEN=<token> sentry-cli debug-files upload --org <org> --project <project> \
  build/ios/archive/Runner.xcarchive/dSYMs
```

The token stays out of the repo, as `sentry_dsn.json` does; `.sentryclirc` and `sentry.properties` are ignored.
Build a store binary only with these commands, never from Xcode's menu after a `flutter run`: Xcode reuses the last run's target and defines.

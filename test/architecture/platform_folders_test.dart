import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards owner decision 4 of the mobile reader: the app ships on Android and iOS only.
///
/// `flutter create` writes one folder per platform at the package root, and `flutter pub get` keeps generating plugin
/// files into each one that exists. A `web/`, `macos/`, `linux/` or `windows/` folder brings back a platform the app
/// neither builds, tests nor supports. `.metadata` is not read: it only feeds `flutter migrate`.
void main() {
  test('only the android and ios platform folders exist at the package root', () {
    final missing = ['android', 'ios'].where((name) => !Directory(name).existsSync()).toList();
    final extra = ['web', 'macos', 'linux', 'windows'].where((name) => Directory(name).existsSync()).toList();

    expect(missing, isEmpty, reason: 'platform folders missing at the package root: ${missing.join(', ')}');
    expect(extra, isEmpty, reason: 'platform folders of unsupported platforms: ${extra.join(', ')}');
  });
}

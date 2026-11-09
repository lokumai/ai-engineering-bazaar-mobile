import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards owner decision 4 of the mobile reader: the app ships on Android and iOS only.
///
/// `flutter create` writes one folder per platform at the package root, and `flutter pub get` keeps generating plugin
/// files into each one that exists. A `web/`, `macos/`, `linux/` or `windows/` folder brings back a platform the app
/// neither builds, tests nor supports. `.metadata` is not read: it only feeds `flutter migrate`.
///
/// Every iOS plugin is a Swift package, so the iOS build does not use CocoaPods (plan decision A7): a `Podfile`, a
/// `Podfile.lock` or a `Pods/` include in the Flutter xcconfig files brings it back.
void main() {
  test('only the android and ios platform folders exist at the package root', () {
    final missing = ['android', 'ios'].where((name) => !Directory(name).existsSync()).toList();
    final extra = ['web', 'macos', 'linux', 'windows'].where((name) => Directory(name).existsSync()).toList();

    expect(missing, isEmpty, reason: 'platform folders missing at the package root: ${missing.join(', ')}');
    expect(extra, isEmpty, reason: 'platform folders of unsupported platforms: ${extra.join(', ')}');
  });

  test('ios has no CocoaPods integration', () {
    expect(File('ios/Podfile').existsSync(), isFalse, reason: 'ios/Podfile brings CocoaPods back');
    expect(File('ios/Podfile.lock').existsSync(), isFalse, reason: 'ios/Podfile.lock brings CocoaPods back');
    for (final config in ['ios/Flutter/Debug.xcconfig', 'ios/Flutter/Release.xcconfig']) {
      expect(File(config).readAsStringSync(), isNot(contains('Pods/')), reason: '$config includes a Pods file');
    }
  });
}

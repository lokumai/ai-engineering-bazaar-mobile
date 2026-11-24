import 'package:flutter/foundation.dart';

/// Adds the licences of the native SDKs built into the app, which the Dart packages' licences do not cover, to the
/// [LicenseRegistry] (review 11, native 10): Sentry's Android and NDK SDKs on Android, its Cocoa SDK on iOS. Each
/// platform lists only its own, as the App Store takes no other platform's name (2.3.10).
void registerNativeLicences(TargetPlatform platform) {
  final packages = switch (platform) {
    TargetPlatform.android => const [('sentry-java', '2019'), ('sentry-native', '2019')],
    TargetPlatform.iOS => const [('sentry-cocoa', '2015')],
    _ => const <(String, String)>[],
  };
  if (packages.isEmpty) return;
  LicenseRegistry.addLicense(() async* {
    for (final (package, year) in packages) {
      yield LicenseEntryWithLineBreaks([package], 'MIT License\n\nCopyright (c) $year Sentry\n\n$_mit');
    }
  });
}

const _mit = '''
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

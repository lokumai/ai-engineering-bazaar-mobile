import 'dart:io';

import 'package:flutter_bloc_advance/infrastructure/analytics/native_sentry_start.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the identity of owner decision 4 and spec 3.13: application id `dev.lokumai.bazaar`, launcher label
/// "Bazaar", the Kotlin sources in the `dev.lokumai.bazaar` package, and the native Sentry channel named after the
/// application id on both sides. Nothing in a build fails when one of these drifts.
void main() {
  const kotlinMain = 'android/app/src/main/kotlin/dev/lokumai/bazaar';
  const kotlinTest = 'android/app/src/test/kotlin/dev/lokumai/bazaar';

  group('Android identity', () {
    test('namespace and applicationId are dev.lokumai.bazaar', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('namespace = "dev.lokumai.bazaar"'));
      expect(gradle, contains('applicationId = "dev.lokumai.bazaar"'));
    });

    test('the launcher label is Bazaar', () {
      expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(), contains('android:label="Bazaar"'));
    });

    test('every Kotlin source sits in dev/lokumai/bazaar and declares that package', () {
      final sources = Directory('android/app/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.kt'));

      expect(sources.map((file) => file.path).toSet(), {
        for (final name in [
          'MainActivity',
          'MainApplication',
          'NativeScrubPatterns',
          'NativeSentry',
          'NativeSentryScrubber',
        ])
          '$kotlinMain/$name.kt',
        for (final name in ['NativeSentryScrubberTest', 'NativeSentryTest']) '$kotlinTest/$name.kt',
      });
      for (final source in sources) {
        expect(source.readAsLinesSync().first, 'package dev.lokumai.bazaar', reason: source.path);
      }
    });

    test('Dart and MainActivity name the native Sentry channel dev.lokumai.bazaar/native_sentry', () {
      expect(nativeSentryChannelName, 'dev.lokumai.bazaar/native_sentry');
      expect(File('$kotlinMain/MainActivity.kt').readAsStringSync(), contains('"dev.lokumai.bazaar/native_sentry"'));
    });
  });
}

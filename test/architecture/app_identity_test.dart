import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/analytics/native_sentry_start.dart';
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
          'AppIconSwitch',
          'MainActivity',
          'MainApplication',
          'NativeScrubPatterns',
          'NativeSentry',
          'NativeSentryScrubber',
        ])
          '$kotlinMain/$name.kt',
        for (final name in ['NativeSentryScrubberTest', 'NativeSentryTest'])
          '$kotlinTest/$name.kt',
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

  group('iOS identity', () {
    test('Runner is dev.lokumai.bazaar and RunnerTests is dev.lokumai.bazaar.RunnerTests', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      final ids = [for (final match in RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(project)) match[1]];

      // File order: Runner Profile, RunnerTests Debug, Release, Profile, then Runner Debug and Release.
      expect(ids, [
        'dev.lokumai.bazaar',
        'dev.lokumai.bazaar.RunnerTests',
        'dev.lokumai.bazaar.RunnerTests',
        'dev.lokumai.bazaar.RunnerTests',
        'dev.lokumai.bazaar',
        'dev.lokumai.bazaar',
      ]);
    });

    // iOS shows CFBundleDisplayName under the icon, so it carries the launcher label too.
    test('CFBundleDisplayName and CFBundleName are Bazaar', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
        expect(RegExp('<key>$key</key>\\s*<string>Bazaar</string>').hasMatch(plist), isTrue, reason: key);
      }
    });

    // Apple asks every app for a privacy manifest; this one says the app tracks nothing, and lists what a prod build
    // with a SENTRY_DSN sends (docs/store-privacy.md): crash data, performance data (how long the app took to open),
    // other diagnostic data (hangs), product interaction (the sessions of release health: the app's launches) and
    // customer support (Report a problem), none linked to the user or used for tracking, all for the app's functioning.
    test('the privacy manifest says no tracking and lists what Sentry sends, and ships in the app', () {
      final manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
      expect(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>').hasMatch(manifest), isTrue);
      final types = RegExp(r'<key>NSPrivacyCollectedDataType</key>\s*<string>(\w+)</string>').allMatches(manifest);
      expect(types.map((m) => m[1]), [
        'NSPrivacyCollectedDataTypeCrashData',
        'NSPrivacyCollectedDataTypePerformanceData',
        'NSPrivacyCollectedDataTypeOtherDiagnosticData',
        'NSPrivacyCollectedDataTypeProductInteraction',
        'NSPrivacyCollectedDataTypeCustomerSupport',
      ]);
      expect(RegExp(r'<key>NSPrivacyCollectedDataTypeLinked</key>\s*<false/>').allMatches(manifest), hasLength(5));
      expect(RegExp(r'<key>NSPrivacyCollectedDataTypeTracking</key>\s*<false/>').allMatches(manifest), hasLength(5));
      expect(
        RegExp(r'<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>').allMatches(manifest),
        hasLength(5),
      );
      expect(manifest, isNot(contains('NSPrivacyCollectedDataTypePurposeAnalytics')));

      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(RegExp(r'/\* PrivacyInfo.xcprivacy in Resources \*/,').allMatches(project), hasLength(1));
    });
  });

  test('the first release is version 1.0.0, build 1', () {
    expect(RegExp(r'^version: 1\.0\.0\+1$', multiLine: true).hasMatch(File('pubspec.yaml').readAsStringSync()), isTrue);
  });
}

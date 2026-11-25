import 'package:ai_engineering_bazaar/app/bootstrap/native_licences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  Future<List<String>> packages() async => [
    for (final entry in await LicenseRegistry.licenses.toList()) ...entry.packages,
  ];

  test('Android lists Sentry\'s Android and NDK SDKs under MIT (review 11, native 10)', () async {
    registerNativeLicences(TargetPlatform.android);
    expect(await packages(), ['sentry-java', 'sentry-native']);
    final text = (await LicenseRegistry.licenses.first).paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('MIT License'));
    expect(text, contains('Permission is hereby granted'));
  });

  test('iOS lists only Sentry\'s Cocoa SDK, and other platforms none', () async {
    registerNativeLicences(TargetPlatform.iOS);
    expect(await packages(), ['sentry-cocoa']);
    LicenseRegistry.reset();
    registerNativeLicences(TargetPlatform.linux);
    expect(await packages(), isEmpty);
  });
}

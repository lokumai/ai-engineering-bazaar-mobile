import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android manifest and backup rules fixed in 2a662ed.
///
/// - The main manifest declares `android.permission.INTERNET`. The debug and profile manifests declare it only for
///   the Flutter tool, so release builds must not depend on a plugin merging it in.
/// - The record directory (`files/record/`) is included in OS backup and device transfer (spec 3.14, owner decision
///   11), and only it, so the reader's progress follows them to a new device while the content cache and every other
///   file stay on the device.
///
/// The release build succeeds without any of these, so this meta-test fails if one is dropped again. XML comments
/// are stripped before matching, so neither a commented-out element nor an attribute quoted in a comment counts.
void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const dataExtractionRulesPath = 'android/app/src/main/res/xml/data_extraction_rules.xml';
  const backupRulesPath = 'android/app/src/main/res/xml/backup_rules.xml';
  final recordInclude = RegExp(r'<include\s+domain="file"\s+path="record/"\s*/>');

  test('the main manifest declares the INTERNET permission', () {
    final manifest = _readWithoutXmlComments(manifestPath);

    expect(
      RegExp(r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>').hasMatch(manifest),
      isTrue,
      reason: '$manifestPath does not declare android.permission.INTERNET, which release builds need to reach the API',
    );
  });

  test('the main manifest turns backup on and points to both backup rule files', () {
    final manifest = _readWithoutXmlComments(manifestPath);

    final missing = const [
      'android:allowBackup="true"',
      'android:fullBackupContent="@xml/backup_rules"',
      'android:dataExtractionRules="@xml/data_extraction_rules"',
    ].where((attribute) => !manifest.contains(attribute)).toList();

    expect(
      missing,
      isEmpty,
      reason:
          '$manifestPath lacks these <application> attributes, so the record would not '
          'follow the reader to a new device:\n${missing.join('\n')}',
    );
  });

  test('the data extraction rules include the record directory in cloud backups and device transfers', () {
    final rules = _readWithoutXmlComments(dataExtractionRulesPath);

    final missing = const [
      'cloud-backup',
      'device-transfer',
    ].where((section) => !_contentsOf(section, rules).any(recordInclude.hasMatch)).toList();

    expect(
      missing,
      isEmpty,
      reason:
          'These sections of $dataExtractionRulesPath lack '
          '<include domain="file" path="record/"/>:\n${missing.join('\n')}',
    );
    expect(rules, isNot(contains('<exclude')), reason: 'an include rule already limits the copy to the record');
  });

  test('the backup rules include the record directory', () {
    final rules = _readWithoutXmlComments(backupRulesPath);

    expect(
      recordInclude.hasMatch(rules),
      isTrue,
      reason: '$backupRulesPath lacks <include domain="file" path="record/"/>, so Android 11 and lower back up nothing',
    );
    expect(rules, isNot(contains('<exclude')));
  });

  // A32: the app loads content over https only. The platform defaults already refuse cleartext; these pin them.
  test('no manifest allows cleartext traffic', () {
    final manifests = Directory('android/app/src')
        .listSync()
        .whereType<Directory>()
        .map((source) => File('${source.path}/AndroidManifest.xml'))
        .where((manifest) => manifest.existsSync())
        .toList();
    expect(manifests, isNotEmpty);

    final allowing = [
      for (final manifest in manifests)
        for (final attribute in const ['usesCleartextTraffic="true"', 'networkSecurityConfig'])
          if (_readWithoutXmlComments(manifest.path).contains(attribute)) '${manifest.path}: $attribute',
    ];
    expect(allowing, isEmpty, reason: 'these manifests open the app to cleartext traffic:\n${allowing.join('\n')}');
  });

  // Owner decision 15 and A9: no OS deep link reaches the router. Flutter's embedding treats a missing
  // flutter_deeplinking_enabled as true and hands the data URI of any explicit intent to go_router.
  test('the main activity turns Flutter deep linking off', () {
    final manifest = _readWithoutXmlComments(manifestPath);
    final mainActivity = RegExp(
      r'<activity\s[^>]*android:name="\.MainActivity"[^>]*>(.*?)</activity>',
      dotAll: true,
    ).firstMatch(manifest);
    expect(mainActivity, isNotNull, reason: '$manifestPath declares no .MainActivity');

    expect(
      RegExp(r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+android:value="false"\s*/>')
          .hasMatch(mainActivity![1]!),
      isTrue,
      reason: '.MainActivity in $manifestPath lacks flutter_deeplinking_enabled=false, so an intent URI opens a route',
    );
  });

  test('iOS turns Flutter deep linking off', () {
    final plist = _readWithoutXmlComments('ios/Runner/Info.plist');

    expect(
      RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>').hasMatch(plist),
      isTrue,
      reason: 'ios/Runner/Info.plist lacks FlutterDeepLinkingEnabled set to false',
    );
  });

  test('iOS allows no arbitrary loads', () {
    final plist = _readWithoutXmlComments('ios/Runner/Info.plist');

    final allowing = const [
      'NSAllowsArbitraryLoads',
      'NSExceptionAllowsInsecureHTTPLoads',
    ].where(plist.contains).toList();
    expect(allowing, isEmpty, reason: 'ios/Runner/Info.plist opens the app to cleartext traffic: $allowing');
  });
}

/// Reads [path] without its XML comments.
String _readWithoutXmlComments(String path) =>
    File(path).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

/// The contents of every [element] in [xml].
Iterable<String> _contentsOf(String element, String xml) =>
    RegExp('<$element(?:\\s[^>]*)?>(.*?)</$element>', dotAll: true).allMatches(xml).map((match) => match[1]!);

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android manifest and backup rules fixed in 2a662ed.
///
/// - The main manifest declares `android.permission.INTERNET`. The debug and profile manifests declare it only for
///   the Flutter tool, so release builds must not depend on a plugin merging it in.
/// - Backup is off and both rule files exclude shared preferences, where flutter_secure_storage keeps the session
///   tokens encrypted with an Android Keystore key that is never backed up, so a restored copy cannot be decrypted.
///   On some devices running Android 12 and higher, device-to-device transfers ignore `android:allowBackup`, see
///   https://developer.android.com/about/versions/12/backup-restore.
///
/// The release build succeeds without any of these, so this meta-test fails if one is dropped again. XML comments
/// are stripped before matching, so neither a commented-out element nor an attribute quoted in a comment counts.
void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const dataExtractionRulesPath = 'android/app/src/main/res/xml/data_extraction_rules.xml';
  const backupRulesPath = 'android/app/src/main/res/xml/backup_rules.xml';
  final sharedPrefsExclude = RegExp(r'<exclude\s+domain="sharedpref"\s+path="\."\s*/>');

  test('the main manifest declares the INTERNET permission', () {
    final manifest = _readWithoutXmlComments(manifestPath);

    expect(
      RegExp(r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>').hasMatch(manifest),
      isTrue,
      reason: '$manifestPath does not declare android.permission.INTERNET, which release builds need to reach the API',
    );
  });

  test('the main manifest turns backup off and points to both backup rule files', () {
    final manifest = _readWithoutXmlComments(manifestPath);

    final missing = const [
      'android:allowBackup="false"',
      'android:fullBackupContent="@xml/backup_rules"',
      'android:dataExtractionRules="@xml/data_extraction_rules"',
    ].where((attribute) => !manifest.contains(attribute)).toList();

    expect(
      missing,
      isEmpty,
      reason:
          '$manifestPath lacks these <application> attributes, so a backup or device transfer can restore '
          'session tokens that no longer decrypt:\n${missing.join('\n')}',
    );
  });

  test('the data extraction rules keep shared preferences out of cloud backups and device transfers', () {
    final rules = _readWithoutXmlComments(dataExtractionRulesPath);

    final unprotected = const [
      'cloud-backup',
      'device-transfer',
    ].where((section) => !_contentsOf(section, rules).any(sharedPrefsExclude.hasMatch)).toList();

    expect(
      unprotected,
      isEmpty,
      reason:
          'These sections of $dataExtractionRulesPath lack <exclude domain="sharedpref" path="."/>, '
          'so they can restore session tokens that no longer decrypt:\n${unprotected.join('\n')}',
    );
  });

  test('the backup rules keep shared preferences out of backups', () {
    final rules = _readWithoutXmlComments(backupRulesPath);

    expect(
      sharedPrefsExclude.hasMatch(rules),
      isTrue,
      reason:
          '$backupRulesPath lacks <exclude domain="sharedpref" path="."/>, so on Android 11 and lower a backup '
          'would carry the session tokens as soon as backup is turned back on',
    );
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

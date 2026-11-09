import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled Vazirmatn is the face the diagrams were measured with', () {
    final index = jsonDecode(File('assets/content/index.json').readAsStringSync()) as Map<String, Object?>;
    final font = index['diagramFont']! as Map<String, Object?>;
    expect(font['family'], diagramFontFamily);
    expect(sha256.convert(File('assets/fonts/Vazirmatn-Regular.ttf').readAsBytesSync()).toString(), font['sha256']);
  });

  test('Vazirmatn is a font family of the app', () async {
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<Object?>;
    expect(
      manifest,
      contains(
        equals({
          'family': 'Vazirmatn',
          'fonts': [
            {'asset': 'assets/fonts/Vazirmatn-Regular.ttf'},
          ],
        }),
      ),
    );
  });

  test('the sans and mono families follow the platform', () {
    expect((sansFamily(TargetPlatform.iOS), monoFamily(TargetPlatform.iOS)), ('Avenir Next', 'Menlo'));
    expect((sansFamily(TargetPlatform.android), monoFamily(TargetPlatform.android)), (null, 'monospace'));
  });

  test('registerFontLicences adds the Vazirmatn OFL', () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);
    registerFontLicences();
    final entry = (await LicenseRegistry.licenses.toList()).singleWhere((e) => e.packages.contains('Vazirmatn'));
    expect(entry.paragraphs.map((p) => p.text).join('\n'), contains('SIL Open Font License, Version 1.1'));
  });
}

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

  test('Vazirmatn is a font family of the app, with its own bold face (review D4)', () async {
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<Object?>;
    expect(
      manifest,
      contains(
        equals({
          'family': 'Vazirmatn',
          'fonts': [
            {'asset': 'assets/fonts/Vazirmatn-Regular.ttf'},
            {'asset': 'assets/fonts/Vazirmatn-Bold.ttf', 'weight': 700},
          ],
        }),
      ),
    );
  });

  test('the bold face is the same release as the regular one, 33.003', () {
    for (final face in ['Regular', 'Bold']) {
      final bytes = File('assets/fonts/Vazirmatn-$face.ttf').readAsBytesSync();
      expect(utf16BigEndianIn(bytes), contains('Version 33.003'), reason: face);
    }
  });

  test('the sans and mono families follow the platform', () {
    expect((sansFamily(TargetPlatform.iOS), monoFamily(TargetPlatform.iOS)), ('Avenir Next', 'Menlo'));
    expect((sansFamily(TargetPlatform.android), monoFamily(TargetPlatform.android)), (null, 'monospace'));
  });

  test('registerFontLicences adds the OFL of Vazirmatn and of Fraunces', () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);
    registerFontLicences();
    final entries = await LicenseRegistry.licenses.toList();
    for (final face in ['Vazirmatn', 'Fraunces']) {
      final entry = entries.singleWhere((e) => e.packages.contains(face));
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL Open Font License, Version 1.1'), reason: face);
      expect(text, contains('The $face Project Authors'), reason: face);
    }
  });
}

/// The UTF-16 big-endian strings of a font's name table, as one text: enough to find its version.
String utf16BigEndianIn(List<int> bytes) {
  final units = <int>[for (var i = 0; i + 1 < bytes.length; i += 2) bytes[i] << 8 | bytes[i + 1]];
  return String.fromCharCodes(units.where((unit) => unit >= 0x20 && unit < 0x7f));
}

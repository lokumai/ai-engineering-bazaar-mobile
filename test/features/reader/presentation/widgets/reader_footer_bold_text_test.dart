@Tags(['widget'])
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/reader_footer.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/content_builders.dart';

// The test font's bold glyphs are as wide as its regular ones, so this file loads Roboto Regular and Bold from the
// Flutter SDK's material fonts under the family the Android theme names. A loaded font stays for the whole isolate,
// which is why these cases live apart from reader_footer_test.dart.

final _entry = testModule(
  tracks: {
    Track.engineers: testModuleTrack(
      revision: const Revision(hash: 'd6c69ec', date: '2026-11-08'),
    ),
  },
);

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set; flutter test sets it');
  final loader = FontLoader('Roboto');
  for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/$name');
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await S.load(const Locale('en'));
    await _loadRoboto();
  });

  // 288 px at 1.96: Android 14 with Display size, Font size and Bold text all at Largest. 358 px at 2.4: the reader
  // column at a scale no Android phone reaches, where the unbolded measurement was also wrong.
  for (final (scale, width) in [(1.96, 288.0), (2.4, 358.0)]) {
    testWidgets('with Bold Text at text scale $scale in $width px nothing in the footer is cut off', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(boldText: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: ReaderFooter(entry: _entry, track: Track.engineers, moduleCount: 9),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final texts = find.descendant(of: find.byType(ReaderFooter), matching: find.byType(RichText));
      final paragraphs = tester.renderObjectList<RenderParagraph>(texts).toList();
      expect(paragraphs, isNotEmpty);
      for (final paragraph in paragraphs) {
        expect(
          paragraph.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(paragraph.size.width),
          reason: paragraph.text.toPlainText(),
        );
      }
    });
  }
}

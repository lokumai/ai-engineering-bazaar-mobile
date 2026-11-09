@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/reader_footer.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/content_builders.dart';

final _entry = testModule(
  tracks: {
    Track.engineers: testModuleTrack(
      revision: const Revision(hash: 'd6c69ec', date: '2026-11-08'),
    ),
  },
);

/// Pumps the footer of [_entry] in a column [width] wide at text scale [scale], on the default 800x600 surface.
Future<void> pumpFooter(WidgetTester tester, {required double width, required double scale}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
}

/// Expects the paragraph that draws [text] to hold it whole on one line.
void expectOneWholeLine(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(paragraph.size.width), reason: text);
}

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('the revision is one line when it fits', (tester) async {
    await pumpFooter(tester, width: 358, scale: 1.0);

    expectOneWholeLine(tester, 'Rev d6c69ec · 2026-11-08');
  });

  // The test font draws every glyph a square as wide as the font size, about twice Roboto's width, so text scale 2.0
  // in the reader's 358 px column, and 3.0 in a 500 px one, are wider than Roboto at 3.0 in 358 px.
  for (final (scale, width) in [(2.0, 358.0), (3.0, 500.0)]) {
    testWidgets('at text scale $scale in $width px the hash and the date each stay whole on two lines', (tester) async {
      await pumpFooter(tester, width: width, scale: scale);

      expect(tester.takeException(), isNull);
      // Nothing in the footer is cut off at the column edge.
      final texts = find.descendant(of: find.byType(ReaderFooter), matching: find.byType(RichText));
      for (final paragraph in tester.renderObjectList<RenderParagraph>(texts)) {
        expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(paragraph.size.width));
      }
      expect(find.text('Rev d6c69ec · 2026-11-08'), findsNothing);
      expectOneWholeLine(tester, 'Rev d6c69ec ·');
      expectOneWholeLine(tester, '2026-11-08');
      expect(
        tester.getTopLeft(find.text('2026-11-08')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Rev d6c69ec ·')).dy),
      );
    });
  }
}

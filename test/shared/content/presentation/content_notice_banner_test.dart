@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

const _cacheDiscarded =
    'The downloaded content could not be read, so the app removed it and shows the content that came with this '
    'version. Check for updates in Settings to download it again.';

void main() {
  testWidgets('the content notice shows only for cacheDiscarded', (tester) async {
    await pumpInTheme(tester, const ContentNoticeBanner(notice: ContentNotice.cacheDiscarded), Brightness.light);
    expect(find.text(_cacheDiscarded), findsOneWidget);

    await pumpInTheme(tester, const ContentNoticeBanner(notice: null), Brightness.light);
    expect(find.descendant(of: find.byType(ContentNoticeBanner), matching: find.byType(Text)), findsNothing);
  });

  testWidgets('the notice is on-surface text', (tester) async {
    for (final brightness in Brightness.values) {
      await pumpInTheme(tester, const ContentNoticeBanner(notice: ContentNotice.cacheDiscarded), brightness);
      final context = tester.element(find.text(_cacheDiscarded));

      expect(tester.widget<Text>(find.text(_cacheDiscarded)).style!.color, Theme.of(context).colorScheme.onSurface);
    }
  });
}

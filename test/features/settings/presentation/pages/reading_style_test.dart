@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/reading_style_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../welcome/presentation/welcome_track_fit_harness.dart' show loadFace, robotoFiles;

/// Settings in the app's router and shell, on a phone of [size] with [insets] (the status bar and the home bar or
/// navigation buttons) at the phone's own text size.
Future<GoRouter> _pumpSettings(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  (double, double) insets = (0, 0),
  ReadingStyleCubit? style,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
  tester.view.viewPadding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
  addTearDown(tester.view.reset);
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, readingStyle: style, locale: locale));
  await tester.pumpAndSettle();
  router.go('/settings');
  await tester.pumpAndSettle();
  return router;
}

final _row = find.byKey(const Key('settings-reading-style'));

void main() {
  // Plan 12.4: Reading and Customize show whole without scrolling, measured in Roboto rather than the test font's
  // squares: an iPhone 17 with its notch and home bar, and a 360 x 800 Android with its status bar and gesture bar.
  group('in a real face', () {
    setUpAll(() => loadFace('Roboto', robotoFiles()));
    for (final (name, size, insets) in [
      ('393x852 iPhone', const Size(393, 852), (62.0, 34.0)),
      ('360x800 Android', const Size(360, 800), (24.0, 24.0)),
    ]) {
      for (final locale in const [Locale('en'), Locale('tr'), Locale('fa')]) {
        testWidgets('on a $name in ${locale.languageCode}, Reading and Customize fit the screen', (tester) async {
          await _pumpSettings(tester, size: size, insets: insets, locale: locale);
          // The wardrobe first, then the app icon, Customize's last row (the owner, 2026-11-17).
          final wardrobe = find.byKey(const Key('settings-robot'));
          final icon = find.byKey(const Key('settings-app-icon'));
          expect(tester.getBottomLeft(wardrobe).dy, lessThanOrEqualTo(tester.getTopLeft(icon).dy));
          // Above the navigation at the screen's foot.
          final navigation = tester.getTopLeft(find.byType(NavigationBar)).dy;
          expect(tester.getBottomLeft(icon).dy, lessThanOrEqualTo(navigation), reason: 'the app icon row on screen');
          // The Apprentice's button floats over Settings too (the owner, 2026-11-17), and may cover the App icon row's end
          // on a small phone: the rows keep their size (the owner: that matters more).
          expect(find.byKey(const ValueKey('pocket-assistant')), findsOneWidget);
          // The Apprentice's label on its choices' line, at the phone's own text size (the owner, 2026-11-17).
          final choice = find.byKey(const Key('settings-pocket-button'));
          final label = find.descendant(of: choice, matching: find.byType(Text)).first;
          expect(
            tester.getCenter(label).dy,
            moreOrLessEquals(tester.getCenter(find.byKey(settingsPocketKey(shown: true))).dy, epsilon: 1),
            reason: 'the label beside On and Off',
          );
        });
      }
    }
  });

  // The owner, 2026-11-17: the size and spacing written under the name made Settings look crowded; its tile's letters
  // show the size instead, and a screen reader hears both.
  testWidgets('the Reading settings row draws its letters at the size chosen, and opens its page', (tester) async {
    final style = ReadingStyleCubit();
    final router = await _pumpSettings(tester, style: style);
    final sample = find.byKey(const ValueKey('settings-reading-sample'));
    final standard = tester.getSize(sample).height;

    await style.chooseSize(ReadingSize.large);
    await tester.pumpAndSettle();
    expect(tester.getSize(sample).height, greaterThan(standard));
    expect(find.descendant(of: _row, matching: find.text('Large, Comfortable')), findsNothing);
    expect(find.bySemanticsLabel('Reading settings, Large, Comfortable'), findsOneWidget);

    await style.chooseSize(ReadingSize.values.last);
    await tester.pumpAndSettle();
    final tile = find.ancestor(of: sample, matching: find.byType(SizedBox)).first;
    expect(tester.getSize(sample).width, lessThan(tester.getSize(tile).width), reason: 'the largest still in its tile');

    await tester.tap(_row);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/settings/reading');
    expect(find.byType(ReadingStylePage), findsOneWidget);
  });

  testWidgets('the page changes the size and the spacing, shows them in its preview, and goes back to the default', (
    tester,
  ) async {
    final style = ReadingStyleCubit();
    final router = await _pumpSettings(tester, style: style);
    router.push('/settings/reading');
    await tester.pumpAndSettle();
    final reset = find.byKey(ReadingStylePage.resetKey);
    expect(tester.widget<TextButton>(reset).onPressed, isNull, reason: 'already the default');

    // The slider's far end: the largest size.
    final slider = find.byKey(ReadingStylePage.sizeKey);
    await tester.tapAt(tester.getRect(slider).centerRight - const Offset(12, 0));
    await tester.pumpAndSettle();
    expect(style.state.size, ReadingSize.largest);
    final tight = find.byKey(readingSpacingKey(ReadingSpacing.tight));
    await tester.ensureVisible(tight);
    await tester.pumpAndSettle();
    await tester.tap(tight);
    await tester.pumpAndSettle();
    expect(style.state.spacing, ReadingSpacing.tight);

    final preview = find.descendant(of: find.byKey(ReadingStylePage.previewKey), matching: find.byType(InlineText));
    expect(tester.widget<InlineText>(preview).style.height, ReadingSpacing.tight.lineHeight);
    final rich = tester.widget<RichText>(find.descendant(of: preview, matching: find.byType(RichText)).first);
    expect(rich.textScaler.scale(16), moreOrLessEquals(16 * ReadingSize.largest.factor));

    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style.state, ReadingStyle.standard);
  });

  // Walk-through 2026-11-24: the preview over the controls grew with the size and moved the spacing under the finger.
  testWidgets('a larger size moves none of the controls: the preview is under them', (tester) async {
    final style = ReadingStyleCubit();
    final router = await _pumpSettings(tester, style: style);
    router.push('/settings/reading');
    await tester.pumpAndSettle();
    final wide = find.byKey(readingSpacingKey(ReadingSpacing.wide));
    final reset = find.byKey(ReadingStylePage.resetKey);
    final before = (tester.getTopLeft(wide), tester.getTopLeft(reset));

    await style.chooseSize(ReadingSize.largest);
    await tester.pumpAndSettle();
    await style.chooseSpacing(ReadingSpacing.wide);
    await tester.pumpAndSettle();

    expect((tester.getTopLeft(wide), tester.getTopLeft(reset)), before);
    expect(tester.getTopLeft(find.byKey(ReadingStylePage.previewKey)).dy, greaterThan(before.$2.dy));
  });

  testWidgets('the page meets the accessibility guidelines', (tester) async {
    final router = await _pumpSettings(tester);
    router.push('/settings/reading');
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
  });
}

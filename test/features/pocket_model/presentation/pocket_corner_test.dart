@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_model_card.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/speech_bubble.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_cubit.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';

/// The Apprentice's corner at Home's head (plan 11.2).

final _corner = find.byKey(const ValueKey('pocket-corner'));

Future<void> _pump(
  WidgetTester tester, {
  MemoryPocketModelStore? store,
  PocketButtonCubit? button,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(393, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, pocketStore: store, pocketButton: button, locale: locale));
  await tester.pump();
  await tester.pump();
}

/// Lets the sheet's stage settle, so no timer is left running.
Future<void> _rest(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Home opens on the Apprentice: its button, its name and level, and Chat', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: clock.now())));

    expect(_corner, findsOneWidget);
    final top = tester.getRect(_corner).top;
    expect(top, lessThan(tester.getRect(find.text('Later on')).top), reason: 'at the head of the page');
    for (final finder in [
      find.byKey(const ValueKey('pocket-corner-robot')),
      find.text('Apprentice'),
      find.text('Level 1'),
      find.byKey(const ValueKey('pocket-corner-chat')),
    ]) {
      expect(find.descendant(of: _corner, matching: finder), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('pocket-assistant')), findsOneWidget, reason: 'the floating one, under the thumb');
  });

  testWidgets('its name says Çırak in Turkish', (tester) async {
    await _pump(tester, locale: const Locale('tr'));

    expect(find.descendant(of: _corner, matching: find.text('Çırak')), findsOneWidget);
    expect(find.descendant(of: _corner, matching: find.text('Sohbet et')), findsOneWidget);
  });

  testWidgets('Chat opens its sheet with it already talking', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: clock.now())));

    await tester.tap(find.byKey(const ValueKey('pocket-corner-chat')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PocketModelCard), findsOneWidget);
    expect(find.byType(SpeechBubble), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('its robot in the corner opens the sheet too', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('pocket-corner-robot')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(PocketModelCard), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('hidden in Settings, it has no corner either', (tester) async {
    final button = PocketButtonCubit(store: MemoryPocketButtonStore(kept: true));
    await button.load();
    await _pump(tester, button: button);

    expect(_corner, findsNothing);
    expect(find.text('Later on'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    await _pump(tester);
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
  });
}

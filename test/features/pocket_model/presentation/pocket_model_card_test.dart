@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_offline_note.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_path.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_model_card.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';

/// Home's pocket model (plan 9.2), under Your path.

Future<void> _pump(
  WidgetTester tester, {
  MemoryPocketModelStore? store,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(393, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouterFactory(initialLocation: '/').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(router: router, pocketStore: store ?? MemoryPocketModelStore(), platform: platform, locale: locale),
  );
  await tester.pump();
  await tester.pump();
}

/// Lets the stage settle: the robot rests after its lively seconds.
Future<void> _rest(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _stage = find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is PocketRobotPainter);

RobotFrame _frame(WidgetTester tester) => (tester.widget<CustomPaint>(_stage).painter! as PocketRobotPainter).frame();

void main() {
  testWidgets('sits on Home under Your path and over the offline note', (tester) async {
    await _pump(tester);

    expect(find.text('Pocket model'), findsOneWidget);
    final path = tester.getRect(find.byType(HomePath));
    final toy = tester.getRect(find.byType(PocketModelCard));
    final note = tester.getRect(find.byType(HomeOfflineNote));
    expect(toy.top, greaterThan(path.bottom));
    expect(note.top, greaterThan(toy.bottom));
    expect(find.text('New: it knows no words yet. Feed it some tokens.'), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('a feed trains it: tokens, the eating face, and the loss curve', (tester) async {
    final store = MemoryPocketModelStore();
    await _pump(tester, store: store);

    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('8 tokens'), findsOneWidget);
    expect(find.textContaining('16 to level 1'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.eating);
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.token), hasLength(5));
    expect(find.textContaining('loss '), findsOneWidget);
    expect(store.kept?.tokens, 8);
    await _rest(tester);
  });

  testWidgets('the feed that reaches a level throws confetti and shows the new level', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 20, lastFed: clock.now())));

    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Level 1: it can say more now.'), findsOneWidget);
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.confetti), isNotEmpty);
    await _rest(tester);
  });

  testWidgets('asked, it streams what it says a token at a time', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())));
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(-400, 0));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pocket-ask')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('more |'), findsOneWidget, reason: 'the first token, and the caret');

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('more tokens more wisdom'), findsOneWidget);
    expect(find.text('Cold: it says its likeliest words, every time.'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.cold);
    await _rest(tester);
  });

  testWidgets('hot, it hallucinates and says so', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())));
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(400, 0));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pocket-ask')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('hallucinating'), findsOneWidget);
    expect(find.text('Too hot: it hallucinates. Turn the temperature down.'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.hallucinating);
    await _rest(tester);
  });

  testWidgets('fed too fast it overfits, then rests and recovers', (tester) async {
    await _pump(tester);
    for (var i = 0; i < PocketModel.overfitFeeds; i++) {
      await tester.tap(find.byKey(const ValueKey('pocket-feed')));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('Overfitted'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.overfit);

    for (var i = 0; i < 230; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Rested, and ready to learn again.'), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('left for a day it sleeps, and a tap on it wakes it', (tester) async {
    final yesterday = clock.now().subtract(const Duration(days: 1));
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 100, lastFed: yesterday)));

    expect(find.text('Asleep. Tap it to wake it.'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.asleep);

    final stage = tester.getRect(_stage);
    await tester.tapAt(stage.topLeft + PocketRobotPainter.seat(stage.size) - const Offset(0, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Asleep. Tap it to wake it.'), findsNothing);
    expect(_frame(tester).face, RobotFace.happy);
    await _rest(tester);
  });

  testWidgets('a tap on the robot pets it: hearts and a happy face', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 100, lastFed: clock.now())));
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Pocket model, level 2. Tap to pet it.'), findsOneWidget);
    final stage = tester.getRect(_stage);
    await tester.tapAt(stage.topLeft + PocketRobotPainter.seat(stage.size) - const Offset(0, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.heart), isNotEmpty);
    expect(_frame(tester).face, RobotFace.happy);
    semantics.dispose();
    await _rest(tester);
  });

  testWidgets('it rests after a while, so Home draws nothing while read', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);

    await _rest(tester);
    expect(_frame(tester).alive, isFalse);
    // Only a blink, a fifth of a second every few seconds, starts the clock again.
    var still = false;
    for (var i = 0; i < 4 && !still; i++) {
      still = !tester.hasRunningAnimations;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(still, isTrue);
  });

  testWidgets('under reduced motion nothing flies and nothing moves', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_frame(tester).particles, isEmpty);
    expect(find.textContaining('8 tokens'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('in Persian the robot sits on the left and speaks Persian', (tester) async {
    await _pump(
      tester,
      store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())),
      locale: const Locale('fa'),
    );
    expect(_frame(tester).mirrored, isTrue);
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(400, 0));
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(-100, 0));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pocket-ask')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining(RegExp('[؀-ۿ]')), findsWidgets);
    await _rest(tester);
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);
    await tester.ensureVisible(find.byType(PocketModelCard));
    await tester.pump();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    await _rest(tester);
  });
}

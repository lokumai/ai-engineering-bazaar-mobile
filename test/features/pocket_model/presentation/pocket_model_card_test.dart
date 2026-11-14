@Tags(['widget'])
library;

import 'dart:math' as math;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_offline_note.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_model_card.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/speech_bubble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/training_panel.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';

/// The pocket model (plan 9.2, 9.4), in the sheet its round button opens from Home.

Future<void> _pump(
  WidgetTester tester, {
  MemoryPocketModelStore? store,
  RecordData? record,
  IPocketTexts? texts,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
  bool open = true,
}) async {
  tester.view.physicalSize = const Size(393, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouterFactory(initialLocation: '/').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      pocketStore: store ?? MemoryPocketModelStore(),
      record: record == null ? null : readyRecordBloc(record),
      pocketTexts: texts,
      platform: platform,
      locale: locale,
    ),
  );
  await tester.pump();
  await tester.pump();
  if (open) {
    await tester.tap(find.byKey(const ValueKey('pocket-assistant')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// Lets the stage settle: the robot rests after its lively seconds.
Future<void> _rest(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _stage = find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is PocketRobotPainter);

final _chart = find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is LossChartPainter);

RobotFrame _frame(WidgetTester tester) => (tester.widget<CustomPaint>(_stage).painter! as PocketRobotPainter).frame();

void main() {
  testWidgets('its round button sits on Home, the catalog and Quiz, never on a module, and opens it', (tester) async {
    await _pump(tester, open: false);
    final button = find.byKey(const ValueKey('pocket-assistant'));
    expect(button, findsOneWidget);
    expect(find.byType(PocketModelCard), findsNothing, reason: 'Home no longer carries it');
    expect(tester.getRect(button).bottom, lessThan(tester.getRect(find.byType(NavigationBar)).top));

    for (final (label, shows) in [('Catalog', true), ('Quiz', true), ('Settings', false), ('Home', true)]) {
      await tester.tap(find.text(label).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(button, shows ? findsOneWidget : findsNothing, reason: label);
    }

    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(PocketModelCard), findsOneWidget);
    expect(find.text('Pocket model'), findsOneWidget);
    expect(find.text('New: it knows no words yet. Feed it some tokens.'), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('the reader moves its button, and it stays there from tab to tab', (tester) async {
    await _pump(tester, open: false);
    final button = find.byKey(const ValueKey('pocket-assistant'));
    final start = tester.getRect(button);
    await tester.timedDrag(button, const Offset(-150, -200), const Duration(seconds: 2));
    await tester.pump();
    final moved = tester.getRect(button);
    expect(moved.center.dx, lessThan(start.center.dx - 100));
    expect(moved.center.dy, lessThan(start.center.dy - 100));

    for (final label in ['Quiz', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.getRect(button), moved);
    expect(find.byType(PocketModelCard), findsNothing, reason: 'a drag is not a tap');
    await _rest(tester);
  });

  testWidgets('the end of a page scrolls clear of its button', (tester) async {
    await _pump(tester, open: false);
    tester.view.physicalSize = const Size(393, 700);
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
    await tester.pump(const Duration(milliseconds: 500));
    final note = tester.getRect(find.byType(HomeOfflineNote));
    final button = tester.getRect(find.byKey(const ValueKey('pocket-assistant')));
    expect(note.bottom, lessThanOrEqualTo(button.top));
  });

  testWidgets('a module the reader finished: a badge on its button, and it reads it in the sheet', (tester) async {
    const module = [
      ['a', 'transformer', 'stacks', 'attention', 'layers'],
      ['each', 'layer', 'refines', 'the', 'tokens'],
    ];
    final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: clock.now()));
    await _pump(
      tester,
      store: store,
      record: signOff(RecordData.empty, 'alpha/first', null, '2026-11-14T12:00:00.000Z'),
      texts: const MemoryPocketTexts({'alpha/first': module}),
      open: false,
    );
    expect(find.byKey(const ValueKey('pocket-assistant-badge')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('pocket-assistant-badge')), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('pocket-assistant')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('1 finished module waiting'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('pocket-read')));
    await tester.tap(find.byKey(const ValueKey('pocket-read')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.kept?.readings.single.key, 'alpha/first');
    expect(find.textContaining('Read:'), findsNothing, reason: 'no line lists the words it read');
    expect(find.byKey(const ValueKey('pocket-read')), findsNothing);
    expect(find.text('Finish a module, and it can read it too.'), findsOneWidget);
    expect(find.byKey(const ValueKey('pocket-assistant-badge')), findsNothing);
    await _rest(tester);
  });

  testWidgets('with no module finished, it says one can be read', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('pocket-read')), findsNothing);
    expect(find.text('Finish a module, and it can read it too.'), findsOneWidget);
    await _rest(tester);
  });

  testWidgets('its button shows its mood, and a screen reader hears its level', (tester) async {
    final yesterday = clock.now().subtract(const Duration(days: 1));
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 100, lastFed: yesterday)), open: false);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    final head = tester.widget<CustomPaint>(
      find.descendant(of: find.byKey(const ValueKey('pocket-assistant')), matching: find.byType(CustomPaint)).last,
    );
    expect((head.painter! as RobotHeadPainter).face, RobotFace.asleep);
    expect(find.bySemanticsLabel('Pocket model, Level 2'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a feed trains it: tokens, the eating face, and the loss curve', (tester) async {
    final store = MemoryPocketModelStore();
    await _pump(tester, store: store);
    expect(find.text('Training loss'), findsOneWidget);
    expect(find.text('The curve starts with the first feed.'), findsOneWidget);
    expect(_chart, findsNothing);

    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('8 tokens'), findsOneWidget);
    expect(find.textContaining('knows 8 words'), findsOneWidget);
    expect(find.textContaining('Read:'), findsNothing, reason: 'no line lists the words it ate');
    expect(_frame(tester).face, RobotFace.eating);
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.token), hasLength(5));
    expect(find.text('The curve starts with the first feed.'), findsNothing);
    expect(_chart, findsOneWidget);
    expect(store.kept?.tokens, 8);
    await _rest(tester);
  });

  testWidgets('the feed that reaches a level throws confetti and shows the new level', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 20, lastFed: clock.now())));

    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
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
    // Cold, it writes its likeliest sentence, the one its language model writes from what it read.
    final said = TinyLm.trained('en', 2000).write(temperature: 0, random: math.Random()).tokens;
    await tester.pump(const Duration(milliseconds: 100));
    expect(_frame(tester).trick, RobotTrick.thinking, reason: 'it thinks before it speaks');
    expect(find.byType(SpeechBubble), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SpeechBubble), matching: find.byType(Text)),
      findsNothing,
      reason: 'nothing said while it thinks',
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('${said.first} |'), findsNothing, reason: 'the bubble pops out first');
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('${said.first} |'), findsOneWidget, reason: 'the first token, and the caret');

    await tester.pump(const Duration(seconds: 3));
    expect(find.text(said.join(' ')), findsOneWidget);
    expect(find.text('Cold: it says its likeliest words, every time.'), findsOneWidget);
    expect(_frame(tester).face, RobotFace.cold);
    await _rest(tester);
  });

  testWidgets('hot, it hallucinates and says so', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())));
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(400, 0));
    await tester.pump();

    // Hot, it joins words it never read together nearly every time; it is asked until it does.
    for (var i = 0; i < 6 && find.text('hallucinating').evaluate().isEmpty; i++) {
      await tester.tap(find.byKey(const ValueKey('pocket-ask')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    }
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

  testWidgets('a tap on the robot pets it: one of its five turns', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 100, lastFed: clock.now())));
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Pocket model, level 2. Tap to pet it.'), findsOneWidget);
    final stage = tester.getRect(_stage);
    await tester.tapAt(stage.topLeft + PocketRobotPainter.seat(stage.size) - const Offset(0, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final frame = _frame(tester);
    final hearts = frame.particles.any((p) => p.kind == ParticleKind.heart);
    expect(
      hearts ||
          {RobotTrick.wiggle, RobotTrick.fezHop, RobotTrick.starEyes, RobotTrick.tasselSpin}.contains(frame.trick),
      isTrue,
    );
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

  testWidgets('its words are in a speech bubble whose tail points at the robot', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())));
    await tester.tap(find.byKey(const ValueKey('pocket-ask')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final bubble = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is ShapeDecoration &&
          (widget.decoration! as ShapeDecoration).shape is SpeechBubbleBorder,
    );
    expect(bubble, findsOneWidget);
    final rect = tester.getRect(bubble);
    final stage = tester.getRect(_stage);
    final robot = stage.topLeft + PocketRobotPainter.seat(stage.size);
    expect(rect.right, lessThan(robot.dx), reason: 'beside the robot, not over it');
    expect(rect.bottom, lessThan(robot.dy), reason: 'up by its head');
    await _rest(tester);
  });

  test('the bubble\'s tail reaches out of its end side, toward the speaker', () {
    const rect = Rect.fromLTWH(0, 0, 160, 44);
    const border = SpeechBubbleBorder();
    final ltr = border.getOuterPath(rect, textDirection: TextDirection.ltr).getBounds();
    final rtl = border.getOuterPath(rect, textDirection: TextDirection.rtl).getBounds();
    expect(ltr.right, closeTo(rect.right, 0.5));
    expect(rtl.left, closeTo(rect.left, 0.5));
    final body = border.getOuterPath(rect, textDirection: TextDirection.ltr);
    expect(body.contains(Offset(rect.right - 1, 4)), isFalse, reason: 'the tail is low, by the bottom');
    expect(body.contains(Offset(rect.right - 3, rect.bottom - 3)), isTrue);
  });

  test('the loss chart marks each level reached', () {
    expect(LossChartPainter.marks(10), isEmpty);
    expect(LossChartPainter.marks(100), [24, 80]);
    expect(LossChartPainter.marks(50000), PocketModel.levels.skip(1).toList());
  });

  testWidgets('three pets in a row send its fez flying', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 100, lastFed: clock.now())));
    final stage = tester.getRect(_stage);
    final robot = stage.topLeft + PocketRobotPainter.seat(stage.size) - const Offset(0, 60);
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(robot);
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(_frame(tester).trick, RobotTrick.fezFly);
    await _rest(tester);
  });

  testWidgets('a feed is chewed: crumbs fall, and the new words it learnt sparkle', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('pocket-feed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final kinds = _frame(tester).particles.map((p) => p.kind).toSet();
    expect(kinds, containsAll({ParticleKind.token, ParticleKind.crumb}));
    expect(kinds, contains(ParticleKind.star), reason: 'its first words');
    await _rest(tester);
  });

  testWidgets('hot, its face flickers after it thinks; cold, its breath frosts', (tester) async {
    await _pump(tester, store: MemoryPocketModelStore(PocketModel(tokens: 2000, lastFed: clock.now())));
    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(-400, 0));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pocket-ask')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.frost), isNotEmpty);
    await _rest(tester);

    await tester.drag(find.byKey(const ValueKey('pocket-temperature')), const Offset(400, 0));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('pocket-ask')));
      await tester.pump();
      // The stage's clock takes at most a tenth of a second a frame, so it is walked past the thinking.
      for (var step = 0; step < 9; step++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (_frame(tester).trick == RobotTrick.glitch) break;
      await tester.pump(const Duration(seconds: 3));
    }
    expect(_frame(tester).trick, RobotTrick.glitch);
    await _rest(tester);
  });

  testWidgets('Start over asks, then starts it again at level 0; Keep it keeps it', (tester) async {
    final store = MemoryPocketModelStore(PocketModel(tokens: 400, lastFed: clock.now()));
    await _pump(tester, store: store);
    final reset = find.byKey(const ValueKey('pocket-reset'));

    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('Start the pocket model over?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(store.kept?.tokens, 400, reason: 'kept as it was');
    expect(find.textContaining('400 tokens'), findsOneWidget);

    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pocket-reset-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.kept, PocketModel.fresh);
    expect(find.textContaining('0 tokens'), findsOneWidget);
    expect(find.text('The curve starts with the first feed.'), findsOneWidget);
    expect(reset, findsNothing, reason: 'a fresh model has nothing to forget');
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

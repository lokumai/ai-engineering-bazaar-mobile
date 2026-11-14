import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The robot's wardrobe (plan 9.9), from Settings.

Future<RobotOutfitCubit> _pump(
  WidgetTester tester, {
  int tokens = 0,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = const Size(393, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouterFactory(initialLocation: '/settings/robot').create();
  addTearDown(router.dispose);
  final store = MemoryRobotOutfitStore();
  final outfit = RobotOutfitCubit(store: store);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      pocketStore: MemoryPocketModelStore(PocketModel(tokens: tokens, lastFed: clock.now())),
      robotOutfit: outfit,
      platform: platform,
    ),
  );
  await tester.pump();
  await tester.pump();
  return outfit;
}

RobotFrame _robot(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: find.byKey(const ValueKey('wardrobe-robot')), matching: find.byType(CustomPaint)),
  );
  return (paint.painter! as PocketRobotPainter).frame();
}

void main() {
  testWidgets('the robot on top in its outfit; at level 0 the fez is worn and what needs a level is locked', (
    tester,
  ) async {
    final outfit = await _pump(tester);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(_robot(tester).outfit, RobotOutfit.initial);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('wardrobe-fez-hat'))),
      isSemantics(label: 'Fez, worn', isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('wardrobe-beanie-hat'))),
      isSemantics(label: 'Beanie, unlocks at level 2'),
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('wardrobe-beanie-hat')), matching: find.text('Level 2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('wardrobe-beanie-hat')));
    await tester.pump();
    expect(outfit.state.hat, RobotHat.fez, reason: 'a locked hat cannot be put on');

    await tester.tap(find.byKey(const ValueKey('wardrobe-antenna-hat')));
    await tester.pump();
    expect(outfit.state.hat, RobotHat.antenna);
    expect(_robot(tester).outfit.hat, RobotHat.antenna);
  });

  testWidgets('its tabs hold its heads and its bodies; a level opens them', (tester) async {
    final outfit = await _pump(tester, tokens: 640);
    await tester.tap(find.byKey(const ValueKey('wardrobe-bodies')));
    await tester.pump();
    expect(find.text('Lab coat'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wardrobe-labCoat-body')));
    await tester.pump();
    expect(outfit.state.body, RobotBody.labCoat);
    expect(_robot(tester).outfit.body, RobotBody.labCoat);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('wardrobe-kaftan-body'))),
      isSemantics(label: 'Kaftan, unlocks at level 7'),
    );

    await tester.tap(find.byKey(const ValueKey('wardrobe-heads')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wardrobe-tv-head')));
    await tester.pump();
    expect(_robot(tester).outfit, const RobotOutfit(head: RobotHead.tv, body: RobotBody.labCoat));
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, tokens: 640, platform: defaultTargetPlatform);
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  testWidgets('at twice the text size nothing overflows', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, tokens: 40000);
    for (final tab in ['wardrobe-hats', 'wardrobe-heads', 'wardrobe-bodies']) {
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('every box in a row is as tall as the others, though a name takes two lines', (tester) async {
    await _pump(tester, tokens: 100000);
    for (final tab in ['wardrobe-hats', 'wardrobe-heads', 'wardrobe-bodies']) {
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pump();
      final boxes = find.byType(InkWell).evaluate().map((e) => tester.getRect(find.byWidget(e.widget))).toList();
      expect(boxes, isNotEmpty);
      final byRow = <double, Set<double>>{};
      for (final box in boxes) {
        (byRow[box.top] ??= {}).add(box.height);
      }
      for (final heights in byRow.values) {
        expect(heights, hasLength(1), reason: tab);
      }
    }
  });
}

import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/robot_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget stage, {bool reduced = false}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 300, height: 280, child: stage)),
    ),
  ),
);

RobotFrame _frame(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.byType(CustomPaint)).painter! as PocketRobotPainter).frame();

void main() {
  testWidgets('it greets with a turn at random as it appears, then says it is done', (tester) async {
    var done = 0;
    await _pump(
      tester,
      RobotStage(
        outfit: const RobotOutfit(hat: RobotHat.crown),
        hello: true,
        onHello: () => done++,
        random: math.Random(1),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final greeting = _frame(tester);
    expect(greeting.outfit, const RobotOutfit(hat: RobotHat.crown), reason: 'in what it was dressed in');
    expect(greeting.face == RobotFace.happy || greeting.trick != null || greeting.particles.isNotEmpty, isTrue);
    expect(done, 0);

    await tester.pump(RobotStage.helloLength);
    expect(done, 1);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('each greeting plays: a wave raises its arm, hearts fly, its eyes turn to stars', (tester) async {
    await _pump(tester, const RobotStage());
    final stage = tester.state<RobotStageState>(find.byType(RobotStage));

    stage.greet(RobotHello.wave);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_frame(tester).trick, RobotTrick.wave);
    expect(_frame(tester).trickAt(RobotTrick.wave), isNotNull);

    stage.greet(RobotHello.hearts);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_frame(tester).particles.where((p) => p.kind == ParticleKind.heart), isNotEmpty);

    stage.greet(RobotHello.starEyes);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_frame(tester).trick, RobotTrick.starEyes);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('under reduced motion it stands still and is done at once', (tester) async {
    var done = 0;
    await _pump(tester, RobotStage(hello: true, onHello: () => done++), reduced: true);
    await tester.pump();
    expect(done, 1);
    expect(_frame(tester).trick, isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('it stands in the middle of its stage', (tester) async {
    await _pump(tester, const RobotStage());
    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).painter,
      isA<PocketRobotPainter>().having((p) => p.centred, 'centred', isTrue),
    );
  });
}

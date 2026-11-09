import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'accessibility.dart';
import 'contrast.dart';

void main() {
  group('contrastRatio', () {
    test('is 21 for black on white, in either order', () {
      expect(contrastRatio(const Color(0xff000000), const Color(0xffffffff)), 21.0);
      expect(contrastRatio(const Color(0xffffffff), const Color(0xff000000)), 21.0);
    });

    test('measures the WCAG ratio of a pair', () {
      expect(contrastRatio(const Color(0xff1b1b47), const Color(0xffffffff)), closeTo(16.22, 0.01));
    });

    test('refuses a translucent colour on either side', () {
      expect(() => contrastRatio(const Color(0x80000000), const Color(0xffffffff)), throwsArgumentError);
      expect(() => contrastRatio(const Color(0xffffffff), const Color(0x80000000)), throwsArgumentError);
    });
  });

  testWidgets('pumpAtTextScale scales text on a 390x844 surface', (tester) async {
    await pumpAtTextScale(
      tester,
      MaterialApp(home: Builder(builder: (context) => Text('${MediaQuery.textScalerOf(context).scale(10)}'))),
      scale: 2.0,
    );
    expect(find.text('20.0'), findsOneWidget);
    expect(tester.view.physicalSize, const Size(390, 844));
  });

  group('expectHittable', () {
    testWidgets('passes on a button nothing covers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: FilledButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      );
      expectHittable(tester, find.byType(FilledButton));
    });

    testWidgets('fails on a button under a box that absorbs the hit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Center(
                child: FilledButton(onPressed: () {}, child: const Text('Save')),
              ),
              const Positioned.fill(
                child: AbsorbPointer(child: ColoredBox(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
      expect(() => expectHittable(tester, find.byType(FilledButton)), throwsA(isA<TestFailure>()));
    });
  });

  testWidgets('expectPlatformGuidelines refuses a platform other than Android and iOS', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await expectLater(expectPlatformGuidelines(tester, platform: TargetPlatform.windows), throwsStateError);
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two platforms the app ships on. A guideline test runs `testWidgets(..., variant: bazaarPlatforms)`, pumps its
/// app with `platform: defaultTargetPlatform`, then calls `expectPlatformGuidelines(tester, platform:
/// defaultTargetPlatform)`.
final bazaarPlatforms = TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS});

/// Checks the tree already pumped against the tap-target guideline of [platform] (48 on Android, 44 on iOS: Flutter's
/// guidelines ignore the platform, so each runs under its own, A28), then the labeled tap-target and text contrast
/// guidelines. Throws [StateError] for any other platform.
Future<void> expectPlatformGuidelines(WidgetTester tester, {required TargetPlatform platform}) async {
  final tapTarget = switch (platform) {
    TargetPlatform.android => androidTapTargetGuideline,
    TargetPlatform.iOS => iOSTapTargetGuideline,
    _ => throw StateError('No tap-target guideline for $platform; the app ships on Android and iOS'),
  };
  final handle = tester.ensureSemantics();
  try {
    // Builds the semantics tree of the tree already pumped.
    await tester.pump();
    await expectLater(tester, meetsGuideline(tapTarget));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    handle.dispose();
  }
}

/// Pumps [app] on a 390x844 surface at device pixel ratio 1 with the platform text scale at [scale], each reset when
/// the test ends. Pumps two frames after [WidgetTester.pumpWidget] and never settles, since a page may hold a spinner.
Future<void> pumpAtTextScale(WidgetTester tester, Widget app, {required double scale}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(app);
  await tester.pump();
  await tester.pump();
}

/// Expects [finder] to find one widget that a tap at its centre reaches: the hit-test path from that point holds the
/// widget's render object, so nothing above it takes the hit.
void expectHittable(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final target = tester.renderObject(finder);
  final path = tester.hitTestOnBinding(tester.getCenter(finder)).path;
  expect(
    path.any((entry) => identical(entry.target, target)),
    isTrue,
    reason: 'a tap at the centre of $finder does not reach it',
  );
}

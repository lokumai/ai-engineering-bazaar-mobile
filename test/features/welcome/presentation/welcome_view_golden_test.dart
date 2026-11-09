import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_view.dart';
import 'package:flutter/material.dart';

import '../../../support/golden_app.dart';

/// Welcome as it ends its entrance: reduced motion draws it in place at once.
Widget _welcome(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: goldenScreen(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: WelcomeView(onEnter: () {}),
      ),
    ),
    dark: brightness == Brightness.dark,
  ),
);

void main() {
  goldenTest(
    'WelcomeView light',
    fileName: 'welcome_view_light',
    // The pictures decode off the frame, so they are loaded before the capture.
    pumpBeforeTest: precacheImages,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'first launch', child: _welcome(Brightness.light))],
    ),
  );

  goldenTest(
    'WelcomeView dark',
    fileName: 'welcome_view_dark',
    pumpBeforeTest: precacheImages,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'first launch', child: _welcome(Brightness.dark))],
    ),
  );
}

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';
import '../../../../support/golden_app.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest(
    'SettingsScreen light',
    fileName: 'settings_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: goldenScreen(const SettingsScreen(), dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'SettingsScreen dark',
    fileName: 'settings_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: goldenScreen(const SettingsScreen(), dark: true)),
        ),
      ],
    ),
  );
}

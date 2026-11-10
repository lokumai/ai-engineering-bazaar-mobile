import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/material.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/golden_app.dart';

/// Home with `alpha/first` completed For Engineers.
Widget _home(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: bazaarTestApp(
    router: const AppRouterFactory().create(),
    record: readyRecordBloc(signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-09T10:00:00.000Z')),
    brightness: brightness,
  ),
);

void main() {
  goldenTest(
    'HomePage light',
    fileName: 'home_page_light',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _home(Brightness.light))],
    ),
  );

  goldenTest(
    'HomePage dark',
    fileName: 'home_page_dark',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _home(Brightness.dark))],
    ),
  );
}

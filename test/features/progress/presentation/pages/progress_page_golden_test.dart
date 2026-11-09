import 'package:ai_engineering_bazaar/features/progress/presentation/pages/progress_page.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/golden_app.dart';

/// The progress page alone, as in `progress_page_test.dart`: the app's shell gives the page its Scaffold, here the
/// route does.
GoRouter _router() => GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(
      path: '/profile',
      builder: (_, _) => const Scaffold(body: ProgressPage()),
    ),
    GoRoute(path: '/courses/:level/:module', builder: (_, _) => const Placeholder()),
    GoRoute(path: '/everyone/courses/:level/:module', builder: (_, _) => const Placeholder()),
  ],
);

/// The For Engineers tab with `alpha/first` completed.
Widget _progress(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: bazaarTestApp(
    router: _router(),
    content: readyContentBloc(),
    record: readyRecordBloc(signOff(RecordData.empty, 'alpha/first', null, '2026-03-15T10:00:00.000Z')),
    brightness: brightness,
  ),
);

void main() {
  goldenTest(
    'ProgressPage light',
    fileName: 'progress_page_light',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _progress(Brightness.light))],
    ),
  );

  goldenTest(
    'ProgressPage dark',
    fileName: 'progress_page_dark',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _progress(Brightness.dark))],
    ),
  );
}

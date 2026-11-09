import 'package:ai_engineering_bazaar/features/progress/presentation/pages/progress_page.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';
import '../../../../support/golden_app.dart';
import '../progress_host.dart';

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

/// The whole page, tall enough to show what stands above the tabs and under the cards: the content notice, a kept
/// quarantine, the write notice and the data line.
Widget _wholePage(Brightness brightness) {
  final content = MockContentBloc();
  whenListen(
    content,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(
      index: catalogFixtureIndex(),
      origin: ContentOrigin.bundled,
      notice: ContentNotice.cacheDiscarded,
      refresh: const RefreshIdle(),
    ),
  );
  return SizedBox(
    width: kGoldenScreenSize.width,
    height: 1600,
    child: bazaarTestApp(
      router: _router(),
      content: content,
      record: recordBlocAt(
        record: signOff(RecordData.empty, 'alpha/first', null, '2026-03-15T10:00:00.000Z'),
        quarantine: QuarantineReason.malformed,
        quarantineKept: true,
        writeState: const WriteQuota(),
      ),
      brightness: brightness,
    ),
  );
}

void main() {
  goldenTest(
    'ProgressPage light',
    fileName: 'progress_page_light',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(name: 'engineers, first completed', child: _progress(Brightness.light)),
        GoldenTestScenario(name: 'whole page with notices and the data line', child: _wholePage(Brightness.light)),
      ],
    ),
  );

  goldenTest(
    'ProgressPage dark',
    fileName: 'progress_page_dark',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(name: 'engineers, first completed', child: _progress(Brightness.dark)),
        GoldenTestScenario(name: 'whole page with notices and the data line', child: _wholePage(Brightness.dark)),
      ],
    ),
  );
}

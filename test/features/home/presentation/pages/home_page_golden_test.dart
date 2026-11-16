import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';
import '../../../../support/golden_app.dart';

/// The first day of the count, which the day's card is chosen by: `alpha/first`, completed, at its first section.
final _day = Clock.fixed(DateTime(1970));

/// A course whose every module document is the same written module.
MockContentRepository _course() {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer(
    (_) async => testDoc(
      title: 'First Module',
      body: const [
        HeadingBlock(
          depth: 2,
          id: 'why',
          mark: null,
          inlines: [TextInline(text: 'Why models call tools')],
        ),
        ParagraphBlock(
          inlines: [
            TextInline(
              text:
                  'A model on its own only writes text. A tool lets it look something up, run a sum or '
                  'change the world, and read what comes back before it answers.',
            ),
          ],
          lead: false,
        ),
      ],
    ),
  );
  return repository;
}

Future<void> _onTheDay(WidgetTester tester, Widget widget) => withClock(_day, () => tester.pumpWidget(widget));

Future<void> _settleOnTheDay(WidgetTester tester) => withClock(_day, () => onlyPumpAndSettle(tester));

/// Home with `alpha/first` completed For Engineers: the Apprentice's corner with the day's card at its head.
Widget _home(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: bazaarTestApp(
    router: const AppRouterFactory().create(),
    record: readyRecordBloc(signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-09T10:00:00.000Z')),
    repository: _course(),
    brightness: brightness,
  ),
);

void main() {
  goldenTest(
    'HomePage light',
    fileName: 'home_page_light',
    pumpWidget: _onTheDay,
    pumpBeforeTest: _settleOnTheDay,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _home(Brightness.light))],
    ),
  );

  goldenTest(
    'HomePage dark',
    fileName: 'home_page_dark',
    pumpWidget: _onTheDay,
    pumpBeforeTest: _settleOnTheDay,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'engineers, first completed', child: _home(Brightness.dark))],
    ),
  );
}

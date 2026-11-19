@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_cards.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/content_builders.dart';

CatalogRow _row(String key, int number, Map<String, int> words) => CatalogRow(
  key: key,
  level: 'alpha',
  number: number,
  title: 'Module $number',
  drawn: true,
  signed: false,
  minutes: 25,
  words: words,
  summary: null,
  requires: const [],
);

Future<void> _pump(WidgetTester tester, String language) async {
  final rows = [
    _row('alpha/first', 1, const {'en': 2317, 'tr': 2104}),
    _row('alpha/second', 2, const {'en': 1980}),
    _row('alpha/third', 3, const {}),
  ];
  await pumpInTheme(
    tester,
    BlocProvider(
      create: (_) => LanguageCubit(initial: language),
      child: SingleChildScrollView(
        child: CatalogCards(
          track: Track.engineers,
          index: testIndex(
            modules: [
              testModule(),
              testModule(key: 'alpha/second', number: 2),
              testModule(key: 'alpha/third', number: 3),
            ],
          ),
          rows: rows,
          openDescription: null,
          onDescription: (_) {},
        ),
      ),
    ),
    Brightness.light,
  );
}

void main() {
  testWidgets("Length gives the minutes and the words of the reader's document, as the web page prints them", (
    tester,
  ) async {
    await _pump(tester, 'en');
    expect(find.text('25 min · 2,317 words'), findsOneWidget);
    expect(find.text('25 min · 1,980 words'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget, reason: 'no word count, the minutes alone');
  });

  testWidgets('in Turkish, the Turkish words, else the English, grouped by a full stop', (tester) async {
    // The harness writes the interface in English; the reading language picks the count and its grouping.
    await _pump(tester, 'tr');
    expect(find.text('25 min · 2.104 words'), findsOneWidget);
    expect(find.text('25 min · 1,980 words'), findsOneWidget, reason: 'the English count, grouped as English');
  });

  group("the catalog's module rows (the owner, 2026-11-18)", () {
    Future<void> pumpOverview(WidgetTester tester, {double scale = 1}) => pumpInTheme(
      tester,
      MediaQuery(
        data: MediaQueryData(size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
        child: BlocProvider(
          create: (_) => CatalogFoldCubit(),
          child: SingleChildScrollView(
            child: CatalogOverview(
              track: Track.engineers,
              index: testIndex(
                modules: [
                  testModule(),
                  testModule(key: 'alpha/second', number: 2),
                ],
              ),
              rows: [
                _row('alpha/first', 1, const {'en': 2317}),
                CatalogRow(
                  key: 'alpha/second',
                  level: 'alpha',
                  number: 2,
                  title: 'A module whose title is long enough to wrap onto a second line',
                  drawn: true,
                  signed: false,
                  minutes: 30,
                  words: const {'en': 1980},
                  summary: null,
                  requires: const [],
                ),
              ],
              counts: null,
              upNext: 'alpha',
            ),
          ),
        ),
      ),
      Brightness.light,
    );

    testWidgets("the minutes alone, at the row's end on the title's first line, every row's in one column", (
      tester,
    ) async {
      await pumpOverview(tester);
      expect(find.textContaining('words'), findsNothing, reason: 'no word count');
      final first = tester.getRect(find.text('~25 min'));
      final second = tester.getRect(find.text('~30 min'));
      final title = tester.getRect(find.text('Module 1'));
      final long = tester.getRect(find.textContaining('A module whose title'));
      expect(first.left, greaterThan(title.right), reason: 'beside the title');
      expect(first.right, moreOrLessEquals(second.right, epsilon: 0.5), reason: 'one column');
      expect(long.height, greaterThan(first.height * 2), reason: 'the long title wraps');
      expect(second.top, lessThan(long.top + long.height / 3), reason: "on the title's first line");
      expect(tester.takeException(), isNull);
    });

    testWidgets('with large text the minutes go under the title', (tester) async {
      await pumpOverview(tester, scale: 2);
      final title = tester.getRect(find.text('Module 1'));
      final minutes = tester.getRect(find.text('~25 min'));
      expect(minutes.top, greaterThanOrEqualTo(title.bottom - 1));
      expect(tester.takeException(), isNull);
    });
  });
}

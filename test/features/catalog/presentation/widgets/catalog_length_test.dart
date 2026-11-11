@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_cards.dart';
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
}

import 'package:ai_engineering_bazaar/app/british_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The delegates in the order the app lists them.
const _delegates = [
  BritishMaterialLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<MaterialLocalizations> _materialIn(WidgetTester tester, String language) async {
  late MaterialLocalizations words;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: _delegates,
      supportedLocales: const [Locale('en'), Locale('tr'), Locale('fa')],
      home: Builder(
        builder: (context) {
          words = MaterialLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return words;
}

void main() {
  // Regression: the Settings row said Licences and the page it opened was titled Licenses (walk-through 2026-11-24).
  testWidgets('English takes Material words as en-GB writes them', (tester) async {
    final words = await _materialIn(tester, 'en');

    expect(words.licensesPageTitle, 'Licences');
  });

  testWidgets('Turkish and Persian keep their own Material words', (tester) async {
    expect((await _materialIn(tester, 'tr')).licensesPageTitle, 'Lisanslar');
    expect((await _materialIn(tester, 'fa')).licensesPageTitle, isNot('Licences'));
  });
}

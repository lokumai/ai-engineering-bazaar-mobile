import 'dart:io';

import 'package:ai_engineering_bazaar/shared/utils/latin_digits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The owner, 2026-11-23: the app writes Latin digits in every language, as the web does. Persian screens mixed the
/// Persian digits intl writes with the Latin digits of every string (review 5, finding 6).
void main() {
  setUpAll(() => initializeDateFormatting());

  final persianDigit = RegExp('[۰-۹٠-٩]');

  test('a Persian date has its own month names and Latin digits', () {
    final written = latinDigits(DateFormat.yMMM('fa')).format(DateTime.utc(2022, 11));
    expect(written, contains('2022'));
    expect(written, isNot(contains(persianDigit)));
  });

  test('a Persian number is written with Latin digits, grouped by comma; Turkish keeps its decimal comma', () {
    expect(NumberFormat('0.0', numberLocale('fa')).format(0.8), '0.8');
    expect(NumberFormat.decimalPattern(numberLocale('fa')).format(12345), '12,345');
    expect(NumberFormat('0.0', numberLocale('tr')).format(0.8), '0,8');
    expect(numberLocale('en'), 'en');
  });

  test('no string of the Persian copy writes a Persian digit', () {
    final copy = File('lib/l10n/intl_fa.arb').readAsStringSync();
    expect(persianDigit.allMatches(copy).map((match) => match[0]), isEmpty);
  });
}

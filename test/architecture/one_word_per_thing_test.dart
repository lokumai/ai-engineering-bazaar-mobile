import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _copy(String language) =>
    jsonDecode(File('lib/l10n/intl_$language.arb').readAsStringSync()) as Map<String, Object?>;

/// Review 6, finding 10: Turkish and Persian named the same thing with two words, and a tour line pointed at a control
/// by a word the control does not show.
void main() {
  final en = _copy('en');
  final tr = _copy('tr');
  final fa = _copy('fa');

  test('Persian calls a module درس everywhere', () {
    final named = fa.entries.where((entry) => '${entry.value}'.contains('ماژول')).map((entry) => entry.key);
    expect(named, isEmpty);
  });

  test('the tour names the track control with its Settings label', () {
    expect('${en['tour_settings_reading']}', startsWith('${en['settings_track']}'));
    expect('${tr['tour_settings_reading']}', startsWith('${tr['settings_track']}'));
    expect('${fa['tour_settings_reading']}', startsWith('${fa['settings_track']}'));
  });

  test('the tour names the app icon row with its own label', () {
    expect('${tr['tour_settings_customize']}', contains('App ikonunu'));
    expect('${fa['tour_settings_customize']}', contains('${fa['settings_app_icon']}'));
  });

  test('the Caravan tour says trend, as the Caravan does', () {
    expect('${tr['tour_caravan_stage']}', contains('trend'));
    expect('${fa['tour_caravan_stage']}', contains('ترند'));
  });

  test('Persian addresses the reader one way on the Apprentice card', () {
    final informal = RegExp(r'(?:^|\s)(?:کن|بخوان|بده|کردی|پیشرفتت)(?:[\s.،]|$)');
    final mixed = fa.entries
        .where((entry) => entry.key.startsWith('pocket_') && informal.hasMatch('${entry.value}'))
        .map((entry) => entry.key);
    expect(mixed, isEmpty);
  });

  // The owner, 2026-11-13: SİL in Turkish, حذف in Persian; review 7 finding 5 found پاک, which the docs and the
  // erase test did not know, and which an Arabic keyboard writes with another kaf.
  test('the erase word is the owner\'s, and the field names it', () {
    expect(tr['erase_word'], 'SİL');
    expect(fa['erase_word'], 'حذف');
    expect('${fa['erase_field_label']}', contains('«حذف»'));
  });

  // Review 7, finding 8: Turkish "tarayıcı" is the browser, and the scan line said one was opening.
  test('Turkish calls the code scanner a kod okuyucu, never the browser', () {
    expect('${tr['website_scan_opening']}', startsWith('Kod okuyucu'));
  });

  // Review 7, finding 16: Turkish quotes with curly marks, as the rest of its copy does.
  test('no Turkish string uses a straight double quote', () {
    final straight = tr.entries.where((entry) => '${entry.value}'.contains('"')).map((entry) => entry.key);
    expect(straight, isEmpty);
  });
}

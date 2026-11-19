import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Practice tab's tile names in each language, as the owner chose them (2026-11-18).
void main() {
  test('the tiles are named Wrong answers, Recap and Glossary; in Turkish Hatalı cevaplar, Özet and Sözlük', () async {
    final names = {
      for (final language in ['en', 'tr', 'fa'])
        language: await S.load(Locale(language)).then((s) => [s.practice_wrong, s.practice_brief, s.practice_glossary]),
    };
    expect(names['en'], ['Wrong answers', 'Recap', 'Glossary']);
    expect(names['tr'], ['Hatalı cevaplar', 'Özet', 'Sözlük']);
    expect(names['fa']![1], 'خلاصه');
  });
}

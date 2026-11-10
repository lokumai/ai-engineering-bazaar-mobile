import 'package:ai_engineering_bazaar/features/quiz/application/quiz_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/catalog_fixture_index.dart';

void main() {
  test('lists the levels that hold a quiz, each with its quiz modules in number order (plan 1AC)', () {
    final levels = quizLevels(catalogFixtureIndex());

    expect([for (final level in levels) level.level.slug], ['alpha', 'beta', 'gamma']);
    expect([for (final level in levels) level.position], [0, 1, 2]);
    expect(
      [
        for (final level in levels) [for (final module in level.modules) module.key],
      ],
      [
        ['alpha/first', 'alpha/second'],
        ['beta/fourth'],
        ['gamma/sixth'],
      ],
      reason: 'alpha/third and beta/fifth are planned For Engineers and carry no quiz',
    );
  });
}

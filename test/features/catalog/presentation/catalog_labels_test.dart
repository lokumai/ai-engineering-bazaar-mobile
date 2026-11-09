import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;
  setUpAll(() async => s = await S.load(const Locale('en')));

  test('moduleNumber pads to two digits', () {
    expect(moduleNumber(1), '01');
    expect(moduleNumber(44), '44');
  });

  test('durationLabel', () {
    expect(durationLabel(s, 0), isNull);
    expect(durationLabel(s, -5), isNull);
    expect(durationLabel(s, 45), '~45 min');
    expect(durationLabel(s, 60), '~1 h');
    expect(durationLabel(s, 75), '~1 h 15 min');
    expect(durationLabel(s, 135), '~2 h 15 min');
  });

  test('levelLeadLine', () {
    expect(levelLeadLine(s, modules: 3, minutes: 75), '3 modules · ~1 h 15 min');
    expect(levelLeadLine(s, modules: 1, minutes: 45), '1 module · ~45 min');
    expect(levelLeadLine(s, modules: 2, minutes: 0), '2 modules');
  });

  test('requiresLabel', () {
    expect(requiresLabel(s, const []), 'Nothing');
    expect(requiresLabel(s, const [1]), '1');
    expect(requiresLabel(s, const [1, 2]), '1, 2');
  });
}

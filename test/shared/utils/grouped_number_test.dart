import 'package:ai_engineering_bazaar/shared/utils/grouped_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thousands are grouped by a comma, by a full stop in Turkish (web groups)', () {
    expect(groupedNumber(2317, 'en'), '2,317');
    expect(groupedNumber(2317, 'tr'), '2.317');
    expect(groupedNumber(2317, 'fa'), '2,317');
    expect(groupedNumber(1234567, 'en'), '1,234,567');
    expect(groupedNumber(999, 'tr'), '999');
    expect(groupedNumber(1000, 'tr'), '1.000');
  });
}

import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moduleNumber pads to two digits', () {
    expect(moduleNumber(1), '01');
    expect(moduleNumber(44), '44');
  });
}

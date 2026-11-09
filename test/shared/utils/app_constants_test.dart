import 'package:ai_engineering_bazaar/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Constants values", () {
    test('appVersion should be 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });
  });
}

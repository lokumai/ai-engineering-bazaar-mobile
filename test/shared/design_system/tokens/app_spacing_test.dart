import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the spacing scale steps by 4 and 8', () {
    expect(
      [AppSpacing.xs, AppSpacing.sm, AppSpacing.md, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl],
      [4.0, 8.0, 12.0, 16.0, 24.0, 32.0],
    );
  });
}

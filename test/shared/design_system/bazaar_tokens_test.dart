import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lerp at 0 and 1 gives the ends, and lerp with null keeps the theme', () {
    expect(BazaarColors.light.lerp(BazaarColors.dark, 1).surface, BazaarColors.dark.surface);
    expect(BazaarColors.light.lerp(BazaarColors.dark, 0).onSurface, BazaarColors.light.onSurface);
    expect(identical(BazaarColors.light.lerp(null, 0.5), BazaarColors.light), isTrue);
  });

  test('copyWith replaces one colour and keeps the rest', () {
    final copy = BazaarColors.light.copyWith(fault: BazaarColors.dark.fault);
    expect((copy.fault, copy.surface), (BazaarColors.dark.fault, BazaarColors.light.surface));
  });

  test('forRole maps each code role to its slab colour and anything else to on-surface', () {
    expect(BazaarSlab.forRole('keyword'), BazaarFixedColors.slabKeyword);
    expect(BazaarSlab.forRole(null), BazaarFixedColors.slabOnSurface);
    expect(BazaarSlab.forRole('no-such-role'), BazaarFixedColors.slabOnSurface);
  });
}

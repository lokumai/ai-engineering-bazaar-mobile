import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// The frame ink is a web pair `contrast.test.ts` does not test (spec 3.8: such a pair needs a Dart contrast test).
/// The grounds come from the bundled index; a ground other than the two measured stops the test, so a web change to
/// diagramThemes forces a new look at the ink.
Color groundOf(String variant) {
  final index = jsonDecode(File('assets/content/index.json').readAsStringSync()) as Map<String, Object?>;
  final text = ((index['diagramThemes']! as Map<String, Object?>)[variant]! as Map<String, Object?>)['background'];
  return switch (text) {
    'white' => const Color(0xffffffff),
    '#333' => const Color(0xff333333),
    _ => throw StateError('diagramThemes.$variant.background is $text; re-measure DiagramFrameInk against it'),
  };
}

void main() {
  test('the light frame takes the Paper ink and the dark frame the Night slab (A26)', () {
    final light = DiagramFrameInk.of(DiagramVariant.light);
    final dark = DiagramFrameInk.of(DiagramVariant.dark);
    expect(
      (light.ink, light.muted, light.edge, light.tool),
      (BazaarFixedColors.onBarChip, BazaarFixedColors.slabArrow, BazaarFixedColors.bandB, BazaarFixedColors.onBar),
    );
    expect(
      (dark.ink, dark.muted, dark.edge, dark.tool),
      (
        BazaarFixedColors.slabOnSurface,
        BazaarFixedColors.slabOnSurfaceMuted,
        BazaarFixedColors.slabLine,
        BazaarFixedColors.slabSurfaceRaised,
      ),
    );
  });

  test('every frame ink clears 4.5:1 on its ground', () {
    final light = DiagramFrameInk.of(DiagramVariant.light);
    final dark = DiagramFrameInk.of(DiagramVariant.dark);
    for (final (fg, ground, ratio) in [
      (light.ink, groundOf('light'), 16.22),
      (light.muted, groundOf('light'), 4.75),
      (dark.ink, groundOf('dark'), 9.85),
      (dark.muted, groundOf('dark'), 4.82),
    ]) {
      expect(contrastRatio(fg, ground), closeTo(ratio, 0.01));
      expect(contrastRatio(fg, ground), greaterThanOrEqualTo(4.5));
    }
  });
}

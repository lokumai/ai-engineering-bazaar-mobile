import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  testWidgets('is the band token tall and spans the width', (tester) async {
    await tester.pumpWidget(themedApp(const Column(children: [LatticeBand()])));

    final size = tester.getSize(find.byType(LatticeBand));
    expect(size.height, BazaarLayout.band);
    expect(size.width, greaterThan(300));
  });

  testWidgets('is hidden from assistive technology', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(const Column(children: [LatticeBand()])));

    expect(find.descendant(of: find.byType(LatticeBand), matching: find.byType(ExcludeSemantics)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('paints the dark third stripe in dark mode', (tester) async {
    await tester.pumpWidget(themedApp(const Column(children: [LatticeBand()]), brightness: Brightness.dark));

    final paint = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(LatticeBand), matching: find.byType(CustomPaint)),
    );
    expect((paint.painter! as LatticeBandPainter).bandC, BazaarColors.dark.bandC);
  });

  test('repaints only when the third stripe changes', () {
    const light = LatticeBandPainter(bandC: Color(0xff000001));
    expect(light.shouldRepaint(const LatticeBandPainter(bandC: Color(0xff000001))), isFalse);
    expect(light.shouldRepaint(const LatticeBandPainter(bandC: Color(0xff000002))), isTrue);
  });
}

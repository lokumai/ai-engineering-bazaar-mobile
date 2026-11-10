import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  const fill = Color(0xff2f8c86);
  const now = Color(0xff282864);

  List<Color?> segmentColours(WidgetTester tester) => [
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(SegmentMeter), matching: find.byType(DecoratedBox)),
    ))
      (box.decoration as BoxDecoration).color,
  ];

  testWidgets('draws one segment per item, the done ones filled and the current one marked', (tester) async {
    await tester.pumpWidget(
      themedApp(
        const SegmentMeter(done: 2, total: 5, color: fill, current: 2, currentColor: now, semanticLabel: 'Question 3'),
      ),
    );

    final track = BazaarColors.light.surfaceSunken;
    expect(segmentColours(tester), [fill, fill, now, track, track]);
  });

  testWidgets('every segment is as tall as the meter', (tester) async {
    await tester.pumpWidget(themedApp(const SegmentMeter(done: 1, total: 3, color: fill, semanticLabel: '')));

    for (final element
        in find.descendant(of: find.byType(SegmentMeter), matching: find.byType(DecoratedBox)).evaluate()) {
      expect(element.size!.height, 6);
    }
  });

  testWidgets('is one image named by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themedApp(const SegmentMeter(done: 1, total: 8, color: fill, semanticLabel: '1 of 8 modules completed')),
    );

    expect(
      tester.getSemantics(find.byType(SegmentMeter)),
      matchesSemantics(label: '1 of 8 modules completed', isImage: true),
    );
    handle.dispose();
  });
}

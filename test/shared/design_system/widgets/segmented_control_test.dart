import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/themed_app.dart';

void main() {
  Widget control({required String selected, required ValueChanged<String> onSelected, List<String>? labels}) =>
      StatefulBuilder(
        builder: (context, setState) => BazaarSegmentedControl<String>(
          semanticLabel: 'Status',
          selected: selected,
          onSelected: onSelected,
          segments: [
            for (final label in labels ?? const ['All', 'Completed']) BazaarSegment(value: label, label: label),
          ],
        ),
      );

  testWidgets('a tap on another segment chooses it; a tap on the chosen one does nothing', (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(themedApp(control(selected: 'All', onSelected: chosen.add)));

    await tester.tap(find.text('Completed'));
    await tester.tap(find.text('All'));

    expect(chosen, ['Completed']);
  });

  testWidgets('the group is named and the chosen segment is a selected button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(control(selected: 'All', onSelected: (_) {})));

    expect(find.bySemanticsLabel('Status'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('All')),
      matchesSemantics(
        label: 'All',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Completed')),
      matchesSemantics(
        label: 'Completed',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('is as tall as a segment, not as the page', (tester) async {
    await tester.pumpWidget(themedApp(control(selected: 'All', onSelected: (_) {})));

    expect(tester.getSize(find.byType(BazaarSegmentedControl<String>)).height, lessThan(80));
  });

  testWidgets('shares the width when the labels fit', (tester) async {
    await tester.pumpWidget(themedApp(control(selected: 'All', onSelected: (_) {})));

    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('scrolls sideways when the labels do not fit, at text scale 2', (tester) async {
    const labels = ['All', 'Ready', 'Planned', 'Completed', 'Not completed'];
    await pumpAtTextScale(tester, themedApp(control(selected: 'All', onSelected: (_) {}, labels: labels)), scale: 2);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets the platform guidelines', (tester) async {
    final platform = defaultTargetPlatform;
    await pumpAtTextScale(
      tester,
      themedApp(
        control(selected: 'All', onSelected: (_) {}),
        platform: platform,
      ),
      scale: 1,
    );

    await expectPlatformGuidelines(tester, platform: platform);
  }, variant: bazaarPlatforms);
}

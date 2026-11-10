import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  test('each shape has the web corners', () {
    expect(BazaarCard.radiusOf(BazaarCardShape.plain), const BorderRadius.all(BazaarRadii.lg));
    expect(BazaarCard.radiusOf(BazaarCardShape.arch), BazaarShapes.arch);
    expect(BazaarCard.radiusOf(BazaarCardShape.leaf), BazaarShapes.leaf);
  });

  testWidgets('a card with onTap is one button named by its label', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      themedApp(BazaarCard(onTap: () => taps++, semanticLabel: 'Open the level', child: const Text('Alpha'))),
    );

    expect(
      tester.getSemantics(find.byType(BazaarCard)),
      matchesSemantics(label: 'Open the level', isButton: true, hasTapAction: true),
    );
    await tester.tap(find.byType(BazaarCard));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a card without onTap is no button and keeps its texts', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(const BazaarCard(child: Text('Alpha'))));

    expect(find.byType(InkWell), findsNothing);
    expect(find.bySemanticsLabel('Alpha'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('draws its accent along the top', (tester) async {
    await tester.pumpWidget(themedApp(const BazaarCard(accent: Color(0xff2f8c86), child: Text('Alpha'))));

    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(BazaarCard), matching: find.byType(DecoratedBox)).first,
    );
    expect(((box.decoration as BoxDecoration).border! as Border).top.color, const Color(0xff2f8c86));
  });
}

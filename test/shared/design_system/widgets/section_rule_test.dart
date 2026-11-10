import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  testWidgets('the title is a header and the rule runs to the end of the line', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(const SectionRule(title: 'Levels')));

    expect(tester.getSemantics(find.text('Levels')), matchesSemantics(label: 'Levels', isHeader: true));
    expect(tester.getTopRight(find.byType(DashedRule)).dx, tester.getTopRight(find.byType(SectionRule)).dx);
    expect(tester.getTopLeft(find.byType(DashedRule)).dx, tester.getTopLeft(find.byType(SectionRule)).dx);
    handle.dispose();
  });

  testWidgets('a long title wraps beside a rule that keeps its place', (tester) async {
    await tester.pumpWidget(themedApp(SectionRule(title: 'Levels ' * 20)));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashedRule), findsOneWidget);
  });
}

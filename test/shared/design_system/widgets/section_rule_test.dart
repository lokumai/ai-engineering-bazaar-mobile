import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  testWidgets('the title is a header and the rule fills the rest of the line', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(const SectionRule(title: 'Levels')));

    expect(tester.getSemantics(find.text('Levels')), matchesSemantics(label: 'Levels', isHeader: true));
    final rule = tester.getSize(find.byType(DashedRule));
    expect(rule.width, greaterThan(tester.getSize(find.text('Levels')).width));
    handle.dispose();
  });

  testWidgets('a long title wraps beside a rule that keeps its place', (tester) async {
    await tester.pumpWidget(themedApp(SectionRule(title: 'Levels ' * 20)));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashedRule), findsOneWidget);
  });
}

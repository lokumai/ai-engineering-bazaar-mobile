import 'package:flutter_test/flutter_test.dart';

/// Opens the level behind [button], a level's button on the catalog or the Quiz tab, unless it is open already: the
/// level of the next module to read starts open.
Future<void> openFold(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  if (isSemantics(isExpanded: true, hasExpandedState: true).matches(tester.getSemantics(button), {})) return;
  await tester.tap(button);
  await tester.pumpAndSettle();
}

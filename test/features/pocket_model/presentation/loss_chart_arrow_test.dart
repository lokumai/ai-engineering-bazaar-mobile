import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/training_panel.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

/// The release build's walk-through (review 11): after a module was read the loss rose, and its arrow still fell.
void main() {
  setUpAll(() => S.load(const Locale('en')));

  Future<void> chart(WidgetTester tester, List<LossPoint> curve) =>
      tester.pumpWidget(themedApp(LossChart(curve: curve)));

  testWidgets('the arrow falls with the loss, and rises when the last step rose', (tester) async {
    await chart(tester, const [(tokens: 10, loss: 5.0), (tokens: 20, loss: 4.36)]);
    expect(find.byIcon(Icons.south_east), findsOneWidget);

    await chart(tester, const [(tokens: 10, loss: 5.0), (tokens: 20, loss: 4.36), (tokens: 30, loss: 5.26)]);
    expect(find.byIcon(Icons.north_east), findsOneWidget);
    expect(find.byIcon(Icons.south_east), findsNothing);
  });

  test('one module read is one module, not modules', () {
    expect(S.current.pocket_stat_modules(1), 'module read');
    expect(S.current.pocket_stat_modules(2), 'modules read');
    expect(S.current.pocket_stat_tokens(1), 'token eaten');
  });
}

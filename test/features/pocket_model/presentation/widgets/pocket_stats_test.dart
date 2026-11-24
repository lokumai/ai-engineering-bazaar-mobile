import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/pocket_stats.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/themed_app.dart';

/// Review 7, finding 10: the stats' small labels sit on the sunken ground, where muted text is 4.2:1 in the light look.
void main() {
  testWidgets('the labels under the numbers are in the text colour', (tester) async {
    await tester.pumpWidget(themedApp(const PocketStats(model: PocketModel.fresh, known: 3)));

    final label = find.text('words known');
    expect(tester.widget<Text>(label).style?.color, tester.element(label).bazaarColors.onSurface);
  });
}

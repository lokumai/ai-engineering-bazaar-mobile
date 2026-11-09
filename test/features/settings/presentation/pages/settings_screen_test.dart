import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_app.dart';

void main() {
  testWidgets('shows the Settings title', (tester) async {
    await tester.pumpWidget(goldenScreen(const SettingsScreen()));

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}

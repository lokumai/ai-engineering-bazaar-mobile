import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Pumps one badge of [variant] under the dark Bazaar theme and returns its text colour, ground and border colour.
  Future<(Color?, Color?, Color?)> badge(WidgetTester tester, AppBadgeVariant variant) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: bazaarTheme(brightness: Brightness.dark, platform: TargetPlatform.android),
        home: Scaffold(
          body: Center(
            child: AppBadge(label: variant.name, variant: variant),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text(variant.name));
    final decoration =
        tester
                .widget<Container>(find.ancestor(of: find.text(variant.name), matching: find.byType(Container)).first)
                .decoration!
            as BoxDecoration;
    return (text.style?.color, decoration.color, (decoration.border as Border?)?.top.color);
  }

  testWidgets('the destructive badge keeps its text on-surface and marks the fault with its border (A18)', (
    tester,
  ) async {
    final (text, _, border) = await badge(tester, AppBadgeVariant.destructive);
    expect((text, border), (BazaarColors.dark.onSurface, BazaarColors.dark.fault));
  });

  testWidgets('the warning badge is on-caution text on caution', (tester) async {
    final (text, ground, _) = await badge(tester, AppBadgeVariant.warning);
    expect((text, ground), (BazaarFixedColors.onCaution, BazaarFixedColors.caution));
  });

  testWidgets('the success badge is on-surface text with a success border', (tester) async {
    final (text, _, border) = await badge(tester, AppBadgeVariant.success);
    expect((text, border), (BazaarColors.dark.onSurface, BazaarFixedColors.success));
  });
}

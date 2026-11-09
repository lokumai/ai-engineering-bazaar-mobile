import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/themed_app.dart';

void main() {
  Future<List<Color>> huesOf(WidgetTester tester, Brightness brightness) async {
    late List<Color> hues;
    await tester.pumpWidget(
      themedApp(
        Builder(
          builder: (context) {
            hues = [for (var position = 0; position < 6; position++) levelHue(context, position)];
            return const SizedBox();
          },
        ),
        brightness: brightness,
      ),
    );
    return hues;
  }

  testWidgets('binds each level position to its category colour, then cycles', (tester) async {
    final hues = await huesOf(tester, Brightness.light);

    expect(hues, [
      BazaarFixedColors.category1,
      BazaarColors.light.category2,
      BazaarColors.light.category3,
      BazaarFixedColors.category4,
      BazaarColors.light.category5,
      BazaarFixedColors.category1,
    ]);
  });

  testWidgets('takes the dark values of the themed categories in dark mode', (tester) async {
    final hues = await huesOf(tester, Brightness.dark);

    expect(hues[1], BazaarColors.dark.category2);
    expect(hues[2], BazaarColors.dark.category3);
    expect(hues[4], BazaarColors.dark.category5);
  });
}

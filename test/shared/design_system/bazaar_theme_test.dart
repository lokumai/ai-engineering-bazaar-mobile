import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/accessibility.dart';
import '../../support/contrast.dart';

void main() {
  test('the colour scheme maps the Bazaar tokens, error text in on-surface (A18)', () {
    for (final (brightness, c, o) in [
      (Brightness.light, BazaarColors.light, BazaarColors.dark),
      (Brightness.dark, BazaarColors.dark, BazaarColors.light),
    ]) {
      final theme = bazaarTheme(brightness: brightness, platform: TargetPlatform.android);
      final s = theme.colorScheme;
      expect(
        (s.brightness, s.primary, s.onPrimary, s.secondary, s.onSecondary),
        (brightness, c.primary, c.onPrimary, c.primary, c.onPrimary),
      );
      expect(
        (s.surface, s.onSurface, s.onSurfaceVariant, s.surfaceContainerHighest, s.surfaceContainer),
        (c.surface, c.onSurface, c.onSurfaceMuted, c.surfaceRaised, c.surfaceRaised),
      );
      expect(
        (s.error, s.onError, s.errorContainer, s.onErrorContainer),
        (c.onSurface, c.surface, c.surfaceRaised, c.onSurface),
      );
      expect(
        (s.outline, s.outlineVariant, s.inverseSurface, s.onInverseSurface, s.inversePrimary),
        (c.lineStrong, c.line, o.surface, o.onSurface, o.primary),
      );
      expect((theme.scaffoldBackgroundColor, theme.extension<BazaarColors>()), (c.surface, c));
      final input = theme.inputDecorationTheme;
      expect(
        (
          input.errorStyle!.color,
          (input.errorBorder! as OutlineInputBorder).borderSide.color,
          (input.focusedErrorBorder! as OutlineInputBorder).borderSide.color,
        ),
        (c.onSurface, c.fault, c.fault),
      );
      expect(
        (theme.appBarTheme.backgroundColor, theme.appBarTheme.foregroundColor),
        (BazaarFixedColors.bar, BazaarFixedColors.onBar),
      );
      expect(contrastRatio(s.error, s.surface), greaterThanOrEqualTo(4.5));
    }
  });

  test('the text theme takes the Bazaar steps, tracking as a factor of the style size (A27)', () {
    final t = bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android).textTheme;
    // The headings in the display face, at its own spacing, its weight and optical size on its axes.
    expect(
      (t.displaySmall!.fontSize, t.displaySmall!.height, t.displaySmall!.letterSpacing, t.displaySmall!.fontFamily),
      (BazaarType.display.size, BazaarType.display.height, 0.0, displayFamily),
    );
    expect(
      (t.headlineSmall!.fontSize, t.headlineSmall!.letterSpacing, t.headlineSmall!.fontFamily),
      (BazaarType.section.size, 0.0, displayFamily),
    );
    expect(t.titleLarge!.fontVariations, [
      const FontVariation('wght', 600),
      FontVariation('opsz', BazaarType.subsection.size),
    ]);
    expect(t.titleLarge!.fontFamilyFallback, [diagramFontFamily], reason: 'Persian falls back to Vazirmatn');
    expect(t.titleMedium!.fontFamily, isNot(displayFamily), reason: 'the text below the headings stays in the sans');
    expect(
      (t.bodyLarge!.fontSize, t.bodyLarge!.height, t.bodyLarge!.color),
      (BazaarType.body.size, BazaarType.body.height, BazaarColors.light.onSurface),
    );
    expect(
      (t.labelSmall!.fontSize, t.labelSmall!.letterSpacing),
      (BazaarType.label.size, BazaarType.trackingLabel * BazaarType.label.size),
    );
    expect((t.titleLarge!.fontWeight, t.bodyLarge!.fontWeight), (FontWeight.w600, FontWeight.w400));
  });

  test('the families follow the platform', () {
    expect(
      bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.iOS).textTheme.bodyLarge!.fontFamily,
      'Avenir Next',
    );
    expect(
      bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android).textTheme.bodyLarge!.fontFamily,
      'Roboto',
    );
  });

  test('page transitions honour reduced motion on both platforms', () {
    final builders = bazaarTheme(
      brightness: Brightness.light,
      platform: TargetPlatform.android,
    ).pageTransitionsTheme.builders;
    expect(
      (builders[TargetPlatform.android]! as ReducedMotionPageTransitionsBuilder).platformBuilder,
      isA<PredictiveBackPageTransitionsBuilder>(),
    );
    expect(
      (builders[TargetPlatform.iOS]! as ReducedMotionPageTransitionsBuilder).platformBuilder,
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });

  test('minTapTarget is 44 on iOS and 48 on Android', () {
    expect((minTapTarget(TargetPlatform.iOS), minTapTarget(TargetPlatform.android)), (44.0, 48.0));
  });

  for (final brightness in Brightness.values) {
    testWidgets('a sample page meets the tap-target, label and contrast guidelines (${brightness.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: bazaarTheme(brightness: brightness, platform: defaultTargetPlatform),
          home: Scaffold(
            body: ListView(
              children: [
                TextButton(onPressed: () {}, child: const Text('A')),
                // Align: a ListView child gets the full width, which would stretch the IconButton past its square.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(onPressed: () {}, tooltip: 'Back', icon: const Icon(Icons.arrow_back)),
                ),
                FilledButton(onPressed: () {}, child: const Text('Save')),
                CheckboxListTile(value: false, onChanged: (_) {}, title: const Text('Done')),
                const TextField(
                  decoration: InputDecoration(labelText: 'Word', errorText: 'Type the word'),
                ),
              ],
            ),
          ),
        ),
      );
      final target = minTapTarget(defaultTargetPlatform);
      expect(tester.getSize(find.byType(TextButton)).height, target);
      expect(tester.getSize(find.byType(IconButton)), Size.square(target));
      await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    }, variant: bazaarPlatforms);
  }

  testWidgets('context.bazaarColors reads the extension and fails loudly without it', (tester) async {
    late BazaarColors read;
    await tester.pumpWidget(
      MaterialApp(
        theme: bazaarTheme(brightness: Brightness.dark, platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            read = context.bazaarColors;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, BazaarColors.dark);

    // A new MaterialApp, so the theme does not animate from the Bazaar one (a lerp keeps its extension).
    late Object error;
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('plain'),
        theme: ThemeData(),
        home: Builder(
          builder: (context) {
            try {
              context.bazaarColors;
            } on StateError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      ),
    );
    expect(error, isA<StateError>());
  });
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bazaar_fonts.dart';
import 'bazaar_tokens.g.dart';
import 'reduced_motion.dart';
import 'type_step.dart';

/// The smallest tap target on [platform]: 44 on iOS, 48 elsewhere (spec 3.10, A28).
double minTapTarget(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? kMinInteractiveDimensionCupertino : kMinInteractiveDimension;

/// The app theme for [brightness] on [platform], built from the Bazaar tokens (spec 3.8).
///
/// No chromatic token is safe for text, so error and destructive text is on-surface and the fault colour marks only
/// edges and icons (A18). Text rests only on the pairs the web's contrast test checks.
ThemeData bazaarTheme({required Brightness brightness, required TargetPlatform platform}) {
  final (c, other) = switch (brightness) {
    Brightness.light => (BazaarColors.light, BazaarColors.dark),
    Brightness.dark => (BazaarColors.dark, BazaarColors.light),
  };
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.surfaceRaised,
    onPrimaryContainer: c.primary,
    secondary: c.primary,
    onSecondary: c.onPrimary,
    secondaryContainer: c.surfaceRaised,
    onSecondaryContainer: c.onSurface,
    tertiary: c.primary,
    onTertiary: c.onPrimary,
    error: c.onSurface,
    onError: c.surface,
    errorContainer: c.surfaceRaised,
    onErrorContainer: c.onSurface,
    surface: c.surface,
    onSurface: c.onSurface,
    onSurfaceVariant: c.onSurfaceMuted,
    surfaceContainerLowest: c.surfaceRaised,
    surfaceContainerLow: c.surfaceRaised,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceRaised,
    outline: c.lineStrong,
    outlineVariant: c.line,
    inverseSurface: other.surface,
    onInverseSurface: other.onSurface,
    inversePrimary: other.primary,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: platform,
    colorScheme: colorScheme,
    fontFamily: sansFamily(platform),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
  final target = minTapTarget(platform);
  const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.md));
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(BazaarRadii.md),
    borderSide: BorderSide(color: color, width: width),
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.surface,
    extensions: [c],
    textTheme: _textTheme(base.textTheme),
    appBarTheme: const AppBarThemeData(
      backgroundColor: BazaarFixedColors.bar,
      foregroundColor: BazaarFixedColors.onBar,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      border: border(c.line),
      enabledBorder: border(c.line),
      focusedBorder: border(c.focus, 2),
      errorBorder: border(c.fault),
      focusedErrorBorder: border(c.fault, 2),
      errorStyle: TextStyle(color: c.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(target, target),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(target, target),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: Size(target, target),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: Size.square(target), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ),
    dividerTheme: DividerThemeData(color: c.line),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ReducedMotionPageTransitionsBuilder(PredictiveBackPageTransitionsBuilder()),
        TargetPlatform.iOS: ReducedMotionPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      },
    ),
  );
}

/// The Material text styles on the Bazaar type steps: the step's size, its line height only when the web sets one, the
/// tracking factor times the size where a tracking token exists, and the weight (an app design choice).
TextTheme _textTheme(TextTheme base) {
  TextStyle? step(TextStyle? style, TypeStep step, FontWeight weight, [double? tracking]) => style?.copyWith(
    fontSize: step.size,
    height: step.height ?? style.height,
    letterSpacing: tracking == null ? style.letterSpacing : tracking * step.size,
    fontWeight: weight,
  );
  const w600 = FontWeight.w600;
  const w400 = FontWeight.w400;
  return base.copyWith(
    displayLarge: step(base.displayLarge, BazaarType.display, w600, BazaarType.trackingDisplay),
    displayMedium: step(base.displayMedium, BazaarType.display, w600, BazaarType.trackingDisplay),
    displaySmall: step(base.displaySmall, BazaarType.display, w600, BazaarType.trackingDisplay),
    headlineLarge: step(base.headlineLarge, BazaarType.section, w600, BazaarType.trackingSection),
    headlineMedium: step(base.headlineMedium, BazaarType.section, w600, BazaarType.trackingSection),
    headlineSmall: step(base.headlineSmall, BazaarType.section, w600, BazaarType.trackingSection),
    titleLarge: step(base.titleLarge, BazaarType.subsection, w600),
    titleMedium: step(base.titleMedium, BazaarType.item, w600),
    titleSmall: step(base.titleSmall, BazaarType.control, w600),
    bodyLarge: step(base.bodyLarge, BazaarType.body, w400),
    bodyMedium: step(base.bodyMedium, BazaarType.control, w400),
    bodySmall: step(base.bodySmall, BazaarType.meta, w400),
    labelLarge: step(base.labelLarge, BazaarType.control, w600),
    labelMedium: step(base.labelMedium, BazaarType.mark, w600),
    labelSmall: step(base.labelSmall, BazaarType.label, w600, BazaarType.trackingLabel),
  );
}

/// The Bazaar colours of the theme in [BuildContext].
extension BazaarThemeContext on BuildContext {
  /// The [BazaarColors] extension of the current theme; a [StateError] when the theme carries none, as a theme not
  /// built by [bazaarTheme] does.
  BazaarColors get bazaarColors {
    final colors = Theme.of(this).extension<BazaarColors>();
    if (colors == null) throw StateError('The theme carries no BazaarColors; build it with bazaarTheme');
    return colors;
  }
}

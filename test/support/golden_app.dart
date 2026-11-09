import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a screen for golden capture: full localization, the app theme, and a
/// phone-sized surface. Pass the screen already wrapped in its BlocProviders
/// (with mock BLoCs seeded to a loaded state). Use `dark: true` for the dark
/// variant.
Widget goldenScreen(Widget screen, {bool dark = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  locale: const Locale('en'),
  home: screen,
);

/// Standard phone surface for screen goldens.
const Size kGoldenScreenSize = Size(390, 844);

/// Pumps [widget] for an alchemist golden with the app's localizations, for a widget that reads `S.of(context)`.
/// Alchemist's own wrapper loads only the default Material, Widgets and Cupertino localizations. Pass it as
/// `goldenTest(pumpWidget: pumpWithLocalizations)`.
Future<void> pumpWithLocalizations(WidgetTester tester, Widget widget) => tester.pumpWidget(
  Localizations(
    locale: const Locale('en'),
    delegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    child: widget,
  ),
);

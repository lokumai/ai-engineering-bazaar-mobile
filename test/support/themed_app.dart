import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// [child] on a [Scaffold] under the app theme of [brightness] and [platform], with the app's localizations, for a
/// widget test of a piece that needs no bloc.
Widget themedApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.android,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: bazaarTheme(brightness: brightness, platform: platform),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: SafeArea(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

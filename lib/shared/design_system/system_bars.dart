import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The phone's bars over a page (plan 18.6): both see-through, the page drawn under them, and their icons dark on a
/// light ground or light on a dark one. iOS has only the status bar; on Android this also keeps the navigation bar off
/// a black band under a cream page, and its buttons or gesture handle readable on it.
SystemUiOverlayStyle systemBarsOn({required bool darkGround}) {
  final icons = darkGround ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: icons,
    // iOS names the status bar by its ground, not its icons.
    statusBarBrightness: darkGround ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: const Color(0x00000000),
    systemNavigationBarDividerColor: const Color(0x00000000),
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Draws the app under Android's bars, as Android 15 and later do anyway, so each page's ground shows through them
/// on older phones too (plan 18.6).
Future<void> drawUnderSystemBars() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

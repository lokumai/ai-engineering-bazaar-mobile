import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// The name of an appearance choice in the interface's language.
String appearanceName(S s, ThemeMode mode) => switch (mode) {
  ThemeMode.dark => s.appearance_dark,
  ThemeMode.light || ThemeMode.system => s.appearance_light,
};

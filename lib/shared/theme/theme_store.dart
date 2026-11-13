import 'package:flutter/material.dart' show ThemeMode;

/// The look the reader chose, kept on this device apart from the record: the theme cubit's port, which `lib/app/di/`
/// fills with the app's file flags.
abstract interface class IThemeStore {
  /// The mode chosen on this device, or null when none was chosen yet (the phone decides).
  Future<ThemeMode?> chosen();

  /// Keeps [mode] as the chosen mode.
  Future<void> choose(ThemeMode mode);
}

/// A store that keeps nothing: the choice lives in memory only.
final class MemoryThemeStore implements IThemeStore {
  const MemoryThemeStore();

  @override
  Future<ThemeMode?> chosen() async => null;

  @override
  Future<void> choose(ThemeMode mode) async {}
}

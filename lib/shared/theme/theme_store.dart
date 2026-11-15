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

/// The ground the phone shows while the app starts, before Flutter draws: the theme cubit names the look to it, so the
/// next launch opens on the page colour of the look the reader reads in, not on the app icon's (the owner,
/// 2026-11-15). `lib/app/di/` fills it with the native channel.
abstract interface class ILaunchGround {
  /// Makes the page colour of [mode] the ground of the next launch.
  Future<void> keep(ThemeMode mode);
}

/// A launch ground that names nothing to the phone.
final class NoLaunchGround implements ILaunchGround {
  const NoLaunchGround();

  @override
  Future<void> keep(ThemeMode mode) async {}
}

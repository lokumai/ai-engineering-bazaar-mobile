import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';

/// The app icon the reader chose, kept on this device apart from the record: the app icon cubit's port, which
/// `lib/app/di/` fills with the app's file flags.
abstract interface class IAppIconStore {
  /// The icon chosen on this device, or null when none was chosen yet.
  Future<BazaarIcon?> chosen();

  /// Keeps [icon] as the chosen icon.
  Future<void> choose(BazaarIcon icon);
}

/// Puts the chosen icon on the phone's home screen: the app icon cubit's port, which `lib/app/di/` fills with the
/// native channel.
abstract interface class IAppIconSwitch {
  /// Makes [icon] the app's icon; a failure is logged, never thrown.
  Future<void> choose(BazaarIcon icon);
}

/// A store that keeps nothing.
final class MemoryAppIconStore implements IAppIconStore {
  const MemoryAppIconStore();

  @override
  Future<BazaarIcon?> chosen() async => null;

  @override
  Future<void> choose(BazaarIcon icon) async {}
}

/// A switch that changes nothing.
final class NoAppIconSwitch implements IAppIconSwitch {
  const NoAppIconSwitch();

  @override
  Future<void> choose(BazaarIcon icon) async {}
}

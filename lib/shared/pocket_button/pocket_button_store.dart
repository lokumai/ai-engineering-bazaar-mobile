/// Whether the reader hid the pocket model's round button, kept on this device apart from the record: the port of
/// [PocketButtonCubit](pocket_button_cubit.dart), which `lib/app/di/` fills with the app's file flags.
abstract interface class IPocketButtonStore {
  /// Whether the button was hidden on this device.
  Future<bool> hidden();

  /// Keeps whether the button is [hidden].
  Future<void> hide({required bool hidden});
}

/// A store that keeps nothing: the choice lives in memory only.
final class MemoryPocketButtonStore implements IPocketButtonStore {
  MemoryPocketButtonStore({this.kept = false});

  bool kept;

  @override
  Future<bool> hidden() async => kept;

  @override
  Future<void> hide({required bool hidden}) async => kept = hidden;
}

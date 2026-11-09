/// Whether the Welcome screen was seen on this device: the welcome feature's port, which `lib/app/di/` fills with a
/// file flag outside the record (plan Phase 1I).
abstract interface class IWelcomeStore {
  /// Whether Welcome was entered once on this device.
  Future<bool> seen();

  /// Records that Welcome was entered.
  Future<void> markSeen();
}

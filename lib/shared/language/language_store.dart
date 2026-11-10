/// The language the reader chose, kept on this device apart from the record (plan 1Q): the language cubit's port,
/// which `lib/app/di/` fills with the app's file flags.
abstract interface class ILanguageStore {
  /// The language code chosen on this device, or null when none was chosen yet.
  Future<String?> chosen();

  /// Keeps [language] as the chosen language.
  Future<void> choose(String language);
}

/// A store that keeps nothing: the language lives in memory only.
final class MemoryLanguageStore implements ILanguageStore {
  const MemoryLanguageStore();

  @override
  Future<String?> chosen() async => null;

  @override
  Future<void> choose(String language) async {}
}

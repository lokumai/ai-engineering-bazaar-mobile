import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';

/// Where the reading settings are kept on this device, apart from the record: the reading style cubit's port, which
/// `lib/app/di/` fills with the app's file flags.
abstract interface class IReadingStyleStore {
  /// The style kept on this device; [ReadingStyle.standard] when none was chosen.
  Future<ReadingStyle> chosen();

  /// Keeps [style].
  Future<void> keep(ReadingStyle style);
}

/// A store that keeps the style in memory only, for tests and for a device without storage.
final class MemoryReadingStyleStore implements IReadingStyleStore {
  MemoryReadingStyleStore([this._style = ReadingStyle.standard]);

  ReadingStyle _style;

  @override
  Future<ReadingStyle> chosen() async => _style;

  @override
  Future<void> keep(ReadingStyle style) async => _style = style;
}

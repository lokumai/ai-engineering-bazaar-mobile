import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/shared/utils/serial_writes.dart';

/// The reader's reading settings (plan 12.5), changed on Settings' Reading settings page and drawn by the reader.
/// Each change is kept by the [IReadingStyleStore], one write at a time in the order made.
final class ReadingStyleCubit extends Cubit<ReadingStyle> {
  ReadingStyleCubit({IReadingStyleStore? store})
    : _store = store ?? MemoryReadingStyleStore(),
      super(ReadingStyle.standard);

  final IReadingStyleStore _store;
  final _writes = SerialWrites();

  /// Reads the kept style.
  Future<void> load() async {
    final kept = await _store.chosen();
    if (!isClosed && kept != state) emit(kept);
  }

  /// Makes [size] current and keeps it.
  Future<void> chooseSize(ReadingSize size) => _choose(state.copyWith(size: size));

  /// Makes [spacing] current and keeps it.
  Future<void> chooseSpacing(ReadingSpacing spacing) => _choose(state.copyWith(spacing: spacing));

  /// Goes back to the design's own size and spacing.
  Future<void> reset() => _choose(ReadingStyle.standard);

  Future<void> _choose(ReadingStyle style) async {
    if (style == state) return;
    emit(style);
    await _writes.run(() => _store.keep(style));
  }
}

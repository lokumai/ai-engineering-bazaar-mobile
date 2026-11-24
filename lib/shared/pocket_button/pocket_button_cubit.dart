import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/shared/utils/serial_writes.dart';

/// Whether the pocket model's round button shows on Home (plan 9.9): shown until the reader
/// hides it in Settings. Shared, because Settings changes it and the shell reads it; kept by the [IPocketButtonStore],
/// on this device and never in the record.
final class PocketButtonCubit extends Cubit<bool> {
  PocketButtonCubit({IPocketButtonStore? store}) : _store = store ?? MemoryPocketButtonStore(), super(true);

  final IPocketButtonStore _store;

  final _writes = SerialWrites();

  /// Whether the reader chose before the kept choice was read: the read then does not undo it (review 11,
  /// architecture 8).
  bool _chosen = false;

  /// Reads whether the button was hidden.
  Future<void> load() async {
    final hidden = await _store.hidden();
    if (!isClosed && !_chosen && hidden == state) emit(!hidden);
  }

  /// Shows the button or hides it, and keeps the choice; choices are written one at a time, in the order made.
  Future<void> show({required bool shown}) async {
    _chosen = true;
    if (shown == state) return;
    emit(shown);
    await _writes.run(() => _store.hide(hidden: !shown));
  }
}

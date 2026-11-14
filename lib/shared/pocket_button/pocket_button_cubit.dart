import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the pocket model's round button shows on Home (plan 9.9): shown until the reader
/// hides it in Settings. Shared, because Settings changes it and the shell reads it; kept by the [IPocketButtonStore],
/// on this device and never in the record.
final class PocketButtonCubit extends Cubit<bool> {
  PocketButtonCubit({IPocketButtonStore? store}) : _store = store ?? MemoryPocketButtonStore(), super(true);

  final IPocketButtonStore _store;

  /// Reads whether the button was hidden.
  Future<void> load() async {
    final hidden = await _store.hidden();
    if (!isClosed && hidden == state) emit(!hidden);
  }

  /// Shows the button or hides it, and keeps the choice.
  Future<void> show({required bool shown}) async {
    if (shown == state) return;
    emit(shown);
    await _store.hide(hidden: !shown);
  }
}

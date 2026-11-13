import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The look of the app: light or dark. Until the reader chooses, it is dark, whatever the phone's setting (owner,
/// 2026-11-13); the reader can change it in Settings or on Welcome's first step.
///
/// The choice is kept by the [IThemeStore], on this device and never in the record.
final class ThemeChoiceCubit extends Cubit<ThemeMode> {
  ThemeChoiceCubit({this._store = const MemoryThemeStore()}) : super(ThemeMode.dark);

  final IThemeStore _store;

  /// The modes a control offers, in order.
  static const modes = [ThemeMode.light, ThemeMode.dark];

  /// Reads the chosen mode, if one was chosen, and makes it current.
  Future<void> load() async {
    final chosen = await _store.chosen();
    if (chosen != null && !isClosed && chosen != state) emit(chosen);
  }

  /// Makes [mode] current and keeps it as the reader's choice.
  Future<void> choose(ThemeMode mode) async {
    if (mode != state) emit(mode);
    // One choice is written at a time, in the order made: the store clears the other flags before it keeps this one,
    // so two quick choices written at once could leave both kept.
    final previous = _saving;
    final saving = _saving = () async {
      // A write that failed was logged by the store; the next one still runs.
      await previous.catchError((Object _) {});
      await _store.choose(mode);
    }();
    await saving;
  }

  /// The write of the last choice, which the next one waits for.
  Future<void> _saving = Future<void>.value();
}

import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The look of the app: light or dark. Until the reader chooses, it is light, whatever the phone's setting (owner,
/// 2026-11-16, dark until then); the reader can change it in Settings or on Welcome's first step.
///
/// The choice is kept by the [IThemeStore], on this device and never in the record, and named to the [ILaunchGround],
/// so the phone opens the next launch on its page colour.
///
/// The boot reads the kept choice before the app's first frame and passes it as [initial], so the first frame is
/// already in it; without it the cubit starts light and [load] reads it.
final class ThemeChoiceCubit extends Cubit<ThemeMode> {
  ThemeChoiceCubit({this._store = const MemoryThemeStore(), this._ground = const NoLaunchGround(), ThemeMode? initial})
    : _read = initial != null,
      super(initial ?? ThemeMode.light);

  final IThemeStore _store;
  final ILaunchGround _ground;

  /// Whether the kept choice was read (by the boot, or by [load]).
  bool _read;

  /// The modes a control offers, in order.
  static const modes = [ThemeMode.light, ThemeMode.dark];

  /// Reads the chosen mode, if one was chosen and the boot did not read it, makes it current and names it to the
  /// launch ground.
  Future<void> load() async {
    if (!_read) {
      final chosen = await _store.chosen();
      _read = true;
      if (chosen != null && !isClosed && chosen != state) emit(chosen);
    }
    final mode = state;
    await _queue(() => _ground.keep(mode));
  }

  /// Makes [mode] current and keeps it as the reader's choice.
  Future<void> choose(ThemeMode mode) async {
    if (mode != state) emit(mode);
    // One choice is written at a time, in the order made: the store clears the other flags before it keeps this one,
    // so two quick choices written at once could leave both kept.
    await _queue(() async {
      await _store.choose(mode);
      await _ground.keep(mode);
    });
  }

  /// Runs [work] after the work queued before it.
  Future<void> _queue(Future<void> Function() work) async {
    final previous = _saving;
    final saving = _saving = () async {
      // A write that failed was logged by the store or the channel; the next one still runs.
      await previous.catchError((Object _) {});
      await work();
    }();
    await saving;
  }

  /// The write of the last choice, which the next one waits for.
  Future<void> _saving = Future<void>.value();
}

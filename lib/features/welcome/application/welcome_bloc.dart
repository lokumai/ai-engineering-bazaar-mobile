import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';

/// Shows Welcome on the first launch only (plan Phase 1I): it asks the [IWelcomeStore] at start, and entering the
/// bazaar records it, so the next launch opens Home directly.
///
/// A Bloc rather than a Cubit, since it touches storage (`CLAUDE.md`, Bloc vs Cubit).
class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc({required this._store}) : super(const WelcomeChecking()) {
    on<WelcomeStarted>(_onStarted);
    on<WelcomeEntered>(_onEntered);
  }

  final IWelcomeStore _store;

  Future<void> _onStarted(WelcomeStarted event, Emitter<WelcomeState> emit) async {
    emit(await _store.seen() ? const WelcomeDone() : const WelcomeShowing());
  }

  /// The app opens at once; the flag is written behind it.
  Future<void> _onEntered(WelcomeEntered event, Emitter<WelcomeState> emit) async {
    if (state is! WelcomeShowing) return;
    emit(const WelcomeDone());
    await _store.markSeen();
  }
}

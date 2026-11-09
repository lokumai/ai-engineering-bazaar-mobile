import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';

/// Steps through Welcome on the first launch only (plan Phase 1I): it asks the [IWelcomeStore] at start; a first
/// launch asks for the language and the track (plan 1L, 1S), then a short guide says how the bazaar works (plan 1X);
/// reading it records Welcome as seen, so the next launch opens Home directly. The gate that plays as the app opens
/// is not a step (plan 1Y).
/// The chosen track itself is kept by the track cubit; this bloc only steps through the screens.
///
/// A Bloc rather than a Cubit, since it touches storage (`CLAUDE.md`, Bloc vs Cubit).
class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc({required this._store}) : super(const WelcomeChecking()) {
    on<WelcomeStarted>(_onStarted);
    on<WelcomeTrackChosen>(_onTrackChosen);
    on<WelcomeIntroRead>(_onIntroRead);
  }

  final IWelcomeStore _store;

  Future<void> _onStarted(WelcomeStarted event, Emitter<WelcomeState> emit) async {
    emit(await _store.seen() ? const WelcomeDone() : const WelcomeChoosingTrack());
  }

  void _onTrackChosen(WelcomeTrackChosen event, Emitter<WelcomeState> emit) {
    if (state is WelcomeChoosingTrack) emit(const WelcomeIntroducing());
  }

  /// The app opens at once; the flag is written behind it.
  Future<void> _onIntroRead(WelcomeIntroRead event, Emitter<WelcomeState> emit) async {
    if (state is! WelcomeIntroducing) return;
    emit(const WelcomeDone());
    await _store.markSeen();
  }
}

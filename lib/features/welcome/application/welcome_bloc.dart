import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';

/// Steps through Welcome on the first launch only (plan Phase 1I): it asks the [IWelcomeStore] at start; a first
/// launch tells the story of the Bazaar when the content has one (plan 3.5), then asks for the language and the track
/// (plan 1L, 1S); choosing them records Welcome as seen, so the next launch opens Home directly. How the bazaar works,
/// Welcome's guide before the story (plan 1X), lives in Settings. The gate that plays as the app opens is not a step
/// (plan 1Y). The chosen track itself is kept by the track cubit; this bloc only steps through the screens.
///
/// A Bloc rather than a Cubit, since it touches storage (`CLAUDE.md`, Bloc vs Cubit).
class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc({required this._store}) : super(const WelcomeChecking()) {
    on<WelcomeStarted>(_onStarted);
    on<WelcomeStoryRead>(_onStoryRead);
    on<WelcomeTrackChosen>(_onTrackChosen);
  }

  final IWelcomeStore _store;

  Future<void> _onStarted(WelcomeStarted event, Emitter<WelcomeState> emit) async {
    if (await _store.seen()) {
      emit(const WelcomeDone());
    } else {
      emit(event.story ? const WelcomeTellingStory() : const WelcomeChoosingTrack());
    }
  }

  void _onStoryRead(WelcomeStoryRead event, Emitter<WelcomeState> emit) {
    if (state is WelcomeTellingStory) emit(const WelcomeChoosingTrack());
  }

  /// The app opens at once; the flag is written behind it.
  Future<void> _onTrackChosen(WelcomeTrackChosen event, Emitter<WelcomeState> emit) async {
    if (state is! WelcomeChoosingTrack) return;
    emit(const WelcomeDone());
    await _store.markSeen();
  }
}

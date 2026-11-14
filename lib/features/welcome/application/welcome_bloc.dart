import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';

/// Steps through Welcome on the first launch only (plan Phase 1I): it asks the [IWelcomeStore] at start; a first launch
/// asks for the language and the track first (plan 1L, 1S); Start learning opens the app there, and the story button
/// tells the story of the Bazaar in the language chosen when the content has one (plan 3.5; the owner, 2026-11-15).
/// Once the app opens Welcome is recorded as seen, so the next launch opens Home directly. A launch left during the
/// story asks again, the choices already made kept. How the bazaar works, Welcome's guide before the story (plan 1X),
/// lives in Settings. The gate that plays as the app opens is not a step (plan 1Y). The chosen track itself is kept by
/// the track cubit; this bloc only steps through the screens.
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
      emit(WelcomeChoosingTrack(story: event.story));
    }
  }

  /// The story follows when the reader asked for it and there is one; else the app opens at once and the flag is
  /// written behind it.
  Future<void> _onTrackChosen(WelcomeTrackChosen event, Emitter<WelcomeState> emit) async {
    final current = state;
    if (current is! WelcomeChoosingTrack) return;
    if (event.story && current.story) {
      emit(WelcomeTellingStory(track: event.track));
    } else {
      await _finish(emit, event.track);
    }
  }

  /// The story was read or skipped: the app opens at once and the flag is written behind it.
  Future<void> _onStoryRead(WelcomeStoryRead event, Emitter<WelcomeState> emit) async {
    final current = state;
    if (current is WelcomeTellingStory) await _finish(emit, current.track);
  }

  Future<void> _finish(Emitter<WelcomeState> emit, Track track) async {
    emit(WelcomeDone(chosen: track));
    await _store.markSeen();
  }
}

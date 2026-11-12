part of 'welcome_bloc.dart';

sealed class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

/// The app started: whether Welcome was seen is asked once; [story] says whether the content has a story to tell after
/// the language and the track (web D125).
final class WelcomeStarted extends WelcomeEvent {
  const WelcomeStarted({this.story = false});

  final bool story;

  @override
  List<Object?> get props => [story];
}

/// The story was read or skipped: Welcome is done.
final class WelcomeStoryRead extends WelcomeEvent {
  const WelcomeStoryRead();
}

/// The language and [track] were chosen: the story follows when there is one, else Welcome is done.
final class WelcomeTrackChosen extends WelcomeEvent {
  const WelcomeTrackChosen(this.track);

  final Track track;

  @override
  List<Object?> get props => [track];
}

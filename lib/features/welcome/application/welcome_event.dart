part of 'welcome_bloc.dart';

sealed class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

/// The app started: whether Welcome was seen is asked once; [story] says whether the content has a story to tell
/// first (web D125).
final class WelcomeStarted extends WelcomeEvent {
  const WelcomeStarted({this.story = false});

  final bool story;

  @override
  List<Object?> get props => [story];
}

/// The story was read: the language and the track follow.
final class WelcomeStoryRead extends WelcomeEvent {
  const WelcomeStoryRead();
}

/// A track was chosen: Welcome is done.
final class WelcomeTrackChosen extends WelcomeEvent {
  const WelcomeTrackChosen();
}

part of 'welcome_bloc.dart';

sealed class WelcomeState extends Equatable {
  const WelcomeState();

  @override
  List<Object?> get props => [];
}

/// Whether Welcome was seen is not known yet.
final class WelcomeChecking extends WelcomeState {
  const WelcomeChecking();
}

/// The first launch opens on the language and a track (plan 1L, 1Y); [story] says whether the story follows.
final class WelcomeChoosingTrack extends WelcomeState {
  const WelcomeChoosingTrack({this.story = false});

  final bool story;

  @override
  List<Object?> get props => [story];
}

/// The story of the Bazaar, in the language just chosen (plan 3.5); [track] is the one chosen before it.
final class WelcomeTellingStory extends WelcomeState {
  const WelcomeTellingStory({required this.track});

  final Track track;

  @override
  List<Object?> get props => [track];
}

/// Welcome was seen: the app is shown. [chosen] is the track chosen on this launch, null on a launch that skips
/// Welcome.
final class WelcomeDone extends WelcomeState {
  const WelcomeDone({this.chosen});

  final Track? chosen;

  @override
  List<Object?> get props => [chosen];
}

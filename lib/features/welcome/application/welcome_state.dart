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

/// The first launch opens on the story of the Bazaar (plan 3.5).
final class WelcomeTellingStory extends WelcomeState {
  const WelcomeTellingStory();
}

/// The reader chooses the language and a track (plan 1L, 1Y), after the story.
final class WelcomeChoosingTrack extends WelcomeState {
  const WelcomeChoosingTrack();
}

/// Welcome was seen: the app is shown.
final class WelcomeDone extends WelcomeState {
  const WelcomeDone();
}

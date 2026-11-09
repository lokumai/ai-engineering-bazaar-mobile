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

/// The first launch: the reader chooses the language and a track (plan 1L, 1Y).
final class WelcomeChoosingTrack extends WelcomeState {
  const WelcomeChoosingTrack();
}

/// A track was chosen: the first-launch guide says how the bazaar works (plan 1X).
final class WelcomeIntroducing extends WelcomeState {
  const WelcomeIntroducing();
}

/// Welcome was seen: the app is shown.
final class WelcomeDone extends WelcomeState {
  const WelcomeDone();
}

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

/// The first launch: Welcome is shown.
final class WelcomeShowing extends WelcomeState {
  const WelcomeShowing();
}

/// Welcome was seen: the app is shown.
final class WelcomeDone extends WelcomeState {
  const WelcomeDone();
}

part of 'welcome_bloc.dart';

sealed class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

/// The app started: whether Welcome was seen is asked once.
final class WelcomeStarted extends WelcomeEvent {
  const WelcomeStarted();
}

/// Enter the bazaar was tapped.
final class WelcomeEntered extends WelcomeEvent {
  const WelcomeEntered();
}

/// A track was chosen: the guide follows.
final class WelcomeTrackChosen extends WelcomeEvent {
  const WelcomeTrackChosen();
}

/// The guide was read: Welcome is done.
final class WelcomeIntroRead extends WelcomeEvent {
  const WelcomeIntroRead();
}

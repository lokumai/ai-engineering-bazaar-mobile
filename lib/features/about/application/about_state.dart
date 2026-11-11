part of 'about_bloc.dart';

sealed class AboutState extends Equatable {
  const AboutState();

  @override
  List<Object?> get props => [];
}

final class AboutLoading extends AboutState {
  const AboutLoading();
}

final class AboutReady extends AboutState {
  const AboutReady({required this.story});

  final StoryDoc story;

  @override
  List<Object?> get props => [story];
}

/// The content names no story: a copy of the course from before the site published it (web D125).
final class AboutAbsent extends AboutState {
  const AboutAbsent();
}

/// The story's document could not be read.
final class AboutFailed extends AboutState {
  const AboutFailed();
}

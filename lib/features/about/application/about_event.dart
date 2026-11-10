part of 'about_bloc.dart';

sealed class AboutEvent extends Equatable {
  const AboutEvent();

  @override
  List<Object?> get props => [];
}

/// The story was opened, to read in [language] (English where it is not written in it).
final class AboutOpened extends AboutEvent {
  const AboutOpened({required this.language});

  final String language;

  @override
  List<Object?> get props => [language];
}

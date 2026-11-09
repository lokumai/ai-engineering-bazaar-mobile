part of 'module_reader_bloc.dart';

sealed class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

/// The reader opened the module [key] in [track], to read in [language] (English where it has no such document).
final class ReaderOpened extends ReaderEvent {
  const ReaderOpened({required this.key, required this.track, this.language = 'en'});

  final String key;
  final Track track;
  final String language;

  @override
  List<Object?> get props => [key, track, language];
}

/// The reader toggled the completion of the open module; it is forwarded to the record (Decision A35).
final class ReaderCompletionToggled extends ReaderEvent {
  const ReaderCompletionToggled();
}

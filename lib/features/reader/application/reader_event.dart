part of 'module_reader_bloc.dart';

sealed class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

/// The reader opened the module [key] in [track].
final class ReaderOpened extends ReaderEvent {
  const ReaderOpened({required this.key, required this.track});

  final String key;
  final Track track;

  @override
  List<Object?> get props => [key, track];
}

/// The reader toggled the completion of the open module; it is forwarded to the record (Decision A35).
final class ReaderCompletionToggled extends ReaderEvent {
  const ReaderCompletionToggled();
}

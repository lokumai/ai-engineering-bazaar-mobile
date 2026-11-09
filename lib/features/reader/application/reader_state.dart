part of 'module_reader_bloc.dart';

sealed class ReaderState extends Equatable {
  const ReaderState();

  @override
  List<Object?> get props => [];
}

/// The module document is being read.
final class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

/// A module written in its track: [doc] has a body. [moduleCount] is the number of modules in the index.
final class ReaderWritten extends ReaderState {
  const ReaderWritten({required this.doc, required this.entry, required this.moduleCount});

  final ModuleDoc doc;
  final ModuleEntry entry;
  final int moduleCount;

  @override
  List<Object?> get props => [doc, entry, moduleCount];
}

/// A planned module: [doc] carries a draft and no body.
final class ReaderPlanned extends ReaderState {
  const ReaderPlanned({required this.doc, required this.entry, required this.moduleCount});

  final ModuleDoc doc;
  final ModuleEntry entry;
  final int moduleCount;

  @override
  List<Object?> get props => [doc, entry, moduleCount];
}

/// The For Everyone version of [entry] has no document yet.
final class ReaderNotWritten extends ReaderState {
  const ReaderNotWritten({required this.entry});

  final ModuleEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// No module has this key, or its For Engineers track has no English document.
final class ReaderNotFound extends ReaderState {
  const ReaderNotFound();
}

/// The module document could not be read on this device.
final class ReaderFailed extends ReaderState {
  const ReaderFailed({required this.code});

  final ContentErrorCode code;

  @override
  List<Object?> get props => [code];
}

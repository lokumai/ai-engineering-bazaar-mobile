import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/completion_toggled.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';

part 'reader_event.dart';
part 'reader_state.dart';

/// Reads one module document in one track (spec 3.6.1) and forwards its completion to the record.
///
/// It keeps the [BundleIndex] it was opened with, so a refresh that lands while the module is open does not change it
/// (spec 3.4.4). A document that is missing, corrupt or does not parse is a [ReaderFailed]; any other error is a fault
/// and propagates to the bloc observer.
///
/// An interface class rather than a final one, so widget tests can provide a `MockBloc` that implements it.
interface class ModuleReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ModuleReaderBloc({required this._repository, required this._index, required this._recordBloc})
    : super(const ReaderLoading()) {
    on<ReaderOpened>(_onOpened);
    on<ReaderRetried>(_onRetried);
    on<ReaderCompletionToggled>(_onCompletionToggled);
  }

  static final _log = AppLogger.getLogger('ModuleReaderBloc');

  final IContentRepository _repository;
  final BundleIndex _index;
  final RecordBloc _recordBloc;

  /// The module last opened, which [ReaderRetried] reads again.
  ReaderOpened? _opened;

  Future<void> _onRetried(ReaderRetried event, Emitter<ReaderState> emit) async {
    final opened = _opened;
    if (opened == null || state is! ReaderFailed) return;
    emit(const ReaderLoading());
    await _onOpened(opened, emit);
  }

  Future<void> _onOpened(ReaderOpened event, Emitter<ReaderState> emit) async {
    _opened = event;
    final entry = _index.module(event.key);
    if (entry == null) {
      emit(const ReaderNotFound());
      return;
    }
    final docs = entry.tracks[event.track]?.docs;
    // A module not translated into the language opens in English, as the web does (plan 1Q).
    final path = docs?[event.language] ?? docs?['en'];
    if (path == null) {
      // Only For Everyone may lack a version; For Engineers always has one, so its absence is no module here.
      emit(event.track == Track.everyone ? ReaderNotWritten(entry: entry) : const ReaderNotFound());
      return;
    }
    final ModuleDoc doc;
    try {
      doc = await _repository.readModuleDoc(path);
    } on ContentMissingException catch (error) {
      _log.warn('module document {} unreadable: {}', [path, error]);
      emit(const ReaderFailed(code: ContentErrorCode.missing));
      return;
    } on ContentCorruptException catch (error) {
      _log.warn('module document {} unreadable: {}', [path, error]);
      emit(const ReaderFailed(code: ContentErrorCode.corrupt));
      return;
    } on ContentFormatException catch (error) {
      _log.warn('module document {} unreadable: {}', [path, error]);
      emit(const ReaderFailed(code: ContentErrorCode.format));
      return;
    }
    final moduleCount = _index.modules.length;
    emit(
      doc.body != null
          ? ReaderWritten(doc: doc, entry: entry, moduleCount: moduleCount)
          : ReaderPlanned(doc: doc, entry: entry, moduleCount: moduleCount),
    );
  }

  void _onCompletionToggled(ReaderCompletionToggled event, Emitter<ReaderState> emit) {
    final current = state;
    if (current is! ReaderWritten) {
      throw StateError('Only a written module can be completed, not in $current');
    }
    final doc = current.doc;
    _recordBloc.add(
      completionToggled(_index, doc.key, doc.track, revision: current.entry.tracks[doc.track]?.revision?.hash),
    );
  }
}

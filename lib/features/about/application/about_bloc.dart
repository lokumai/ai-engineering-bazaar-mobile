import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

part 'about_event.dart';
part 'about_state.dart';

/// Reads the story of the Bazaar (web D115, D125) for the About page and Welcome's second step (plan 3.5): the document
/// the index names in the reader's language, or in English, which is the only language it is written in today.
///
/// A Bloc rather than a Cubit, since it reads storage (`CLAUDE.md`, Bloc vs Cubit). A document that is missing, corrupt
/// or does not parse is an [AboutFailed]; any other error is a fault and propagates to the bloc observer.
class AboutBloc extends Bloc<AboutEvent, AboutState> {
  AboutBloc({required this._repository, required this._index}) : super(const AboutLoading()) {
    on<AboutOpened>(_onOpened);
  }

  static final _log = AppLogger.getLogger('AboutBloc');

  final IContentRepository _repository;
  final BundleIndex _index;

  Future<void> _onOpened(AboutOpened event, Emitter<AboutState> emit) async {
    final path = _index.storyIn(event.language);
    if (path == null) {
      emit(const AboutAbsent());
      return;
    }
    try {
      emit(AboutReady(story: await _repository.readStoryDoc(path)));
    } on ContentMissingException catch (error) {
      _fail(path, error, emit);
    } on ContentCorruptException catch (error) {
      _fail(path, error, emit);
    } on ContentFormatException catch (error) {
      _fail(path, error, emit);
    }
  }

  void _fail(String path, Object error, Emitter<AboutState> emit) {
    _log.warn('story document {} unreadable: {}', [path, error]);
    emit(const AboutFailed());
  }
}

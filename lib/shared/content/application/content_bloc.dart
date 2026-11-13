import 'dart:io';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';

part 'content_event.dart';
part 'content_state.dart';

/// Opens the course content at start and refreshes it from the site (spec 3.4.2 to 3.4.4).
///
/// [ContentStarted] opens the repository and then asks for one refresh; Settings asks for more with
/// [ContentRefreshRequested]. A request that arrives while a refresh runs is dropped.
///
/// An interface class rather than a final one, so widget tests can provide a `MockBloc` that implements it.
interface class ContentBloc extends Bloc<ContentEvent, ContentState> {
  ContentBloc({required this._repository}) : super(const ContentLoading()) {
    on<ContentStarted>(_onStarted);
    on<ContentRefreshRequested>(_onRefreshRequested, transformer: droppable());
  }

  static final _log = AppLogger.getLogger('ContentBloc');

  final IContentRepository _repository;

  Future<void> _onStarted(ContentStarted event, Emitter<ContentState> emit) async {
    final ContentOpening opening;
    try {
      opening = await _repository.open();
    } on ContentFormatException catch (error) {
      _log.error('bundled content unreadable: {}', [error]);
      emit(const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable));
      return;
    } on ContentMissingException catch (error) {
      _log.error('bundled content unreadable: {}', [error]);
      emit(const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable));
      return;
    } on FileSystemException catch (error) {
      _log.error('content store unusable: {}', [error]);
      emit(const ContentBroken(code: ContentErrorCode.storage));
      return;
    } on Object catch (error, stack) {
      // Anything else, such as the platform refusing the cache directory, ends on the notice too and not on the
      // loading page for ever.
      _log.error('content could not be opened: {}\n{}', [error, stack]);
      emit(const ContentBroken(code: ContentErrorCode.storage));
      return;
    }
    emit(
      ContentReady(index: opening.index, origin: opening.origin, notice: opening.notice, refresh: const RefreshIdle()),
    );
    add(const ContentRefreshRequested());
  }

  Future<void> _onRefreshRequested(ContentRefreshRequested event, Emitter<ContentState> emit) async {
    final current = state;
    if (current is! ContentReady) return;
    emit(current.withRefresh(const RefreshChecking()));

    final RefreshOutcome outcome;
    try {
      outcome = await _repository.refresh();
    } on Object catch (error, stack) {
      // An error the repository does not name ends the check too, or Check for updates would stay disabled until the
      // next launch. The content in use is kept.
      _log.error('content refresh failed: {}\n{}', [error, stack]);
      emit(current.withRefresh(const RefreshFailed(ContentErrorCode.storage)));
      return;
    }
    emit(switch (outcome) {
      ContentUpToDate() => current.withRefresh(const RefreshUpToDate()),
      ContentUpdated(:final index) => ContentReady(
        index: index,
        origin: ContentOrigin.downloaded,
        // The cache-discarded notice describes the content this update replaces (decision E7).
        notice: null,
        refresh: const RefreshUpdated(),
      ),
      ContentNeedsAppUpdate() => current.withRefresh(const RefreshNeedsAppUpdate()),
      ContentRefreshFailed(:final code) => current.withRefresh(RefreshFailed(code)),
    });
  }
}

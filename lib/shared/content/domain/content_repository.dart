import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

/// The course content on the device: the bundled snapshot, or a downloaded copy that replaced it (spec 3.4).
abstract interface class IContentRepository {
  /// Opens the content by the startup rule of spec 3.4.3.
  ///
  /// Throws [ContentFormatException] when the bundled index fails the parser.
  Future<ContentOpening> open();

  /// Checks the site for newer content (spec 3.4.4), against the current index.
  Future<RefreshOutcome> refresh();

  /// The bytes [sitePath] names in the current index, or else in the most recent index this session served before it,
  /// checked against its sha256: a page open during a refresh keeps its files (spec 3.4.3 row 6).
  ///
  /// Throws [ContentMissingException] when none of those indexes names it or the object is not on the device, and
  /// [ContentCorruptException] when the stored bytes do not match.
  Future<Uint8List> readObject(String sitePath);

  Future<ModuleDoc> readModuleDoc(String sitePath);

  Future<LevelDoc> readLevelDoc(String sitePath);

  /// The story document at [sitePath] (web D125), read as [readObject] reads a file.
  Future<StoryDoc> readStoryDoc(String sitePath);
}

/// Where the current content came from.
enum ContentOrigin { bundled, downloaded }

/// A notice shown on Settings and the progress page.
enum ContentNotice {
  /// The downloaded content could not be read and was deleted at startup.
  cacheDiscarded,
}

/// What [IContentRepository.open] found.
final class ContentOpening extends Equatable {
  const ContentOpening({required this.index, required this.origin, required this.notice});

  final BundleIndex index;
  final ContentOrigin origin;
  final ContentNotice? notice;

  @override
  List<Object?> get props => [index, origin, notice];
}

/// The result of [IContentRepository.refresh].
sealed class RefreshOutcome extends Equatable {
  const RefreshOutcome();

  @override
  List<Object?> get props => [];
}

/// The site publishes nothing newer than the current content.
final class ContentUpToDate extends RefreshOutcome {
  const ContentUpToDate();
}

/// Newer content was downloaded and is now current.
final class ContentUpdated extends RefreshOutcome {
  const ContentUpdated({required this.index});

  final BundleIndex index;

  @override
  List<Object?> get props => [index];
}

/// The site publishes no API major this app reads.
final class ContentNeedsAppUpdate extends RefreshOutcome {
  const ContentNeedsAppUpdate();
}

/// The refresh stopped; the current content is unchanged.
final class ContentRefreshFailed extends RefreshOutcome {
  const ContentRefreshFailed({required this.code});

  final ContentErrorCode code;

  @override
  List<Object?> get props => [code];
}

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';

/// The content repository over the bundled snapshot and the downloaded object store (spec 3.4.1).
///
/// The store lives at `<cacheRoot>/content/`, where `cacheRoot` is what `cacheDirectory` returned: `objects/<sha256>`,
/// `indexes/<contentVersion>.json`, `current` (the current `contentVersion`) and `corrupt` (the marker a mismatched
/// object leaves for the next start). `cacheDirectory` is resolved once, at the start of [open], so the repository
/// can be built synchronously; every other method throws a [StateError] until [open] has completed.
final class FileContentRepository implements IContentRepository {
  FileContentRepository({required this._bundled, required this._cacheDirectory});

  static final _log = AppLogger.getLogger('FileContentRepository');
  static final _contentVersion = RegExp(r'^[0-9a-f]{64}$');

  final BundledContent _bundled;
  final Future<Directory> Function() _cacheDirectory;

  _Opened? _opened;

  @override
  Future<ContentOpening> open() async {
    final bundledIndex = ContentParser.parseIndex(await _bundled.readIndex());
    final bundledObjects = {...bundledIndex.files.values, ...bundledIndex.images.values};
    final store = Directory('${(await _cacheDirectory()).path}/content');

    final (index, origin, notice) = await _startup(store, bundledIndex, bundledObjects);
    _opened = _Opened(store: store, index: index, bundledObjects: bundledObjects);
    return ContentOpening(index: index, origin: origin, notice: notice);
  }

  /// Spec 3.4.3 rows 2 to 6, after the bundled index parsed (row 1).
  Future<(BundleIndex, ContentOrigin, ContentNotice?)> _startup(
    Directory store,
    BundleIndex bundledIndex,
    Set<String> bundledObjects,
  ) async {
    const bundled = ContentOrigin.bundled;
    if (await File('${store.path}/corrupt').exists()) {
      await _discard(store, 'corrupt marker');
      return (bundledIndex, bundled, null);
    }
    final currentFile = File('${store.path}/current');
    if (!await currentFile.exists()) {
      if (await store.exists()) await _discard(store, 'no current pointer');
      return (bundledIndex, bundled, null);
    }

    final BundleIndex cacheIndex;
    try {
      cacheIndex = await _readCacheIndex(store, await currentFile.readAsString());
    } on Object catch (error) {
      if (error is! FileSystemException && error is! FormatException && error is! ContentFormatException) rethrow;
      _log.error('content cache index unreadable: {}', [error]);
      await _discard(store, 'unreadable index');
      return (bundledIndex, bundled, ContentNotice.cacheDiscarded);
    }

    if (!cacheIndex.publishedAtInstant.isAfter(bundledIndex.publishedAtInstant)) {
      await _discard(store, 'not newer than the bundle');
      return (bundledIndex, bundled, null);
    }

    final referenced = {...cacheIndex.files.values, ...cacheIndex.images.values};
    for (final sha256 in referenced.difference(bundledObjects)) {
      if (!await File('${store.path}/objects/$sha256').exists()) {
        await _discard(store, 'missing object');
        return (bundledIndex, bundled, null);
      }
    }

    await _deleteEntries(Directory('${store.path}/indexes'), keep: {'${cacheIndex.contentVersion}.json'});
    await _deleteEntries(Directory('${store.path}/objects'), keep: referenced);
    return (cacheIndex, ContentOrigin.downloaded, null);
  }

  /// Parses `indexes/<current>.json`; a pointer that is not a content version is unreadable.
  Future<BundleIndex> _readCacheIndex(Directory store, String current) async {
    if (!_contentVersion.hasMatch(current)) {
      throw const FormatException('current does not name a content version');
    }
    final bytes = await File('${store.path}/indexes/$current.json').readAsBytes();
    return ContentParser.parseIndex(utf8.decode(bytes));
  }

  Future<void> _discard(Directory store, String reason) async {
    _log.warn('content cache discarded: {}', [reason]);
    if (await store.exists()) await store.delete(recursive: true);
  }

  Future<void> _deleteEntries(Directory directory, {required Set<String> keep}) async {
    if (!await directory.exists()) return;
    await for (final entry in directory.list(followLinks: false)) {
      if (!keep.contains(entry.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty))) {
        await entry.delete(recursive: true);
      }
    }
  }

  @override
  Future<RefreshOutcome> refresh() async {
    _requireOpened();
    throw UnimplementedError('refresh arrives in Task 7.5');
  }

  @override
  Future<Uint8List> readObject(String sitePath) async {
    final opened = _requireOpened();
    final sha256Name = opened.index.sha256Of(sitePath);
    if (sha256Name == null) throw ContentMissingException(sitePath);

    if (opened.bundledObjects.contains(sha256Name)) {
      try {
        return await _bundled.readObject(sha256Name);
      } on FlutterError {
        throw ContentMissingException(sitePath);
      }
    }

    final Uint8List bytes;
    try {
      bytes = await File('${opened.store.path}/objects/$sha256Name').readAsBytes();
    } on PathNotFoundException {
      throw ContentMissingException(sitePath);
    }
    if (sha256.convert(bytes).toString() != sha256Name) {
      await File('${opened.store.path}/corrupt').writeAsString('');
      _log.error('content object does not match its sha256: {}', [sitePath]);
      throw ContentCorruptException(sitePath);
    }
    return bytes;
  }

  @override
  Future<ModuleDoc> readModuleDoc(String sitePath) async {
    final index = _requireOpened().index;
    final bytes = await readObject(sitePath);
    return ContentParser.parseModuleDoc(utf8.decode(bytes), index, path: sitePath);
  }

  @override
  Future<LevelDoc> readLevelDoc(String sitePath) async {
    final index = _requireOpened().index;
    final bytes = await readObject(sitePath);
    return ContentParser.parseLevelDoc(utf8.decode(bytes), index, path: sitePath);
  }

  _Opened _requireOpened() => _opened ?? (throw StateError('open() has not completed'));
}

/// What [FileContentRepository.open] settled: the store directory, the current index and the bundled sha256 set.
final class _Opened {
  const _Opened({required this.store, required this.index, required this.bundledObjects});

  final Directory store;
  final BundleIndex index;
  final Set<String> bundledObjects;
}

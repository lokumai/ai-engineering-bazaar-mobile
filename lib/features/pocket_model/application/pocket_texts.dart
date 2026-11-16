import 'dart:async';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/module_sentences.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// Where the pocket model reads a course module (plan 9.6).
abstract interface class IPocketTexts {
  /// The text of the module [key] in [language] (in English where it is not translated), its sentences and where its
  /// sections start, or null when it cannot be read: no such module, a planned one, or a storage error.
  Future<ModuleText?> text(String key, String language);
}

/// Reads a module's document from the course on this device, once the content is ready; For Engineers' document, or
/// For Everyone's where only that track has the module.
final class ContentPocketTexts implements IPocketTexts {
  ContentPocketTexts({required this._repository, required this._content});

  final IContentRepository _repository;
  final ContentBloc _content;
  static final _log = AppLogger.getLogger('ContentPocketTexts');

  @override
  Future<ModuleText?> text(String key, String language) async {
    try {
      final state = _content.state is ContentReady
          ? _content.state
          : await _content.stream.firstWhere((state) => state is ContentReady).timeout(const Duration(seconds: 20));
      if (state is! ContentReady) return null;
      final module = state.index.modules.where((module) => module.key == key).firstOrNull;
      if (module == null) return null;
      for (final track in [Track.engineers, Track.everyone]) {
        final docs = module.tracks[track]?.docs;
        final path = docs?[language] ?? docs?['en'];
        if (path == null) continue;
        final read = textOf(await _repository.readModuleDoc(path));
        if (read.sentences.isNotEmpty) return read;
      }
      return null;
    } on Object catch (error) {
      // A module it cannot read is one it does not read; the toy goes on.
      _log.warn('module {} not read by the pocket model: {}', [key, error]);
      return null;
    }
  }
}

/// Modules for tests: [texts] by key, each one section.
final class MemoryPocketTexts implements IPocketTexts {
  const MemoryPocketTexts(this.texts);

  final Map<String, List<List<String>>> texts;

  @override
  Future<ModuleText?> text(String key, String language) async => switch (texts[key]) {
    final sentences? => oneSection(sentences),
    null => null,
  };
}

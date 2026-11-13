import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// `api/index.json`: the API majors the site serves.
final class ApiMajors extends Equatable {
  const ApiMajors({required this.majors});

  final List<int> majors;

  @override
  List<Object?> get props => [majors];
}

/// `api/v1/index.json`, parsed by `ContentParser.parseIndex`.
///
/// Holds the known tracks only; a track this app does not know is left out (Decision A23).
final class BundleIndex extends Equatable {
  BundleIndex({
    required this.contentVersion,
    required this.publishedAt,
    required this.publishedAtInstant,
    required this.tracks,
    required this.diagramFont,
    required this.diagramThemes,
    required this.levels,
    required this.modules,
    required this.moved,
    required this.files,
    required this.images,
    this.story = const {},
  }) : _levelBySlug = {for (final level in levels) level.slug: level},
       _moduleByKey = {for (final module in modules) module.key: module};

  /// Opaque identity of the published content (64 lowercase hex).
  final String contentVersion;

  /// The publication time as the bundle writes it (`2026-01-02T03:04:05.000Z`).
  final String publishedAt;
  final DateTime publishedAtInstant;

  /// The tracks this app knows, in index order.
  final List<TrackInfo> tracks;
  final DiagramFont diagramFont;
  final DiagramThemes diagramThemes;

  /// Levels in curriculum order.
  final List<LevelEntry> levels;

  /// Modules in index order (by `number`).
  final List<ModuleEntry> modules;
  final Moved moved;

  /// Site path to sha256, for the documents and diagrams.
  final Map<String, String> files;

  /// Site path to sha256, for the figures and logos.
  final Map<String, String> images;

  /// The About page's story document per language it is written in (web D125); empty while the site publishes none.
  final Map<String, String> story;

  /// The story's document in [language], or in English when it is not written in [language]; null when there is none.
  String? storyIn(String language) => story[language] ?? story['en'];

  final Map<String, LevelEntry> _levelBySlug;
  final Map<String, ModuleEntry> _moduleByKey;

  ModuleEntry? module(String key) => _moduleByKey[key];

  LevelEntry? level(String slug) => _levelBySlug[slug];

  /// The sha256 of [sitePath], looked up in [files], then in [images]; null when the index does not name it.
  String? sha256Of(String sitePath) => files[sitePath] ?? images[sitePath];

  @override
  List<Object?> get props => [
    contentVersion,
    publishedAt,
    publishedAtInstant,
    tracks,
    diagramFont,
    diagramThemes,
    levels,
    modules,
    moved,
    files,
    images,
    story,
  ];

  /// Names the version only, so a logged state never prints the whole index.
  @override
  String toString() => 'BundleIndex($contentVersion, $publishedAt)';
}

/// One entry of the index's `tracks`: a track and the name to show for it.
final class TrackInfo extends Equatable {
  const TrackInfo({required this.track, required this.label});

  final Track track;
  final String label;

  @override
  List<Object?> get props => [track, label];
}

/// The font the diagrams are drawn with.
final class DiagramFont extends Equatable {
  const DiagramFont({required this.family, required this.sha256});

  final String family;
  final String sha256;

  @override
  List<Object?> get props => [family, sha256];
}

/// The diagram themes of the light and dark variants.
final class DiagramThemes extends Equatable {
  const DiagramThemes({required this.light, required this.dark});

  final DiagramTheme light;
  final DiagramTheme dark;

  @override
  List<Object?> get props => [light, dark];
}

/// One diagram variant: the Mermaid theme name and its ground as an opaque ARGB value.
final class DiagramTheme extends Equatable {
  const DiagramTheme({required this.theme, required this.backgroundArgb});

  final String theme;
  final int backgroundArgb;

  @override
  List<Object?> get props => [theme, backgroundArgb];
}

/// Old level slugs and module keys mapped to their new ones.
final class Moved extends Equatable {
  const Moved({required this.levels, required this.modules});

  final Map<String, String> levels;
  final Map<String, String> modules;

  @override
  List<Object?> get props => [levels, modules];
}

/// A level's status: a closed set.
enum LevelStatus { ready, draft }

/// One entry of the index's `levels`.
final class LevelEntry extends Equatable {
  const LevelEntry({
    required this.slug,
    required this.title,
    required this.status,
    required this.blurb,
    required this.total,
    required this.readme,
  });

  final String slug;
  final String title;
  final LevelStatus status;

  /// May be empty.
  final String blurb;

  /// Modules in the level, drafts included.
  final int total;

  /// Site path of the level document; null when the level has none.
  final String? readme;

  @override
  List<Object?> get props => [slug, title, status, blurb, total, readme];
}

/// One entry of the index's `modules`.
final class ModuleEntry extends Equatable {
  const ModuleEntry({
    required this.key,
    required this.level,
    required this.number,
    required this.minutes,
    required this.prerequisites,
    required this.tracks,
  });

  /// `<level>/<module>`, also the record key.
  final String key;
  final String level;
  final int number;
  final int minutes;

  /// Module keys.
  final List<String> prerequisites;

  /// The known tracks; both are always present.
  final Map<Track, ModuleTrack> tracks;

  @override
  List<Object?> get props => [key, level, number, minutes, prerequisites, tracks];
}

/// One module in one track.
final class ModuleTrack extends Equatable {
  const ModuleTrack({
    required this.title,
    required this.drawn,
    required this.summary,
    required this.hasQuiz,
    required this.revision,
    required this.docs,
    this.words = const {},
    this.titles = const {},
    required this.webPath,
  });

  /// The English title, the source language's.
  final String title;

  /// Written in this track.
  final bool drawn;
  final String? summary;
  final bool hasQuiz;

  /// Null where the track is not written.
  final Revision? revision;

  /// Language to the document's site path; may be empty.
  final Map<String, String> docs;

  /// Language to the words its web page prints under the title (web D128); empty where the module is not written.
  final Map<String, int> words;

  /// Language to the title its document carries (web D139); empty in an index from before it.
  final Map<String, String> titles;

  /// The title in [language], the English one where the module has none in it.
  String titleIn(String language) => titles[language] ?? title;

  /// The page on the web, relative to the site root (`courses/<key>/`).
  final String webPath;

  @override
  List<Object?> get props => [title, drawn, summary, hasQuiz, revision, docs, words, titles, webPath];
}

/// The commit a module was last changed in.
final class Revision extends Equatable {
  const Revision({required this.hash, required this.date});

  /// 4 to 40 lowercase hex characters (Decision A24).
  final String hash;

  /// `YYYY-MM-DD`.
  final String date;

  @override
  List<Object?> get props => [hash, date];
}

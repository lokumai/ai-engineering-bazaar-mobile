import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/css_colour.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The consumer parser of the bundle contract (spec 3.4.5).
///
/// Every key of the contract's type map is required, with its type, even where the app does not store it; a key the
/// contract does not name is never read. Open sets (track ids) skip what the app does not know; closed sets (level
/// status, text direction, the diagram font) throw (Decision A23). Every rejection is a [ContentFormatException]
/// naming the document and the location of the offending value.
abstract final class ContentParser {
  static const _majorsPath = 'api/index.json';
  static const _indexPath = 'api/v1/index.json';

  /// Parses `api/index.json`.
  static ApiMajors parseMajors(String json) {
    final root = _Node.root(json, _majorsPath);
    return ApiMajors(majors: List.unmodifiable(root['majors'].list().map((major) => major.integer(min: 1))));
  }

  /// Parses `api/v1/index.json`.
  static BundleIndex parseIndex(String json) {
    final root = _Node.root(json, _indexPath);

    final schemaVersion = root['schemaVersion'];
    if (schemaVersion.integer() != 1) schemaVersion.fail();

    final contentVersion = root['contentVersion'].matching(_contentVersion);
    final publishedAtNode = root['publishedAt'];
    final publishedAt = publishedAtNode.matching(_publishedAt);
    final publishedAtInstant = DateTime.parse(publishedAt);
    if (publishedAtInstant.toIso8601String() != publishedAt) publishedAtNode.fail();

    root['sourceLanguage'].string();
    for (final translation in root['translations'].list()) {
      translation['id'].string();
      translation['label'].string();
      translation['dir'].oneOf(const {'ltr', 'rtl'});
    }

    final files = _hashes(root['files']);
    final images = _hashes(root['images']);

    final tracksNode = root['tracks'];
    final tracks = <TrackInfo>[];
    for (final entry in tracksNode.list()) {
      final track = Track.fromId(entry['id'].string());
      if (track == null) continue;
      tracks.add(TrackInfo(track: track, label: entry['label'].string()));
    }
    for (final track in Track.values) {
      if (!tracks.any((info) => info.track == track)) tracksNode.fail();
    }

    final font = root['diagramFont'];
    final diagramFont = DiagramFont(
      family: font['family'].oneOf(const {'Vazirmatn'}),
      sha256: font['sha256'].matching(_sha256),
    );

    final themes = root['diagramThemes'];
    final diagramThemes = DiagramThemes(light: _diagramTheme(themes['light']), dark: _diagramTheme(themes['dark']));

    final levels = List<LevelEntry>.unmodifiable(root['levels'].list().map((level) => _level(level, files)));
    final levelSlugs = {for (final level in levels) level.slug};

    final modules = List<ModuleEntry>.unmodifiable(
      root['modules'].list().map((module) => _module(module, levelSlugs, files)),
    );

    final moved = root['moved'];
    return BundleIndex(
      contentVersion: contentVersion,
      publishedAt: publishedAt,
      publishedAtInstant: publishedAtInstant,
      tracks: List.unmodifiable(tracks),
      diagramFont: diagramFont,
      diagramThemes: diagramThemes,
      levels: levels,
      modules: modules,
      moved: Moved(levels: _strings(moved['levels']), modules: _strings(moved['modules'])),
      files: files,
      images: images,
    );
  }

  static Map<String, String> _hashes(_Node node) {
    final hashes = <String, String>{};
    for (final MapEntry(:key, :value) in node.entries()) {
      if (!_sitePath.hasMatch(key)) value.fail();
      hashes[key] = value.matching(_sha256);
    }
    return Map.unmodifiable(hashes);
  }

  static Map<String, String> _strings(_Node node) =>
      Map.unmodifiable({for (final MapEntry(:key, :value) in node.entries()) key: value.string()});

  static DiagramTheme _diagramTheme(_Node node) {
    final theme = node['theme'].string();
    final background = node['background'];
    final int argb;
    try {
      argb = parseCssColour(background.string(), path: background.path);
    } on ContentFormatException {
      background.fail();
    }
    return DiagramTheme(theme: theme, backgroundArgb: argb);
  }

  static LevelEntry _level(_Node node, Map<String, String> files) => LevelEntry(
    slug: node['slug'].string(),
    title: node['title'].string(),
    status: node['status'].named(LevelStatus.values.asNameMap()),
    blurb: node['blurb'].string(),
    total: node['total'].integer(min: 0),
    readme: node['readme'].nullable((readme) => readme.listedIn(files)),
  );

  static ModuleEntry _module(_Node node, Set<String> levelSlugs, Map<String, String> files) {
    final key = node['key'].string();
    final levelNode = node['level'];
    final level = levelNode.string();
    if (!levelSlugs.contains(level)) levelNode.fail();
    final number = node['number'].integer(min: 1);
    final minutes = node['minutes'].integer(min: 0);
    final prerequisites = List<String>.unmodifiable(node['prerequisites'].list().map((key) => key.string()));
    final tracksNode = node['tracks'];
    final tracks = Map<Track, ModuleTrack>.unmodifiable({
      for (final track in Track.values) track: _moduleTrack(tracksNode[track.id], track, files),
    });
    return ModuleEntry(
      key: key,
      level: level,
      number: number,
      minutes: minutes,
      prerequisites: prerequisites,
      tracks: tracks,
    );
  }

  static ModuleTrack _moduleTrack(_Node node, Track track, Map<String, String> files) {
    final title = node['title'].string();
    final drawn = node['drawn'].boolean();
    final summary = node['summary'].nullable((summary) => summary.string());
    final hasQuiz = node['hasQuiz'].boolean();
    final revision = node['revision'].nullable(_revision);
    final docsNode = node['docs'];
    final docs = Map<String, String>.unmodifiable({
      for (final MapEntry(:key, :value) in docsNode.entries()) key: value.listedIn(files),
    });
    // The English document of the For Engineers track is required; the operator throws when the key is missing.
    if (track == Track.engineers) docsNode['en'];
    return ModuleTrack(
      title: title,
      drawn: drawn,
      summary: summary,
      hasQuiz: hasQuiz,
      revision: revision,
      docs: docs,
      webPath: node['webPath'].matching(_sitePath),
    );
  }

  static Revision _revision(_Node node) {
    final hash = node['hash'].matching(_shortHash);
    final dateNode = node['date'];
    final date = dateNode.matching(_day);
    final day = DateTime.utc(
      int.parse(date.substring(0, 4)),
      int.parse(date.substring(5, 7)),
      int.parse(date.substring(8, 10)),
    );
    if (day.toIso8601String().substring(0, 10) != date) dateNode.fail();
    return Revision(hash: hash, date: date);
  }
}

final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
final RegExp _contentVersion = _sha256;
final RegExp _sitePath = RegExp(r'^[^/\s][^\s]*$');
final RegExp _publishedAt = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$');
final RegExp _shortHash = RegExp(r'^[0-9a-f]{4,40}$');
final RegExp _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// A JSON value with its location in the document; each reader checks one rule and throws a
/// [ContentFormatException] naming that location.
final class _Node {
  const _Node(this.path, this.field, this.value);

  /// Decodes [text] and requires an object at the root.
  factory _Node.root(String text, String path) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw ContentFormatException(path, '(json)');
    }
    if (decoded is! Map<String, Object?>) throw ContentFormatException(path, '(root)');
    return _Node(path, '', decoded);
  }

  final String path;
  final String field;
  final Object? value;

  Never fail() => throw ContentFormatException(path, field);

  String _child(String key) => field.isEmpty ? key : '$field.$key';

  Map<String, Object?> _object() {
    final value = this.value;
    if (value is! Map<String, Object?>) fail();
    return value;
  }

  /// The required key [key] of this object; its value may still be null.
  _Node operator [](String key) {
    final object = _object();
    final child = _Node(path, _child(key), object[key]);
    if (!object.containsKey(key)) child.fail();
    return child;
  }

  /// The entries of this object, in document order.
  Iterable<MapEntry<String, _Node>> entries() =>
      _object().entries.map((entry) => MapEntry(entry.key, _Node(path, _child(entry.key), entry.value)));

  List<_Node> list() {
    final value = this.value;
    if (value is! List<Object?>) fail();
    return [for (var i = 0; i < value.length; i++) _Node(path, '$field[$i]', value[i])];
  }

  String string() {
    final value = this.value;
    if (value is! String) fail();
    return value;
  }

  bool boolean() {
    final value = this.value;
    if (value is! bool) fail();
    return value;
  }

  /// A finite, whole JSON number, at least [min] when given.
  int integer({int? min}) {
    final value = this.value;
    if (value is! num || !value.isFinite || value != value.truncateToDouble()) fail();
    final integer = value.toInt();
    if (min != null && integer < min) fail();
    return integer;
  }

  String matching(RegExp pattern) {
    final text = string();
    if (!pattern.hasMatch(text)) fail();
    return text;
  }

  /// A string in the closed set [allowed].
  String oneOf(Set<String> allowed) {
    final text = string();
    if (!allowed.contains(text)) fail();
    return text;
  }

  /// The value named by a string in the closed set [allowed].
  T named<T>(Map<String, T> allowed) {
    final text = string();
    if (!allowed.containsKey(text)) fail();
    return allowed[text] as T;
  }

  /// A site path that is a key of [files].
  String listedIn(Map<String, String> files) {
    final sitePath = matching(_sitePath);
    if (!files.containsKey(sitePath)) fail();
    return sitePath;
  }

  T? nullable<T>(T Function(_Node node) read) => value == null ? null : read(this);
}

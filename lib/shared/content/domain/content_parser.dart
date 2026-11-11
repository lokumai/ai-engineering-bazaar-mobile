import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/css_colour.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The consumer parser of the bundle contract (spec 3.4.5).
///
/// Every key of the contract's type map is required, with its type, even where the app does not store it; a key the
/// contract does not name is never read. Open sets (track ids, block, inline and target kinds, code roles) skip or
/// keep what the app does not know; closed sets (level status, text direction, heading and toc depth, alignment,
/// callout kind, the diagram font) throw (Decision A23). Every rejection is a [ContentFormatException] naming the
/// document and the location of the offending value.
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
    // Added by the web in D125; an index from before it has none, and an app that finds none shows no story.
    final story = root
        .optional('story')
        ?.let(
          (node) => Map<String, String>.unmodifiable({
            for (final MapEntry(:key, :value) in node.entries()) key: value.listedIn(files),
          }),
        );
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
      story: story ?? const {},
    );
  }

  /// Parses a module document at the site path [path]; every figure, logo and diagram it names must be listed in
  /// [index].
  static ModuleDoc parseModuleDoc(String json, BundleIndex index, {required String path}) {
    final root = _Node.root(json, path);
    _schemaVersion(root);
    final reader = _DocumentReader(index);

    final key = root['key'].string();
    final track = root['track'].named(_tracksById);
    final lang = root['lang'].string();
    final dir = root['dir'].named(TextDir.values.asNameMap());
    final title = root['title'].string();
    // Added by the web in D128: the words the module's page prints under its title, null on a draft. A document from
    // before it has no key.
    final words = root.optional('words')?.nullable((node) => node.integer(min: 1));
    final objectivesNode = root['objectives'];
    objectivesNode['lang'].string();
    final objectives = List<String>.unmodifiable(objectivesNode['items'].list().map((item) => item.string()));
    // Added by the web in D124: the objectives the document's own translation declares, null in English and where it
    // declares none. A document from before it has no key; a list in another language than the document's is not its.
    final translatedObjectives = root.optional('translatedObjectives')?.nullable((node) {
      final language = node['lang'].string();
      final items = List<String>.unmodifiable(node['items'].list().map((item) => item.string()));
      return language == lang && items.isNotEmpty ? items : null;
    });
    final prerequisites = List<Ref>.unmodifiable(root['prerequisites'].list().map(_ref));
    final previous = root['previous'].nullable(_ref);
    final next = root['next'].nullable(_ref);
    final toc = List<TocEntry>.unmodifiable(root['toc'].list().map(_tocEntry));

    final bodyNode = root['body'];
    final draftNode = root['draft'];
    if ((bodyNode.value == null) == (draftNode.value == null)) bodyNode.fail();
    final body = bodyNode.nullable(reader.blocks);
    final draft = draftNode.nullable((node) => _draft(node, reader));
    final quiz = root['quiz'].nullable((node) => List<QuizItem>.unmodifiable(node.list().map(_quizItem)));

    return ModuleDoc(
      key: key,
      track: track,
      lang: lang,
      dir: dir,
      title: title,
      words: words,
      objectives: objectives,
      translatedObjectives: translatedObjectives,
      prerequisites: prerequisites,
      previous: previous,
      next: next,
      toc: toc,
      body: body,
      draft: draft,
      quiz: quiz,
    );
  }

  /// Parses a level document at the site path [path]; every figure, logo and diagram it names must be listed in
  /// [index].
  static LevelDoc parseLevelDoc(String json, BundleIndex index, {required String path}) {
    final root = _Node.root(json, path);
    _schemaVersion(root);
    return LevelDoc(
      slug: root['slug'].string(),
      title: root['title'].string(),
      blocks: _DocumentReader(index).blocks(root['blocks']),
    );
  }

  /// Parses the story document at the site path [path] (web D125).
  static StoryDoc parseStoryDoc(String json, {required String path}) {
    final root = _Node.root(json, path);
    _schemaVersion(root);
    final stalls = root['stalls'].list();
    if (stalls.isEmpty) root['stalls'].fail();
    return StoryDoc(
      lang: root['lang'].string(),
      dir: root['dir'].named(TextDir.values.asNameMap()),
      title: root['title'].nullable((node) => node.string()),
      stalls: List.unmodifiable(
        stalls.map(
          (stall) => StoryStall(
            heading: stall['heading'].string(),
            paragraphs: List.unmodifiable(stall['paragraphs'].list().map((paragraph) => paragraph.string())),
          ),
        ),
      ),
      motto: root['motto'].nullable(
        (node) => StoryMotto(
          lead: node['lead'].string(),
          lines: List.unmodifiable(node['lines'].list().map((line) => line.string())),
        ),
      ),
    );
  }

  static void _schemaVersion(_Node root) {
    final schemaVersion = root['schemaVersion'];
    if (schemaVersion.integer() != 1) schemaVersion.fail();
  }

  static Ref _ref(_Node node) => Ref(
    key: node['key'].string(),
    number: node['number'].integer(min: 1),
    title: node['title'].string(),
    drawn: node['drawn'].boolean(),
    track: Track.fromId(node['track'].string()),
    lang: node['lang'].string(),
  );

  static TocEntry _tocEntry(_Node node) => TocEntry(
    id: node['id'].string(),
    text: node['text'].string(),
    depth: node['depth'].integerIn(const {2, 3}),
    mark: node.optional('mark')?.string(),
  );

  static Draft _draft(_Node node, _DocumentReader reader) => Draft(
    summary: node['summary'].nullable((summary) => summary.string()),
    parts: List.unmodifiable(node['parts'].list().map((part) => part.string())),
    written: node['written'].nullable(reader.blocks),
  );

  static QuizItem _quizItem(_Node node) {
    final question = node['question'].string();
    final options = List<String>.unmodifiable(node['options'].list().map((option) => option.string()));
    final answerNode = node['answer'];
    final answer = answerNode.integer(min: 0);
    if (answer >= options.length) answerNode.fail();
    return QuizItem(question: question, options: options, answer: answer, explain: node['explain'].string());
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
    // Added by the web in D128: the words each language's page prints; empty where the module is not written. An
    // index from before it has no key.
    final words = Map<String, int>.unmodifiable({
      for (final MapEntry(:key, :value) in node.optional('words')?.entries() ?? const <MapEntry<String, _Node>>[])
        key: value.integer(min: 1),
    });
    return ModuleTrack(
      title: title,
      drawn: drawn,
      summary: summary,
      hasQuiz: hasQuiz,
      revision: revision,
      docs: docs,
      words: words,
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

final Map<String, Track> _tracksById = {for (final track in Track.values) track.id: track};

final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
final RegExp _contentVersion = _sha256;
final RegExp _sitePath = RegExp(r'^[^/\s][^\s]*$');
final RegExp _publishedAt = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$');
final RegExp _shortHash = RegExp(r'^[0-9a-f]{4,40}$');
final RegExp _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _captionNumber = RegExp(r'^\d+(?:\.\d+)?$');
final RegExp _externalUrl = RegExp(r'^https?://', caseSensitive: false);

/// The recursive readers of a document's blocks, inlines and link targets.
///
/// Cross-checks against the index happen where the node is read, so they cover every nesting (callouts, quotes, list
/// items, table cells, links, a draft's written sections): a figure or logo `src` must be a key of the index's
/// `images`, a diagram variant a key of its `files`.
final class _DocumentReader {
  const _DocumentReader(this.index);

  final BundleIndex index;

  List<Block> blocks(_Node node) => List.unmodifiable(node.list().map(block));

  List<Inline> inlines(_Node node) => List.unmodifiable(node.list().map(inline));

  Block block(_Node node) => switch (node['type'].string()) {
    'paragraph' => ParagraphBlock(inlines: inlines(node['inlines']), lead: node.optional('lead')?.boolean() ?? false),
    'heading' => HeadingBlock(
      depth: node['depth'].integerIn(const {2, 3, 4}),
      id: node['id'].string(),
      mark: node.optional('mark')?.string(),
      inlines: inlines(node['inlines']),
    ),
    'list' => ListBlock(
      ordered: node['ordered'].boolean(),
      start: node.optional('start')?.integer(),
      items: List.unmodifiable(node['items'].list().map(_listItem)),
    ),
    'quote' => QuoteBlock(label: node.optional('label')?.string(), blocks: blocks(node['blocks'])),
    'callout' => CalloutBlock(
      kind: node['kind'].named(CalloutKind.values.asNameMap()),
      title: node['title'].nullable(inlines),
      blocks: blocks(node['blocks']),
      action: node['action'].nullable(
        (action) => CalloutAction(target: target(action['target']), inlines: inlines(action['inlines'])),
      ),
    ),
    'code' => _code(node),
    'table' => _table(node),
    'image' => ImageBlock(
      number: node['number'].matching(_captionNumber),
      title: node['title'].nullable((title) => title.string()),
      note: node['note'].nullable((note) => note.string()),
      src: node['src'].listedIn(index.images),
      alt: node['alt'].string(),
      width: node['width'].integer(min: 1),
      height: node['height'].integer(min: 1),
    ),
    'diagram' => _diagram(node),
    'rule' => const RuleBlock(),
    final type => UnknownBlock(type: type),
  };

  ListItem _listItem(_Node node) {
    final task = node.optional('task');
    return ListItem(
      checked: task?['checked'].boolean(),
      // Added by the web in D129: the item's place in the module's one checklist, the key its tick is recorded under.
      // A document from before it has no key, and its boxes stay as drawn.
      taskIndex: task?.optional('index')?.integer(min: 0),
      blocks: blocks(node['blocks']),
    );
  }

  CodeBlock _code(_Node node) {
    final languageNode = node['language'];
    final language = languageNode.string();
    if (language.isEmpty) languageNode.fail();
    return CodeBlock(
      language: language,
      lines: List.unmodifiable(
        node['lines'].list().map((line) => List<CodeToken>.unmodifiable(line.list().map(_token))),
      ),
    );
  }

  CodeToken _token(_Node node) {
    final text = node['text'].string();
    final role = node.optional('role')?.string();
    // The bundle writes `bold` only as `true`.
    final boldNode = node.optional('bold');
    if (boldNode != null && !boldNode.boolean()) boldNode.fail();
    return CodeToken(text: text, role: role, bold: boldNode != null);
  }

  TableBlock _table(_Node node) {
    final number = node['number'].matching(_captionNumber);
    final title = node['title'].nullable((title) => title.string());
    final rowHeaders = node['rowHeaders'].boolean();
    final alignNode = node['align'];
    final align = List<CellAlign?>.unmodifiable(
      alignNode.list().map((cell) => cell.nullable((cell) => cell.named(CellAlign.values.asNameMap()))),
    );
    final head = List<Cell>.unmodifiable(node['head'].list().map(_cell));
    if (align.length != head.length) alignNode.fail();
    // A row as wide as the head (plan 2.1): Flutter's Table asserts on rows of unequal length, and the web's tables come
    // from GFM, which pads a short row with empty cells and drops the cells past the head.
    final rows = List<List<Cell>>.unmodifiable(
      node['rows'].list().map((row) {
        final cells = row.list().map(_cell).take(head.length).toList();
        return List<Cell>.unmodifiable([
          ...cells,
          for (var i = cells.length; i < head.length; i++) const Cell(inlines: []),
        ]);
      }),
    );
    return TableBlock(number: number, title: title, rowHeaders: rowHeaders, align: align, head: head, rows: rows);
  }

  Cell _cell(_Node node) => Cell(inlines: inlines(node['inlines']));

  DiagramBlock _diagram(_Node node) {
    final number = node['number'].matching(_captionNumber);
    final title = node['title'].nullable((title) => title.string());
    final svg = node['svg'];
    return DiagramBlock(
      number: number,
      title: title,
      svgLight: svg['light'].listedIn(index.files),
      svgDark: svg['dark'].listedIn(index.files),
    );
  }

  Inline inline(_Node node) => switch (node['type'].string()) {
    'text' => TextInline(text: node['text'].string()),
    'code' => CodeInline(text: node['text'].string()),
    'break' => const BreakInline(),
    'strong' => StrongInline(inlines: inlines(node['inlines'])),
    'emphasis' => EmphasisInline(inlines: inlines(node['inlines'])),
    'delete' => DeleteInline(inlines: inlines(node['inlines'])),
    'link' => LinkInline(target: target(node['target']), inlines: inlines(node['inlines'])),
    'logo' => LogoInline(
      src: node['src'].listedIn(index.images),
      alt: node['alt'].string(),
      mono: node['mono'].boolean(),
    ),
    final type => UnknownInline(type: type, inlines: node.optional('inlines')?.let(inlines) ?? const []),
  };

  LinkTarget target(_Node node) {
    switch (node['kind'].string()) {
      case 'module':
        final key = node['key'].string();
        final track = Track.fromId(node['track'].string());
        final lang = node['lang'].string();
        final fragment = node.optional('fragment')?.string();
        // A module target in a track this app does not know cannot be opened (Decision A23).
        if (track == null) return const UnknownTarget(kind: 'module');
        return ModuleTarget(key: key, track: track, lang: lang, fragment: fragment);
      case 'external':
        return ExternalTarget(url: node['url'].matching(_externalUrl));
      case 'anchor':
        return AnchorTarget(id: node['id'].string());
      case 'catalog':
        return const CatalogTarget();
      case final kind:
        return UnknownTarget(kind: kind);
    }
  }
}

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

  /// The optional key [key] of this object, or null when it is absent; a present value must still have its type.
  _Node? optional(String key) {
    final object = _object();
    return object.containsKey(key) ? _Node(path, _child(key), object[key]) : null;
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

  /// An integer in the closed set [allowed].
  int integerIn(Set<int> allowed) {
    final integer = this.integer();
    if (!allowed.contains(integer)) fail();
    return integer;
  }

  /// [read] applied to this node.
  T let<T>(T Function(_Node node) read) => read(this);

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

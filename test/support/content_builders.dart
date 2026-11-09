import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bazaar_app_harness.dart';

/// A [ModuleTrack] with defaults; [docs] defaults to the English document of `alpha/first`.
ModuleTrack testModuleTrack({
  String title = 'First',
  bool drawn = true,
  bool hasQuiz = false,
  Revision? revision,
  Map<String, String>? docs,
  String webPath = 'courses/alpha/first/',
}) {
  return ModuleTrack(
    title: title,
    drawn: drawn,
    summary: drawn ? 'A summary.' : null,
    hasQuiz: hasQuiz,
    revision: revision,
    docs: docs ?? const {'en': 'api/v1/modules/alpha/first/en.json'},
    webPath: webPath,
  );
}

/// A [ModuleEntry] with defaults; [tracks] defaults to a drawn For Engineers track whose document and web path follow
/// [key].
ModuleEntry testModule({
  String key = 'alpha/first',
  String level = 'alpha',
  int number = 1,
  int minutes = 12,
  Map<Track, ModuleTrack>? tracks,
}) {
  return ModuleEntry(
    key: key,
    level: level,
    number: number,
    minutes: minutes,
    prerequisites: const [],
    tracks:
        tracks ??
        {
          Track.engineers: testModuleTrack(docs: {'en': 'api/v1/modules/$key/en.json'}, webPath: 'courses/$key/'),
        },
  );
}

/// A [BundleIndex] built from entities: the diagram grounds `white` and `#333`, one level `alpha` whose total is the
/// module count, and a `files` entry for every document its modules name.
BundleIndex testIndex({List<ModuleEntry>? modules, Map<String, String> images = const {}}) {
  final entries = modules ?? [testModule()];
  return BundleIndex(
    contentVersion: 'a' * 64,
    publishedAt: '2026-11-01T00:00:00.000Z',
    publishedAtInstant: DateTime.utc(2026, 11, 1),
    tracks: const [
      TrackInfo(track: Track.engineers, label: 'For Engineers'),
      TrackInfo(track: Track.everyone, label: 'For Everyone'),
    ],
    diagramFont: DiagramFont(family: 'Vazirmatn', sha256: '0' * 64),
    diagramThemes: const DiagramThemes(
      light: DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF),
      dark: DiagramTheme(theme: 'dark', backgroundArgb: 0xFF333333),
    ),
    levels: [
      LevelEntry(
        slug: 'alpha',
        title: 'Alpha Level',
        status: LevelStatus.ready,
        blurb: 'A blurb.',
        total: entries.length,
        readme: null,
      ),
    ],
    modules: entries,
    moved: const Moved(levels: {}, modules: {}),
    files: {
      for (final entry in entries)
        for (final track in entry.tracks.values)
          for (final path in track.docs.values) path: '1' * 64,
    },
    images: images,
  );
}

/// A [ModuleDoc] with defaults, written in English and left to right.
ModuleDoc testDoc({
  String key = 'alpha/first',
  Track track = Track.engineers,
  String title = 'First',
  List<Block>? body,
  Draft? draft,
  List<QuizItem>? quiz,
  List<Ref> prerequisites = const [],
  Ref? previous,
  Ref? next,
  List<TocEntry> toc = const [],
  List<String> objectives = const [],
}) {
  return ModuleDoc(
    key: key,
    track: track,
    lang: 'en',
    dir: TextDir.ltr,
    title: title,
    objectives: objectives,
    prerequisites: prerequisites,
    previous: previous,
    next: next,
    toc: toc,
    body: body,
    draft: draft,
    quiz: quiz,
  );
}

/// A [Ref] with defaults, in English.
Ref testRef({
  String key = 'alpha/second',
  int number = 2,
  String title = 'Second',
  bool drawn = true,
  Track? track = Track.engineers,
}) {
  return Ref(key: key, number: number, title: title, drawn: drawn, track: track, lang: 'en');
}

/// Pumps [child] in a 390 px wide column under the Bazaar theme of [brightness] on [platform], with [repository]
/// (default [missingContentRepository]) provided as the [IContentRepository].
Future<void> pumpInTheme(
  WidgetTester tester,
  Widget child,
  Brightness brightness, {
  TargetPlatform platform = TargetPlatform.android,
  IContentRepository? repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: bazaarTheme(brightness: brightness, platform: platform),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      home: RepositoryProvider<IContentRepository>.value(
        value: repository ?? missingContentRepository(),
        // The Scaffold hands its body a tight width; the Align lets the column be 390 wide.
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 390, child: child),
          ),
        ),
      ),
    ),
  );
}

/// Lets content objects arrive and decode: `flutter_svg` and image decoding run outside the fake clock, so ten rounds
/// of a short real wait and a frame.
Future<void> settleContent(WidgetTester tester) async {
  for (var round = 0; round < 10; round++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/device_app.dart';

/// The app on a device or simulator over the bundled snapshot, with no network. Every value compared is read at run
/// time from the snapshot or from the blocs, never written down (spec 3.11).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Directory> dataDirectory(WidgetTester tester) async {
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('bazaar_device_')))!;
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  Future<ContentReady> settledContent(WidgetTester tester) async => await pumpUntil<ContentBloc, ContentState>(
    tester,
    (s) => s is ContentReady && s.refresh is! RefreshChecking && s.refresh is! RefreshIdle,
  ) as ContentReady;

  // True once the reader shows this module in this track; a leftover reader of the previous page never matches.
  bool showsModule(ReaderState s, String key, Track track) => switch (s) {
    ReaderLoading() => false,
    ReaderWritten(:final doc) || ReaderPlanned(:final doc) => doc.key == key && doc.track == track,
    ReaderNotWritten(:final entry) => entry.key == key,
    ReaderNotFound() || ReaderFailed() => true,
  };

  Future<ReaderState> openModule(WidgetTester tester, String key, Track track) async {
    final path = BazaarPaths.module(track, key);
    goTo(tester, path);
    return pumpUntil<ModuleReaderBloc, ReaderState>(
      tester,
      (s) => currentPath(tester) == path && showsModule(s, key, track),
    );
  }

  Future<(ModuleEntry, ReaderWritten)> openFirstWrittenModule(WidgetTester tester, BundleIndex index) async {
    final entry = index.modules.firstWhere((m) => m.tracks[Track.engineers]?.drawn ?? false);
    final state = await openModule(tester, entry.key, Track.engineers);
    expect(state, isA<ReaderWritten>(), reason: 'module ${entry.key} did not open as written');
    return (entry, state as ReaderWritten);
  }

  testWidgets('boots offline from the bundled snapshot to Home', (tester) async {
    await pumpDeviceApp(tester, directory: await dataDirectory(tester));
    final content = await settledContent(tester);

    expect(content.origin, ContentOrigin.bundled);
    expect(content.refresh, isA<RefreshFailed>().having((f) => f.code, 'code', ContentErrorCode.network));
    expect(currentPath(tester), BazaarPaths.home);
    expect(content.index.levels, isNotEmpty);
    expect(findProse(content.index.levels.first.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a written module opens and renders its first heading', (tester) async {
    await pumpDeviceApp(tester, directory: await dataDirectory(tester));
    final content = await settledContent(tester);
    final (_, written) = await openFirstWrittenModule(tester, content.index);

    final heading = written.doc.body!.whereType<HeadingBlock>().first;
    final text = plainText(heading.inlines);
    expect(text.trim(), isNotEmpty);
    await tester.scrollUntilVisible(findProse(text).first, 400, scrollable: find.byType(Scrollable).first);
    expect(findProse(text), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every module with an English document opens as written or planned in both tracks', (tester) async {
    await pumpDeviceApp(tester, directory: await dataDirectory(tester));
    final content = await settledContent(tester);
    final opened = <String>[];

    for (final track in Track.values) {
      for (final entry in content.index.modules) {
        if (!(entry.tracks[track]?.docs.containsKey('en') ?? false)) continue;
        final state = await openModule(tester, entry.key, track);
        await tester.pump(const Duration(milliseconds: 300)); // let the page decode its images and diagrams
        expect(
          state,
          anyOf(isA<ReaderWritten>(), isA<ReaderPlanned>()),
          reason: '${track.id} ${entry.key} opened as $state',
        );
        expect(tester.takeException(), isNull, reason: '${track.id} ${entry.key}');
        expect(
          find.byType(ContentUnreadable, skipOffstage: false),
          findsNothing,
          reason: '${track.id} ${entry.key} shows an unreadable figure or diagram',
        );
        opened.add('${track.id} ${entry.key}');
      }
    }
    expect(opened, isNotEmpty, reason: 'the bundled index lists no module with an English document');
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('a completion persists after the app is rebuilt over the same directory', (tester) async {
    final directory = await dataDirectory(tester);
    await pumpDeviceApp(tester, directory: directory);
    final content = await settledContent(tester);
    final (entry, _) = await openFirstWrittenModule(tester, content.index);

    final completion = find.byKey(const Key('reader-completion'));
    await tester.scrollUntilVisible(completion, 600, scrollable: find.byType(Scrollable).first, maxScrolls: 1000);
    await tester.tap(completion);
    final saved = await pumpUntil<RecordBloc, RecordState>(
      tester,
      (s) => s is RecordReady && s.writeState is WriteSaved && s.record.signedOff(entry.key, Track.engineers) != null,
    ) as RecordReady;
    expect(File('${directory.path}/record/record.json').existsSync(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDeviceApp(tester, directory: directory);
    final reloaded = await pumpUntil<RecordBloc, RecordState>(tester, (s) => s is RecordReady) as RecordReady;

    expect(reloaded.record.signedOff(entry.key, Track.engineers), saved.record.signedOff(entry.key, Track.engineers));
    expect(reloaded.quarantine, isNull);
    expect(reloaded.launchReadFailed, isFalse);
  });
}

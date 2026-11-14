@Tags(['widget'])
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/catalog_page.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/pages/home_page.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_sting.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/flags/file_flag_store.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_welcome_step.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/bazaar_app_harness.dart';
import '../support/content_builders.dart';
import '../support/content_fixture.dart';

/// The fixture dependencies over real files in [dir]: the content store opens the synthetic bundle with its cache in
/// `<dir>/cache` and a refresh that fails offline, and the record lives in `<dir>/record/`.
class _SmokeDependencies extends FixtureAppDependencies {
  const _SmokeDependencies(this.dir);

  final Directory dir;

  @override
  IContentRepository createContentRepository() => FileContentRepository(
    bundled: BundledContent(bundle: FixtureAssetBundle()),
    cacheDirectory: () async => Directory('${dir.path}/cache')..createSync(recursive: true),
    http: ContentHttp(client: MockClient((_) async => http.Response('', 500)), contentBaseUrl: testContentBaseUrl),
  );

  @override
  IRecordRepository createRecordRepository() => FileRecordRepository(baseDirectory: () async => dir);
}

/// The smoke wiring with the real Welcome flag under [dir], as a first launch has it.
class _FirstLaunchDependencies extends _SmokeDependencies {
  const _FirstLaunchDependencies(super.dir);

  @override
  IWelcomeStore createWelcomeStore() => FlagWelcomeStore(FileFlagStore(baseDirectory: () async => dir));

  @override
  ITrackStore createTrackStore() => FlagTrackStore(FileFlagStore(baseDirectory: () async => dir));

  @override
  ILanguageStore createLanguageStore() => FlagLanguageStore(FileFlagStore(baseDirectory: () async => dir));

  @override
  IThemeStore createThemeStore() => FlagThemeStore(FileFlagStore(baseDirectory: () async => dir));

  @override
  IAppIconStore createAppIconStore() => FlagAppIconStore(FileFlagStore(baseDirectory: () async => dir));
}

/// Lets real file I/O finish, which does not complete under the fake clock: a short real wait and a frame, repeated
/// until [done] holds, failing after [rounds] rounds.
Future<void> _drain(WidgetTester tester, bool Function() done, {required String what, int rounds = 100}) async {
  for (var round = 0; round < rounds; round++) {
    if (done()) return;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    // Frames move on in time too, so the gate that plays as the app opens plays out (plan 1Y).
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (done()) return;
  throw TestFailure('$what did not happen after $rounds rounds');
}

/// End-to-end smoke: boots the whole app over the fixture dependencies (the fixture content, no network), and lands on
/// Home inside the shell once the content and the record are ready. There is no sign-in. The second test opens a
/// module from the catalog, completes it over real files and reads it back after a restart.
void main() {
  testWidgets('cold start shows Home with no sign-in', (tester) async {
    await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
    await pumpUntilFound(tester, find.byType(HomePage));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(BazaarShell), findsOneWidget);
  });

  testWidgets(
    'the first launch plays the gate, asks the track, tells the story and lands on Home; the next launch opens Home in that track',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('bazaar_welcome_');
      addTearDown(() => dir.deleteSync(recursive: true));
      await tester.pumpWidget(App(dependencies: _FirstLaunchDependencies(dir)));
      await _drain(tester, () => find.byKey(WelcomeSting.sceneKey).evaluate().isNotEmpty, what: 'the opening');
      await _drain(tester, () => find.byKey(WelcomeSting.sceneKey).evaluate().isEmpty, what: 'the opening giving way');
      expect(find.byType(HomePage), findsNothing);
      // The language and the track first, then the story (plan 3.5).
      final everyone = find.byKey(WelcomeTrackView.optionKey(Track.everyone));
      await _drain(tester, () => everyone.evaluate().isNotEmpty, what: 'the track question first (plan 3.5)');
      await tester.ensureVisible(everyone);
      await tester.pump();
      await tester.tap(everyone);
      await tester.pump();
      final toStory = find.byKey(WelcomeTrackView.storyKey);
      await tester.ensureVisible(toStory);
      await tester.pump();
      await tester.tap(toStory);
      // The story, its film played to the end.
      final intro = find.byKey(AboutWelcomeStep.doneKey);
      await _drain(tester, () => find.text('Story').evaluate().isNotEmpty, what: 'the story after the track');
      // Each tap on the far side moves on a screen, and at the motto brings its button.
      for (var tap = 0; tap < 8 && intro.hitTestable().evaluate().isEmpty; tap++) {
        final size = tester.getSize(find.byType(AboutWelcomeStep));
        await tester.tapAt(Offset(size.width * 0.85, size.height * 0.6));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.tap(intro);
      // Home, as every later launch opens, not the catalog (the owner, 2026-11-15).
      await _drain(tester, () => find.byType(HomePage).evaluate().isNotEmpty, what: 'Home');
      expect(find.byType(CatalogPage), findsNothing);
      await _drain(tester, () => File('${dir.path}/flags/welcome-2-seen').existsSync(), what: 'the Welcome flag');
      await _drain(tester, () => File('${dir.path}/flags/track-chosen').existsSync(), what: 'the chosen track');
      expect(File('${dir.path}/flags/track-everyone').existsSync(), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(App(dependencies: _FirstLaunchDependencies(dir)));
      await _drain(tester, () => find.byType(HomePage).evaluate().isNotEmpty, what: 'Home after a restart');
      await _drain(tester, () => find.byKey(WelcomeSting.sceneKey).evaluate().isEmpty, what: 'the opening giving way');
      expect(find.byType(WelcomeTrackView), findsNothing);
      await _drain(
        tester,
        () => tester.element(find.byType(HomePage)).read<TrackCubit>().state == Track.everyone,
        what: 'the chosen track after a restart',
      );
    },
  );

  testWidgets('Start learning on the first launch opens Home at once (the owner, 2026-11-15)', (tester) async {
    final dir = Directory.systemTemp.createTempSync('bazaar_welcome_');
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(App(dependencies: _FirstLaunchDependencies(dir)));
    await _drain(tester, () => find.byKey(WelcomeSting.sceneKey).evaluate().isNotEmpty, what: 'the opening');
    await _drain(tester, () => find.byKey(WelcomeSting.sceneKey).evaluate().isEmpty, what: 'the opening giving way');
    final start = find.byKey(WelcomeTrackView.startKey);
    await _drain(tester, () => start.evaluate().isNotEmpty, what: 'the first step');
    await tester.ensureVisible(start);
    await tester.pump();
    await tester.tap(start);

    await _drain(tester, () => find.byType(HomePage).evaluate().isNotEmpty, what: 'Home');
    expect(find.byType(CatalogPage), findsNothing);
    expect(find.byType(AboutWelcomeStep), findsNothing, reason: 'no story');
    await _drain(tester, () => File('${dir.path}/flags/welcome-2-seen').existsSync(), what: 'the Welcome flag');
  });

  testWidgets(
    'completing a module survives a restart',
    (tester) => withClock(Clock.fixed(DateTime.utc(2026, 11, 9, 10)), () async {
      final dir = Directory.systemTemp.createTempSync('bazaar_smoke_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final title = ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync())
          .module('alpha/first')!
          .tracks[Track.engineers]!
          .title;
      final recordFile = File('${dir.path}/record/record.json');
      final completion = find.byKey(const Key('reader-completion'));

      Future<void> openFirst() async {
        await _drain(tester, () => find.byType(HomePage).evaluate().isNotEmpty, what: 'Home');
        await _drain(
          tester,
          () => find.byKey(WelcomeSting.sceneKey).evaluate().isEmpty,
          what: 'the opening giving way',
        );
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byTooltip('Catalog')));
        await tester.pump();
        await _drain(tester, () => find.byType(CatalogPage).evaluate().isNotEmpty, what: 'the catalog');
        // The level of the next module to read starts open: alpha, before and after the completion.
        await _drain(
          tester,
          () => find.descendant(of: find.byType(CatalogPage), matching: find.text(title)).evaluate().isNotEmpty,
          what: 'the modules of the first level',
        );
        // The modules unfold over a short animation; tap the title once it is in place.
        await tester.pump(const Duration(seconds: 1));
        await tester.ensureVisible(find.descendant(of: find.byType(CatalogPage), matching: find.text(title)));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.descendant(of: find.byType(CatalogPage), matching: find.text(title)));
        await tester.pump();
        await _drain(tester, () => completion.evaluate().isNotEmpty, what: 'the reader of $title');
        await settleContent(tester);
      }

      await tester.pumpWidget(App(dependencies: _SmokeDependencies(dir)));
      await openFirst();
      await tester.ensureVisible(completion);
      await tester.tap(completion);
      await tester.pump();
      await _drain(tester, recordFile.existsSync, what: 'the record write');
      await tester.pump();

      expect(find.text('Completed 9 Nov 2026'), findsOneWidget);
      expect(recordFile.readAsStringSync(), contains('"signedOff":"2026-11-09T10:00:00.000Z"'));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(App(dependencies: _SmokeDependencies(dir)));
      await openFirst();

      expect(tester.widget<CheckboxListTile>(completion).value, isTrue);
      expect(find.text('Completed 9 Nov 2026'), findsOneWidget);
      final state = tester.element(find.byType(ModuleReaderView)).read<RecordBloc>().state;
      expect(state, isA<RecordReady>());
      final record = (state as RecordReady).record;
      expect(record.signedOff('alpha/first', Track.engineers), '2026-11-09T10:00:00.000Z');
      // The fixture's For Everyone version is written, so it is completed along with For Engineers (plan 1V).
      expect(record.signedMap(Track.everyone), {'alpha/first': '2026-11-09T10:00:00.000Z'});
    }),
  );
}

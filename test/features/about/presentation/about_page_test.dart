@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_page.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_welcome_step.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_film.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/catalog_fixture_index.dart';

const _path = 'api/v1/story/en.json';

const _story = StoryDoc(
  lang: 'en',
  dir: TextDir.ltr,
  title: 'A Title',
  stalls: [
    StoryStall(heading: 'The first section.', paragraphs: ['A first paragraph.', 'A second paragraph.']),
    StoryStall(heading: 'The second section.', paragraphs: ['One paragraph.']),
  ],
  motto: StoryMotto(lead: 'A lead', lines: ['First line.', 'Second line.']),
);

IContentRepository _repository({Object? error}) {
  final repository = MockContentRepository();
  if (error != null) {
    when(() => repository.readStoryDoc(_path)).thenThrow(error);
  } else {
    when(() => repository.readStoryDoc(_path)).thenAnswer((_) async => _story);
  }
  return repository;
}

/// Settings, then its story row, over content that names a story unless [story] is false; the film has just begun.
Future<void> _pump(
  WidgetTester tester, {
  bool story = true,
  Object? error,
  String language = 'en',
  TargetPlatform platform = TargetPlatform.android,
  bool open = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouterFactory(initialLocation: '/settings').create();
  addTearDown(router.dispose);
  final languageCubit = LanguageCubit(initial: language);
  addTearDown(languageCubit.close);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      platform: platform,
      language: languageCubit,
      content: readyContentBloc(catalogFixtureIndex(story: story ? const {'en': _path} : const {})),
      repository: _repository(error: error),
    ),
  );
  await tester.pumpAndSettle();
  if (!open) return;
  final row = find.text('The story of the Bazaar');
  await tester.scrollUntilVisible(row, 200);
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// The far and near sides of the film.
Future<void> _tapNext(WidgetTester tester) async {
  final size = tester.getSize(find.byType(AboutFilm));
  await tester.tapAt(Offset(size.width * 0.85, size.height * 0.85));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tapPrevious(WidgetTester tester) async {
  final size = tester.getSize(find.byType(AboutFilm));
  await tester.tapAt(Offset(size.width * 0.1, size.height * 0.85));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Finder _said(String label) => find.bySemanticsLabel(label);

void main() {
  testWidgets('Settings opens the story over the whole app: the title in the gate, with no bar and no navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(find.byType(AboutPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'a film over the app, apart from its pages');
    expect(find.byKey(AboutFilm.exitKey), findsOneWidget);
    expect(_said('A Title'), findsOneWidget);
    expect(find.text('The story is written in English.'), findsNothing);
    semantics.dispose();
  });

  testWidgets('plays on by itself through each section to the motto, whose button goes back to Settings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(_said('The first section.'), findsOneWidget);
    expect(_said('A first paragraph.'), findsOneWidget);
    expect(_said('A second paragraph.'), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget, reason: 'the section\'s scene');

    // The film stops at the motto, so it settles there.
    await tester.pumpAndSettle();
    // The motto is read as one piece.
    expect(find.bySemanticsLabel(RegExp(r'^A lead:\s+First line\.\s+Second line\.$')), findsOneWidget);

    await tester.tap(find.byKey(AboutFilm.finishKey));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsNothing);
    expect(find.byType(SettingsPage), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a tap on the far side goes on at once, on the near side goes back, and the close button leaves', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    await _tapNext(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_said('The first section.'), findsOneWidget);
    await _tapNext(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_said('The second section.'), findsOneWidget);
    await _tapPrevious(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_said('The first section.'), findsOneWidget);

    await tester.tap(find.byKey(AboutFilm.exitKey));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('under a screen reader nothing moves on by itself, and the sides are Previous and Next', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('A Title'), findsNothing, reason: 'the title is split into its two words');
    expect(find.text('Title'), findsOneWidget, reason: 'still on the opening');
    expect(_said('Next'), findsOneWidget);
    expect(_said('Previous'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('The first section.'), findsOneWidget, reason: 'drawn in place, not word by word');
    semantics.dispose();
  });

  testWidgets('says the story is in English when the app is not', (tester) async {
    await _pump(tester, language: 'tr');
    await tester.pump(const Duration(seconds: 3));

    // The harness draws the interface in English whatever the language cubit holds.
    expect(find.text('The story is written in English.'), findsOneWidget);
  });

  testWidgets('says so when the story cannot be read, and still offers the way back', (tester) async {
    await _pump(tester, error: const ContentCorruptException(_path));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be opened'), findsOneWidget);
    await tester.tap(find.byKey(AboutFilm.finishKey));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('Settings offers no story when the content names none (web D125)', (tester) async {
    await _pump(tester, story: false, open: false);

    expect(find.text('The story of the Bazaar', skipOffstage: false), findsNothing);
    expect(find.text('How the bazaar works', skipOffstage: false), findsOneWidget);
  });

  testWidgets('text scale 2.0 keeps every screen of the story readable', (tester) async {
    final router = AppRouterFactory(initialLocation: '/settings/about').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(
      tester,
      bazaarTestApp(
        router: router,
        content: readyContentBloc(catalogFixtureIndex(story: const {'en': _path})),
        repository: _repository(),
      ),
      scale: 2.0,
    );
    for (var screen = 0; screen < 4; screen++) {
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull, reason: 'screen $screen');
      await _tapNext(tester);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expectHittable(tester, find.byKey(AboutFilm.finishKey));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);
    await tester.pump(const Duration(seconds: 4));
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  group('Welcome\'s story step (plan 3.5)', () {
    Future<List<String>> pumpStep(WidgetTester tester, {double scale = 1.0}) async {
      final done = <String>[];
      await pumpAtTextScale(
        tester,
        bazaarTestApp(
          router: AppRouterFactory(initialLocation: '/').create(),
          content: readyContentBloc(catalogFixtureIndex(story: const {'en': _path})),
          repository: _repository(),
        ),
        scale: scale,
      );
      await tester.pumpAndSettle();
      // Draw the step over the app's providers, as Welcome draws it.
      final context = tester.element(find.byType(Navigator).first);
      unawaited(
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => AboutWelcomeStep(onDone: () => done.add('done')))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      return done;
    }

    testWidgets('ends with the way on to the track, reachable at text scale 2.0', (tester) async {
      final done = await pumpStep(tester, scale: 2.0);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final start = find.byKey(AboutWelcomeStep.doneKey);
      expectHittable(tester, start);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(start);
      expect(done, ['done']);
    });

    testWidgets('Skip leaves the story at any time', (tester) async {
      final done = await pumpStep(tester);

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.byKey(AboutWelcomeStep.skipKey));
      expect(done, ['done']);
    });
  });
}

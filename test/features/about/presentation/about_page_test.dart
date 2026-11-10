@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_page.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_welcome_step.dart';
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

/// Settings, then its story row, over content that names a story unless [story] is false.
Future<void> _pump(
  WidgetTester tester, {
  bool story = true,
  Object? error,
  String language = 'en',
  TargetPlatform platform = TargetPlatform.android,
  bool open = true,
}) async {
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings opens the story: its title, each section, and the motto, with the Settings tab selected', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(AboutPage), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);
    expect(find.byType(BackButton), findsOneWidget, reason: 'a page pushed over Settings');
    for (final text in ['A Title', 'The first section.', 'A first paragraph.', 'A second paragraph.']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    for (final text in ['The second section.', 'A lead', 'First line.', 'Second line.']) {
      expect(find.text(text, skipOffstage: false), findsOneWidget, reason: text);
    }
    expect(find.byType(Image, skipOffstage: false), findsNWidgets(2), reason: 'one picture by each section');
    expect(find.text('The story is written in English.'), findsNothing);
  });

  testWidgets('says the story is in English when the app is not', (tester) async {
    await _pump(tester, language: 'tr');

    // The harness draws the interface in English whatever the language cubit holds.
    expect(find.text('The story is written in English.'), findsOneWidget);
    expect(find.text('A Title'), findsOneWidget);
  });

  testWidgets('says so when the story cannot be read', (tester) async {
    await _pump(tester, error: const ContentCorruptException(_path));

    expect(find.textContaining('could not be opened'), findsOneWidget);
  });

  testWidgets('Settings offers no story when the content names none (web D125)', (tester) async {
    await _pump(tester, story: false, open: false);

    expect(find.text('The story of the Bazaar', skipOffstage: false), findsNothing);
    expect(find.text('How the bazaar works', skipOffstage: false), findsOneWidget);
  });

  testWidgets('text scale 2.0 keeps the story readable', (tester) async {
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
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('A Title'), findsOneWidget);
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  group('Welcome\'s story step (plan 3.5)', () {
    testWidgets('ends with the way into the catalog, reachable at text scale 2.0', (tester) async {
      final done = <String>[];
      await pumpAtTextScale(
        tester,
        bazaarTestApp(
          router: AppRouterFactory(initialLocation: '/').create(),
          content: readyContentBloc(catalogFixtureIndex(story: const {'en': _path})),
          repository: _repository(),
        ),
        scale: 2.0,
      );
      await tester.pumpAndSettle();
      // Draw the step over the app's providers, as Welcome draws it.
      final context = tester.element(find.byType(Navigator).first);
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => AboutWelcomeStep(onDone: () => done.add('done'))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('A Title'), findsOneWidget);
      final start = find.byKey(AboutWelcomeStep.doneKey);
      await tester.scrollUntilVisible(start, 300);
      await tester.pumpAndSettle();
      expectHittable(tester, start);
      await tester.tap(start);
      expect(done, ['done']);
    });
  });
}

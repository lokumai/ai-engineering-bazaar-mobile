@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/level_page.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_cards.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';

RecordData _signed(String slug) => signOff(RecordData.empty, slug, 'abc1234', '2026-11-09T10:00:00.000Z');

RecordReady _ready(RecordData record) => RecordReady(
  record: record,
  writeState: const WriteSaved(),
  quarantine: null,
  quarantineKept: false,
  launchReadFailed: false,
  undo: null,
);

/// The record with `alpha/first` completed For Engineers.
RecordBloc _firstCompleted() => readyRecordBloc(_signed('alpha/first'));

GoRouter _router(String location) {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  return router;
}

Future<GoRouter> _pumpLevel(WidgetTester tester, String location, {RecordBloc? record}) async {
  final router = _router(location);
  await tester.pumpWidget(bazaarTestApp(router: router, record: record ?? _firstCompleted()));
  await tester.pumpAndSettle();
  return router;
}

/// The path of the page on top, a pushed one included.
String _path(GoRouter router) => router.state.uri.path;

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

/// The level row's `All` chip comes first in the tree, the status row's second.
Finder get _levelAll => _chip('All').first;

bool _selected(WidgetTester tester, Finder chip) => tester.widget<ChoiceChip>(chip).selected;

Finder _inCards(Finder finder) => find.descendant(of: find.byType(CatalogCards), matching: finder);

/// The card of the module titled [title].
Finder _card(String title) => find.ancestor(of: _inCards(find.text(title)), matching: find.byType(BazaarCard));

Finder _inCard(String title, String text) => find.descendant(of: _card(title), matching: find.text(text));

/// Scrolls the page until [finder] is built: the page's list builds lazily, so the cards under its header are not built
/// until they come near the screen.
Future<void> _build(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _build(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const _alphaReadme = 'api/v1/levels/alpha.json';

/// [catalogFixtureIndex] with alpha's entry rebuilt with a level document at [_alphaReadme].
BundleIndex _indexWithAlphaReadme() {
  final index = catalogFixtureIndex();
  return BundleIndex(
    contentVersion: index.contentVersion,
    publishedAt: index.publishedAt,
    publishedAtInstant: index.publishedAtInstant,
    tracks: index.tracks,
    diagramFont: index.diagramFont,
    diagramThemes: index.diagramThemes,
    levels: [
      for (final level in index.levels)
        level.slug == 'alpha'
            ? LevelEntry(
                slug: level.slug,
                title: level.title,
                status: level.status,
                blurb: level.blurb,
                total: level.total,
                readme: _alphaReadme,
              )
            : level,
    ],
    modules: index.modules,
    moved: index.moved,
    files: index.files,
    images: index.images,
  );
}

void main() {
  group('the level notes', () {
    testWidgets('a level without a document shows no notes and reads none', (tester) async {
      final repository = MockContentRepository();
      final router = _router('/sheets/alpha');
      await tester.pumpWidget(bazaarTestApp(router: router, record: _firstCompleted(), repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('General notes'), findsNothing);
      verifyNever(() => repository.readLevelDoc(any()));
    });

    testWidgets('a level with a document shows its notes below the cards', (tester) async {
      final repository = MockContentRepository();
      when(() => repository.readLevelDoc(_alphaReadme)).thenAnswer(
        (_) async => const LevelDoc(
          slug: 'alpha',
          title: 'Alpha',
          blocks: [
            ParagraphBlock(inlines: [TextInline(text: 'Level note.')], lead: true),
          ],
        ),
      );
      final router = _router('/sheets/alpha');
      await tester.pumpWidget(
        bazaarTestApp(
          router: router,
          content: readyContentBloc(_indexWithAlphaReadme()),
          record: _firstCompleted(),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // The page is a lazy list: scroll until the notes are built, then bring them into view.
      final notes = find.text('General notes');
      final page = find.descendant(of: find.byType(LevelPage), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(notes, 200, scrollable: page);
      await tester.pumpAndSettle();

      final lastCard = _card('Third Module');
      await tester.ensureVisible(lastCard);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(notes).dy, greaterThan(tester.getTopLeft(lastCard).dy));
      await tester.ensureVisible(find.text('Level note.', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('Level note.', findRichText: true), findsOneWidget);
      verify(() => repository.readLevelDoc(_alphaReadme)).called(1);
    });
  });

  group('the head of the page', () {
    testWidgets('alpha', (tester) async {
      await _pumpLevel(tester, '/sheets/alpha');

      final header = find.descendant(of: find.byType(LevelPage), matching: find.text('Alpha Level')).first;
      expect(
        find.ancestor(
          of: header,
          matching: find.byWidgetPredicate((widget) => widget is Semantics && (widget.properties.header ?? false)),
        ),
        findsOneWidget,
        reason: 'the level title is the page header',
      );
      expect(tester.getTopLeft(header).dy, lessThan(tester.getTopLeft(find.text('Level:')).dy));
      expect(find.text('3 modules · ~1 h 15 min'), findsOneWidget);
      expect(find.text('1/3 completed'), findsOneWidget);
      expect(find.text('Showing 3 of 6'), findsOneWidget);
      expect(_selected(tester, _chip('Alpha Level')), isTrue);
      expect(_selected(tester, _levelAll), isFalse);
    });

    testWidgets('beta', (tester) async {
      await _pumpLevel(tester, '/sheets/beta');

      expect(find.text('2 modules · ~1 h'), findsOneWidget);
      expect(find.text('0/2 completed'), findsOneWidget);
      expect(find.text('Showing 2 of 6'), findsOneWidget);
      expect(_selected(tester, _chip('Beta Level')), isTrue);
    });

    testWidgets('gamma', (tester) async {
      await _pumpLevel(tester, '/sheets/gamma');

      expect(find.text('1 module · ~45 min'), findsOneWidget);
      expect(find.text('0/1 completed'), findsOneWidget);
    });
  });

  testWidgets('the meter counts this track only', (tester) async {
    await _pumpLevel(tester, '/everyone/sheets/alpha');

    expect(find.text('0/3 completed'), findsOneWidget);
    expect(find.text('3 modules · ~1 h 15 min'), findsOneWidget, reason: 'the lead line is the same in both tracks');
  });

  group('a completion updates its own track\'s meter only', () {
    RecordBloc completingSecond() {
      final bloc = MockRecordBloc();
      whenListen(
        bloc,
        Stream<RecordState>.value(_ready(_signed('alpha/second'))),
        initialState: _ready(RecordData.empty),
      );
      return bloc;
    }

    testWidgets('For Engineers', (tester) async {
      await tester.pumpWidget(bazaarTestApp(router: _router('/sheets/alpha'), record: completingSecond()));
      expect(find.text('0/3 completed'), findsOneWidget);

      await tester.pump();
      expect(find.text('1/3 completed'), findsOneWidget);
      expect(find.text('0/3 completed'), findsNothing);
    });

    testWidgets('For Everyone', (tester) async {
      await tester.pumpWidget(bazaarTestApp(router: _router('/everyone/sheets/alpha'), record: completingSecond()));
      expect(find.text('0/3 completed'), findsOneWidget);

      await tester.pump();
      expect(find.text('0/3 completed'), findsOneWidget);
    });
  });

  testWidgets('the meter waits for the record', (tester) async {
    await _pumpLevel(tester, '/sheets/alpha', record: loadingRecordBloc());

    expect(find.text('--/3 completed'), findsOneWidget);
  });

  testWidgets('the cards', (tester) async {
    await _pumpLevel(tester, '/sheets/alpha');

    await _build(tester, find.byType(CatalogCards));
    expect(find.byType(BazaarCard), findsNWidgets(3));
    expect(_inCard('First Module', 'Alpha Level 01'), findsOneWidget);
    expect(_inCard('Second Module', 'Alpha Level 02'), findsOneWidget);
    expect(_inCard('Third Module', 'Alpha Level 03'), findsOneWidget);
    expect(_inCards(find.text('Length')), findsNWidgets(3));
    expect(_inCard('First Module', '20 min'), findsOneWidget);
    expect(_inCard('Second Module', '25 min'), findsOneWidget);
    expect(_inCard('Third Module', 'Planned'), findsOneWidget);
    expect(_inCards(find.text('Requires')), findsNWidgets(3));
    expect(_inCard('First Module', 'Nothing'), findsOneWidget);
    expect(_inCard('Second Module', '1'), findsOneWidget);
    expect(_inCard('Third Module', '1, 2'), findsOneWidget);
    expect(_inCards(find.text('Description')), findsNWidgets(2));
    expect(_inCard('First Module', 'Description'), findsOneWidget);
    expect(_inCard('Second Module', 'Description'), findsOneWidget);
    expect(_inCard('Third Module', 'Description'), findsNothing, reason: 'a planned module has no summary');
    expect(find.text('Summary of the first module.'), findsNothing, reason: 'every Description starts closed');
  });

  testWidgets('one description open at a time', (tester) async {
    await _pumpLevel(tester, '/sheets/alpha');

    await _tap(tester, _inCard('First Module', 'Description'));
    expect(find.text('Summary of the first module.'), findsOneWidget);
    expect(
      tester.getSemantics(_inCard('First Module', 'Description')),
      isSemantics(isExpanded: true, hasExpandedState: true),
    );

    await _tap(tester, _inCard('Second Module', 'Description'));
    expect(find.text('Summary of the second module.'), findsOneWidget);
    expect(find.text('Summary of the first module.'), findsNothing);

    await _tap(tester, _inCard('Second Module', 'Description'));
    expect(find.text('Summary of the second module.'), findsNothing, reason: 'the open one closes again');
  });

  testWidgets('For Everyone', (tester) async {
    await _pumpLevel(tester, '/everyone/sheets/alpha');
    await _build(tester, find.byType(CatalogCards));

    expect(_card('First Module'), findsOneWidget);
    expect(find.text('First Story'), findsNothing);
    await _tap(tester, _inCard('First Module', 'Description'));
    expect(find.text('Story of the first module.'), findsOneWidget);
    expect(_inCard('Second Module', 'Planned'), findsOneWidget);
    expect(_inCard('Second Module', 'Description'), findsNothing);
  });

  testWidgets('filters and the empty state', (tester) async {
    final router = await _pumpLevel(tester, '/everyone/sheets/alpha');

    await _tap(tester, _chip('Completed'));
    expect(find.text('No module matches both filters · 0 of 6'), findsOneWidget);
    expect(find.text('Showing 0 of 6'), findsOneWidget);
    expect(find.byType(CatalogCards), findsNothing);

    await _tap(tester, find.text('Show the whole catalog'));
    expect(_path(router), '/everyone/sheets');
  });

  testWidgets('a status filter narrows the cards to this level', (tester) async {
    await _pumpLevel(tester, '/sheets/alpha');

    await _tap(tester, _chip('Ready'));
    expect(find.text('Showing 2 of 6'), findsOneWidget);
    await _build(tester, find.byType(CatalogCards));
    expect(find.byType(BazaarCard), findsNWidgets(2));
    expect(_card('Third Module'), findsNothing);
  });

  testWidgets('the selected level chip keeps a pushed level page and its Status filter', (tester) async {
    final router = await _pumpLevel(tester, '/sheets');
    await _tap(tester, find.descendant(of: find.byType(CatalogOverview), matching: find.text('Beta Level')));
    expect(_path(router), '/sheets/beta');
    await _tap(tester, _chip('Planned'));
    expect(find.text('Showing 1 of 6'), findsOneWidget);

    await _tap(tester, _chip('Beta Level'));
    expect(_path(router), '/sheets/beta');
    expect(_selected(tester, _chip('Beta Level')), isTrue);
    expect(_selected(tester, _chip('Planned')), isTrue);
    expect(find.text('Showing 1 of 6'), findsOneWidget);
    expect(router.canPop(), isTrue, reason: 'the catalog stays below');
  });

  group('a level chip opens the other level with its own filters', () {
    for (final (track, prefix, status) in [
      ('For Engineers', '/sheets', 'Completed'),
      ('For Everyone', '/everyone/sheets', 'Planned'),
    ]) {
      testWidgets(track, (tester) async {
        final router = await _pumpLevel(tester, '$prefix/alpha');
        await _tap(tester, _chip(status));
        expect(_selected(tester, _chip(status)), isTrue);

        await _tap(tester, _chip('Beta Level'));
        expect(_path(router), '$prefix/beta');
        expect(_selected(tester, _chip('All').last), isTrue, reason: 'the Status row starts at All');
        expect(_selected(tester, _chip(status)), isFalse);
        expect(find.text('Showing 2 of 6'), findsOneWidget);
      });
    }
  });

  group('links', () {
    testWidgets('a module title opens the module', (tester) async {
      final router = await _pumpLevel(tester, '/sheets/alpha');
      await _tap(tester, _inCards(find.text('First Module')));
      expect(_path(router), '/courses/alpha/first');
    });

    testWidgets('a module title opens the For Everyone module', (tester) async {
      final router = await _pumpLevel(tester, '/everyone/sheets/alpha');
      await _tap(tester, _inCards(find.text('First Module')));
      expect(_path(router), '/everyone/courses/alpha/first');
    });

    testWidgets('the level chip All opens the catalog root', (tester) async {
      final router = await _pumpLevel(tester, '/sheets/alpha');
      await _tap(tester, _levelAll);
      expect(_path(router), '/sheets');
    });
  });

  testWidgets('an unknown level', (tester) async {
    await _pumpLevel(tester, '/sheets/nope');

    expect(find.byType(NotFoundView), findsOneWidget);
    expect(find.text('No such module'), findsOneWidget);
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(
      tester,
      bazaarTestApp(router: _router('/sheets/alpha'), record: _firstCompleted()),
      scale: 2.0,
    );

    expect(tester.takeException(), isNull);
    for (final target in [
      _chip('Completed'),
      _inCards(find.text('First Module')),
      _inCard('First Module', 'Description'),
    ]) {
      await tester.ensureVisible(target);
      await tester.pump();
      expectHittable(tester, target);
    }
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      bazaarTestApp(platform: defaultTargetPlatform, router: _router('/sheets/alpha'), record: _firstCompleted()),
    );
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}

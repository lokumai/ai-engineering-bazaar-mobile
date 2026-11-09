@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/level_notes.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/content_builders.dart';

const _readme = 'api/v1/levels/alpha.json';

final _themes = testIndex().diagramThemes;

const _doc = LevelDoc(
  slug: 'alpha',
  title: 'Alpha',
  blocks: [
    ParagraphBlock(inlines: [TextInline(text: 'Level note.')], lead: true),
    UnknownBlock(type: 'poll'),
  ],
);

const _betaReadme = 'api/v1/levels/beta.json';

const _betaDoc = LevelDoc(
  slug: 'beta',
  title: 'Beta',
  blocks: [
    ParagraphBlock(inlines: [TextInline(text: 'Beta note.')], lead: false),
  ],
);

LevelDoc _linkedDoc(String id) => LevelDoc(
  slug: 'alpha',
  title: 'Alpha',
  blocks: [
    ParagraphBlock(
      inlines: [
        LinkInline(
          target: AnchorTarget(id: id),
          inlines: const [TextInline(text: 'Jump')],
        ),
      ],
      lead: false,
    ),
    for (var i = 0; i < 40; i++) ParagraphBlock(inlines: [TextInline(text: 'Filler paragraph $i.')], lead: false),
    const HeadingBlock(
      depth: 2,
      id: 'later',
      mark: null,
      inlines: [TextInline(text: 'Later')],
    ),
  ],
);

Future<void> _pumpNotes(WidgetTester tester, MockContentRepository repository, {String readme = _readme}) async {
  await pumpInTheme(
    tester,
    SingleChildScrollView(
      child: LevelNotes(readme: readme, diagramThemes: _themes),
    ),
    Brightness.light,
    repository: repository,
  );
  await tester.pump();
}

void main() {
  setUpAll(() => S.load(const Locale('en')));

  late MockContentRepository repository;

  setUp(() => repository = MockContentRepository());

  testWidgets('the notes render the level document under General notes, with no web action', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _doc);

    await _pumpNotes(tester, repository);

    expect(tester.getSemantics(find.text('General notes')), matchesSemantics(isHeader: true, label: 'General notes'));
    expect(find.text('Level note.', findRichText: true), findsOneWidget);
    expect(find.text('This part needs a newer version of the app.'), findsOneWidget);
    expect(find.text('Open on the web'), findsNothing);
    expect(tester.widget<BlockList>(find.byType(BlockList)).render.webPage, isNull);
    verify(() => repository.readLevelDoc(_readme)).called(1);
  });

  testWidgets('the heading is the section step at w600, 44 above and 14 below', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _doc);

    await _pumpNotes(tester, repository);

    final style = tester.widget<Text>(find.text('General notes')).style!;
    expect(style.fontSize, BazaarType.section.size);
    expect(style.fontWeight, FontWeight.w600);
    final heading = tester.getRect(find.text('General notes'));
    final notes = tester.getRect(find.byType(LevelNotes));
    final body = tester.getRect(find.byType(BlockList));
    expect(heading.top - notes.top, 44);
    expect(body.top - heading.bottom, 14);
  });

  testWidgets('the document is read once across rebuilds', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _doc);

    await _pumpNotes(tester, repository);
    await _pumpNotes(tester, repository);

    verify(() => repository.readLevelDoc(_readme)).called(1);
  });

  for (final (name, error) in [
    ('missing', const ContentMissingException(_readme)),
    ('corrupt', const ContentCorruptException(_readme)),
    ('malformed', const ContentFormatException(_readme, 'blocks')),
  ]) {
    testWidgets('an unreadable level document shows the unreadable line ($name)', (tester) async {
      when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => throw error);

      await _pumpNotes(tester, repository);

      expect(find.text('General notes'), findsOneWidget);
      expect(find.byType(ContentUnreadable), findsOneWidget);
      expect(
        find.text('This part of the course could not be read on this device. Restart the app to reload it.'),
        findsOneWidget,
      );
      expect(find.byType(BlockList), findsNothing);
    });
  }

  testWidgets('any other error is rethrown', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => throw StateError('disk'));

    await _pumpNotes(tester, repository);

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('the heading shows while the document is read', (tester) async {
    when(() => repository.readLevelDoc(_readme))
        .thenAnswer((_) => Future<LevelDoc>.delayed(const Duration(seconds: 1), () => _doc));

    await pumpInTheme(
      tester,
      SingleChildScrollView(
        child: LevelNotes(readme: _readme, diagramThemes: _themes),
      ),
      Brightness.light,
      repository: repository,
    );

    expect(find.text('General notes'), findsOneWidget);
    expect(find.byType(BlockList), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Level note.', findRichText: true), findsOneWidget);
  });

  testWidgets('a new readme reads and shows the new level document', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _doc);
    when(() => repository.readLevelDoc(_betaReadme)).thenAnswer((_) async => _betaDoc);

    await _pumpNotes(tester, repository);
    expect(find.text('Level note.', findRichText: true), findsOneWidget);
    await _pumpNotes(tester, repository, readme: _betaReadme);

    expect(find.text('Beta note.', findRichText: true), findsOneWidget);
    expect(find.text('Level note.', findRichText: true), findsNothing);
    verify(() => repository.readLevelDoc(_betaReadme)).called(1);
  });

  testWidgets('a read for a readme no longer shown is dropped', (tester) async {
    final alpha = Completer<LevelDoc>();
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) => alpha.future);
    when(() => repository.readLevelDoc(_betaReadme)).thenAnswer((_) async => _betaDoc);

    await _pumpNotes(tester, repository);
    await _pumpNotes(tester, repository, readme: _betaReadme);
    expect(find.text('Beta note.', findRichText: true), findsOneWidget);
    alpha.complete(_doc);
    await tester.pump();

    expect(find.text('Beta note.', findRichText: true), findsOneWidget);
    expect(find.text('Level note.', findRichText: true), findsNothing);
  });

  testWidgets('an anchor link scrolls its heading into view', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _linkedDoc('later'));

    await _pumpNotes(tester, repository);
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final later = find.text('Later', findRichText: true);
    expect(tester.getTopLeft(later).dy, greaterThan(screenHeight));

    await tester.tapOnText(find.textRange.ofSubstring('Jump'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(later).dy, inInclusiveRange(0, screenHeight));
  });

  testWidgets('an anchor link to no heading of the document throws', (tester) async {
    when(() => repository.readLevelDoc(_readme)).thenAnswer((_) async => _linkedDoc('nowhere'));

    await _pumpNotes(tester, repository);
    await tester.tapOnText(find.textRange.ofSubstring('Jump'));

    expect(tester.takeException(), isA<StateError>());
  });
}

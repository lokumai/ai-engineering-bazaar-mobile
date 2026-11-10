@Tags(['widget'])
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' hide Block;
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

const _diagrams = 'test/fixtures/content/src/api/v1/diagrams';
const _flowLight = 'api/v1/diagrams/flow-light.svg';
const _flowDark = 'api/v1/diagrams/flow-dark.svg';
const _figure = 'course-images/alpha/figure.png';

List<Inline> _text(String text) => [TextInline(text: text)];

ParagraphBlock _paragraph(String text, {bool lead = false}) => ParagraphBlock(inlines: _text(text), lead: lead);

ListItem _item(String text, {bool? checked}) => ListItem(checked: checked, blocks: [_paragraph(text)]);

const _code = CodeBlock(
  language: 'dart',
  lines: [
    [
      CodeToken(text: 'final', role: 'keyword', bold: true),
      CodeToken(text: ' answer = ', role: null, bold: false),
      CodeToken(text: '42', role: 'number', bold: false),
      CodeToken(text: ';', role: null, bold: false),
    ],
    [],
    [CodeToken(text: '// A comment on the answer.', role: 'comment', bold: false)],
  ],
);

String _actionLabel(CalloutKind kind) => 'Act on the ${kind.name}';

/// One block of every type the renderer draws.
final _everyBlock = <Block>[
  _paragraph('A lead paragraph that opens the module.', lead: true),
  _paragraph('A plain paragraph of the module body.'),
  HeadingBlock(depth: 2, id: 'one', mark: null, inlines: _text('Section one')),
  HeadingBlock(depth: 3, id: 'one-a', mark: null, inlines: _text('Subsection one a')),
  ListBlock(ordered: true, start: null, items: [_item('First step'), _item('Second step')]),
  ListBlock(ordered: false, start: null, items: [_item('A point'), _item('Another point')]),
  ListBlock(
    ordered: false,
    start: null,
    items: [_item('Done task', checked: true), _item('Open task', checked: false)],
  ),
  QuoteBlock(label: 'A source', blocks: [_paragraph('A quoted line.')]),
  for (final kind in CalloutKind.values)
    CalloutBlock(
      kind: kind,
      title: _text('A ${kind.name} title'),
      blocks: [_paragraph('The ${kind.name} body.')],
      action: CalloutAction(
        target: ExternalTarget(url: 'https://example.com/${kind.name}'),
        inlines: _text(_actionLabel(kind)),
      ),
    ),
  _code,
  TableBlock(
    number: '1',
    title: 'A table',
    rowHeaders: true,
    align: const [null, CellAlign.right],
    head: [
      Cell(inlines: _text('Name')),
      Cell(inlines: _text('Value')),
    ],
    rows: [
      [Cell(inlines: _text('Alpha')), Cell(inlines: _text('1'))],
      [Cell(inlines: _text('Beta')), Cell(inlines: _text('2'))],
    ],
  ),
  const ImageBlock(
    number: '1.1',
    title: 'A figure',
    note: 'A note.',
    src: _figure,
    alt: 'A figure',
    width: 400,
    height: 300,
  ),
  const DiagramBlock(number: '1.2', title: 'A flow', svgLight: _flowLight, svgDark: _flowDark),
  const RuleBlock(),
  const UnknownBlock(type: 'carousel'),
];

final _engineersOnly = testModule(
  tracks: {
    Track.engineers: testModuleTrack(),
    Track.everyone: testModuleTrack(docs: const {}, webPath: 'everyone/courses/alpha/first/'),
  },
);

final _previous = testRef(key: 'alpha/zero', number: 0, title: 'Zero');
final _next = testRef();

final _written = ReaderWritten(
  doc: testDoc(
    body: _everyBlock,
    toc: const [
      TocEntry(id: 'one', text: 'Section one', depth: 2, mark: null),
      TocEntry(id: 'one-a', text: 'Subsection one a', depth: 3, mark: null),
    ],
    prerequisites: [_previous],
    objectives: const ['Name the parts', 'Use them'],
    next: _next,
    quiz: const [
      QuizItem(question: 'Why?', options: ['Because', 'No'], answer: 0, explain: 'It is so.'),
    ],
  ),
  entry: testModule(),
  moduleCount: 2,
);

final _planned = ReaderPlanned(
  doc: testDoc(
    draft: Draft(
      summary: 'What this module will cover.',
      parts: const ['Part one', 'Part two'],
      written: [_paragraph('A section already written.'), _code],
    ),
    previous: _previous,
    next: _next,
  ),
  entry: testModule(),
  moduleCount: 2,
);

final _notWritten = ReaderNotWritten(entry: _engineersOnly);

void main() {
  late MockContentRepository repository;

  setUp(() {
    repository = MockContentRepository();
    final light = File('$_diagrams/77235fba878b47f1d72f180d8babf2c4.svg').readAsBytesSync();
    final dark = File('$_diagrams/9bb8502b0371cba0d2e5b7e98362455e.svg').readAsBytesSync();
    final png = File('test/fixtures/content/src/$_figure').readAsBytesSync();
    when(() => repository.readObject(_flowLight)).thenAnswer((_) async => Uint8List.fromList(light));
    when(() => repository.readObject(_flowDark)).thenAnswer((_) async => Uint8List.fromList(dark));
    when(() => repository.readObject(_figure)).thenAnswer((_) async => Uint8List.fromList(png));
  });

  /// The reader view over a reader bloc that stays at [state], at `/reader`, on [platform].
  Widget app(ReaderState state, {required TargetPlatform platform}) {
    final bloc = MockModuleReaderBloc();
    whenListen(bloc, const Stream<ReaderState>.empty(), initialState: state);
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (_, _) => BlocProvider<ModuleReaderBloc>.value(
            value: bloc,
            child: ModuleReaderView(quizBuilder: (_, _, _) => Container(height: 48)),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    return bazaarTestApp(router: router, repository: repository, platform: platform);
  }

  /// Pumps [state] at text scale 3.0 and expects no layout fault and each of [controls] reachable by a tap.
  Future<void> expectScalesTo3(WidgetTester tester, ReaderState state, List<Finder> controls) async {
    await pumpAtTextScale(tester, app(state, platform: TargetPlatform.android), scale: 3.0);
    await settleContent(tester);

    expect(tester.takeException(), isNull);
    // The diagram and the figure arrived, so the scale test covers them drawn rather than their unreadable line.
    expect(find.byType(ContentUnreadable), findsNothing);
    for (final control in controls) {
      await tester.ensureVisible(control);
      await tester.pump();
      expectHittable(tester, control);
    }
  }

  group('text scale 3.0', () {
    testWidgets('a written module keeps every control reachable', (tester) async {
      await expectScalesTo3(tester, _written, [
        find.text('Contents'),
        find.byKey(const Key('reader-completion')),
        find.text(_next.title),
        for (final kind in CalloutKind.values) find.text(_actionLabel(kind), findRichText: true),
        find.text('Open on the web'),
      ]);
    });

    testWidgets('a written module whose figure is gone from the device keeps the unreadable line whole', (
      tester,
    ) async {
      when(() => repository.readObject(_figure)).thenThrow(const ContentMissingException(_figure));
      await pumpAtTextScale(tester, app(_written, platform: TargetPlatform.android), scale: 3.0);
      await settleContent(tester);

      expect(tester.takeException(), isNull);
      final unreadable = find.text(S.current.content_unreadable);
      await tester.ensureVisible(unreadable);
      await tester.pump();
      final frame = tester.getRect(find.byType(FigureImage));
      final line = tester.getRect(unreadable);
      expect(frame.contains(line.topLeft) && frame.contains(line.bottomRight - const Offset(0.01, 0.01)), isTrue);
    });

    testWidgets('a planned module keeps its pager reachable', (tester) async {
      await expectScalesTo3(tester, _planned, [find.text(_next.title), find.text(_previous.title)]);
    });

    testWidgets('a module not written For Everyone keeps both ways out reachable', (tester) async {
      await expectScalesTo3(tester, _notWritten, [
        find.text('Read it For Engineers'),
        find.text('See what is written For Everyone'),
      ]);
    });
  });

  testWidgets('a written module meets the platform guidelines', (tester) async {
    await tester.pumpWidget(app(_written, platform: defaultTargetPlatform));
    await settleContent(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('a planned module meets the platform guidelines', (tester) async {
    await tester.pumpWidget(app(_planned, platform: defaultTargetPlatform));
    await settleContent(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('a module not written For Everyone meets the platform guidelines', (tester) async {
    await tester.pumpWidget(app(_notWritten, platform: defaultTargetPlatform));
    await settleContent(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}

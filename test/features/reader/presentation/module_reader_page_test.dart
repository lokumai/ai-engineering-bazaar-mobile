@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/quiz_slot.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';
import '../../../support/url_launcher_stub.dart';

final first = testModule(
  tracks: {
    Track.engineers: testModuleTrack(
      revision: const Revision(hash: 'def5678', date: '2026-11-01'),
      docs: const {'en': 'api/v1/modules/alpha/first/en.json'},
    ),
    Track.everyone: testModuleTrack(
      revision: const Revision(hash: 'abc1234', date: '2026-11-02'),
      docs: const {'en': 'api/v1/modules/alpha/first/everyone/en.json'},
      webPath: 'everyone/courses/alpha/first/',
    ),
  },
);

final second = testModule(
  key: 'alpha/second',
  number: 2,
  tracks: {
    Track.engineers: testModuleTrack(
      title: 'Second',
      drawn: false,
      docs: const {'en': 'api/v1/modules/alpha/second/en.json'},
    ),
    Track.everyone: testModuleTrack(title: 'Second', drawn: false, docs: const {}),
  },
);

final index = testIndex(modules: [first, second]);

List<Inline> _text(String text) => [TextInline(text: text)];

ParagraphBlock _paragraph(String text) => ParagraphBlock(inlines: _text(text), lead: false);

/// Forty filler paragraphs, enough to push what follows below an 844 px screen.
final _filler = [for (var i = 0; i < 40; i++) _paragraph('Filler paragraph number $i of the module body.')];

const _sectionOne = HeadingBlock(
  depth: 2,
  id: 'one',
  mark: null,
  inlines: [TextInline(text: 'Section one')],
);

const _toc = [
  TocEntry(id: 'one', text: 'Section one', depth: 2, mark: null),
  TocEntry(id: 'one-a', text: 'Sub', depth: 3, mark: null),
];

RecordBloc _record({RecordData? record, WriteState writeState = const WriteSaved()}) {
  final bloc = MockRecordBloc();
  whenListen(
    bloc,
    const Stream<RecordState>.empty(),
    initialState: RecordReady(
      record: record ?? RecordData.empty,
      writeState: writeState,
      quarantine: null,
      quarantineKept: false,
      launchReadFailed: false,
      undo: null,
    ),
  );
  return bloc;
}

String _path(GoRouter router) => router.state.uri.path;

void main() {
  late MockModuleReaderBloc readerBloc;

  setUp(() => readerBloc = MockModuleReaderBloc());

  void stateIs(ReaderState state) => whenListen(readerBloc, const Stream<ReaderState>.empty(), initialState: state);

  /// Pumps the reader view of [readerBloc] at `/reader` on a 390x844 surface, with a page showing its location at
  /// every route the reader leaves for.
  Future<GoRouter> pumpReader(
    WidgetTester tester, {
    RecordBloc? record,
    String? fragment,
    QuizBuilder? quizBuilder,
    bool reducedMotion = false,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget location(GoRouterState state) => Scaffold(body: Text('at ${state.uri.path}'));
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (context, _) {
            final view = BlocProvider<ModuleReaderBloc>.value(
              value: readerBloc,
              child: ModuleReaderView(fragment: fragment, quizBuilder: quizBuilder),
            );
            if (!reducedMotion) return view;
            return MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: view);
          },
        ),
        GoRoute(path: '/', builder: (_, state) => location(state)),
        GoRoute(path: '/courses/:level/:module', builder: (_, state) => location(state)),
        GoRoute(path: '/everyone/courses/:level/:module', builder: (_, state) => location(state)),
        GoRoute(path: '/everyone/sheets/:level', builder: (_, state) => location(state)),
        GoRoute(path: '/profile', builder: (_, state) => location(state)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(router: router, content: readyContentBloc(index), record: record ?? _record(), platform: platform),
    );
    await tester.pumpAndSettle();
    return router;
  }

  double top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

  testWidgets('a written module follows the web order', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          prerequisites: [testRef(key: 'alpha/zero', number: 0, title: 'Zero')],
          objectives: const ['Do one thing'],
          body: [_paragraph('Body text.')],
          next: testRef(),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    final order = [
      'First',
      '12 min',
      'Before you start',
      'What you will be able to do',
      'Body text.',
      'Mark this module as complete',
      'Start of the course',
      'MODULE 1 OF 2',
      'Rev def5678 · 2026-11-01',
    ];
    final tops = [for (final text in order) top(tester, find.text(text, findRichText: true))];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('Do one thing'), findsOneWidget);
    expect(find.text('Zero'), findsOneWidget);
    expect(find.text('Planned'), findsNothing);
    expect(find.text('Contents'), findsNothing);
    expect(tester.getSemantics(find.text('First')), isSemantics(isHeader: true, label: 'First'));
  });

  testWidgets('a planned module shows its band, summary and schedule, and no completion', (tester) async {
    final parts = ['Part one', 'Part two'];
    stateIs(
      ReaderPlanned(
        doc: testDoc(
          draft: Draft(summary: 'The plan.', parts: parts, written: null),
          toc: _toc,
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    final band = find.text('Planned · Schedule of parts only', findRichText: true);
    final order = [
      band,
      find.text('First'),
      find.text('The plan.', findRichText: true),
      find.text('Schedule of parts'),
    ];
    final tops = [for (final finder in order) top(tester, finder)];
    expect(tops, orderedEquals([...tops]..sort()));
    for (final text in ['Item', 'Description', '01', 'Part one', '02', 'Part two']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Mark this module as complete'), findsNothing);
    expect(find.byKey(const Key('reader-completion')), findsNothing);
    expect(find.text('12 min'), findsNothing);
    expect(find.text('MODULE 1 OF 2'), findsOneWidget);
    // The web draws no contents rail for a draft (ModuleSheet.tsx:298-300).
    expect(find.text('Contents'), findsNothing);
  });

  testWidgets('a partly written module shows its written sections under the schedule', (tester) async {
    stateIs(
      ReaderPlanned(
        doc: testDoc(
          draft: Draft(summary: null, parts: const ['Part one', 'Part two'], written: [_paragraph('Already here.')]),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Planned · Partly written', findRichText: true), findsOneWidget);
    expect(top(tester, find.text('Already here.', findRichText: true)), greaterThan(top(tester, find.text('02'))));
  });

  testWidgets('the band hides its separator from the screen reader', (tester) async {
    stateIs(
      ReaderPlanned(
        doc: testDoc(draft: const Draft(summary: null, parts: [], written: null)),
        entry: first,
        moduleCount: 2,
      ),
    );
    final handle = tester.ensureSemantics();
    await pumpReader(tester);

    expect(find.text('Schedule of parts'), findsNothing);
    expect(find.bySemanticsLabel('Planned Schedule of parts only'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a completed module shows its day', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    final record = normaliseRecord({
      'sheets': {
        'alpha/first': {'signedOff': '2026-09-03T23:59:00.000Z', 'signedRevision': 'def5678'},
      },
    });
    await pumpReader(tester, record: _record(record: record));

    expect(find.text('Completed 3 Sept 2026'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('a module completed in the other track is not complete here', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(track: Track.everyone, body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    final record = normaliseRecord({
      'sheets': {
        'alpha/first': {'signedOff': '2026-09-03T23:59:00.000Z', 'signedRevision': 'def5678'},
      },
    });
    await pumpReader(tester, record: _record(record: record));

    expect(find.textContaining('Completed'), findsNothing);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('tapping the completion control adds ReaderCompletionToggled', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    final control = find.byKey(const Key('reader-completion'));
    expect(tester.widget(control), isA<CheckboxListTile>());
    await tester.ensureVisible(control);
    await tester.tap(control);

    verify(() => readerBloc.add(const ReaderCompletionToggled())).called(1);
  });

  testWidgets('no completion control while the record loads', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, record: loadingRecordBloc());

    expect(find.byKey(const Key('reader-completion')), findsNothing);
    expect(find.text('MODULE 1 OF 2'), findsOneWidget);
  });

  testWidgets('a failed write shows the write notice under the completion row', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    final router = await pumpReader(tester, record: _record(writeState: const WriteQuota()));

    expect(find.byType(RecordWriteNotice), findsOneWidget);
    expect(
      top(tester, find.byKey(const Key('write-failure'))),
      greaterThanOrEqualTo(tester.getBottomLeft(find.byKey(const Key('reader-completion'))).dy),
    );
    await tester.ensureVisible(find.textContaining('Back up to a file'));
    await tester.tap(find.textContaining('Back up to a file'));
    await tester.pumpAndSettle();
    expect(_path(router), '/profile');
    expect(router.canPop(), isTrue);
  });

  testWidgets('a saved record shows no write notice', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.byKey(const Key('write-failure')), findsNothing);
  });

  testWidgets('the contents drawer lists depth-2 entries and jumps to them', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(toc: _toc, body: [..._filler, _sectionOne]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);
    expect(top(tester, find.text('Section one', findRichText: true)), greaterThan(844));

    await tester.tap(find.text('Contents'));
    await tester.pumpAndSettle();
    final drawer = find.byType(Drawer);
    expect(find.descendant(of: drawer, matching: find.text('On this page')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('Sub')), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.descendant(of: drawer, matching: find.text('Section one')));
    await tester.pumpAndSettle();
    expect(drawer, findsNothing);
    expect(top(tester, find.text('Section one', findRichText: true)), lessThan(844));
  });

  testWidgets('the contents drawer closes on its close button', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(toc: _toc, body: [_sectionOne]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    await tester.tap(find.text('Contents'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('the contents drawer shows the marks when the entries carry them', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          toc: const [TocEntry(id: 'one', text: 'Section one', depth: 2, mark: 'I')],
          body: [_sectionOne],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    await tester.tap(find.text('Contents'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Drawer), matching: find.text('I')), findsOneWidget);
  });

  testWidgets('no contents button without depth-2 entries', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          toc: const [TocEntry(id: 'one-a', text: 'Sub', depth: 3, mark: null)],
          body: [_sectionOne],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Contents'), findsNothing);
  });

  testWidgets('a planned module has no contents button', (tester) async {
    stateIs(
      ReaderPlanned(
        doc: testDoc(
          toc: _toc,
          draft: Draft(summary: null, parts: const ['Part one'], written: [_sectionOne]),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Contents'), findsNothing);
  });

  testWidgets('the fragment scrolls to its heading after the first frame', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(toc: _toc, body: [..._filler, _sectionOne]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, fragment: 'one');

    expect(top(tester, find.text('Section one', findRichText: true)), lessThan(844));
  });

  testWidgets('an anchor link jumps at once under reduced motion', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          toc: _toc,
          body: [
            const ParagraphBlock(
              inlines: [
                LinkInline(
                  target: AnchorTarget(id: 'one'),
                  inlines: [TextInline(text: 'to one')],
                ),
              ],
              lead: false,
            ),
            ..._filler,
            _sectionOne,
          ],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, reducedMotion: true);
    expect(top(tester, find.text('Section one', findRichText: true)), greaterThan(844));

    await tester.tapOnText(find.textRange.ofSubstring('to one'));
    await tester.pump();

    expect(top(tester, find.text('Section one', findRichText: true)), lessThan(844));
  });

  testWidgets('the pager marks a planned target and pushes it', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')], next: testRef(drawn: false)),
        entry: first,
        moduleCount: 2,
      ),
    );
    final router = await pumpReader(tester);

    expect(find.text('Start of the course'), findsOneWidget);
    expect(find.text('Next · Planned'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    await tester.ensureVisible(find.text('Second'));
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    expect(_path(router), '/courses/alpha/second');
    expect(router.canPop(), isTrue);
  });

  testWidgets('the pager links the previous module and ends the course', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          body: [_paragraph('Body text.')],
          previous: testRef(key: 'alpha/zero', number: 0, title: 'Zero', track: Track.everyone),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    final router = await pumpReader(tester);

    expect(find.text('End of the course'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    await tester.ensureVisible(find.text('Zero'));
    await tester.tap(find.text('Zero'));
    await tester.pumpAndSettle();

    expect(_path(router), '/everyone/courses/alpha/zero');
  });

  testWidgets('a pager target with no known track is not a link', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')], next: testRef(track: null)),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.ancestor(of: find.text('Second'), matching: find.byType(FilledButton)), findsNothing);
  });

  testWidgets('a prerequisite that is not written carries the Planned tag', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          body: [_paragraph('Body text.')],
          prerequisites: [testRef(key: 'alpha/zero', number: 0, drawn: false, title: 'Zero')],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    final router = await pumpReader(tester);

    expect(find.text('Zero'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    await tester.tap(find.text('Zero'));
    await tester.pumpAndSettle();
    expect(_path(router), '/courses/alpha/zero');
  });

  testWidgets('a prerequisite with no known track is plain text', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          body: [_paragraph('Body text.')],
          prerequisites: [testRef(key: 'alpha/zero', number: 0, title: 'Zero', track: null)],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Zero'), findsOneWidget);
    expect(find.ancestor(of: find.text('Zero'), matching: find.byType(TextButton)), findsNothing);
  });

  testWidgets('For Everyone not written offers both ways out', (tester) async {
    stateIs(ReaderNotWritten(entry: second));
    final router = await pumpReader(tester);

    expect(find.text(second.tracks[Track.engineers]!.title), findsOneWidget);
    expect(find.text('The For Everyone version of this module is planned.'), findsOneWidget);
    expect(find.text('Mark this module as complete'), findsNothing);
    expect(find.textContaining('MODULE'), findsNothing);

    await tester.tap(find.text('Read it For Engineers'));
    await tester.pumpAndSettle();
    expect(_path(router), '/courses/alpha/second');
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('See what is written For Everyone'));
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/sheets/alpha');
  });

  testWidgets('the quiz slot is filled only when the document has a quiz', (tester) async {
    const quiz = [
      QuizItem(question: 'Why?', options: ['A', 'B'], answer: 0, explain: 'Because.'),
    ];
    List<QuizItem>? built;
    Widget quizBuilder(BuildContext context, List<QuizItem> items) {
      built = items;
      return const SizedBox(key: Key('quiz-slot'), height: 10);
    }

    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')], quiz: quiz),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, quizBuilder: quizBuilder);

    final slot = find.byKey(const Key('quiz-slot'));
    expect(slot, findsOneWidget);
    expect(built, quiz);
    expect(top(tester, slot), greaterThan(top(tester, find.text('Start of the course'))));
    expect(top(tester, slot), lessThan(top(tester, find.text('MODULE 1 OF 2'))));
  });

  testWidgets('no quiz slot without a quiz', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, quizBuilder: (_, _) => const SizedBox(key: Key('quiz-slot'), height: 10));

    expect(find.byKey(const Key('quiz-slot')), findsNothing);
  });

  testWidgets('not found shows the not-found view', (tester) async {
    stateIs(const ReaderNotFound());
    final router = await pumpReader(tester);

    expect(find.byType(NotFoundView), findsOneWidget);
    expect(find.text('No such module'), findsOneWidget);
    expect(
      find.text('This address is not a module in the curriculum. The catalog lists every one that is.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    expect(_path(router), '/');
  });

  testWidgets('a failed read shows the unreadable line', (tester) async {
    stateIs(const ReaderFailed(code: ContentErrorCode.missing));
    await pumpReader(tester);

    expect(find.byType(ContentUnreadable), findsOneWidget);
    expect(
      find.text('This part of the course could not be read on this device. Restart the app to reload it.'),
      findsOneWidget,
    );
  });

  testWidgets('loading shows a spinner', (tester) async {
    stateIs(const ReaderLoading());
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (_, _) => BlocProvider<ModuleReaderBloc>.value(value: readerBloc, child: const ModuleReaderView()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, content: readyContentBloc(index)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an unknown block opens the web page of the document track', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          track: Track.everyone,
          body: [const UnknownBlock(type: 'poll')],
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    final calls = stubOpeningUrlLauncher(canLaunch: true);
    await pumpReader(tester);

    await tester.tap(find.text('Open on the web'));
    await tester.pumpAndSettle();

    expect(calls.launchedUrls, ['https://content.test/everyone/courses/alpha/first/']);
  });

  testWidgets('the footer shows the revision of the document track', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(track: Track.everyone, body: [_paragraph('Body text.')]),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester);

    expect(find.text('Rev abc1234 · 2026-11-02'), findsOneWidget);
  });

  testWidgets('the written page meets the platform guidelines', (tester) async {
    stateIs(
      ReaderWritten(
        doc: testDoc(
          toc: _toc,
          prerequisites: [testRef(key: 'alpha/zero', number: 0, title: 'Zero', drawn: false)],
          objectives: const ['Do one thing'],
          body: [_paragraph('Body text.'), _sectionOne],
          next: testRef(),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(
      tester,
      record: _record(writeState: const WriteQuota()),
      platform: defaultTargetPlatform,
    );

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('the planned page meets the platform guidelines', (tester) async {
    stateIs(
      ReaderPlanned(
        doc: testDoc(
          draft: const Draft(summary: 'The plan.', parts: ['Part one'], written: null),
          previous: testRef(key: 'alpha/zero', number: 0, title: 'Zero'),
        ),
        entry: first,
        moduleCount: 2,
      ),
    );
    await pumpReader(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('the not-written page meets the platform guidelines', (tester) async {
    stateIs(ReaderNotWritten(entry: second));
    await pumpReader(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  group('ModuleReaderPage', () {
    testWidgets('opens the module of its key and track from the content in context', (tester) async {
      final repository = MockContentRepository();
      when(
        () => repository.readModuleDoc('api/v1/modules/alpha/first/everyone/en.json'),
      ).thenAnswer((_) async => testDoc(track: Track.everyone, title: 'First for everyone', body: [_paragraph('Hi.')]));
      final router = GoRouter(
        initialLocation: '/reader',
        routes: [
          GoRoute(
            path: '/reader',
            builder: (_, _) => const ModuleReaderPage(moduleKey: 'alpha/first', track: Track.everyone),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router, content: readyContentBloc(index), repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('First for everyone'), findsOneWidget);
    });

    testWidgets('a go to another module of the same route opens that module', (tester) async {
      // go_router keys a page by its route pattern, so this go rebuilds the same page with another module key.
      final other = testModule(key: 'alpha/second', number: 2);
      final repository = MockContentRepository();
      when(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json'))
          .thenAnswer((_) async => testDoc(title: 'First doc', body: [_paragraph('One.')]));
      when(() => repository.readModuleDoc('api/v1/modules/alpha/second/en.json'))
          .thenAnswer((_) async => testDoc(key: 'alpha/second', title: 'Second doc', body: [_paragraph('Two.')]));
      final router = GoRouter(
        initialLocation: '/courses/alpha/first',
        routes: [
          GoRoute(
            path: '/courses/:level/:module',
            builder: (_, state) => ModuleReaderPage(
              moduleKey: '${state.pathParameters['level']}/${state.pathParameters['module']}',
              track: Track.engineers,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        bazaarTestApp(
          router: router,
          content: readyContentBloc(testIndex(modules: [testModule(), other])),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('First doc'), findsOneWidget);

      router.go('/courses/alpha/second');
      await tester.pumpAndSettle();

      expect(find.text('Second doc'), findsOneWidget);
      expect(find.text('First doc'), findsNothing);
    });

    testWidgets('throws unless the content is ready', (tester) async {
      final content = MockContentBloc();
      whenListen(content, const Stream<ContentState>.empty(), initialState: const ContentLoading());
      final router = GoRouter(
        initialLocation: '/reader',
        routes: [
          GoRoute(
            path: '/reader',
            builder: (_, _) => const ModuleReaderPage(moduleKey: 'alpha/first', track: Track.engineers),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router, content: content));

      expect(tester.takeException(), isA<StateError>());
    });
  });
}

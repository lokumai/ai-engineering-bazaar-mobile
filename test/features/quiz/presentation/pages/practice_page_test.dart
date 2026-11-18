@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// Practice's head and its sessions (plan 13.2 to 13.4, 13.6).

const _items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
];

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', '2026-11-09T10:00:00.000Z'));

Future<(GoRouter, ReviewBloc)> _pump(
  WidgetTester tester, {
  RecordData? record,
  String at = '/practice',
  TargetPlatform platform = TargetPlatform.android,
  ModuleDoc? doc,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((_) async => doc ?? testDoc(quiz: _items));
  final review = ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted());
  addTearDown(review.close);
  final router = AppRouterFactory(initialLocation: at).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      record: readyRecordBloc(record),
      repository: repository,
      review: review,
      platform: platform,
    ),
  );
  await tester.pumpAndSettle();
  return (router, review);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _today = find.byKey(const Key('practice-today'));

void main() {
  testWidgets("Today's review offers the completed modules' questions, and a session asks them once each", (
    tester,
  ) async {
    final (router, review) = await _pump(tester, record: _completed(['alpha/first']));

    expect(find.descendant(of: _today, matching: find.text('2 cards, about 1 min')), findsOneWidget);
    expect(
      find.descendant(of: _today, matching: find.text('First Module')),
      findsOneWidget,
      reason: 'its module',
    );
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    expect(router.state.uri.path, '/practice/review');
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen, outside the shell');
    expect(find.text('Card 1 of 2'), findsOneWidget);

    // The options are shuffled; each has its own words, so the right one is found by them.
    await _tap(tester, find.text('One'));
    expect(find.text('Correct.'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('Card 2 of 2'), findsOneWidget);
    await _tap(tester, find.text('Three'));
    expect(find.textContaining('Not this one.'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('1 of 2 right'), findsOneWidget);

    final history = review.state.history;
    final today = dayNumber(DateTime.now());
    expect(history.doneOn(today), 2, reason: "both count toward the day's five");
    expect(history.cards['alpha/first#0']!.wrong, isFalse);
    expect(history.cards['alpha/first#1']!.wrong, isTrue);

    await _tap(tester, find.byKey(const Key('review-back')));
    expect(router.state.uri.path, '/practice');
    expect(find.descendant(of: _today, matching: find.text('That is all for today')), findsOneWidget);
    expect(find.descendant(of: _today, matching: find.byKey(const Key('practice-today-wrong'))), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('practice-wrong')), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('Wrong answers lists the questions answered wrong by level, and Answer them all asks them (plan 13.4)', (
    tester,
  ) async {
    final (router, review) = await _pump(tester);
    review
      ..add(const ReviewAnswered(key: 'beta/fourth#1', right: false, length: 2))
      ..add(const ReviewAnswered(key: 'alpha/first#0', right: false, length: 2))
      ..add(const ReviewAnswered(key: 'alpha/first#1', right: true, length: 2));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('practice-wrong')));
    expect(router.state.uri.path, '/practice/wrong');
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'a page of the tab');
    expect(find.textContaining('Alpha Level', findRichText: true), findsOneWidget);
    expect(find.textContaining('Beta Level', findRichText: true), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('wrong-alpha/first#0'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('wrong-beta/fourth#1'))).dy),
      reason: "in the course's order",
    );
    expect(find.byKey(const ValueKey('wrong-alpha/first#1')), findsNothing, reason: 'answered right');

    await _tap(tester, find.byKey(const ValueKey('wrong-answer-all')));
    expect(router.state.uri.path, '/practice/wrong/all');
    expect(find.text('Card 1 of 2'), findsOneWidget);
    await _tap(tester, find.text('One'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('2 of 2 right'), findsOneWidget);
    expect(review.state.history.cards['alpha/first#0']!.wrong, isTrue, reason: 'right once is not enough');
    expect(review.state.history.doneOn(dayNumber(DateTime.now())), 0, reason: "not Today's review");

    await _tap(tester, find.byKey(const Key('review-back')));
    await _tap(tester, find.byKey(const ValueKey('wrong-answer-all')));
    await _tap(tester, find.text('One'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.byKey(const Key('review-back')));
    expect(find.text('No wrong answers now.'), findsOneWidget, reason: 'right twice in a row, and they leave');
  });

  testWidgets('a wrong answer links to the section that teaches it, opened with its words marked (plan 13.5)', (
    tester,
  ) async {
    HeadingBlock h(String id, String text) => HeadingBlock(
      depth: 2,
      id: id,
      mark: null,
      inlines: [TextInline(text: text)],
    );
    ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);
    final doc = testDoc(
      body: [
        h('lamps', 'Lamps'),
        p('A lantern holds a flame behind glass, carried by hand at night.'),
        h('oil', 'Oil'),
        p('The wick draws paraffin up from the reservoir, and the flame burns the paraffin.'),
        h('care', 'Care'),
        p('Trim the wick and clean the glass, so the light stays bright.'),
      ],
      quiz: const [
        QuizItem(
          question: 'What does the wick draw up from the reservoir?',
          options: ['Paraffin', 'Water', 'Air', 'Sand'],
          answer: 0,
          explain: 'The wick draws the fuel.',
        ),
      ],
    );
    final (router, _) = await _pump(tester, record: _completed(['alpha/first']), doc: doc);
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    await _tap(tester, find.text('Water'));
    expect(find.text('This is in: Oil'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('review-section-link')));
    expect(router.state.uri.path, '/courses/alpha/first');
    final target = router.state.extra! as ReaderTarget;
    expect(target.fragment, 'oil');
    expect(target.glance, isTrue, reason: 'a look: it keeps no place');
    expect(target.query!.split(' '), containsAll(['paraffin', 'reservoir']));
  });

  testWidgets('a right answer offers no section link', (tester) async {
    HeadingBlock h(String id, String text) => HeadingBlock(
      depth: 2,
      id: id,
      mark: null,
      inlines: [TextInline(text: text)],
    );
    ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);
    final doc = testDoc(
      body: [h('a', 'A'), p('paraffin reservoir wick'), h('b', 'B'), p('glass flame'), h('c', 'C'), p('night hand')],
      quiz: const [
        QuizItem(question: 'Wick reservoir?', options: ['Paraffin', 'Water'], answer: 0, explain: 'E'),
      ],
    );
    await _pump(tester, record: _completed(['alpha/first']), doc: doc);
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    await _tap(tester, find.text('Paraffin'));
    expect(find.text('Correct.'), findsOneWidget);
    expect(find.byKey(const Key('review-section-link')), findsNothing);
  });

  testWidgets('a module in 2 minutes: its Summary point by point, its Key Terms, then Take the quiz (plan 13.7)', (
    tester,
  ) async {
    HeadingBlock h(String id, String text) => HeadingBlock(
      depth: 2,
      id: id,
      mark: null,
      inlines: [TextInline(text: text)],
    );
    ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);
    ListItem term(String name, String definition) => ListItem(
      checked: null,
      taskIndex: null,
      blocks: [
        ParagraphBlock(
          inlines: [
            StrongInline(inlines: [TextInline(text: name)]),
            TextInline(text: ': $definition'),
          ],
          lead: false,
        ),
      ],
    );
    final doc = testDoc(
      body: [
        h('lamps', 'Lamps'),
        p('A lantern holds a flame.'),
        h('words', 'Words'),
        ListBlock(ordered: false, start: null, items: [term('Wick', 'what burns.'), term('Glass', 'keeps wind out.')]),
        h('sum', 'Sum'),
        p('Lanterns carry light.'),
        p('Wicks draw oil.'),
        h('refs', 'Sources'),
        p('A book.'),
      ],
      quiz: _items,
    );
    final (router, _) = await _pump(tester, record: _completed(['alpha/first']), doc: doc);
    expect(find.bySemanticsLabel('A module in 2 minutes, 1 completed module'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('practice-brief')));
    expect(router.state.uri.path, '/practice/brief');
    await _tap(tester, find.byKey(const ValueKey('brief-alpha/first')));
    expect(router.state.uri.path, '/practice/brief/alpha/first');
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen');

    expect(find.bySemanticsLabel('1 of 4'), findsOneWidget, reason: 'two points, one card of terms, the end');
    expect(find.text('Lanterns carry light.', findRichText: true), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('brief-pager')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('2 of 4'), findsOneWidget, reason: 'a swipe goes on');
    expect(find.text('Wicks draw oil.', findRichText: true), findsOneWidget);
    await _tap(tester, find.byKey(const Key('brief-next')));
    expect(find.text('Wick'), findsOneWidget);
    expect(find.text('what burns.', findRichText: true), findsOneWidget);
    await _tap(tester, find.byKey(const Key('brief-next')));
    expect(find.byKey(const Key('brief-next')).hitTestable(), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const Key('brief-next'))).onPressed, isNull, reason: 'the last card');
    await _tap(tester, find.byKey(const Key('brief-take-quiz')));
    expect(router.state.uri.path, '/quiz/alpha/first');
  });

  testWidgets('the glossary lists the terms A to Z; a term opens its definition and counts as looked up (plan 13.8)', (
    tester,
  ) async {
    final (router, review) = await _pump(tester, doc: _termsDoc());
    expect(
      find.bySemanticsLabel('Glossary, 2 terms'),
      findsOneWidget,
      reason: 'the same names in every module: one entry each',
    );
    await _tap(tester, find.byKey(const Key('practice-glossary')));
    expect(router.state.uri.path, '/practice/glossary');
    expect(
      tester.getTopLeft(find.text('Glass')).dy,
      lessThan(tester.getTopLeft(find.text('Wick')).dy),
      reason: 'A to Z',
    );
    expect(find.text('what burns.', findRichText: true), findsNothing);

    await _tap(tester, find.text('Wick'));
    expect(find.text('what burns.', findRichText: true), findsOneWidget);
    expect(find.text('In these modules'), findsOneWidget);
    expect(review.state.history.cards.keys, ['term:engineers/alpha/first#0'], reason: 'looked up');

    await tester.enterText(find.byKey(const ValueKey('glossary-find')), 'gla');
    await tester.pumpAndSettle();
    expect(find.text('Wick'), findsNothing);
    expect(find.text('Glass'), findsOneWidget);
  });

  testWidgets('with no module completed, there is nothing to review today', (tester) async {
    await _pump(tester);
    expect(find.descendant(of: _today, matching: find.text('Nothing to review today')), findsOneWidget);
    expect(find.byKey(const Key('practice-today-start')), findsNothing);
    expect(find.byKey(const Key('practice-today-wrong')), findsNothing, reason: 'no wrong answer either');
  });

  testWidgets('the head and a session meet the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, record: _completed(['alpha/first']), platform: defaultTargetPlatform);
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    await _tap(tester, find.text('One'));
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}

/// A module whose Key Terms are Wick and Glass.
ModuleDoc _termsDoc() {
  HeadingBlock h(String id, String text) => HeadingBlock(
    depth: 2,
    id: id,
    mark: null,
    inlines: [TextInline(text: text)],
  );
  ListItem term(String name, String definition) => ListItem(
    checked: null,
    taskIndex: null,
    blocks: [
      ParagraphBlock(
        inlines: [
          StrongInline(inlines: [TextInline(text: name)]),
          TextInline(text: ': $definition'),
        ],
        lead: false,
      ),
    ],
  );
  return testDoc(
    body: [
      h('words', 'Words'),
      ListBlock(ordered: false, start: null, items: [term('Wick', 'what burns.'), term('Glass', 'keeps wind out.')]),
      h('refs', 'Sources'),
    ],
    quiz: _items,
  );
}

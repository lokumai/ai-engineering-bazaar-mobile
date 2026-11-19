import 'dart:math';

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = QuizItem(question: 'Q', options: ['A0', 'A1', 'A2', 'A3'], answer: 2, explain: 'E');
  const term = GlossaryTerm(
    moduleKey: 'alpha/first',
    index: 0,
    name: 'Lantern',
    forms: ['Lantern'],
    definition: [TextInline(text: 'a light you carry.')],
  );
  group('shuffled (plan 13.6)', () {
    test('moves the answer with its option, and keeps every option', () {
      for (var seed = 0; seed < 20; seed++) {
        final shown = shuffled(item, Random(seed));
        expect(shown.options[shown.answer], 'A2');
        expect(shown.options.toSet(), item.options.toSet());
        expect((shown.question, shown.explain), (item.question, item.explain));
      }
    });

    test('some order differs from the web\'s', () {
      final orders = {for (var seed = 0; seed < 20; seed++) shuffled(item, Random(seed)).options.join()};
      expect(orders.length, greaterThan(1));
    });
  });

  group('reviewItems', () {
    test(
      'a question with its module quiz length, a term asked as one, and nothing for a key the notes do not hold',
      () {
        final items = reviewItems(
          ['alpha/first#1', 'term:engineers/alpha/first#0', 'alpha/first#9', 'gone/module#0'],
          _notes([
            ModuleNotes(
              moduleKey: 'alpha/first',
              quiz: const [item, item],
              terms: [term, _term('alpha/first', 1, 'Wick')],
              termsHeading: 'words',
            ),
          ]),
          titleOf: (key) => 'Title of $key',
          random: Random(1),
        );
        expect(items, hasLength(2));
        expect((items[0] as QuestionItem).length, 2);
        expect(items[0].moduleTitle, 'Title of alpha/first');
        final asked = items[1] as TermItem;
        expect(asked.term, term);
        expect(asked.options.toSet(), {'Lantern', 'Wick'});
        expect(asked.options[asked.answer], 'Lantern');
        expect(asked.termsHeading, 'words', reason: 'the verdict links to the Key Terms');
      },
    );

    test('a term with no other term to set beside it is not asked (plan 13.16)', () {
      final items = reviewItems(
        ['term:engineers/alpha/first#0'],
        _notes([
          const ModuleNotes(moduleKey: 'alpha/first', terms: [term]),
        ]),
        titleOf: (key) => key,
        random: Random(1),
      );
      expect(items, isEmpty);
    });
  });

  group('drawItem (the owner, 2026-11-18)', () {
    final notes = _notes([
      const ModuleNotes(moduleKey: 'alpha/first', quiz: [item, item]),
    ]);
    test('one of the keys at random, never the last one again while another can be drawn', () {
      final seen = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final drawn = drawItem(
          ['alpha/first#0', 'alpha/first#1'],
          notes,
          titleOf: (key) => key,
          random: Random(seed),
          last: 'alpha/first#0',
        );
        expect(drawn!.key, 'alpha/first#1');
        seen.add(drawItem(['alpha/first#0', 'alpha/first#1'], notes, titleOf: (key) => key, random: Random(seed))!.key);
      }
      expect(seen, {'alpha/first#0', 'alpha/first#1'}, reason: 'either, with no last');
    });

    test('a single key comes again; none the notes hold draws nothing', () {
      expect(
        drawItem(['alpha/first#0'], notes, titleOf: (key) => key, random: Random(1), last: 'alpha/first#0')!.key,
        'alpha/first#0',
      );
      expect(drawItem(['gone/module#0', 'alpha/first#7'], notes, titleOf: (key) => key, random: Random(1)), isNull);
    });
  });

  group('termChoices (plan 13.16)', () {
    final notes = _notes([
      ModuleNotes(
        moduleKey: 'alpha/first',
        terms: [term, _term('alpha/first', 1, 'Wick'), _term('alpha/first', 2, 'LANTERN')],
      ),
      ModuleNotes(
        moduleKey: 'alpha/second',
        terms: [_term('alpha/second', 0, 'Glass'), _term('alpha/second', 1, 'Hook')],
      ),
      ModuleNotes(moduleKey: 'beta/third', terms: [_term('beta/third', 0, 'Oil'), _term('beta/third', 1, 'Bowl')]),
    ]);

    test('four names: its own, its module\'s first, then its level\'s, never a name twice in any case', () {
      for (var seed = 0; seed < 20; seed++) {
        final choices = termChoices(term, notes, Random(seed))!;
        expect(choices.options, hasLength(termOptions));
        expect(choices.options[choices.answer], 'Lantern');
        expect(choices.options, contains('Wick'), reason: 'its module first');
        expect(choices.options, isNot(contains('LANTERN')), reason: 'its own name in another case');
        expect(
          choices.options.where((name) => name == 'Glass' || name == 'Hook'),
          hasLength(2),
          reason: 'then its level',
        );
        expect(choices.options, isNot(anyOf(contains('Oil'), contains('Bowl'))), reason: 'the level filled the four');
      }
    });

    test('the other levels fill what its own cannot', () {
      final choices = termChoices(_term('beta/third', 0, 'Oil'), notes, Random(3))!;
      expect(choices.options, hasLength(termOptions));
      expect(choices.options, contains('Bowl'));
      expect(choices.options[choices.answer], 'Oil');
    });

    test('the right name stands in every place across shuffles', () {
      final places = {for (var seed = 0; seed < 40; seed++) termChoices(term, notes, Random(seed))!.answer};
      expect(places, {0, 1, 2, 3});
    });
  });

  group('ReviewSessionCubit', () {
    test('a question takes one answer, which goes to the history once; Next waits for it', () {
      final answers = <(String, bool)>[];
      final question = QuestionItem(key: 'alpha/first#0', moduleTitle: 'First', item: item, length: 2);
      final cubit = ReviewSessionCubit([question, question], onAnswered: (it, right) => answers.add((it.key, right)));
      addTearDown(cubit.close);

      cubit.next();
      expect((cubit.state as ReviewAt).index, 0, reason: 'not answered yet');
      cubit.pick(1);
      cubit.pick(2);
      expect(answers, [('alpha/first#0', false)], reason: 'the first answer is final');
      expect((cubit.state as ReviewAt).pick, 1);

      cubit.next();
      cubit.pick(2);
      cubit.next();
      expect(cubit.state, isA<ReviewFinished>());
      expect((cubit.state as ReviewFinished).right, 1);
    });

    test('a term is answered as a question: one pick, graded, then Next (plan 13.16)', () {
      final answers = <bool>[];
      const card = TermItem(
        key: 'term:engineers/alpha/first#0',
        moduleTitle: 'First',
        term: term,
        options: ['Wick', 'Lantern', 'Glass'],
        answer: 1,
      );
      final cubit = ReviewSessionCubit([card, card], onAnswered: (_, right) => answers.add(right));
      addTearDown(cubit.close);

      cubit.next();
      expect((cubit.state as ReviewAt).index, 0, reason: 'not answered yet');
      cubit.pick(0);
      cubit.pick(1);
      expect(answers, [false], reason: 'the first answer is final');
      expect(cubit.state, const ReviewAt(index: 0, results: [false, null], pick: 0));
      cubit.next();
      cubit.pick(1);
      cubit.next();
      expect(answers, [false, true]);
      expect(cubit.state, const ReviewFinished(results: [false, true]));
    });

    test('endless: Next after the last card draws another, and Finish ends with the cards answered '
        '(the owner, 2026-11-18)', () {
      QuestionItem question(int i) => QuestionItem(key: 'alpha/first#$i', moduleTitle: 'First', item: item, length: 9);
      var drawn = 0;
      final cubit = ReviewSessionCubit(
        [question(0)],
        onAnswered: (_, _) {},
        draw: (last) {
          drawn++;
          return question(int.parse(last.key.split('#').last) + 1);
        },
      );
      addTearDown(cubit.close);
      expect(cubit.endless, isTrue);

      for (var i = 0; i < 3; i++) {
        cubit
          ..pick(2)
          ..next();
      }
      expect(cubit.state, const ReviewAt(index: 3, results: [true, true, true, null]));
      expect(cubit.items.map((card) => card.key), ['alpha/first#0', 'alpha/first#1', 'alpha/first#2', 'alpha/first#3']);
      expect(drawn, 3);

      cubit.finish();
      expect(cubit.state, const ReviewFinished(results: [true, true, true]), reason: 'the card unanswered left out');
      expect(cubit.items, hasLength(3));
    });

    test('a session of fixed cards draws none and is not endless', () {
      final cubit = ReviewSessionCubit([
        QuestionItem(key: 'alpha/first#0', moduleTitle: 'First', item: item, length: 1),
      ], onAnswered: (_, _) {});
      addTearDown(cubit.close);
      expect(cubit.endless, isFalse);
      cubit
        ..pick(2)
        ..next();
      expect(cubit.state, const ReviewFinished(results: [true]));
    });

    test('a session needs a card', () {
      expect(() => ReviewSessionCubit(const [], onAnswered: (_, _) {}), throwsArgumentError);
    });
  });
}

StudyNotesReady _notes(List<ModuleNotes> modules) =>
    StudyNotesReady(track: Track.engineers, language: 'en', modules: modules);

GlossaryTerm _term(String moduleKey, int index, String name) => GlossaryTerm(
  moduleKey: moduleKey,
  index: index,
  name: name,
  forms: [name],
  definition: [TextInline(text: 'what $name is.')],
);

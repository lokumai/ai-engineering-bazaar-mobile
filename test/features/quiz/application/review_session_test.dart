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
  final notes = StudyNotesReady(
    track: Track.engineers,
    language: 'en',
    modules: const [
      ModuleNotes(
        moduleKey: 'alpha/first',
        quiz: [item, item],
        terms: [term],
        sections: [NoteSection(id: 'lamps', title: 'Lamps', text: 'Night falls. A lantern lights the road.')],
      ),
    ],
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
    test('a question with its module quiz length, a term, and nothing for a key the notes do not hold', () {
      final items = reviewItems(
        ['alpha/first#1', 'term:engineers/alpha/first#0', 'alpha/first#9', 'gone/module#0'],
        notes,
        titleOf: (key) => 'Title of $key',
        random: Random(1),
      );
      expect(items, hasLength(2));
      expect((items[0] as QuestionItem).length, 2);
      expect(items[0].moduleTitle, 'Title of alpha/first');
      expect((items[1] as TermItem).term, term);
      expect(
        (items[1] as TermItem).usage?.text,
        'A lantern lights the road.',
        reason: 'the sentence of the module that uses it (the owner, 2026-11-18)',
      );
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

    test('a term shows its definition when asked, then is known or not yet, which goes on to the next card', () {
      final answers = <bool>[];
      const card = TermItem(key: 'term:engineers/alpha/first#0', moduleTitle: 'First', term: term);
      final cubit = ReviewSessionCubit([card, card], onAnswered: (_, right) => answers.add(right));
      addTearDown(cubit.close);

      cubit.judge(knew: true);
      expect(answers, isEmpty, reason: 'not before the definition shows');
      cubit.pick(0);
      expect(answers, isEmpty, reason: 'a term has no options');
      cubit.reveal();
      expect((cubit.state as ReviewAt).revealed, isTrue);
      cubit.judge(knew: false);
      expect(answers, [false]);
      expect(
        cubit.state,
        const ReviewAt(index: 1, results: [false, null]),
        reason: 'the answer is the way on: no Next for a term (the owner, 2026-11-18)',
      );
      cubit.reveal();
      cubit.judge(knew: true);
      expect(answers, [false, true]);
      expect(cubit.state, const ReviewFinished(results: [false, true]), reason: 'after the last, the results');
    });

    test('a session needs a card', () {
      expect(() => ReviewSessionCubit(const [], onAnswered: (_, _) {}), throwsArgumentError);
    });
  });
}

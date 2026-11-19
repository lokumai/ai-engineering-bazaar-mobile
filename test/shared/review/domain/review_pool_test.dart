import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_pool.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = QuizItem(question: 'Q', options: ['a', 'b'], answer: 0, explain: 'E');
  const term = GlossaryTerm(moduleKey: 'alpha/second', index: 0, name: 'Wick', forms: ['Wick'], definition: []);
  const modules = [
    ModuleNotes(moduleKey: 'alpha/first', quiz: [item, item]),
    ModuleNotes(moduleKey: 'alpha/second', quiz: [item], terms: [term]),
  ];

  test("the completed modules' questions for Today's review, every question for Wrong answers", () {
    final record = signOff(RecordData.empty, 'alpha/second', 'abc1234', '2026-11-17T10:00:00.000Z');
    final pool = reviewPool(track: Track.engineers, record: record, modules: modules);
    expect(pool.completed, ['alpha/second']);
    expect(pool.studied, ['alpha/second']);
    expect(pool.questions, ['alpha/second#0']);
    expect(pool.everyQuestion, ['alpha/first#0', 'alpha/first#1', 'alpha/second#0']);
    expect(pool.terms, ['term:engineers/alpha/second#0']);
    expect(pool.newTerms, ['term:engineers/alpha/second#0'], reason: "a completed module's terms, never seen yet");

    final history = ReviewHistory.empty.answered('alpha/first#1', right: false, today: 1, length: 2);
    expect(pool.wrong(history), ['alpha/first#1'], reason: 'a question of a module not completed still counts');
    expect(pool.today(history, 1), [
      'alpha/second#0',
      'term:engineers/alpha/second#0',
    ], reason: 'questions and terms mixed, a question first (the owner, 2026-11-18)');
  });

  test('a module completed in the other track is not completed in this one', () {
    final record = signOff(RecordData.empty, 'alpha/second', 'abc1234', '2026-11-17T10:00:00.000Z');
    expect(reviewPool(track: Track.everyone, record: record, modules: modules).completed, isEmpty);
  });

  test(
    'before any module is completed, review draws on the first with a question or a term (the owner, 2026-11-18)',
    () {
      final pool = reviewPool(
        track: Track.engineers,
        record: RecordData.empty,
        modules: const [
          ModuleNotes(moduleKey: 'alpha/zero'),
          ...modules,
        ],
      );
      expect(pool.completed, isEmpty);
      expect(pool.studied, ['alpha/first'], reason: 'a module with nothing to ask is passed over');
      expect(pool.questions, ['alpha/first#0', 'alpha/first#1']);
      expect(pool.newTerms, isEmpty);
      expect(
        reviewPool(
          track: Track.engineers,
          record: RecordData.empty,
          modules: const [ModuleNotes(moduleKey: 'a/b')],
        ).studied,
        isEmpty,
      );
    },
  );
}

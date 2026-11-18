import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/module_brief_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GlossaryTerm term(int index) =>
      GlossaryTerm(moduleKey: 'alpha/first', index: index, name: 'T$index', forms: ['T$index'], definition: const []);
  ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

  ModuleNotes notes(int terms) => ModuleNotes(
    moduleKey: 'alpha/first',
    summary: [p('a'), p('b'), p('c')],
    terms: [for (var i = 0; i < terms; i++) term(i)],
    quiz: const [
      QuizItem(question: 'Q', options: ['a', 'b'], answer: 0, explain: 'E'),
    ],
  );

  test('the Summary on one card when it fits, the Key Terms five to a card, then the end', () {
    final cards = briefCards(notes(11));
    expect(cards.map((card) => card.runtimeType), [SummaryCard, TermsCard, TermsCard, TermsCard, EndCard]);
    expect((cards.first as SummaryCard).blocks, hasLength(3), reason: 'not cut for nothing (the owner, 2026-11-18)');
    expect([for (final card in cards.whereType<TermsCard>()) card.terms.length], [5, 5, 1]);
    expect((cards.last as EndCard).hasQuiz, isTrue);
  });

  test('a Summary too long for one card is cut between its blocks, as few cards as fit', () {
    final cards = briefCards(notes(0), fits: (blocks) => blocks.length <= 2);
    expect([for (final card in cards.whereType<SummaryCard>()) card.blocks.length], [2, 1]);
    expect(briefCards(notes(0), fits: (_) => false).whereType<SummaryCard>().map((card) => card.blocks.length), [
      1,
      1,
      1,
    ], reason: 'a block too long for a card still has its own');
  });

  test('a module with no quiz ends without one', () {
    expect((briefCards(const ModuleNotes(moduleKey: 'alpha/first')).single as EndCard).hasQuiz, isFalse);
  });
}

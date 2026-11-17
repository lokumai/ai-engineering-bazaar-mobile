import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/module_brief_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GlossaryTerm term(int index) =>
      GlossaryTerm(moduleKey: 'alpha/first', index: index, name: 'T$index', forms: ['T$index'], definition: const []);
  ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

  test('the Summary point by point, the Key Terms four to a card, then the end', () {
    final cards = briefCards(
      ModuleNotes(
        moduleKey: 'alpha/first',
        summary: [p('a'), p('b')],
        terms: [for (var i = 0; i < 9; i++) term(i)],
        quiz: const [
          QuizItem(question: 'Q', options: ['a', 'b'], answer: 0, explain: 'E'),
        ],
      ),
    );
    expect(cards.map((card) => card.runtimeType), [SummaryCard, SummaryCard, TermsCard, TermsCard, TermsCard, EndCard]);
    expect([for (final card in cards.whereType<TermsCard>()) card.terms.length], [4, 4, 1]);
    expect((cards.last as EndCard).hasQuiz, isTrue);
  });

  test('a module with no quiz ends without one', () {
    expect((briefCards(const ModuleNotes(moduleKey: 'alpha/first')).single as EndCard).hasQuiz, isFalse);
  });
}

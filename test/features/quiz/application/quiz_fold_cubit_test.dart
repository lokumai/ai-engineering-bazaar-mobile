import 'package:ai_engineering_bazaar/features/quiz/application/quiz_fold_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('untouched, the next level is open, and nothing when every module is complete', () {
    final fold = QuizFoldCubit();
    addTearDown(fold.close);

    expect(fold.openWith('alpha'), {'alpha'});
    expect(fold.openWith(null), isEmpty);
  });

  test('a toggle fixes the levels from what was showing', () {
    final fold = QuizFoldCubit();
    addTearDown(fold.close);

    fold.toggle('alpha', 'alpha');
    expect(fold.openWith('beta'), isEmpty, reason: 'no longer follows the next module');
    fold.toggle('beta', 'beta');
    expect(fold.openWith('alpha'), {'beta'});
  });
}

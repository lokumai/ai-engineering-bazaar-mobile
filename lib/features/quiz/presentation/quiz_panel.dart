import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/quiz/application/quiz_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_frame.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_option.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The quiz panel for the reader's quiz slot (Decision A38); the router passes it as the reader's `quizBuilder`.
Widget buildQuizPanel(BuildContext context, String moduleKey, List<QuizItem> items) =>
    QuizPanel(moduleKey: moduleKey, items: items);

/// A [QuizCubit] over [items] that hands each finished attempt to the scores of this device (plan 1W), and each answer
/// to Practice's history (plan 13.1).
QuizCubit quizCubitFor(BuildContext context, String moduleKey, List<QuizItem> items) {
  final scores = context.read<QuizScoresBloc>()..add(QuizLengthSeen(key: moduleKey, total: items.length));
  final review = context.read<ReviewBloc>()..add(ReviewQuizLengthSeen(moduleKey: moduleKey, length: items.length));
  return QuizCubit(
    items,
    onFinished: (right, total) => scores.add(QuizScoreRecorded(key: moduleKey, right: right, total: total)),
    onAnswered: (index, right) =>
        review.add(ReviewAnswered(key: questionKey(moduleKey, index), right: right, length: items.length)),
  );
}

/// The quiz at the end of a module on either track (web D137, `QuickQuiz.tsx`, `ModuleSheet.tsx:493-509`) as the
/// redesign draws it (plan Phase 1F): a card in the reader that opens the quiz full screen over the reader, one
/// question at a time, then the score and a recap. The quiz has no route of its own, as the web's has none (A9).
///
/// The [QuizCubit] lives with the card, so closing the quiz and opening it again keeps the answers, as collapsing the
/// web's disclosure does; nothing is written to the record (R51), and the score is kept on this device (plan 1W).
class QuizPanel extends StatelessWidget {
  const QuizPanel({super.key, required this.moduleKey, required this.items});

  /// `<level>/<module>`, which the score is kept under.
  final String moduleKey;
  final List<QuizItem> items;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => quizCubitFor(context, moduleKey, items),
      child: _QuizCard(moduleKey: moduleKey, items: items),
    );
  }
}

/// The card that opens the quiz: the question disc, the title, the count and an arrow, one button as a whole.
class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.moduleKey, required this.items});

  final String moduleKey;
  final List<QuizItem> items;

  void _open(BuildContext context) {
    final cubit = context.read<QuizCubit>();
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: QuizScreen(moduleKey: moduleKey, items: items),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    return BazaarCard(
      key: const Key('quiz-card'),
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              child: Text(
                '?',
                style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  s.quiz_title,
                  style: TextStyle(
                    fontSize: BazaarType.control.size,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceTitle,
                  ),
                ),
                Text(
                  s.quiz_subtitle(items.length),
                  style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          ExcludeSemantics(child: Icon(Icons.arrow_forward, color: colors.primary)),
        ],
      ),
    );
  }
}

/// The quiz full screen: the bar with the quiz's title and a close button over the lattice band, then the current
/// question or the results. Closing returns to the reader where it was, or to the page that opened the quiz (plan 1AC).
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.moduleKey, required this.items, this.title, this.doneLabel});

  /// `<level>/<module>`, whose kept score the results compare with.
  final String moduleKey;
  final List<QuizItem> items;

  /// The bar's title; the reader's quiz title when null.
  final String? title;

  /// The results' closing button; Back to the module when null.
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    return QuizFrame(
      title: title ?? S.of(context).quiz_title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: _QuizBody(moduleKey: moduleKey, items: items, doneLabel: doneLabel),
      ),
    );
  }
}

/// The open panel: the current question or the results, by the [QuizCubit]'s state.
class _QuizBody extends StatefulWidget {
  const _QuizBody({required this.moduleKey, required this.items, required this.doneLabel});

  final String moduleKey;
  final List<QuizItem> items;
  final String? doneLabel;

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  final _questionFocus = FocusNode(debugLabel: 'quiz-question');

  @override
  void dispose() {
    _questionFocus.dispose();
    super.dispose();
  }

  /// The question takes the focus on every move (web `QuickQuiz.tsx:80-84`), once the frame that draws it is built.
  void _focusQuestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _questionFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listenWhen: (previous, current) =>
          current is QuizAsking && (previous is! QuizAsking || previous.index != current.index),
      listener: (_, _) => _focusQuestion(),
      builder: (context, state) => switch (state) {
        QuizAsking(:final index, :final picks) => _QuestionView(
          items: widget.items,
          index: index,
          picks: picks,
          focusNode: _questionFocus,
        ),
        QuizResults(:final picks) => _ResultsView(
          moduleKey: widget.moduleKey,
          items: widget.items,
          picks: picks,
          doneLabel: widget.doneLabel,
        ),
      },
    );
  }
}

/// Question [index] with its options, the verdict once answered, and Previous with Next or See results.
class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.items, required this.index, required this.picks, required this.focusNode});

  final List<QuizItem> items;
  final int index;
  final List<int?> picks;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<QuizCubit>();
    final item = items[index];
    final pick = picks[index];
    final answered = pick != null;
    final last = index == items.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              s.quiz_progress(index + 1, items.length),
              style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurface),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) _StepDot(item: items[i], pick: picks[i], current: i == index),
                ],
              ),
            ),
            TextButton(onPressed: cubit.restart, child: Text(s.quiz_start_over)),
          ],
        ),
        const SizedBox(height: 12),
        Focus(
          focusNode: focusNode,
          child: Text(
            item.question,
            style: TextStyle(fontSize: BazaarType.lead.size, fontWeight: FontWeight.w600, color: colors.onSurfaceTitle),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < item.options.length; i++) ...[
          QuizOptionButton(
            letter: quizLetter(i),
            text: item.options[i],
            selected: pick == i,
            outcome: !answered
                ? QuizOutcome.open
                : i == item.answer
                ? QuizOutcome.right
                : pick == i
                ? QuizOutcome.wrong
                : QuizOutcome.other,
            onPressed: answered ? null : () => cubit.pick(i),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          key: const Key('quiz-verdict'),
          container: true,
          liveRegion: true,
          child: answered ? QuizVerdict(item: item, right: pick == item.answer) : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: index == 0 ? null : cubit.previous, child: Text(s.quiz_previous)),
            if (last)
              FilledButton(onPressed: answered ? cubit.showResults : null, child: Text(s.quiz_see_results))
            else
              FilledButton(onPressed: answered ? cubit.next : null, child: Text(s.quiz_next)),
          ],
        ),
      ],
    );
  }
}

/// One step of the top row: open (a `lineStrong` ring), right (`success`) or wrong (`fault`), the current one ringed in
/// `primary`.
class _StepDot extends StatelessWidget {
  const _StepDot({required this.item, required this.pick, required this.current});

  final QuizItem item;
  final int? pick;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final fill = switch (pick) {
      null => null,
      final p when p == item.answer => BazaarFixedColors.success,
      _ => colors.fault,
    };
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: current ? colors.primary : (fill ?? colors.lineStrong), width: current ? 2 : 1),
      ),
    );
  }
}

/// The score, the attempt before it and the best kept on this device, a recap of every question that returns to it,
/// then Back to the questions and Start over.
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.moduleKey, required this.items, required this.picks, required this.doneLabel});

  final String moduleKey;
  final List<QuizItem> items;
  final List<int?> picks;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<QuizCubit>();
    final score = cubit.score;
    final count = s.quiz_score_count(score, items.length);
    final style = TextStyle(fontSize: BazaarType.body.size, color: colors.onSurface);
    final kept = context.select<QuizScoresBloc, QuizScore?>((bloc) => bloc.state.of(moduleKey));
    final previous = kept?.previous;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The score as the mockup's dial; the line under it says the same for assistive technology.
        Center(
          child: ExcludeSemantics(
            child: CompletionDial(
              done: score,
              total: items.length,
              color: BazaarFixedColors.success,
              center: '$score/${items.length}',
              semanticLabel: count,
              size: 120,
              ring: 12,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Semantics(
          key: const Key('quiz-score'),
          container: true,
          liveRegion: true,
          label: '$count ${s.quiz_score_rest}',
          excludeSemantics: true,
          child: Wrap(
            spacing: 5,
            children: [
              Text(count, style: style.copyWith(fontWeight: FontWeight.w700)),
              Text(s.quiz_score_rest, style: style),
            ],
          ),
        ),
        if (kept != null && previous != null && kept.total == items.length) ...[
          const SizedBox(height: 4),
          Text(
            s.quiz_score_before(previous, kept.best, kept.total),
            key: const Key('quiz-score-before'),
            style: style.copyWith(color: colors.onSurfaceMuted),
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          _RecapRow(
            number: i + 1,
            count: items.length,
            question: items[i].question,
            right: picks[i] == items[i].answer,
            onPressed: () => cubit.go(i),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: cubit.backToQuestions, child: Text(s.quiz_back_to_questions)),
            OutlinedButton(onPressed: cubit.restart, child: Text(s.quiz_start_over)),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(doneLabel ?? s.quiz_back_to_module),
        ),
      ],
    );
  }
}

/// One row of the recap: the question's number, its text and a check or cross; a button back to that question.
class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.number,
    required this.count,
    required this.question,
    required this.right,
    required this.onPressed,
  });

  final int number;

  /// The number of questions: the recap's widest number sets the width of every row's number column.
  final int count;
  final String question;
  final bool right;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final style = TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface);
    return Semantics(
      container: true,
      button: true,
      label: '$question${right ? s.quiz_recap_correct : s.quiz_recap_wrong}',
      onTap: onPressed,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(BazaarRadii.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(Theme.of(context).platform)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                // 24 at text scale 1.0, wider when larger text needs it, the same in every row.
                SizedBox(
                  width: math.max(24.0, (quizTextSize(context, '$count.', style).width + 4).ceilToDouble()),
                  child: Text('$number.', style: style),
                ),
                ExcludeSemantics(
                  child: Icon(
                    right ? Icons.check : Icons.close,
                    color: right ? BazaarFixedColors.success : colors.fault,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(question, style: style)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

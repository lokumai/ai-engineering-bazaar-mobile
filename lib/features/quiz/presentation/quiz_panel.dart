import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/quiz/application/quiz_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The quiz panel for the reader's quiz slot (Decision A38); the router passes it as the reader's `quizBuilder`.
Widget buildQuizPanel(BuildContext context, List<QuizItem> items) => QuizPanel(items: items);

/// The letter of option [index]: A, B, C, D (web `QuickQuiz.tsx:35`).
String _letter(int index) => String.fromCharCode(0x41 + index);

/// The size [text] takes in [style] at the current text scale, so a box sized from it grows with the text (spec 3.10).
Size _textSize(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

/// The quiz at the end of a For Engineers module, as the web's `QuickQuiz.tsx` in its disclosure
/// (`ModuleSheet.tsx:493-509`): collapsed at start, one question at a time, then the score and a recap.
///
/// The [QuizCubit] sits above the disclosure, so collapsing the panel keeps the answers; nothing is written to the
/// record.
class QuizPanel extends StatelessWidget {
  const QuizPanel({super.key, required this.items});

  final List<QuizItem> items;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    return BlocProvider(
      create: (_) => QuizCubit(items),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.primary),
          borderRadius: const BorderRadius.all(BazaarRadii.xl),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(BazaarRadii.xl),
          child: Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
              maintainState: true,
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              iconColor: colors.onSurface,
              collapsedIconColor: colors.onSurface,
              leading: ExcludeSemantics(
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  child: Text(
                    '?',
                    style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              title: Text(
                s.quiz_title,
                style: TextStyle(
                  fontSize: BazaarType.item.size,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceTitle,
                ),
              ),
              subtitle: Text(
                s.quiz_subtitle(items.length),
                style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
              ),
              children: [_QuizBody(items: items)],
            ),
          ),
        ),
      ),
    );
  }
}

/// The open panel: the current question or the results, by the [QuizCubit]'s state.
class _QuizBody extends StatefulWidget {
  const _QuizBody({required this.items});

  final List<QuizItem> items;

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
        QuizResults(:final picks) => _ResultsView(items: widget.items, picks: picks),
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
          _OptionButton(
            letter: _letter(i),
            text: item.options[i],
            selected: pick == i,
            outcome: !answered
                ? _Outcome.open
                : i == item.answer
                ? _Outcome.right
                : pick == i
                ? _Outcome.wrong
                : _Outcome.other,
            onPressed: () => cubit.pick(i),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          key: const Key('quiz-verdict'),
          container: true,
          liveRegion: true,
          child: answered ? _Verdict(item: item, right: pick == item.answer) : const SizedBox.shrink(),
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

/// How an option is drawn: before the answer, the right option, the wrong pick, or any other option once answered.
enum _Outcome { open, right, wrong, other }

/// One option: its letter and text in `onSurface` on `surfaceRaised` in every state (the web's `on-primary` letter on
/// a `success` or `fault` disc reads under 4.5:1), the outcome shown by an edge and an icon only.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.text,
    required this.selected,
    required this.outcome,
    required this.onPressed,
  });

  final String letter;
  final String text;
  final bool selected;
  final _Outcome outcome;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final edge = switch (outcome) {
      _Outcome.right => const BorderSide(color: BazaarFixedColors.success, width: 2),
      _Outcome.wrong => BorderSide(color: colors.fault, width: 2),
      _Outcome.open || _Outcome.other => BorderSide(color: colors.lineStrong),
    };
    final ink = outcome == _Outcome.other ? colors.onSurfaceMuted : colors.onSurface;
    final icon = switch (outcome) {
      _Outcome.right => const Icon(Icons.check, color: BazaarFixedColors.success),
      _Outcome.wrong => Icon(Icons.close, color: colors.fault),
      _Outcome.open || _Outcome.other => null,
    };
    final target = minTapTarget(Theme.of(context).platform);
    final letterStyle = TextStyle(fontSize: BazaarType.mark.size, fontWeight: FontWeight.w600, color: ink);
    // 26 at text scale 1.0; larger text grows the circle around its letter instead of cutting the letter off.
    final letterSize = _textSize(context, letter, letterStyle);
    final diameter = math.max(26.0, (math.max(letterSize.width, letterSize.height) + 8).ceilToDouble());
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: '$letter $text',
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(side: edge, borderRadius: const BorderRadius.all(BazaarRadii.md)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.md)),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: target),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: diameter,
                    height: diameter,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.lineStrong),
                    ),
                    child: Text(letter, style: letterStyle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: BazaarType.control.size, color: ink),
                    ),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), ExcludeSemantics(child: icon)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The verdict of an answered question and its explanation, on `surfaceSunken` with a 3 px edge in `success` or
/// `fault`; the text stays `onSurface` (Decision A18).
class _Verdict extends StatelessWidget {
  const _Verdict({required this.item, required this.right});

  final QuizItem item;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final edge = right ? BazaarFixedColors.success : colors.fault;
    final style = TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(left: BorderSide(color: edge, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(right ? Icons.check : Icons.close, color: edge, size: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  right ? s.quiz_correct : s.quiz_wrong(_letter(item.answer)),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.explain, style: style),
        ],
      ),
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

/// The score, a recap of every question that returns to it, then Back to the questions and Start over.
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.items, required this.picks});

  final List<QuizItem> items;
  final List<int?> picks;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<QuizCubit>();
    final score = cubit.score;
    final count = s.quiz_score_count(score, items.length);
    final style = TextStyle(fontSize: BazaarType.body.size, color: colors.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
            FilledButton(onPressed: cubit.restart, child: Text(s.quiz_start_over)),
          ],
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
                  width: math.max(24.0, (_textSize(context, '$count.', style).width + 4).ceilToDouble()),
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

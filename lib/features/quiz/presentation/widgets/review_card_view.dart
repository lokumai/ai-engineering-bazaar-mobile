import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/section_finder.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_option.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:go_router/go_router.dart';

/// A Practice session's page by the [ReviewSessionCubit]'s state: the card shown, or the results.
class ReviewSessionView extends StatefulWidget {
  const ReviewSessionView({super.key});

  @override
  State<ReviewSessionView> createState() => _ReviewSessionViewState();
}

class _ReviewSessionViewState extends State<ReviewSessionView> {
  final _focus = FocusNode(debugLabel: 'review-card');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewSessionCubit, ReviewSessionState>(
      // A new card takes the focus, as a new question of a module's quiz does.
      listenWhen: (previous, current) =>
          current is ReviewAt && (previous is! ReviewAt || previous.index != current.index),
      listener: (_, _) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      }),
      builder: (context, state) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: switch (state) {
          ReviewAt() => _CardView(at: state, focus: _focus),
          ReviewFinished() => _Results(finished: state),
        },
      ),
    );
  }
}

/// The card shown, with Next or Finish once it is answered.
class _CardView extends StatelessWidget {
  const _CardView({required this.at, required this.focus});

  final ReviewAt at;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<ReviewSessionCubit>();
    final item = cubit.items[at.index];
    final last = at.index == cubit.items.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.review_progress(at.index + 1, cubit.items.length),
          style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurface),
        ),
        Text(
          item.moduleTitle,
          style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (item) {
          QuestionItem() => _QuestionCard(item: item, at: at, focus: focus),
          TermItem() => _TermCard(item: item, at: at, focus: focus),
        },
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            key: const Key('review-next'),
            onPressed: at.answered ? cubit.next : null,
            child: Text(last ? s.review_finish : s.quiz_next),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.item, required this.at, required this.focus});

  final QuestionItem item;
  final ReviewAt at;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final cubit = context.read<ReviewSessionCubit>();
    final quiz = item.item;
    final pick = at.pick;
    final answered = at.answered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          focusNode: focus,
          child: Text(
            quiz.question,
            style: TextStyle(fontSize: BazaarType.lead.size, fontWeight: FontWeight.w600, color: colors.onSurfaceTitle),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < quiz.options.length; i++) ...[
          QuizOptionButton(
            letter: quizLetter(i),
            text: quiz.options[i],
            selected: pick == i,
            outcome: !answered
                ? QuizOutcome.open
                : i == quiz.answer
                ? QuizOutcome.right
                : pick == i
                ? QuizOutcome.wrong
                : QuizOutcome.other,
            onPressed: answered ? null : () => cubit.pick(i),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Semantics(
          key: const Key('review-verdict'),
          container: true,
          liveRegion: true,
          child: answered
              ? QuizVerdict(
                  item: quiz,
                  right: at.results[at.index]!,
                  // From a wrong answer to the section that teaches it, its words marked (plan 13.5).
                  footer: switch (item.section) {
                    final section? when at.results[at.index] == false => _SectionLink(item: item, section: section),
                    _ => null,
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// "This is in: <section> ›": opens the module at the section, with the question's words marked by the find bar. The
/// module is opened for a look: it keeps no place, as from the day's card.
class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.item, required this.section});

  final QuestionItem item;
  final FoundSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final label = S.of(context).review_section_link(section.title);
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: const Key('review-section-link'),
        onTap: () => context.push(
          BazaarPaths.module(context.read<TrackCubit>().state, item.moduleKey),
          extra: ReaderTarget(fragment: section.heading, query: section.words.join(' '), glance: true),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(Theme.of(context).platform)),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: BazaarType.control.size,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.item, required this.at, required this.focus});

  final TermItem item;
  final ReviewAt at;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<ReviewSessionCubit>();
    final result = at.results[at.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        Text(s.review_term, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
        Focus(
          focusNode: focus,
          child: Text(
            item.term.name,
            style: TextStyle(fontSize: BazaarType.lead.size, fontWeight: FontWeight.w600, color: colors.onSurfaceTitle),
          ),
        ),
        if (!at.revealed)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              key: const Key('review-term-show'),
              onPressed: cubit.reveal,
              child: Text(s.review_term_show),
            ),
          )
        else ...[
          Semantics(
            liveRegion: true,
            child: InlineText(
              inlines: item.term.definition,
              style: TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface),
              // A definition's link would leave the session; it is read here, not followed.
              onLink: (_) {},
            ),
          ),
          if (result == null)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: const Key('review-term-not-yet'),
                  onPressed: () => cubit.judge(knew: false),
                  child: Text(s.review_term_not_yet),
                ),
                FilledButton.tonal(
                  key: const Key('review-term-knew'),
                  onPressed: () => cubit.judge(knew: true),
                  child: Text(s.review_term_knew),
                ),
              ],
            )
          else
            Text(
              result ? s.review_term_knew : s.review_term_not_yet,
              style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
            ),
        ],
      ],
    );
  }
}

/// The results: how many were right, as a dial and in words, and the way back to Practice.
class _Results extends StatelessWidget {
  const _Results({required this.finished});

  final ReviewFinished finished;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final total = finished.results.length;
    final line = s.review_result(finished.right, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: AppSpacing.lg,
      children: [
        CompletionDial(
          done: finished.right,
          total: total,
          color: BazaarFixedColors.success,
          center: '${finished.right}/$total',
          semanticLabel: line,
        ),
        ExcludeSemantics(
          child: Text(line, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
        ),
        FilledButton(
          key: const Key('review-back'),
          onPressed: () => Navigator.maybePop(context),
          child: Text(s.review_back),
        ),
      ],
    );
  }
}

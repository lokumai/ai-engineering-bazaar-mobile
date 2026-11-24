import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_option.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// The hue of the level the module [moduleKey] is in; the primary ink while the content is not there.
Color _hueOf(BuildContext context, String moduleKey) {
  final index = switch (context.watch<ContentBloc>().state) {
    ContentReady(:final index) => index,
    _ => null,
  };
  final level = index?.module(moduleKey)?.level;
  final position = index?.levels.indexWhere((entry) => entry.slug == level) ?? -1;
  return position < 0 ? context.bazaarColors.primary : levelHue(context, position);
}

/// A Practice session's page by the [ReviewSessionCubit]'s state: the card shown, or the results.
/// A card is drawn as the app draws a level's: on a card in its level's hue (the owner, 2026-11-18).
class ReviewSessionView extends StatefulWidget {
  const ReviewSessionView({super.key, this.fromHome = false});

  /// Whether Home opened the session: its results then lead back to Home.
  final bool fromHome;

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
      builder: (context, state) => switch (state) {
        ReviewAt() => _CardPage(at: state, focus: _focus),
        ReviewFinished() => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: _Results(finished: state, fromHome: widget.fromHome),
        ),
      },
    );
  }
}

/// The card shown under the session's steps. The way on is in the card's own flow, not at the page's foot (the owner,
/// 2026-11-18): a question's Next under its verdict, as in a module's quiz; a term's Not yet and Knew it.
class _CardPage extends StatelessWidget {
  const _CardPage({required this.at, required this.focus});

  final ReviewAt at;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewSessionCubit>();
    final item = cubit.items[at.index];
    final hue = _hueOf(context, item.moduleKey);
    return SingleChildScrollView(
      // A new card starts at its top, not where a long explanation left the last one.
      key: ValueKey(at.index),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cubit.endless) _Tally(at: at) else _Steps(at: at, count: cubit.items.length),
          const SizedBox(height: AppSpacing.md),
          switch (item) {
            QuestionItem() => _QuestionCard(item: item, at: at, focus: focus, hue: hue),
            TermItem() => _TermCard(item: item, at: at, focus: focus, hue: hue),
          },
        ],
      ),
    );
  }
}

/// The session's steps: one mark per card, a green dot once right and a rust square once wrong, the current one ringed,
/// and which card of how many in words.
class _Steps extends StatelessWidget {
  const _Steps({required this.at, required this.count});

  final ReviewAt at;
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        // A Wrap of their own, so a long session (Wrong answers, uncapped) runs the dots onto more lines rather than
        // off the screen (review 8).
        ExcludeSemantics(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < count; i++)
                _StepDot(key: ValueKey('review-step-$i'), result: at.results[i], current: i == at.index),
            ],
          ),
        ),
        Text(
          s.review_progress(at.index + 1, count),
          style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// An endless review's head (the owner, 2026-11-18): how many of the cards answered were right, and Finish, which ends
/// it with its results; with none answered it goes back to Practice.
class _Tally extends StatelessWidget {
  const _Tally({required this.at});

  final ReviewAt at;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final answered = at.results.where((result) => result != null).length;
    final right = at.results.where((result) => result ?? false).length;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Text(
            answered == 0 ? '' : s.review_result(right, answered),
            key: const Key('review-tally'),
            style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
          ),
        ),
        TextButton.icon(
          key: const Key('review-end'),
          onPressed: answered == 0 ? () => context.go(BazaarPaths.practice) : context.read<ReviewSessionCubit>().finish,
          icon: const Icon(Icons.check),
          label: Text(s.review_finish),
        ),
      ],
    );
  }
}

/// One step: open (a ring), right (`success`) or wrong (`fault`); the current one larger and ringed in `primary`.
class _StepDot extends StatelessWidget {
  const _StepDot({super.key, required this.result, required this.current});

  final bool? result;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final fill = switch (result) {
      null => null,
      true => BazaarFixedColors.success,
      false => colors.fault,
    };
    final size = current ? 14.0 : 10.0;
    // A wrong step is a square, so right and wrong differ by more than colour (review 8).
    final wrong = result == false;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: wrong ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: wrong ? const BorderRadius.all(Radius.circular(2)) : null,
        color: fill,
        border: Border.all(color: current ? colors.primary : (fill ?? colors.lineStrong), width: current ? 2 : 1),
      ),
    );
  }
}

/// The card's head inside its card: its kind and module, after the level's key.
class _CardHead extends StatelessWidget {
  const _CardHead({required this.kind, required this.module, required this.hue});

  final String? kind;
  final String module;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final style = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted);
    return Row(
      spacing: 6,
      children: [
        LevelKey(color: hue, size: 8),
        Expanded(child: Text(kind == null ? module : '$kind · $module', style: style)),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.item, required this.at, required this.focus, required this.hue});

  final QuestionItem item;
  final ReviewAt at;
  final FocusNode focus;
  final Color hue;

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
        BazaarCard(
          shape: BazaarCardShape.leaf,
          accent: hue,
          tint: hue,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              _CardHead(kind: null, module: item.moduleTitle, hue: hue),
              Focus(
                focusNode: focus,
                child: Text(
                  quiz.question,
                  style: TextStyle(
                    fontSize: BazaarType.lead.size,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: colors.onSurfaceTitle,
                  ),
                ),
              ),
            ],
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
                    final section? when at.results[at.index] == false => _SectionLink(
                      moduleKey: item.moduleKey,
                      fragment: section.heading,
                      title: section.title,
                      query: section.words.join(' '),
                    ),
                    _ => null,
                  },
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        _NextButton(at: at),
      ],
    );
  }
}

/// Next, or Finish on the last card: where a module's quiz has its Next, under the verdict on the end side; a little
/// larger, under the thumb (the owner, 2026-11-18).
class _NextButton extends StatelessWidget {
  const _NextButton({required this.at});

  final ReviewAt at;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<ReviewSessionCubit>();
    final last = !cubit.endless && at.index == cubit.items.length - 1;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FilledButton.icon(
        key: const Key('review-next'),
        onPressed: at.answered ? cubit.next : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(128, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: BazaarType.control.size),
        ),
        icon: Icon(last ? Icons.check : Icons.arrow_forward),
        iconAlignment: IconAlignment.end,
        label: Text(last ? s.review_finish : s.quiz_next),
      ),
    );
  }
}

/// "This is in: <title> ›": opens the module [moduleKey] at [fragment], with the words of [query] marked by the find
/// bar: a question's section, or a term's Key Terms. The module is opened for a look: it keeps no place, as from the
/// day's card.
class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.moduleKey, required this.fragment, required this.title, required this.query});

  final String moduleKey;
  final String? fragment;
  final String title;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final label = S.of(context).review_section_link(title);
    void open() => context.push(
      BazaarPaths.module(context.read<TrackCubit>().state, moduleKey),
      extra: ReaderTarget(fragment: fragment, query: query, glance: true),
    );
    // The tap is the node's own: excludeSemantics drops the InkWell's (review 8, finding 4).
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        key: const Key('review-section-link'),
        onTap: open,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(Theme.of(context).platform)),
          child: Row(
            spacing: 6,
            children: [
              Icon(Icons.menu_book_outlined, color: colors.primary, size: 18),
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

/// A term asked as a question (plan 13.16, the owner, 2026-11-18): its definition on a leaf card in its level's hue,
/// "Which term is this?", then term names to choose from, graded as a question is, with a way to the module's Key Terms
/// and Next under the verdict.
class _TermCard extends StatelessWidget {
  const _TermCard({required this.item, required this.at, required this.focus, required this.hue});

  final TermItem item;
  final ReviewAt at;
  final FocusNode focus;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final cubit = context.read<ReviewSessionCubit>();
    final pick = at.pick;
    final answered = at.answered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BazaarCard(
          shape: BazaarCardShape.leaf,
          accent: hue,
          tint: hue,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              _CardHead(kind: s.review_term, module: item.moduleTitle, hue: hue),
              Text(s.review_term_ask, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
              Focus(
                focusNode: focus,
                child: InlineText(
                  inlines: item.term.definition,
                  style: TextStyle(
                    fontSize: BazaarType.lead.size,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: colors.onSurfaceTitle,
                  ),
                  // A definition's link would leave the session; it is read here, not followed.
                  onLink: (_) {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.sm),
        ],
        Semantics(
          key: const Key('review-verdict'),
          container: true,
          liveRegion: true,
          child: answered
              ? QuizVerdict(
                  item: QuizItem(
                    question: item.term.definitionText,
                    options: item.options,
                    answer: item.answer,
                    explain: '',
                  ),
                  right: at.results[at.index]!,
                  // The term among its module's Key Terms, its words marked.
                  footer: _SectionLink(
                    moduleKey: item.moduleKey,
                    fragment: item.termsHeading,
                    title: item.moduleTitle,
                    query: item.term.name,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        _NextButton(at: at),
      ],
    );
  }
}

/// The results: how many were right as the module quiz's dial and in words, each card with a check or a cross, and
/// the way back to where the session was opened: Home, or Practice.
class _Results extends StatelessWidget {
  const _Results({required this.finished, required this.fromHome});

  final ReviewFinished finished;
  final bool fromHome;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final items = context.read<ReviewSessionCubit>().items;
    final total = finished.results.length;
    final line = s.review_result(finished.right, total);
    final style = TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface);
    final numbers = math.max(24.0, (quizTextSize(context, '$total.', style).width + 4).ceilToDouble());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CompletionDial(
            done: finished.right,
            total: total,
            color: BazaarFixedColors.success,
            center: '${finished.right}/$total',
            semanticLabel: line,
            size: 120,
            ring: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ExcludeSemantics(
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: displayFace(theme.textTheme.titleLarge)?.copyWith(color: colors.onSurfaceTitle),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < items.length && i < total; i++)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: numbers,
                    child: Text('${i + 1}.', style: style),
                  ),
                  Icon(
                    finished.results[i] ?? false ? Icons.check : Icons.close,
                    size: 20,
                    color: finished.results[i] ?? false ? BazaarFixedColors.success : colors.fault,
                    semanticLabel: finished.results[i] ?? false ? s.quiz_recap_correct : s.quiz_recap_wrong,
                  ),
                  Expanded(
                    child: Text(switch (items[i]) {
                      QuestionItem(:final item) => item.question,
                      TermItem(:final term) => term.name,
                    }, style: style),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('review-back'),
          // Back to Home when Home opened it; else to Practice's page, from Wrong answers too (the owner, 2026-11-18).
          onPressed: () => context.go(fromHome ? BazaarPaths.home : BazaarPaths.practice),
          child: Text(fromHome ? s.review_back_home : s.review_back),
        ),
      ],
    );
  }
}

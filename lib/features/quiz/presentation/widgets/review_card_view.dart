import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/section_finder.dart';
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

/// A Practice session's page by the [ReviewSessionCubit]'s state: the card shown with Next under it, or the results.
/// A card is drawn as the app draws a level's: on a card in its level's hue (the owner, 2026-11-18).
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
      builder: (context, state) => switch (state) {
        ReviewAt() => _CardPage(at: state, focus: _focus),
        ReviewFinished() => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: _Results(finished: state),
        ),
      },
    );
  }
}

/// The card shown under the session's steps, and Next or Finish at the foot, once it is answered.
class _CardPage extends StatelessWidget {
  const _CardPage({required this.at, required this.focus});

  final ReviewAt at;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<ReviewSessionCubit>();
    final item = cubit.items[at.index];
    final last = at.index == cubit.items.length - 1;
    final hue = _hueOf(context, item.moduleKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Steps(at: at, count: cubit.items.length),
                const SizedBox(height: AppSpacing.md),
                switch (item) {
                  QuestionItem() => _QuestionCard(item: item, at: at, focus: focus, hue: hue),
                  TermItem() => _TermCard(item: item, at: at, focus: focus, hue: hue),
                },
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            key: const Key('review-next'),
            onPressed: at.answered ? cubit.next : null,
            icon: Icon(last ? Icons.check : Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            label: Text(last ? s.review_finish : s.quiz_next),
          ),
        ),
      ],
    );
  }
}

/// The session's steps: one dot per card, green once right and rust once wrong, the current one ringed, and which card
/// of how many in words.
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
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [for (var i = 0; i < count; i++) _StepDot(result: at.results[i], current: i == at.index)],
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

/// One step: open (a ring), right (`success`) or wrong (`fault`); the current one larger and ringed in `primary`.
class _StepDot extends StatelessWidget {
  const _StepDot({required this.result, required this.current});

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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

/// A term as a card: the term and the sentence of its module that uses it, the term marked there, on a leaf card in
/// its level's hue; a tap on the card shows its definition under it, drawn as a question's explanation, then Not yet
/// and Knew it side by side (the owner, 2026-11-18: the first one stood alone on an empty screen).
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
    final result = at.results[at.index];
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold;
    final usage = item.usage;
    final quoted = TextStyle(fontSize: BazaarType.control.size, height: 1.5, color: colors.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: [
        BazaarCard(
          key: at.revealed ? null : const Key('review-term-show'),
          shape: BazaarCardShape.leaf,
          accent: hue,
          tint: hue,
          onTap: at.revealed ? null : cubit.reveal,
          semanticLabel: at.revealed
              ? null
              : ['${s.review_term}: ${item.term.name}.', if (usage != null) usage.text, s.review_term_show].join(' '),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              _CardHead(kind: s.review_term, module: item.moduleTitle, hue: hue),
              Focus(
                focusNode: focus,
                child: Text(
                  item.term.name,
                  style: displayFace(theme.textTheme.titleLarge)?.copyWith(color: colors.onSurfaceTitle),
                ),
              ),
              if (usage != null)
                // The module's own sentence, the term in it marked: how the module put it.
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 2, 0, 2),
                  decoration: BoxDecoration(
                    border: BorderDirectional(start: BorderSide(color: hue, width: 3)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: usage.text.substring(0, usage.start)),
                        TextSpan(
                          text: usage.text.substring(usage.start, usage.end),
                          style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurfaceTitle),
                        ),
                        TextSpan(text: usage.text.substring(usage.end)),
                      ],
                    ),
                    style: quoted.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              if (!at.revealed)
                Row(
                  spacing: 6,
                  children: [
                    Icon(Icons.touch_app_outlined, size: 18, color: colors.primary),
                    Flexible(
                      child: Text(
                        s.review_term_show,
                        style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: BazaarMotion.bazaar,
          alignment: Alignment.topCenter,
          child: !at.revealed
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSunken,
                      border: BorderDirectional(start: BorderSide(color: colors.primary, width: 3)),
                    ),
                    child: InlineText(
                      inlines: item.term.definition,
                      style: TextStyle(fontSize: BazaarType.control.size, height: 1.45, color: colors.onSurface),
                      // A definition's link would leave the session; it is read here, not followed.
                      onLink: (_) {},
                    ),
                  ),
                ),
        ),
        if (at.revealed && result == null)
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('review-term-not-yet'),
                  onPressed: () => cubit.judge(knew: false),
                  icon: Icon(Icons.replay_rounded, color: colors.fault),
                  label: Text(s.review_term_not_yet),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('review-term-knew'),
                  onPressed: () => cubit.judge(knew: true),
                  icon: const Icon(Icons.check),
                  label: Text(s.review_term_knew),
                ),
              ),
            ],
          )
        else if (result != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(
                result ? Icons.check : Icons.replay_rounded,
                size: 20,
                color: result ? BazaarFixedColors.success : colors.fault,
              ),
              Text(
                result ? s.review_term_knew : s.review_term_not_yet,
                style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
              ),
            ],
          ),
      ],
    );
  }
}

/// The results: how many were right as the module quiz's dial and in words, each card with a check or a cross, and
/// the way back to Practice.
class _Results extends StatelessWidget {
  const _Results({required this.finished});

  final ReviewFinished finished;

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
          // Back to Practice's page, from Wrong answers too (the owner, 2026-11-18).
          onPressed: () => context.go(BazaarPaths.practice),
          child: Text(s.review_back),
        ),
      ],
    );
  }
}

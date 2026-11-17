import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Practice's head (plan 13.2): Today's review, with its cards, minutes and modules and Start, or why there is none
/// today; then the row to Wrong answers.
class PracticeHead extends StatelessWidget {
  const PracticeHead({super.key, required this.index, required this.track});

  final BundleIndex index;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = context.watch<LanguageCubit>().state;
    final history = context.watch<ReviewBloc>().state.history;
    final pool = reviewPoolOf(context, track, language);
    final today = dayNumber(clock.now());
    final cards = pool?.today(history, today) ?? const <String>[];
    final wrong = pool?.wrong(history) ?? const <String>[];
    String titleOf(String key) => index.module(key)?.tracks[track]?.titleIn(language) ?? key;
    final modules = <String>{for (final key in cards) titleOf(moduleOfKey(key))};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodayCard(
          key: const Key('practice-today'),
          ready: pool != null,
          cards: cards.length,
          modules: modules.toList(),
          done: history.doneOn(today) > 0,
          wrong: wrong.length,
        ),
        const SizedBox(height: AppSpacing.md),
        BazaarRows(
          children: [
            _PracticeRow(
              key: const Key('practice-wrong'),
              icon: Icons.replay_rounded,
              title: s.practice_wrong,
              detail: s.practice_wrong_count(wrong.length),
              onTap: () => context.push(BazaarPaths.practiceWrong),
            ),
          ],
        ),
      ],
    );
  }
}

/// Today's review: its name, then its cards and Start, or that there is nothing today, or that today's are done.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    super.key,
    required this.ready,
    required this.cards,
    required this.modules,
    required this.done,
    required this.wrong,
  });

  /// Whether the notes are read; until then only the name shows.
  final bool ready;
  final int cards;
  final List<String> modules;

  /// Whether Today's review took a card today.
  final bool done;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    return BazaarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Semantics(
            header: true,
            child: Text(s.practice_today, style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurfaceTitle)),
          ),
          if (ready && cards > 0) ...[
            Text(
              s.practice_today_cards(cards, reviewMinutes(cards)),
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
            Text(s.practice_today_from(modules.join(', ')), style: muted),
            const SizedBox(height: AppSpacing.xs),
            FilledButton(
              key: const Key('practice-today-start'),
              onPressed: () => context.push(BazaarPaths.practiceReview),
              child: Text(s.practice_start),
            ),
          ] else if (ready) ...[
            Text(
              done ? s.practice_today_done : s.practice_today_none,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
            Text(done ? s.practice_today_done_lede : s.practice_today_none_lede, style: muted),
            if (wrong > 0)
              TextButton(
                key: const Key('practice-today-wrong'),
                onPressed: () => context.push(BazaarPaths.practiceWrong),
                child: Text(s.practice_go_wrong),
              ),
          ],
        ],
      ),
    );
  }
}

/// One of Practice's rows: an icon, a name and a count, and an arrow; a tap opens its page.
class _PracticeRow extends StatelessWidget {
  const _PracticeRow({super.key, required this.icon, required this.title, required this.detail, required this.onTap});

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return BazaarRow(
      onTap: onTap,
      semanticLabel: '$title, $detail',
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(icon, color: colors.onSurfaceMuted),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}

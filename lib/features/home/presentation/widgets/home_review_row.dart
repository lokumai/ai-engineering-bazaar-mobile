import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Home's one row to Practice (plan 13.2), in place of its three quiz rows: Today's review and its cards, which a tap
/// starts. Nothing shows on a day with no card, or while the notes are being read.
class HomeReviewRow extends StatelessWidget {
  const HomeReviewRow({super.key, required this.track, required this.language});

  final Track track;
  final String language;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ReviewBloc>().state.history;
    final cards = reviewPoolOf(context, track, language)?.today(history, dayNumber(clock.now())).length ?? 0;
    if (cards == 0) return const SizedBox.shrink();
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final title = s.home_review(cards);
    final minutes = s.practice_today_cards(cards, reviewMinutes(cards));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: BazaarRow(
        key: const Key('home-review'),
        onTap: () => context.push(BazaarPaths.practiceReview),
        semanticLabel: '$title, $minutes',
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Icon(Icons.style_rounded, color: colors.primary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                  Text(minutes, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

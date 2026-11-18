import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Home's Practice (plan 13.2), under the day's card with its own heading: Today's review and its cards, which a tap
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
    final title = s.practice_today;
    final minutes = s.practice_today_cards(cards, reviewMinutes(cards));
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionRule(title: s.nav_practice),
          const SizedBox(height: 12),
          // Practice's deck in small: a leaf card with the primary edge, as Today's review is drawn there.
          BazaarCard(
            key: const Key('home-review'),
            shape: BazaarCardShape.leaf,
            accent: colors.primary,
            // Its results lead back to Home, where it was opened (the owner, 2026-11-18).
            onTap: () => context.push(BazaarPaths.practiceReviewFromHome),
            semanticLabel: '$title, $minutes',
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(colors.primary.withValues(alpha: 0.12), colors.surface),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Icon(Icons.school_rounded, size: 18, color: colors.onSurfaceTitle),
                ),
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
                Icon(Icons.arrow_forward, size: 20, color: colors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

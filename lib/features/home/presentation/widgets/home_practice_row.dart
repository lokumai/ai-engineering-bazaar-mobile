import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/home_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';

/// One completed module whose quiz the reader can take again (plan 1AD): the question disc, the number and title, the
/// level with the last and best score once taken (plan 1W), and an arrow; a tap opens the quiz full screen.
class HomePracticeRow extends StatelessWidget {
  const HomePracticeRow({super.key, required this.entry, required this.onTap});

  final HomeNext entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final number = homeModuleNumber(entry.module.number);
    final score = entry.score;
    final line = score == null ? null : S.of(context).quiz_score_line(score.last, score.best, score.total);
    return BazaarCard(
      onTap: onTap,
      semanticLabel: ['$number ${entry.title}', entry.level.title, ?line].join(', '),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
            child: Text(
              '?',
              style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  '$number ${entry.title}',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                ),
                Text(
                  [entry.level.title, ?line].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}

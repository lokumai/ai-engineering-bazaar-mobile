import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/home_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/quiz_disc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:flutter/material.dart';

/// One completed module whose quiz the reader can take again (plan 1AD), straight on the page: the question disc in its level's hue, the number and title, the
/// level, the last score as one segment per question once taken (plan 1W, as on the Quiz tab), and an arrow; a tap opens the quiz full screen.
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
    return BazaarRow(
      onTap: onTap,
      semanticLabel: ['$number ${entry.title}', entry.level.title, ?line].join(', '),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          QuizDisc(hue: levelHue(context, entry.position)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  '$number ${entry.title}',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                ),
                Text(entry.level.title, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                if (score != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(14.0 * score.total + 4 * (score.total - 1)),
                    child: SegmentMeter(
                      done: score.last,
                      total: score.total,
                      color: BazaarFixedColors.success,
                      restColor: colors.fault,
                      semanticLabel: line!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}

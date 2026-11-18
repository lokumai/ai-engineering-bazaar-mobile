import 'package:flutter/material.dart';

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';

/// A level's part of a Practice list (Wrong answers, A module in 2 minutes): an arch card in the level's hue, as the
/// quizzes by level are, with the level's number, title and [count] at its head and [rows] under a rule, one rule
/// between each.
class PracticeLevelGroup extends StatelessWidget {
  const PracticeLevelGroup({
    super.key,
    required this.position,
    required this.title,
    required this.count,
    required this.rows,
  });

  /// The 0-based place of the level in the index: its hue and its number.
  final int position;
  final String title;
  final String count;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final hue = levelHue(context, position < 0 ? 0 : position);
    return BazaarCard(
      shape: BazaarCardShape.arch,
      tint: hue,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (position >= 0)
                            TextSpan(
                              text: '${(position + 1).toString().padLeft(2, '0')}  ',
                              style: TextStyle(color: colors.onSurfaceMuted),
                            ),
                          TextSpan(text: title),
                        ],
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                    ),
                  ),
                  Text(count, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                ],
              ),
            ),
          ),
          for (final row in rows) ...[Divider(height: 1, color: colors.line), row],
        ],
      ),
    );
  }
}

/// A round mark in [hue] with [icon] in the title ink, as the quiz's question disc is drawn: decoration.
class PracticeDisc extends StatelessWidget {
  const PracticeDisc({super.key, required this.hue, required this.icon});

  final Color hue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color.alphaBlend(hue.withValues(alpha: 0.14), colors.surface),
          shape: BoxShape.circle,
          border: Border.all(color: hue, width: 2),
        ),
        child: Icon(icon, size: 16, color: colors.onSurfaceTitle),
      ),
    );
  }
}

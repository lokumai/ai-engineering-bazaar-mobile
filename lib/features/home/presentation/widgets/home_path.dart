import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:flutter/material.dart';

/// The reader's path at a glance (the user, 2026-11-10): one line per level, its title, a bar in its hue filled by the
/// share of its written modules completed, and the count. Each line is read as the level and its count.
class HomePath extends StatelessWidget {
  const HomePath({super.key, required this.levels});

  final List<HomeLevel> levels;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        for (final level in levels)
          Semantics(
            container: true,
            label: '${level.level.title}, ${s.level_completed(level.done, level.total)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        level.level.title,
                        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceTitle),
                      ),
                    ),
                    Text(
                      '${level.done}/${level.total}',
                      style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  child: LinearProgressIndicator(
                    value: level.total == 0 ? 0 : level.done / level.total,
                    minHeight: 6,
                    color: levelHue(context, level.position),
                    backgroundColor: colors.surfaceSunken,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

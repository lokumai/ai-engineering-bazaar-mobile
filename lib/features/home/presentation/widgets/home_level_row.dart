import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/home_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:flutter/material.dart';

/// One level on Home, in the arch shape: its completion dial in the level hue, its key and title, its module count
/// and reading time, and `Planned` for a level still being written. The whole row opens the level page.
class HomeLevelRow extends StatelessWidget {
  const HomeLevelRow({super.key, required this.level, required this.onTap});

  final HomeLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final hue = levelHue(context, level.position);
    final entry = level.level;
    final line = homeLevelLine(s, modules: entry.total, minutes: level.minutes);
    final completed = s.level_completed(level.completed, level.total);
    final planned = entry.status == LevelStatus.draft;
    return BazaarCard(
      shape: BazaarCardShape.arch,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      semanticLabel: [entry.title, line, completed, if (planned) s.module_planned].join(', '),
      child: Row(
        spacing: 14,
        children: [
          CompletionDial(
            done: level.completed,
            total: level.total,
            color: hue,
            center: s.progress_level_dial(level.completed.toString(), level.total),
            semanticLabel: completed,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    LevelKey(color: hue),
                    Flexible(
                      child: Text(
                        entry.title,
                        style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                      ),
                    ),
                  ],
                ),
                Text(line, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          if (planned)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.lineStrong),
                borderRadius: const BorderRadius.all(BazaarRadii.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  s.module_planned,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

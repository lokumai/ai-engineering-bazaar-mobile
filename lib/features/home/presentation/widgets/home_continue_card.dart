import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/home_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The continue card: the next module of the track not yet completed, with its level, number, title and minutes, and
/// the button that opens it; or, when every written module is completed, a line saying so and the way to the catalog,
/// which shows the completion (plan 1AB).
///
/// The mockup showed a reading position ("section 3 of 8, 37 %"); the record keeps none (R61), so the card names the
/// next module instead (plan Phase 1, decisions taken).
class HomeContinueCard extends StatelessWidget {
  const HomeContinueCard({super.key, required this.track, required this.next});

  final Track track;
  final HomeNext? next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    final next = this.next;
    if (next == null) {
      return BazaarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(s.home_all_complete, style: theme.textTheme.bodyLarge),
            OutlinedButton(onPressed: () => context.go(BazaarPaths.catalog(track)), child: Text(s.home_see_catalog)),
          ],
        ),
      );
    }
    final hue = levelHue(context, next.position);
    return BazaarCard(
      accent: hue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              LevelKey(color: hue, size: 8),
              Expanded(
                child: Text(next.level.title, style: muted?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(homeModuleNumber(next.module.number), style: muted),
            ],
          ),
          Text(next.title, style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle)),
          Text(s.reader_minutes(next.module.minutes), style: muted),
          FilledButton.icon(
            onPressed: () => context.push(BazaarPaths.module(track, next.module.key)),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            label: Text(s.home_open_module),
          ),
        ],
      ),
    );
  }
}

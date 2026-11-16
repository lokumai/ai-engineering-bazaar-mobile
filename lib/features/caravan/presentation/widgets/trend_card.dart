import 'package:ai_engineering_bazaar/features/caravan/application/caravan_modules.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_art.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_period.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/utils/locale_case.dart';
import 'package:flutter/material.dart';

/// The chosen trend under the stage: when, what, how strong, and where to read more.
///
/// Its top edge is the colour of the goods the stop's merchant sells, so the card and the lit stall read as one. A
/// swipe sideways moves to the next or the previous stop, the way the reader reads ([onNext], [onPrevious]); the page's
/// buttons do the same for a screen reader.
class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.stop,
    required this.modules,
    required this.sample,
    required this.onOpenModule,
    required this.onNext,
    required this.onPrevious,
  });

  final CaravanStop stop;
  final List<CaravanModule> modules;

  /// Whether the trend is the sample's, which the card says.
  final bool sample;
  final ValueChanged<String> onOpenModule;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final trend = stop.trend;
    final hue = inkOf(stop.index);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final language = Localizations.localeOf(context).languageCode;
    final muted = theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.velocity.pixelsPerSecond.dx;
        if (v.abs() < 220) return;
        // A swipe toward the start edge reads on, as turning a page does.
        final forward = rtl ? v > 0 : v < 0;
        forward ? onNext() : onPrevious();
      },
      child: BazaarCard(
        accent: hue,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: caravanPeriod(context, stop),
                    excludeSemantics: true,
                    child: Text(upperCaseIn(caravanPeriod(context, stop), language), style: muted),
                  ),
                ),
                if (sample) _SampleBadge(label: s.caravan_sample_badge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              header: true,
              child: Text(
                trend.title,
                style: displayFace(theme.textTheme.headlineSmall)?.copyWith(color: colors.onSurfaceTitle),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Strength(level: trend.peak, hue: hue),
            const SizedBox(height: AppSpacing.md),
            Text(trend.text, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface)),
            if (modules.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(upperCaseIn(s.caravan_in_course, language), style: muted),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final module in modules)
                    ActionChip(
                      avatar: Icon(Icons.menu_book_outlined, size: 18, color: colors.primary),
                      label: Text(module.title),
                      onPressed: () => onOpenModule(module.key),
                    ),
                ],
              ),
            ],
            if (trend.sources.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(upperCaseIn(s.caravan_reading, language), style: muted),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [for (final kind in trend.sources) _SourceChip(kind: kind)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleBadge extends StatelessWidget {
  const _SampleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: BazaarFixedColors.caution, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: BazaarFixedColors.onCaution, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// How strong the trend was at its height, as five segments in the colour of its goods.
class _Strength extends StatelessWidget {
  const _Strength({required this.level, required this.hue});

  final int level;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    return Semantics(
      label: s.caravan_strength_of(level),
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            s.caravan_strength,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 22,
                height: 7,
                decoration: BoxDecoration(
                  color: i < level ? hue : colors.line,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: i < level ? Color.lerp(hue, Colors.black, 0.25)! : colors.line),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A reading the trend points to. The sample has no address for any, so each is a placeholder, not a link.
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.kind});

  final CaravanSourceKind kind;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final (icon, label) = switch (kind) {
      CaravanSourceKind.articles => (Icons.article_outlined, s.caravan_sample_articles),
      CaravanSourceKind.videos => (Icons.play_circle_outline, s.caravan_sample_videos),
      CaravanSourceKind.tools => (Icons.build_outlined, s.caravan_sample_tools),
      CaravanSourceKind.repositories => (Icons.folder_open_outlined, s.caravan_sample_repositories),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
        color: colors.surfaceSunken,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(icon, size: 16, color: colors.onSurfaceMuted),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

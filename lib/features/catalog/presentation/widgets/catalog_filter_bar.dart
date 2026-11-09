import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The catalog's filter bar (web `Catalog.tsx:296-413`, without the View row, A10): the Level chips, which open the
/// catalog root or a level page of [track], each level keyed by its hue, the Status chips, and the live count
/// `Showing {visible} of {total}`. The chips take the mockup's look: framed, the chosen one filled.
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.index,
    required this.track,
    required this.levels,
    required this.level,
    required this.status,
    required this.onStatus,
    required this.visible,
    required this.total,
  });

  /// The index the levels come from, for each level's place and so its hue.
  final BundleIndex index;
  final Track track;

  /// One chip each, in this order.
  final List<LevelEntry> levels;

  /// The level shown; null on the catalog root.
  final String? level;
  final StatusFilter status;
  final ValueChanged<StatusFilter> onStatus;

  /// The number of rows the filters keep.
  final int visible;

  /// The number of rows before filtering.
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = context.bazaarColors;
    return ChipTheme(
      data: ChipTheme.of(context).copyWith(
        showCheckmark: false,
        // Material 3 fills a chip from `color`, which wins over `selectedColor`.
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primary : colors.surfaceRaised,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(color: states.contains(WidgetState.selected) ? colors.primary : colors.lineStrong),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.pill)),
        labelStyle: textTheme.labelLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          _ChipRow(
            label: l10n.catalog_level_label,
            chips: [
              ChoiceChip(
                label: _label(context, l10n.catalog_filter_all, chosen: level == null),
                selected: level == null,
                // A selected level chip does nothing: a go to the page shown would replace a pushed page with a fresh
                // one and drop the pages below it.
                onSelected: (_) {
                  if (level != null) context.go(BazaarPaths.catalog(track));
                },
              ),
              for (final entry in levels)
                ChoiceChip(
                  avatar: LevelKey(
                    color: level == entry.slug ? colors.onPrimary : levelHue(context, levelPosition(index, entry.slug)),
                    size: 8,
                  ),
                  label: _label(context, entry.title, chosen: level == entry.slug),
                  selected: level == entry.slug,
                  onSelected: (_) {
                    if (level != entry.slug) context.go(BazaarPaths.level(track, entry.slug));
                  },
                ),
            ],
          ),
          _ChipRow(
            label: l10n.catalog_status_label,
            chips: [
              for (final filter in StatusFilter.values)
                ChoiceChip(
                  label: _label(context, _statusLabel(l10n, filter), chosen: status == filter),
                  selected: status == filter,
                  onSelected: (_) => onStatus(filter),
                ),
            ],
          ),
          // The web's `role="status"`.
          Semantics(liveRegion: true, child: Text(l10n.catalog_showing(visible, total), style: textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// A chip's label, in the ink of its fill: Material 3 chips do not resolve a themed label style by selection.
  static Widget _label(BuildContext context, String text, {required bool chosen}) {
    final colors = context.bazaarColors;
    return Text(text, style: TextStyle(color: chosen ? colors.onPrimary : colors.onSurface));
  }

  static String _statusLabel(S l10n, StatusFilter filter) => switch (filter) {
    StatusFilter.all => l10n.catalog_filter_all,
    StatusFilter.ready => l10n.catalog_filter_ready,
    StatusFilter.planned => l10n.catalog_filter_planned,
    StatusFilter.completed => l10n.catalog_filter_completed,
    StatusFilter.notCompleted => l10n.catalog_filter_not_completed,
  };
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.chips});

  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        ...chips,
      ],
    );
  }
}

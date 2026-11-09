import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The catalog's filter bar (web `Catalog.tsx:296-413`, without the View row, A10): the Level chips, which open the
/// catalog root or a level page of [track], the Status chips, and the live count `Showing {visible} of {total}`.
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.track,
    required this.levels,
    required this.level,
    required this.status,
    required this.onStatus,
    required this.visible,
    required this.total,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        _ChipRow(
          label: l10n.catalog_level_label,
          chips: [
            ChoiceChip(
              label: Text(l10n.catalog_filter_all),
              selected: level == null,
              // A selected level chip does nothing: a go to the page shown would replace a pushed page with a fresh
              // one and drop the pages below it.
              onSelected: (_) {
                if (level != null) context.go(BazaarPaths.catalog(track));
              },
            ),
            for (final entry in levels)
              ChoiceChip(
                label: Text(entry.title),
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
                label: Text(_statusLabel(l10n, filter)),
                selected: status == filter,
                onSelected: (_) => onStatus(filter),
              ),
          ],
        ),
        // The web's `role="status"`.
        Semantics(liveRegion: true, child: Text(l10n.catalog_showing(visible, total), style: textTheme.bodyMedium)),
      ],
    );
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

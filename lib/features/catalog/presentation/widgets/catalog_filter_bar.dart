import 'dart:async';

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
/// catalog root or a level page of [track], each level keyed by its hue. The chips take the mockup's look: framed, the
/// chosen one filled.
///
/// The web's Status chips and its `Showing {visible} of {total}` count are left out (plan 1N): each card already says
/// whether it is planned or completed.
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.index,
    required this.track,
    required this.levels,
    required this.level,
  });

  /// The index the levels come from, for each level's place and so its hue.
  final BundleIndex index;
  final Track track;

  /// One chip each, in this order.
  final List<LevelEntry> levels;

  /// The level shown; null on the catalog root.
  final String? level;

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
      child: _ChipRow(
        label: l10n.catalog_level_label,
        chips: [
          ChoiceChip(
            label: _label(context, l10n.catalog_filter_all, chosen: level == null),
            selected: level == null,
            // A selected chip does nothing: the page shown stays, with the pages below it.
            onSelected: (_) {
              if (level != null) _show(context, BazaarPaths.catalog(track));
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
                if (level != entry.slug) _show(context, BazaarPaths.level(track, entry.slug));
              },
            ),
        ],
      ),
    );
  }

  /// Opens [target], the catalog root or a level page, so that back follows the pages the reader opened (plan 1M).
  ///
  /// From the catalog root a level is pushed, so back returns to the root. On a level page the chips are a filter, so
  /// the target takes the page's place and back skips the levels tried, back to the page the level was opened from;
  /// when that page is [target] itself (the root, for All), the level page is popped instead of covering it twice.
  void _show(BuildContext context, String target) {
    final router = GoRouter.of(context);
    if (level == null) {
      unawaited(router.push<void>(target));
    } else if (_below(router.routerDelegate.currentConfiguration.matches) == target) {
      router.pop();
    } else {
      unawaited(router.pushReplacement<void>(target));
    }
  }

  /// The path of the page under the one on top, or null when there is none.
  static String? _below(List<RouteMatchBase> matches) {
    final pages = _leaves(matches).toList();
    return pages.length < 2 ? null : pages[pages.length - 2].matchedLocation;
  }

  /// The pages of [matches] in order, the pages of a shell included.
  static Iterable<RouteMatchBase> _leaves(List<RouteMatchBase> matches) =>
      matches.expand((match) => match is ShellRouteMatch ? _leaves(match.matches) : [match]);

  /// A chip's label, in the ink of its fill: Material 3 chips do not resolve a themed label style by selection.
  static Widget _label(BuildContext context, String text, {required bool chosen}) {
    final colors = context.bazaarColors;
    return Text(text, style: TextStyle(color: chosen ? colors.onPrimary : colors.onSurface));
  }
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

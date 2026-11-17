import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/reading_style_names.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Reading settings row under Reading (plan 12.5), in the App icon row's style but smaller, since Reading and
/// Customize must fit one screen: a tile with two letters drawn at the reader's text size, so it shows what the page
/// sets, the row's name, and an arrow; [onTap] opens the Reading settings page. The current size and spacing are said to a
/// screen reader only (the owner, 2026-11-17: written under the name, they made Settings look crowded).
class ReadingStyleRow extends StatelessWidget {
  const ReadingStyleRow({super.key, required this.onTap});

  final VoidCallback onTap;

  /// The tile's side.
  static const double tile = 40;

  /// The letters' size at the standard text size; the largest size draws them at 1.45 times this, inside the tile.
  static const double sampleSize = 15;

  /// The key of the letters in the tile.
  static const sampleKey = ValueKey('settings-reading-sample');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final style = context.watch<ReadingStyleCubit>().state;
    final summary = '${readingSizeName(s, style.size)}, ${readingSpacingName(s, style.spacing)}';
    return BazaarRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: AppSpacing.xs),
      semanticLabel: '${s.settings_reading_style}, $summary',
      child: Row(
        spacing: AppSpacing.md,
        children: [
          SizedBox.square(
            dimension: tile,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                border: Border.all(color: colors.line),
                borderRadius: const BorderRadius.all(Radius.circular(tile * 0.23)),
              ),
              // The letters in the module text's face at its size, kept inside the tile at the phone's own text size.
              child: Center(
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    s.reading_sample_mark,
                    key: sampleKey,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: sampleSize * style.size.factor,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceTitle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              s.settings_reading_style,
              style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle),
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}

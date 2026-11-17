import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/reading_style_names.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Reading settings row under Reading (plan 12.5), in the App icon row's style but smaller, since Reading and
/// Customize must fit one screen: a text mark in a tile, the row's name with the current size and spacing under it, and an
/// arrow; [onTap] opens the Reading settings page.
class ReadingStyleRow extends StatelessWidget {
  const ReadingStyleRow({super.key, required this.onTap});

  final VoidCallback onTap;

  /// The tile's side.
  static const double tile = 40;

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
          Container(
            width: tile,
            height: tile,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              border: Border.all(color: colors.line),
              borderRadius: const BorderRadius.all(Radius.circular(tile * 0.23)),
            ),
            child: Icon(Icons.text_fields, size: 22, color: colors.onSurfaceTitle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settings_reading_style,
                  style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle),
                ),
                Text(summary, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}

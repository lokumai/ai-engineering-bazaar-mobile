import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/home_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One module that comes after the next one (plan 1P): its number, title, level, and its minutes and words as the
/// catalog's rows print them (the minutes alone where the content has no word count); a tap opens it.
class HomeAfterRow extends StatelessWidget {
  const HomeAfterRow({super.key, required this.entry, required this.onTap});

  final HomeNext entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final language = context.watch<LanguageCubit>().state;
    final length = homeModuleLength(s, entry, language) ?? homeDurationLabel(s, entry.module.minutes);
    final line = [entry.level.title, ?length].join(' · ');
    return BazaarRow(
      onTap: onTap,
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Text(
            homeModuleNumber(entry.module.number),
            style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(entry.title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                Text(line, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          ExcludeSemantics(child: Icon(Icons.chevron_right, color: colors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

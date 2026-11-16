import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// What the apprentice has learnt, at the foot of its sheet, for whoever scrolls to it: the modules it read, the words
/// it knows and the tokens it ate, each a number over a word. The sheet itself is for playing with it, so the numbers
/// wait down here (the owner, 2026-11-14).
class PocketStats extends StatelessWidget {
  const PocketStats({super.key, required this.model, required this.known});

  final PocketModel model;

  /// The words it knows.
  final int known;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final number = NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionRule(title: s.pocket_stats_title),
        const SizedBox(height: AppSpacing.md),
        Row(
          spacing: AppSpacing.sm,
          children: [
            for (final (count, label) in [
              (model.readings.length, s.pocket_stat_modules),
              (known, s.pocket_stat_words),
              (model.total, s.pocket_stat_tokens),
            ])
              Expanded(
                child: _Stat(value: number.format(count), label: label),
              ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  value,
                  maxLines: 1,
                  style: displayFace(theme.textTheme.titleLarge)?.copyWith(color: colors.primary, height: 1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

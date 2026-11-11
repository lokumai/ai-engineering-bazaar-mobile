import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/utils/grouped_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The catalog's Cards view (web `CatalogCards.tsx:226-320`): per level that holds a visible row, a heading with the
/// level title (no count), then one card per row with the level and number, the title as a link to the module, the
/// Description disclosure, and the Length and Requires facts.
///
/// One Description is open at a time (the web's `<details name>` group); the page holds which one.
/// Length shows the minutes and the words of the document the reader opens (web D128), the minutes only where the
/// content has no word count; a planned card has no Description, because the index carries no planned module's parts
/// (D111).
class CatalogCards extends StatelessWidget {
  const CatalogCards({
    super.key,
    required this.track,
    required this.index,
    required this.rows,
    required this.openDescription,
    required this.onDescription,
  });

  final Track track;
  final BundleIndex index;

  /// The visible rows.
  final List<CatalogRow> rows;

  /// The key of the row whose Description is open; null when every one is closed.
  final String? openDescription;

  /// Called with the key of the row whose Description should be open, or null to close it.
  final ValueChanged<String?> onDescription;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        for (final level in levelsOf(index, rows)) ...[
          Row(
            spacing: AppSpacing.sm,
            children: [
              LevelKey(color: levelHue(context, levelPosition(index, level.slug))),
              Flexible(
                child: Semantics(header: true, child: Text(level.title, style: textTheme.titleMedium)),
              ),
            ],
          ),
          for (final row in applyLevel(rows, level.slug))
            _ModuleCard(
              track: track,
              level: level,
              row: row,
              open: openDescription == row.key,
              onDescription: () => onDescription(openDescription == row.key ? null : row.key),
            ),
        ],
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.track,
    required this.level,
    required this.row,
    required this.open,
    required this.onDescription,
  });

  final Track track;
  final LevelEntry level;
  final CatalogRow row;
  final bool open;
  final VoidCallback onDescription;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.bazaarColors;
    final muted = colors.onSurfaceMuted;
    final minHeight = minTapTarget(theme.platform);
    final summary = row.summary;
    return BazaarCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(moduleNumber(row.number), style: textTheme.labelLarge?.copyWith(color: muted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${level.title} ${moduleNumber(row.number)}',
                  style: textTheme.labelMedium?.copyWith(color: muted),
                ),
                InkWell(
                  onTap: () => context.push(BazaarPaths.module(track, row.key)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(row.title, style: textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                    ),
                  ),
                ),
                if (summary != null) ...[
                  Semantics(
                    container: true,
                    button: true,
                    expanded: open,
                    child: InkWell(
                      onTap: onDescription,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Row(
                          spacing: AppSpacing.xs,
                          children: [
                            Flexible(child: Text(l10n.card_description, style: textTheme.labelLarge)),
                            ExcludeSemantics(child: Icon(open ? Icons.expand_less : Icons.expand_more, size: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (open)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(summary, style: textTheme.bodyMedium?.copyWith(color: muted)),
                    ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Fact(
                      label: l10n.card_length,
                      value: row.drawn ? _length(l10n, row, context.watch<LanguageCubit>().state) : l10n.module_planned,
                    ),
                    _Fact(label: l10n.card_requires, value: requiresLabel(l10n, row.requires)),
                  ],
                ),
              ],
            ),
          ),
          if (row.drawn) _CompletionDisc(completed: row.signed),
        ],
      ),
    );
  }
}

/// A written module's completion, at the card's end: a filled disc with a check once completed, named for assistive
/// technology; an empty ring before, which is decoration, since the Status filter already says what is not completed.
class _CompletionDisc extends StatelessWidget {
  const _CompletionDisc({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (!completed) {
      return ExcludeSemantics(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.bazaarColors.lineStrong, width: 1.5),
          ),
        ),
      );
    }
    return Semantics(
      image: true,
      label: S.of(context).catalog_filter_completed,
      excludeSemantics: true,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: BazaarFixedColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}

/// A written module's length: its minutes and the words of the document the reader opens, in the reader's language or
/// in English where it is not written in it, as its web page prints them (web D128); the minutes alone when the content
/// has no word count.
String _length(S l10n, CatalogRow row, String language) {
  final lang = row.words.containsKey(language) ? language : 'en';
  return switch (row.words[lang]) {
    final words? => l10n.length_minutes_words(row.minutes, groupedNumber(words, lang)),
    null => l10n.card_length_minutes(row.minutes),
  };
}

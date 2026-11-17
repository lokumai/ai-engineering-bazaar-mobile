import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/reading_style_names.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The key of [spacing]'s segment.
Key readingSpacingKey(ReadingSpacing spacing) => ValueKey('reading-spacing-${spacing.name}');

/// The Reading settings page, from Settings' Reading settings row (plan 12.5): a paragraph drawn as a module's text is,
/// in the chosen settings, then the text size on a slider, the line spacing, and the way back to the default. They
/// change a module's text only, never the menus; a note says so.
class ReadingStylePage extends StatelessWidget {
  const ReadingStylePage({super.key});

  /// The key of the preview's frame.
  static const previewKey = ValueKey('reading-style-preview');

  /// The key of the text size's slider.
  static const sizeKey = ValueKey('reading-style-size');

  /// The key of Back to the default.
  static const resetKey = ValueKey('reading-style-reset');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final style = context.watch<ReadingStyleCubit>().state;
    final cubit = context.read<ReadingStyleCubit>();
    final diagramThemes = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index.diagramThemes,
      // Settings mounts only once the content is ready; the preview needs no diagram.
      _ => null,
    };
    if (diagramThemes == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.settings_reading_style),
            const SizedBox(height: AppSpacing.lg),
            Text(s.reading_preview, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
            const SizedBox(height: AppSpacing.sm),
            // As the reader draws a paragraph, so it shows what a module will look like.
            DecoratedBox(
              key: previewKey,
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                border: Border.all(color: colors.line),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ReadingStyleScope(
                  style: style,
                  child: BlockList(
                    blocks: [
                      ParagraphBlock(inlines: [TextInline(text: s.reading_preview_text)], lead: false),
                    ],
                    render: BlockRenderContext(
                      onLink: (_) {},
                      webPage: null,
                      headingKey: (_) => GlobalKey(),
                      diagramThemes: diagramThemes,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Text(s.reading_size, style: theme.textTheme.titleSmall)),
                Text(
                  readingSizeName(s, style.size),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
                ),
              ],
            ),
            Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.text_decrease, size: 18, color: colors.onSurfaceMuted)),
                Expanded(
                  child: Slider(
                    key: sizeKey,
                    value: style.size.index.toDouble(),
                    max: (ReadingSize.values.length - 1).toDouble(),
                    divisions: ReadingSize.values.length - 1,
                    label: readingSizeName(s, style.size),
                    semanticFormatterCallback: (value) =>
                        '${s.reading_size}, ${readingSizeName(s, ReadingSize.values[value.round()])}',
                    onChanged: (value) => cubit.chooseSize(ReadingSize.values[value.round()]),
                  ),
                ),
                ExcludeSemantics(child: Icon(Icons.text_increase, size: 26, color: colors.onSurfaceMuted)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(s.reading_spacing, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            BazaarSegmentedControl<ReadingSpacing>(
              semanticLabel: s.reading_spacing,
              selected: style.spacing,
              onSelected: cubit.chooseSpacing,
              segments: [
                for (final spacing in ReadingSpacing.values)
                  BazaarSegment(value: spacing, label: readingSpacingName(s, spacing), key: readingSpacingKey(spacing)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: resetKey,
                onPressed: style == ReadingStyle.standard ? null : cubit.reset,
                child: Text(s.reading_reset),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(s.reading_note, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

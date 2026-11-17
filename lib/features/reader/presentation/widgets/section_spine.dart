import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// A module's sections beside its text on a wide screen, an iPad in landscape (plan 12.10), as the web's section spine
/// (`SectionSpine.tsx`, `TableOfContents.tsx`): a line at the start with each section's heading against it, the one
/// in view in the page's ink with its tick out into the gutter, the others muted. A tap scrolls to it. What it tracks
/// is the scroll position, not completion, so it has no visited state. It does not scroll: a module's sections fit a
/// tablet's height.
class SectionSpine extends StatelessWidget {
  const SectionSpine({super.key, required this.sections, required this.current, required this.onTap});

  final List<TocEntry> sections;

  /// The id of the section in view; null above the first.
  final ValueListenable<String?> current;
  final ValueChanged<String> onTap;

  /// The key of [id]'s row.
  static Key rowKey(String id) => ValueKey('section-spine-$id');

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: S.of(context).reader_contents,
      child: ValueListenableBuilder<String?>(
        valueListenable: current,
        builder: (context, inView, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in sections)
              InkWell(
                key: rowKey(section.id),
                onTap: () => onTap(section.id),
                child: Container(
                  constraints: BoxConstraints(minHeight: minTapTarget(Theme.of(context).platform)),
                  alignment: AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        color: section.id == inView ? colors.onSurface : colors.line,
                        width: section.id == inView ? 2 : 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, top: 6, bottom: 6),
                  child: Semantics(
                    selected: section.id == inView,
                    child: Text(
                      section.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: section.id == inView ? colors.onSurface : colors.onSurfaceMuted,
                        fontWeight: section.id == inView ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

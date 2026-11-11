import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/text_find.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';

/// The bar under the reader's bar while the words searched in the catalog are marked in the module (plan 7.1): the
/// words, which mark the reader is on of how many, the previous and the next mark, and close, which takes the marks
/// away. As a browser's find in page.
class FindBar extends StatelessWidget {
  const FindBar({super.key, required this.finder, required this.onClose});

  final TextFinder finder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: ListenableBuilder(
        listenable: finder,
        builder: (context, _) {
          final total = finder.total;
          final position = finder.position;
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: colors.onSurfaceMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finder.query,
                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  label: s.reader_find_position(position, total),
                  child: ExcludeSemantics(
                    child: Text(
                      '$position / $total',
                      style: textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: s.reader_find_previous,
                  onPressed: total == 0 ? null : finder.previous,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: s.reader_find_next,
                  onPressed: total == 0 ? null : finder.next,
                ),
                IconButton(icon: const Icon(Icons.close), tooltip: s.reader_find_close, onPressed: onClose),
              ],
            ),
          );
        },
      ),
    );
  }
}

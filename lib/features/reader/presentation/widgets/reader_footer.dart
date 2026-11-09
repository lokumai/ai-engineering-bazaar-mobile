import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// What closes the page (web `SiteFooter.tsx:58-69`, `title-block.ts:96-98`): `MODULE n OF N` and, when the track has
/// one, the revision `Rev {hash} · {date}`.
class ReaderFooter extends StatelessWidget {
  const ReaderFooter({super.key, required this.entry, required this.track, required this.moduleCount});

  final ModuleEntry entry;
  final Track track;
  final int moduleCount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final style = TextStyle(fontSize: BazaarType.mark.size, color: context.bazaarColors.onSurfaceMuted);
    final revision = entry.tracks[track]?.revision;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.reader_module_of(entry.number, moduleCount), style: style),
        if (revision != null) ...[
          const SizedBox(height: 4),
          _RevisionLine(text: s.reader_revision(revision.hash, revision.date), date: revision.date, style: style),
        ],
      ],
    );
  }
}

/// The revision [text] on one line when it fits; otherwise the part before [date] and [date] on two lines. A
/// machine-derived value never breaks inside itself (web `SiteFooter.tsx`: whitespace-nowrap), and is never cut off.
class _RevisionLine extends StatelessWidget {
  const _RevisionLine({required this.text, required this.date, required this.style});

  final String text;
  final String date;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured in the style Text draws: it adds bold when the platform asks for Bold Text, and bold is wider.
        var drawn = DefaultTextStyle.of(context).style.merge(style);
        if (MediaQuery.boldTextOf(context)) drawn = drawn.merge(const TextStyle(fontWeight: FontWeight.bold));
        final painter = TextPainter(
          text: TextSpan(text: text, style: drawn),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        if (width <= constraints.maxWidth) return Text(text, style: style, softWrap: false);
        final split = text.lastIndexOf(date);
        if (split <= 0) throw StateError('The revision line "$text" does not end with its date "$date"');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text.substring(0, split).trimRight(), style: style, softWrap: false),
            Text(text.substring(split), style: style, softWrap: false),
          ],
        );
      },
    );
  }
}

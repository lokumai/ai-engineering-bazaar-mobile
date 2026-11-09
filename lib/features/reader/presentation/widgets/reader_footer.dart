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
          Text(s.reader_revision(revision.hash, revision.date), style: style, softWrap: false),
        ],
      ],
    );
  }
}

import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A module whose For Everyone version has no document yet (web `NotWritten`, `ModuleSheet.tsx:526-548`): the For
/// Engineers title, one lead line, and the two ways out, to the For Engineers version and to what is written For
/// Everyone at this level.
class NotWrittenView extends StatelessWidget {
  const NotWrittenView({super.key, required this.entry});

  final ModuleEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final title = entry.tracks[Track.engineers]?.title;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Semantics(header: true, child: Text(title, style: readerTitleStyle(context))),
            const SizedBox(height: 16),
          ],
          Text(
            s.reader_not_written,
            style: TextStyle(fontSize: BazaarType.lead.size, color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => unawaited(context.push<void>(BazaarPaths.module(Track.engineers, entry.key))),
                child: Text(s.reader_read_for_engineers),
              ),
              OutlinedButton(
                onPressed: () => unawaited(context.push<void>(BazaarPaths.level(Track.everyone, entry.level))),
                child: Text(s.reader_see_everyone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The module title: the display step at weight 600 with its tracking, in the title ink.
TextStyle readerTitleStyle(BuildContext context) => TextStyle(
  fontSize: BazaarType.display.size,
  height: BazaarType.display.height,
  fontWeight: FontWeight.w600,
  letterSpacing: BazaarType.trackingDisplay * BazaarType.display.size,
  color: context.bazaarColors.onSurfaceTitle,
);

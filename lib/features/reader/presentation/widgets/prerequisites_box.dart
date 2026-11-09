import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The modules to read first (web `Prerequisites.tsx:23-48`, `app/prose.css:565-575`): a book icon and the title, then
/// one link per module, with the `Planned` tag on a module that is not written. A reference to a track this app does
/// not know is plain text.
class PrerequisitesBox extends StatelessWidget {
  const PrerequisitesBox({super.key, required this.refs});

  final List<Ref> refs;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final titleStyle = TextStyle(fontSize: BazaarType.item.size, fontWeight: FontWeight.w600, color: colors.onSurface);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: s.reader_before_you_start,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(BazaarRadii.lg),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                border: Border.all(color: colors.line),
                borderRadius: const BorderRadius.all(BazaarRadii.lg),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The region carries the title as its name, so the visible title is not read twice.
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.reader_before_you_start, style: titleStyle)),
                      ],
                    ),
                  ),
                  for (final ref in refs) _Prerequisite(ref: ref),
                ],
              ),
            ),
            // The 3 px primary edge over the box's start side.
            PositionedDirectional(start: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: colors.primary)),
          ],
        ),
      ),
    );
  }
}

class _Prerequisite extends StatelessWidget {
  const _Prerequisite({required this.ref});

  final Ref ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final track = ref.track;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            ref.title,
            style: TextStyle(
              fontSize: BazaarType.control.size,
              color: track == null ? colors.onSurface : colors.primary,
              decoration: track == null ? null : TextDecoration.underline,
              decorationColor: colors.primary,
            ),
          ),
        ),
        if (!ref.drawn) ...[const SizedBox(width: 8), const _PlannedTag()],
      ],
    );
    if (track == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: label);
    }
    return TextButton(
      onPressed: () => unawaited(context.push<void>(BazaarPaths.module(track, ref.key))),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: AlignmentDirectional.centerStart,
      ),
      child: label,
    );
  }
}

/// The `Planned` tag of a module that is not written (`app/prose.css:613-619`).
class _PlannedTag extends StatelessWidget {
  const _PlannedTag();

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: const BorderRadius.all(BazaarRadii.xs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        S.of(context).module_planned,
        style: TextStyle(fontSize: BazaarType.label.size, color: colors.onSurfaceMuted),
      ),
    );
  }
}

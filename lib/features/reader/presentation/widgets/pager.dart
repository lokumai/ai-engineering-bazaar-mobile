import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The previous and the next module (web `PrevNext.tsx`): Next filled in primary, Previous outlined in it, each a small
/// label over the bold title, with ` · Planned` on a target that is not written. With no target the cell says the
/// course starts or ends there; a target in a track this app does not know is shown but is not a link.
class Pager extends StatelessWidget {
  const Pager({super.key, required this.previous, required this.next});

  final Ref? previous;
  final Ref? next;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Cell(ref: previous, forward: false)),
          const SizedBox(width: 12),
          Expanded(child: _Cell(ref: next, forward: true)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.ref, required this.forward});

  final Ref? ref;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final ref = this.ref;
    final align = forward ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = forward ? TextAlign.end : TextAlign.start;
    final titleStyle = TextStyle(fontSize: BazaarType.control.size, fontWeight: FontWeight.w600);
    const padding = EdgeInsets.symmetric(vertical: 12, horizontal: 14);
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.md));

    if (ref == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: const BorderRadius.all(BazaarRadii.md),
        ),
        padding: padding,
        alignment: forward ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Text(
          forward ? s.reader_end_of_course : s.reader_start_of_course,
          style: titleStyle.copyWith(color: colors.onSurface),
          textAlign: textAlign,
        ),
      );
    }

    final word = forward ? s.reader_next : s.reader_previous;
    final label = ref.drawn ? word : s.reader_pager_planned(word);
    final texts = Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: BazaarType.meta.size),
          textAlign: textAlign,
        ),
        const SizedBox(height: 2),
        Text(ref.title, style: titleStyle, textAlign: textAlign),
      ],
    );
    final track = ref.track;
    if (track == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: const BorderRadius.all(BazaarRadii.md),
        ),
        padding: padding,
        alignment: forward ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onSurface),
          child: texts,
        ),
      );
    }

    final chevron = ExcludeSemantics(child: Icon(forward ? Icons.chevron_right : Icons.chevron_left, size: 20));
    final child = Row(
      mainAxisAlignment: forward ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!forward) chevron,
        Flexible(child: texts),
        if (forward) chevron,
      ],
    );
    void open() => unawaited(context.push<void>(BazaarPaths.module(track, ref.key)));
    return forward
        ? FilledButton(
            onPressed: open,
            style: FilledButton.styleFrom(padding: padding, shape: shape),
            child: child,
          )
        : OutlinedButton(
            onPressed: open,
            style: OutlinedButton.styleFrom(
              padding: padding,
              shape: shape,
              side: BorderSide(color: colors.primary),
            ),
            child: child,
          );
  }
}

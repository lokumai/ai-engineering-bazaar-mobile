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
///
/// On a phone the two stack, Next first as the mockup's next-module card, each as wide as the page.
class Pager extends StatelessWidget {
  const Pager({super.key, required this.previous, required this.next});

  final Ref? previous;
  final Ref? next;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _Cell(ref: next, forward: true),
        _Cell(ref: previous, forward: false),
      ],
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
    const align = CrossAxisAlignment.start;
    const textAlign = TextAlign.start;
    final titleStyle = TextStyle(fontSize: BazaarType.item.size + 2, fontWeight: FontWeight.w600);
    const padding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.md));

    if (ref == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: const BorderRadius.all(BazaarRadii.md),
        ),
        padding: padding,
        alignment: AlignmentDirectional.centerStart,
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
        alignment: AlignmentDirectional.centerStart,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onSurface),
          child: texts,
        ),
      );
    }

    final arrow = ExcludeSemantics(child: Icon(forward ? Icons.arrow_forward : Icons.arrow_back, size: 20));
    final child = Row(
      spacing: 12,
      children: [
        if (!forward) arrow,
        Expanded(child: texts),
        if (forward) arrow,
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

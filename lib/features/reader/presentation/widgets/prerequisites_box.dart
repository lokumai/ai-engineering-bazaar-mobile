import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    // Spaced near the body's list items, not a full tap target apart (review findings, F): each link keeps its 48 px
    // target, and the rows overlap by the part of it the text does not need.
    if (track == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: label);
    }
    return _Overlapping(
      by: 7,
      child: TextButton(
        onPressed: () => unawaited(context.push<void>(BazaarPaths.module(track, ref.key))),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: AlignmentDirectional.centerStart,
        ),
        child: label,
      ),
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

/// [child] laid out [by] shorter at its top and at its bottom than it is: it paints and takes taps over the whole of
/// itself, overlapping its neighbours by that much, so a tap target can be taller than the line it sits on.
class _Overlapping extends SingleChildRenderObjectWidget {
  const _Overlapping({required this.by, required super.child});

  final double by;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOverlapping(by);

  @override
  void updateRenderObject(BuildContext context, _RenderOverlapping renderObject) => renderObject.by = by;
}

class _RenderOverlapping extends RenderProxyBox {
  _RenderOverlapping(this._by);

  double _by;
  set by(double value) {
    if (value == _by) return;
    _by = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!..layout(constraints.loosen(), parentUsesSize: true);
    final inset = math.min(_by, child.size.height / 2);
    size = constraints.constrain(Size(child.size.width, child.size.height - inset * 2));
    (child.parentData! as BoxParentData).offset = Offset(0, -inset);
  }

  Offset get _offset => (child!.parentData! as BoxParentData).offset;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  void paint(PaintingContext context, Offset offset) => context.paintChild(child!, offset + _offset);

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => hitTestChildren(result, position: position);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => result.addWithPaintOffset(
    offset: _offset,
    position: position,
    hitTest: (result, transformed) => child!.hitTest(result, position: transformed),
  );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(_offset.dx, _offset.dy, 0, 1);
}

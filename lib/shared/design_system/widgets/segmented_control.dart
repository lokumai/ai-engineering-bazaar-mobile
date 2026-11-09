import 'package:flutter/material.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// One choice of a [BazaarSegmentedControl].
final class BazaarSegment<T> {
  const BazaarSegment({required this.value, required this.label, this.key});

  final T value;
  final String label;

  /// The key of the segment's button, for tests.
  final Key? key;
}

/// A row of choices in one framed track, the chosen one filled (the mockup's track and status controls).
///
/// Each segment is a selectable button named by its label, at least the platform's tap target tall (spec 3.10, A28).
/// The segments share the width when they fit at their natural size; otherwise the row scrolls sideways, so a large
/// text scale never cuts a label.
class BazaarSegmentedControl<T> extends StatelessWidget {
  const BazaarSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    required this.semanticLabel,
    this.filled = true,
  });

  final List<BazaarSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// The name of the group for assistive technology.
  final String semanticLabel;

  /// Whether the chosen segment is filled with the primary colour (the track control) or with the sunken surface (the
  /// status control).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final minHeight = minTapTarget(Theme.of(context).platform);
    final buttons = [
      for (final segment in segments)
        _SegmentButton<T>(
          key: segment.key,
          segment: segment,
          chosen: segment.value == selected,
          filled: filled,
          minHeight: minHeight,
          onTap: () {
            if (segment.value != selected) onSelected(segment.value);
          },
        ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.line),
          borderRadius: const BorderRadius.all(BazaarRadii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: LayoutBuilder(
            builder: (context, constraints) => _fits(context, constraints.maxWidth)
                ? Row(spacing: 6, children: [for (final button in buttons) Expanded(child: button)])
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(spacing: 6, children: buttons),
                  ),
          ),
        ),
      ),
    );
  }

  /// Whether every label fits an equal share of [width] on one line at the current text scale.
  bool _fits(BuildContext context, double width) {
    final style = _SegmentButton.styleOf(context, chosen: true);
    final share = (width - 6 * (segments.length - 1)) / segments.length - 2 * _SegmentButton.inset;
    final scaler = MediaQuery.textScalerOf(context);
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final fits = painter.width <= share;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    super.key,
    required this.segment,
    required this.chosen,
    required this.filled,
    required this.minHeight,
    required this.onTap,
  });

  final BazaarSegment<T> segment;
  final bool chosen;
  final bool filled;
  final double minHeight;
  final VoidCallback onTap;

  static const double inset = 12;

  static TextStyle? styleOf(BuildContext context, {required bool chosen}) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: chosen ? FontWeight.w600 : FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final (Color background, Color ink) = switch ((chosen, filled)) {
      (true, true) => (colors.primary, colors.onPrimary),
      (true, false) => (colors.surfaceSunken, colors.onSurfaceTitle),
      (false, _) => (Colors.transparent, colors.onSurfaceMuted),
    };
    return Semantics(
      button: true,
      selected: chosen,
      child: Material(
        color: background,
        borderRadius: const BorderRadius.all(BazaarRadii.base),
        child: InkWell(
          borderRadius: const BorderRadius.all(BazaarRadii.base),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: inset),
              // heightFactor 1: the segment is as tall as its label and the tap target, not as its parent.
              child: Center(
                heightFactor: 1,
                child: Text(
                  segment.label,
                  maxLines: 1,
                  softWrap: false,
                  style: styleOf(context, chosen: chosen)?.copyWith(color: ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

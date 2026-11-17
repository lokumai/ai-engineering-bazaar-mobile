import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:flutter/material.dart';

/// A setting of a few short choices with its [label] at the start of the same line as its control, so Settings shows
/// Reading and Customize whole on one screen (plan 12.4). When the label and every choice do not fit on one line, at a
/// larger text size or on a narrow screen, the label stands above the control as before; nothing is ever cut.
class InlineSetting<T> extends StatelessWidget {
  const InlineSetting({
    super.key,
    required this.label,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<BazaarSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// The room between the label and the control on one line.
  static const double gap = AppSpacing.lg;

  /// A segment's room beside its label: its insets on both sides.
  static const double _segmentRoom = 2 * 12;

  /// The control's own room beyond its segments: the frame's padding and border, and the gaps between segments.
  double _controlRoom() => 2 * 3 + 2 + 6.0 * (segments.length - 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall;
    final control = BazaarSegmentedControl<T>(
      semanticLabel: label,
      selected: selected,
      onSelected: onSelected,
      segments: segments,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_fits(context, constraints.maxWidth, labelStyle)) {
          return Row(
            children: [
              Text(label, style: labelStyle, maxLines: 1),
              const SizedBox(width: gap),
              Expanded(child: control),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(label, style: labelStyle),
            control,
          ],
        );
      },
    );
  }

  /// Whether the label, the gap and the control with every choice an equal share wide enough fit in [width].
  bool _fits(BuildContext context, double width, TextStyle? labelStyle) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final measured = painter.width;
      painter.dispose();
      return measured;
    }

    final segmentStyle = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    var widest = 0.0;
    for (final segment in segments) {
      final measured = measure(segment.label, segmentStyle);
      if (measured > widest) widest = measured;
    }
    final controlWidth = segments.length * (widest + _segmentRoom) + _controlRoom();
    // A little to spare, so the control does not stand on the edge of wrapping its segments.
    return measure(label, labelStyle) + gap + controlWidth + 8 <= width;
  }
}

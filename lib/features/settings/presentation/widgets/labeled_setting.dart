import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:flutter/material.dart';

/// A setting of a few choices with its [label] just above its control (the owner, 2026-11-17: a label beside the
/// control, or none at all, made Settings look crowded). The label is said once, by the control, to a screen reader.
class LabeledSetting<T> extends StatelessWidget {
  const LabeledSetting({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        ExcludeSemantics(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        BazaarSegmentedControl<T>(semanticLabel: label, selected: selected, onSelected: onSelected, segments: segments),
      ],
    );
  }
}

import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/level_card.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The legend under a track's level cards (web `CourseCompletion.tsx:281-294`): each mark of a module row with its word.
class ProgressLegend extends StatelessWidget {
  const ProgressLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        for (final (kind, word) in [
          (ProgressMarkKind.complete, s.progress_state_complete),
          (ProgressMarkKind.notYet, s.progress_state_not_yet),
          (ProgressMarkKind.planned, s.module_planned),
        ])
          Row(
            spacing: AppSpacing.sm,
            children: [
              ExcludeSemantics(child: ProgressMark(kind)),
              Flexible(child: Text(word, style: style)),
            ],
          ),
      ],
    );
  }
}

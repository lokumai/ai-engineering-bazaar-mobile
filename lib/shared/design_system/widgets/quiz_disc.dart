import 'package:flutter/material.dart';

import '../bazaar_theme.dart';

/// A quiz's mark in a list: a question mark in a ring of its level's [hue], so the quizzes of each level read apart
/// (the user, 2026-11-10). The hue is the ring only; the mark is in the title ink (spec 3.8: no hue is safe for text).
/// Decoration: the row names the quiz.
class QuizDisc extends StatelessWidget {
  const QuizDisc({super.key, required this.hue});

  final Color hue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.alphaBlend(hue.withValues(alpha: 0.14), colors.surface),
          shape: BoxShape.circle,
          border: Border.all(color: hue, width: 2),
        ),
        child: Text(
          '?',
          textScaler: TextScaler.noScaling,
          style: TextStyle(color: colors.onSurfaceTitle, fontWeight: FontWeight.w700, fontSize: 14, height: 1),
        ),
      ),
    );
  }
}

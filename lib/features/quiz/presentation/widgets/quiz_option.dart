import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The letter of option [index]: A, B, C, D (web `QuickQuiz.tsx:35`).
String quizLetter(int index) => String.fromCharCode(0x41 + index);

/// The size [text] takes in [style] at the current text scale, so a box sized from it grows with the text (spec 3.10).
Size quizTextSize(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

/// How an option is drawn: before the answer, the right option, the wrong pick, or any other option once answered.
enum QuizOutcome { open, right, wrong, other }

/// One option: its letter and text in `onSurface` on `surfaceRaised` in every state (the web's `on-primary` letter on
/// a `success` or `fault` disc reads under 4.5:1), the outcome shown by an edge and an icon only.
class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.outcome,
    required this.onPressed,
  });

  final String letter;
  final String text;
  final bool selected;
  final QuizOutcome outcome;

  /// Null once the question is answered: the option is then disabled, as the web's `aria-disabled` option is.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final edge = switch (outcome) {
      QuizOutcome.right => const BorderSide(color: BazaarFixedColors.success, width: 2),
      QuizOutcome.wrong => BorderSide(color: colors.fault, width: 2),
      QuizOutcome.open || QuizOutcome.other => BorderSide(color: colors.lineStrong),
    };
    final ink = outcome == QuizOutcome.other ? colors.onSurfaceMuted : colors.onSurface;
    final icon = switch (outcome) {
      QuizOutcome.right => const Icon(Icons.check, color: BazaarFixedColors.success),
      QuizOutcome.wrong => Icon(Icons.close, color: colors.fault),
      QuizOutcome.open || QuizOutcome.other => null,
    };
    final target = minTapTarget(Theme.of(context).platform);
    final letterStyle = TextStyle(fontSize: BazaarType.mark.size, fontWeight: FontWeight.w600, color: ink);
    // 26 at text scale 1.0; larger text grows the circle around its letter instead of cutting the letter off.
    final letterSize = quizTextSize(context, letter, letterStyle);
    final diameter = math.max(26.0, (math.max(letterSize.width, letterSize.height) + 8).ceilToDouble());
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: onPressed != null,
      label: '$letter $text',
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(side: edge, borderRadius: const BorderRadius.all(BazaarRadii.md)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(BazaarRadii.md)),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: target),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: diameter,
                    height: diameter,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.lineStrong),
                    ),
                    child: Text(letter, style: letterStyle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: BazaarType.control.size, color: ink),
                    ),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), ExcludeSemantics(child: icon)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The verdict of an answered question and its explanation, on `surfaceSunken` with a 3 px edge at the start of the line
/// (the right in Persian) in `success` or `fault`; the text stays `onSurface` (Decision A18).
class QuizVerdict extends StatelessWidget {
  const QuizVerdict({super.key, required this.item, required this.right, this.answer, this.footer});

  final QuizItem item;
  final bool right;

  /// The right option's place as shown, when the options are shown in another order than the item's (plan 13.6).
  final int? answer;

  /// What follows the explanation: Practice's way to the section the question is about (plan 13.5).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final edge = right ? BazaarFixedColors.success : colors.fault;
    final style = TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: BorderDirectional(start: BorderSide(color: edge, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(right ? Icons.check : Icons.close, color: edge, size: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  right ? s.quiz_correct : s.quiz_wrong(quizLetter(answer ?? item.answer)),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // A term asked in Practice has no explanation of its own (plan 13.16).
          if (item.explain.isNotEmpty) ...[const SizedBox(height: 6), Text(item.explain, style: style)],
          if (footer case final footer?) ...[const SizedBox(height: 8), footer],
        ],
      ),
    );
  }
}

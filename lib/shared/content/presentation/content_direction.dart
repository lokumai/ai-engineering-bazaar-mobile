import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out in the direction its text is written in, whatever the interface's: English shown in the Persian
/// interface (a planned module's draft, a summary, a level's notes, which the web writes in English only) reads left
/// to right, its full stop at the end of the line, not at its start (review 5, finding 5).
class ContentDirection extends StatelessWidget {
  const ContentDirection({super.key, required this.dir, required this.child});

  /// English, the language of what the web publishes in English only.
  const ContentDirection.english({super.key, required this.child}) : dir = TextDir.ltr;

  final TextDir dir;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: dir == TextDir.rtl ? TextDirection.rtl : TextDirection.ltr, child: child);
}

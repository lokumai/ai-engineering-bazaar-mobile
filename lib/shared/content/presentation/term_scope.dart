import 'package:flutter/widgets.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/term_marks.dart';

/// The terms a module's text marks (plan 13.9): an [InlineText] under it draws each of its texts' marks with a dotted
/// underline, and a tap on one calls [onTap] with the term and where the finger lifted, or null when the tap came from a
/// screen reader.
class TermScope extends InheritedWidget {
  const TermScope({super.key, required this.marks, required this.onTap, required super.child});

  /// The marks of each text, by the text inline itself.
  final Map<TextInline, List<TermMark>> marks;
  final void Function(GlossaryTerm term, Offset? at) onTap;

  static TermScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TermScope>();

  @override
  bool updateShouldNotify(TermScope oldWidget) => !identical(marks, oldWidget.marks) || onTap != oldWidget.onTap;
}

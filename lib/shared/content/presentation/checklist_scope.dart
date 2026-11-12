import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

/// The module's checklist made live (web `ChecklistIsland`, D129): the task items under it show the reader's ticks
/// and change them. Without one, a task box shows the document's own state and cannot be changed (A16).
class ChecklistScope extends InheritedWidget {
  const ChecklistScope({super.key, required this.ticks, required this.onToggle, required super.child});

  /// The indexes of the items ticked.
  final Set<int> ticks;

  /// Ticks the item at an index, or takes its tick away.
  final void Function(int index, {required bool ticked}) onToggle;

  /// The scope above [context], if any.
  static ChecklistScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ChecklistScope>();

  @override
  bool updateShouldNotify(ChecklistScope oldWidget) =>
      !setEquals(ticks, oldWidget.ticks) || onToggle != oldWidget.onToggle;
}

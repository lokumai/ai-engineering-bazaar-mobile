import 'package:flutter/widgets.dart';

/// The room a button floating over a page's foot takes (plan 9.4: the pocket model's round button in the shell's
/// corner): the shell sets it, and a page that scrolls adds it under its end, so its last lines scroll clear of the
/// button. None where nothing floats.
class FloatingRoom extends InheritedWidget {
  const FloatingRoom({super.key, required this.room, required super.child});

  /// The height, in logical pixels, to keep free under a page's end.
  final double room;

  /// The room over [context]'s page; 0 when nothing floats there.
  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FloatingRoom>()?.room ?? 0;

  @override
  bool updateShouldNotify(FloatingRoom oldWidget) => oldWidget.room != room;
}

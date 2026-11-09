import 'package:flutter/widgets.dart';

/// [duration], or [Duration.zero] when the platform asks for reduced motion (spec 3.10).
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

/// A page transition that draws the incoming page unanimated when the platform asks for reduced motion (spec 3.10), and
/// [platformBuilder]'s transition otherwise. Durations and the delegated transition stay [platformBuilder]'s; a route
/// that must also take no time under reduced motion sets its own duration (A40).
final class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder(this.platformBuilder);

  final PageTransitionsBuilder platformBuilder;

  @override
  Duration get transitionDuration => platformBuilder.transitionDuration;

  @override
  Duration get reverseTransitionDuration => platformBuilder.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => platformBuilder.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return platformBuilder.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}

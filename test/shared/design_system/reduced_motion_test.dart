import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A platform builder that marks the child it wraps, so a test can tell whether it ran.
class _MarkerBuilder extends PageTransitionsBuilder {
  const _MarkerBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 321);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 123);

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _delegated;

  static Widget? _delegated(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => KeyedSubtree(key: const ValueKey('animated'), child: child);
}

void main() {
  Future<BuildContext> contextWith(WidgetTester tester, {required bool disableAnimations}) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  group('motionDuration', () {
    testWidgets('is zero under reduced motion', (tester) async {
      final context = await contextWith(tester, disableAnimations: true);
      expect(motionDuration(context, const Duration(milliseconds: 200)), Duration.zero);
    });

    testWidgets('is the given duration otherwise', (tester) async {
      final context = await contextWith(tester, disableAnimations: false);
      expect(motionDuration(context, const Duration(milliseconds: 200)), const Duration(milliseconds: 200));
    });
  });

  group('ReducedMotionPageTransitionsBuilder', () {
    const builder = ReducedMotionPageTransitionsBuilder(_MarkerBuilder());
    const child = SizedBox(key: ValueKey('child'));
    final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());

    Widget build(BuildContext context) =>
        builder.buildTransitions(route, context, kAlwaysCompleteAnimation, kAlwaysDismissedAnimation, child);

    testWidgets('returns the child itself under reduced motion', (tester) async {
      final context = await contextWith(tester, disableAnimations: true);
      expect(identical(build(context), child), isTrue);
    });

    testWidgets('delegates to the platform builder otherwise', (tester) async {
      final context = await contextWith(tester, disableAnimations: false);
      final built = build(context);
      expect((built as KeyedSubtree).key, const ValueKey('animated'));
      expect(built.child, same(child));
    });

    test('takes its durations and delegated transition from the platform builder', () {
      const marker = _MarkerBuilder();
      expect(
        (builder.transitionDuration, builder.reverseTransitionDuration, builder.delegatedTransition),
        (marker.transitionDuration, marker.reverseTransitionDuration, marker.delegatedTransition),
      );
    });
  });
}

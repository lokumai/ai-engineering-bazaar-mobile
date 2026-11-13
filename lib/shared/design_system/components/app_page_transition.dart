import 'package:ai_engineering_bazaar/shared/navigation/tab_switch.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates a platform-adaptive [MaterialPage], built the way go_router 17 built pages for `builder:` routes.
///
/// go_router 18 only detects material_ui's MaterialApp. Under the SDK MaterialApp it turns `builder:` routes into
/// `NoTransitionPage`s, so every route must return an explicit page.
///
/// Unlike go_router 17, path and query parameters are not copied into the page arguments: nothing reads them, and a
/// navigator observer added later would otherwise record values such as the module key of a reader path (Decision A5).
///
/// [name] replaces the route-derived name for a page that has no route of its own, such as the error page.
MaterialPage<void> appPlatformPage({required Widget child, required GoRouterState state, String? name}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: name ?? state.name ?? state.path,
    restorationId: state.pageKey.value,
    child: child,
  );
}

/// Creates a route's page with the platform's own transition, the theme's: on iOS it slides in from the side and goes
/// back with the edge swipe, on Android it zooms in. The page is drawn on the app's ground, so the page under it never
/// shows through while it moves (the owner, 2026-11-12: one tab's text showed behind another's in the fade before).
///
/// Named like [appPlatformPage], so every page carries the same kind of name.
///
/// [context] is the page builder's: when the platform asks for reduced motion, both durations are zero (Decision A40,
/// spec 3.10). While the shell moves to another tab ([TabSwitch]) the page comes in and goes out at once.
Page<void> appTransitionPage({required BuildContext context, required Widget child, required GoRouterState state}) =>
    _AppPage(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      still: MediaQuery.disableAnimationsOf(context),
      child: child,
    );

class _AppPage extends MaterialPage<void> {
  const _AppPage({super.key, super.name, super.restorationId, required this.still, required super.child});

  /// Whether the platform asks for reduced motion.
  final bool still;

  @override
  Route<void> createRoute(BuildContext context) => _AppPageRoute(page: this);
}

class _AppPageRoute extends PageRoute<void> with MaterialRouteTransitionMixin<void> {
  _AppPageRoute({required _AppPage page}) : super(settings: page, allowSnapshotting: page.allowSnapshotting);

  _AppPage get _page => settings as _AppPage;

  @override
  Widget buildContent(BuildContext context) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: _page.child);

  // Read when the route is created: a page that comes in with a move to another tab takes no time.
  @override
  Duration get transitionDuration => _page.still || TabSwitch.active ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.still ? Duration.zero : super.reverseTransitionDuration;

  @override
  bool didPop(void result) {
    // The route was created before the move, so its going out is made instant here.
    if (TabSwitch.active) controller?.reverseDuration = Duration.zero;
    return super.didPop(result);
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

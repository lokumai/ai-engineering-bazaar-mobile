import 'package:ai_engineering_bazaar/app/shell/caravan_icon.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The frame of every page inside the router's ShellRoute: the bar on the page's ground with a back button when there is
/// a page to go back to and, on a level's page or a module's, its name after the level's hue (the four tabs' pages carry
/// no name), the thin lattice band under it, the page, and the bottom navigation (web nav labels `Home` and `Catalog`,
/// `src/components/shell/MainNav.tsx`; `Quiz` and `Settings` are app copy: the catalog carries the progress, plan 1AB,
/// 1AC). The track is chosen once and changed in Settings (plan 1L).
///
/// The navigation is a low row of icons, each with its name small under it, on the page's ground under a hairline: the
/// open tab's icon is filled and its name dark, the others outlined and muted (the user, 2026-11-10: "like X", with the
/// names kept so each is clear). The Caravan's camel holds the middle and opens its page, which says it is under
/// maintenance until the bundle carries the web's timeline (plan 3.1).
///
/// On a module page the bar, the band and the bottom navigation slide away while the reader scrolls down, for a taller
/// page, and come back on a scroll up, at the top and at the end; the status strip stays. They stay while a screen
/// reader runs, and move without animation under reduced motion.
///
/// Each tab keeps its pages: leaving a module for another tab and coming back opens the module again, where the reader
/// left it (plan 1AZ, 1BA); a tap on the open tab goes back to its first page.
///
/// Opening a page of a track remembers that track, as the web remembers the last track page opened
/// (`src/lib/tracks.ts:77-114`).
class BazaarShell extends StatefulWidget {
  const BazaarShell({super.key, required this.location, required this.child});

  /// The path of the page [child] shows.
  final String location;
  final Widget child;

  /// The navigation's height: under Material's 80, the icons and their small names.
  static const double navHeight = 62;

  @override
  State<BazaarShell> createState() => _BazaarShellState();
}

class _BazaarShellState extends State<BazaarShell> {
  /// The scroll distance in one direction that hides or shows the navigation, so a trembling finger does neither.
  static const double _travel = 24;

  bool _navHidden = false;

  /// The distance scrolled since the direction last changed: positive down, negative up.
  double _run = 0;

  /// Which way the reader is scrolling the page; idle while the page is scrolled for them, as a module that opens at
  /// the place it was left (plan 1BA), which hides nothing.
  ScrollDirection _direction = ScrollDirection.idle;

  @override
  void initState() {
    super.initState();
    _rememberTrack();
  }

  @override
  void didUpdateWidget(BazaarShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _rememberTrack();
      _navHidden = false;
      _run = 0;
      _direction = ScrollDirection.idle;
    }
  }

  bool get _onModule => BazaarPaths.moduleOf(widget.location) != null;

  /// Hides the navigation after [_travel] down and shows it after [_travel] up, at either end, and on an overscroll.
  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (!_onModule || notification.depth != 0 || metrics.axis != Axis.vertical) return false;
    var hidden = _navHidden;
    if (notification is UserScrollNotification) _direction = notification.direction;
    if (notification is OverscrollNotification) {
      hidden = false;
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (metrics.pixels <= metrics.minScrollExtent || metrics.extentAfter <= 0) {
        hidden = false;
        _run = 0;
      } else if (delta != 0 && _direction != ScrollDirection.idle) {
        _run = (_run > 0) == (delta > 0) ? _run + delta : delta;
        if (_run > _travel) hidden = true;
        if (_run < -_travel) hidden = false;
      }
    }
    if (hidden != _navHidden) setState(() => _navHidden = hidden);
    return false;
  }

  /// The hue of the level a level page or a module page belongs to; null on every other page.
  Color? _accent(BuildContext context, BundleIndex? index) {
    final location = widget.location;
    final slug = BazaarPaths.levelOf(location) ?? BazaarPaths.moduleOf(location)?.split('/').first;
    if (slug == null || index == null) return null;
    final position = index.levels.indexWhere((level) => level.slug == slug);
    return position < 0 ? null : levelHue(context, position);
  }

  /// The name the bar gives a level's page or a module's, from the index; none on the four tabs' pages (owner, 2026-11-10).
  String? _title(BundleIndex? index) {
    final location = widget.location;
    if (BazaarPaths.moduleOf(location) case final key?) {
      final track = BazaarPaths.trackOf(location)!;
      if (index?.module(key)?.tracks[track]?.title case final title?) return title;
    }
    if (BazaarPaths.levelOf(location) case final slug?) {
      if (index?.level(slug)?.title case final title?) return title;
    }
    return null;
  }

  void _rememberTrack() {
    final track = BazaarPaths.trackOf(widget.location);
    if (track != null) context.read<TrackCubit>().select(track);
  }

  /// The pages each tab showed last, by its place in the navigation, with the path of the page on top: a tab opened
  /// again opens them again.
  final _stacks = <int, ({RouteMatchList pages, String top})>{};

  /// Home, Catalog (every page of a track), the Caravan, Quiz and Settings.
  int get _selectedIndex => switch (widget.location) {
    BazaarPaths.caravan => 2,
    BazaarPaths.quizzes => 3,
    final location when location == BazaarPaths.settings || location.startsWith('${BazaarPaths.settings}/') => 4,
    final location when BazaarPaths.trackOf(location) != null => 1,
    _ => 0,
  };

  void _onDestinationSelected(int index) {
    final track = context.read<TrackCubit>().state;
    final target = switch (index) {
      0 => BazaarPaths.home,
      2 => BazaarPaths.caravan,
      3 => BazaarPaths.quizzes,
      4 => BazaarPaths.settings,
      _ => BazaarPaths.catalog(BazaarPaths.trackOf(widget.location) ?? track),
    };
    final router = GoRouter.of(context);
    final kept = _stacks[index];
    // The open tab goes back to its first page; another opens its own pages again, unless they are of the track the
    // reader left since (Settings changes the track).
    if (index == _selectedIndex || kept == null || (index == 1 && BazaarPaths.trackOf(kept.top) != track)) {
      _stacks.remove(index);
      router.go(target);
    } else {
      router.restore(kept.pages);
    }
  }

  /// Whether a page was pushed over the shell's first page: the shell's matches hold more than one page.
  ///
  /// Read from the router's configuration, which is already the new one when the shell rebuilds; the navigator's own
  /// `canPop` still answers for the pages it showed before.
  static bool _pushed(List<RouteMatchBase> matches) => _pages(matches) > 1;

  static int _pages(List<RouteMatchBase> matches) =>
      matches.fold(0, (count, match) => count + (match is ShellRouteMatch ? _pages(match.matches) : 1));

  /// The paths of the pages in [matches], the first page first.
  static List<String> _locations(List<RouteMatchBase> matches) => [
    for (final match in matches)
      if (match is ShellRouteMatch) ..._locations(match.matches) else match.matchedLocation,
  ];

  /// The bar's back button, which only a module's page shows: it goes back to the catalog of the module's track, not to
  /// the page before as a browser would (the owner, 2026-11-11). The catalog page under the module, its root or a level's
  /// page, is found again as it was left, its search included; when none is under it (the module was opened from Home,
  /// from Quiz or from another module), the catalog opens.
  void _back() {
    final router = GoRouter.of(context);
    final track = BazaarPaths.trackOf(widget.location);
    if (track == null) {
      router.pop();
      return;
    }
    final catalog = BazaarPaths.catalog(track);
    final pages = _locations(router.routerDelegate.currentConfiguration.matches);
    // The catalog's root or one of its level pages, of the module's track.
    final at = pages.lastIndexWhere(
      (page) => page == catalog || (BazaarPaths.levelOf(page) != null && BazaarPaths.trackOf(page) == track),
    );
    if (at < 0) {
      router.go(catalog);
      return;
    }
    for (var i = pages.length - 1; i > at; i--) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final index = context.select<ContentBloc, BundleIndex?>(
      (bloc) => switch (bloc.state) {
        ContentReady(:final index) => index,
        _ => null,
      },
    );
    final media = MediaQuery.of(context);
    final chromeHidden = _navHidden && _onModule && !media.accessibleNavigation;
    final motion = media.disableAnimations ? Duration.zero : BazaarMotion.fold;
    final configuration = GoRouter.of(context).routerDelegate.currentConfiguration;
    final pushed = _pushed(configuration.matches);
    _stacks[_selectedIndex] = (pages: configuration, top: widget.location);
    final colors = context.bazaarColors;
    final idle = IconThemeData(size: 24, color: colors.onSurfaceMuted);
    final open = IconThemeData(size: 24, color: colors.onSurface);
    NavigationDestination tab(IconData outlined, IconData filled, String label) => NavigationDestination(
      icon: Icon(outlined, color: idle.color, size: idle.size),
      selectedIcon: Icon(filled, color: open.color, size: open.size),
      label: label,
    );
    // The system back on the first page of a tab other than Home goes Home, as Android apps with a navigation bar do,
    // rather than leaving the app; on Home's first page it leaves.
    final atTabRoot = !pushed && _selectedIndex != 0;
    return PopScope(
      canPop: !atTabRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && atTabRoot) _onDestinationSelected(0);
      },
      child: Scaffold(
        body: Column(
          children: [
            // The status strip stays; the bar and the band fold up with the navigation while a module is read.
            const BazaarStatusStrip(),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.bottomCenter,
                heightFactor: chromeHidden ? 0 : 1,
                duration: motion,
                curve: BazaarMotion.bazaar,
                child: ExcludeSemantics(
                  excluding: chromeHidden,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BazaarBar(
                        statusStrip: false,
                        title: _title(index),
                        accent: _accent(context, index),
                        // The bar sits above the shell's navigator, so the router goes back, to the catalog.
                        onBack: pushed ? _back : null,
                      ),
                      const LatticeBand(thin: true),
                    ],
                  ),
                ),
              ),
            ),
            // The status strip already keeps the page clear of the status bar.
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
              ),
            ),
          ],
        ),
        // The bar slides out under the screen's foot as its height closes, so the page grows into the room it leaves.
        bottomNavigationBar: ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: chromeHidden ? 0 : 1,
            duration: motion,
            curve: BazaarMotion.bazaar,
            child: ExcludeSemantics(
              excluding: chromeHidden,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.line, width: 0.5)),
                ),
                child: NavigationBar(
                  height: BazaarShell.navHeight,
                  backgroundColor: colors.surface,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  labelPadding: const EdgeInsets.only(top: 2),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      letterSpacing: 0.1,
                      fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
                      color: states.contains(WidgetState.selected) ? open.color : idle.color,
                    ),
                  ),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: [
                    tab(Icons.home_outlined, Icons.home_rounded, l10n.nav_home),
                    tab(Icons.menu_book_outlined, Icons.menu_book_rounded, l10n.nav_catalog),
                    NavigationDestination(
                      icon: IconTheme.merge(data: idle, child: const CaravanIcon()),
                      selectedIcon: IconTheme.merge(data: open, child: const CaravanIcon()),
                      label: l10n.nav_caravan,
                    ),
                    tab(Icons.quiz_outlined, Icons.quiz_rounded, l10n.nav_quiz),
                    tab(Icons.settings_outlined, Icons.settings_rounded, l10n.nav_settings),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

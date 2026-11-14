import 'dart:async';

import 'package:ai_engineering_bazaar/shared/design_system/widgets/caravan_icon.dart';
import 'package:ai_engineering_bazaar/app/shell/floating_dock.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/navigation/tab_switch.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
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
/// left it (plan 1AZ, 1BA); a tap on the open tab goes back to its first page. Another tab's pages come at once, with
/// no transition, as tabs change on iOS and Android ([TabSwitch], the owner, 2026-11-12).
///
/// On iOS a tap on the status bar takes the page in front back to its top, as iOS apps do.
///
/// Opening a page of a track remembers that track, as the web remembers the last track page opened
/// (`src/lib/tracks.ts:77-114`).
///
/// The [assistant] the router passes (the pocket model's round button, plan 9.4) sits in the corner over the
/// navigation on Home's first page only; never over the catalog, the Quiz tab, a level's page, a module or the
/// Caravan's stage, and it goes with the navigation when a page folds it away. The reader can drag it or throw it
/// ([FloatingDock]); it stays where it rests, from one of those pages to the next.
class BazaarShell extends StatefulWidget {
  const BazaarShell({super.key, required this.location, required this.child, this.assistant});

  /// The path of the page [child] shows.
  final String location;
  final Widget child;

  /// The round button in the corner of some tabs' first pages.
  final Widget? assistant;

  /// The pages that show the [assistant]: Home's first page only; elsewhere it would only distract (the owner,
  /// 2026-11-14).
  static const Set<String> assistantPages = {BazaarPaths.home};

  /// The [assistant]'s width and height.
  static const double assistantSize = 58;

  /// The navigation's height: under Material's 80, the icons and their small names.
  static const double navHeight = 62;

  @override
  State<BazaarShell> createState() => _BazaarShellState();
}

class _BazaarShellState extends State<BazaarShell> with WidgetsBindingObserver {
  /// Where the reader left the assistant's button; null is its start corner.
  Offset? _assistantAt;

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
    WidgetsBinding.instance.addObserver(this);
    _rememberTrack();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TabSwitch.end();
    super.dispose();
  }

  /// The page under the shell, where the scrollable in front is looked for.
  final _pageKey = GlobalKey();

  /// Takes the page in front back to its top on a tap on the iOS status bar. The shell's Scaffold would scroll its
  /// primary scroll controller, but the pages scroll under the shell's own navigator, whose routes hold controllers of
  /// their own, and the reader holds one of its own too; so the shell finds the page's scrollable itself.
  @override
  void handleStatusBarTap() {
    final page = _pageKey.currentContext;
    final scrollable = page == null ? null : frontScrollable(page);
    if (scrollable == null) return;
    final position = scrollable.position;
    if (MediaQuery.of(context).disableAnimations) {
      position.jumpTo(position.minScrollExtent);
    } else {
      unawaited(
        position.animateTo(
          position.minScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCirc,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(BazaarShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      // The shell is built before its navigator, so the move to another tab ends once the new pages are drawn.
      if (TabSwitch.active) {
        WidgetsBinding.instance.addPostFrameCallback((_) => TabSwitch.end());
      } else if (_tabOf(oldWidget.location) != _selectedIndex) {
        // Back or a link left the tab's pages for another tab's page: the tab left keeps no pages, so it opens at its
        // first page again rather than at a page already gone back from.
        _stacks.remove(_tabOf(oldWidget.location));
      }
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
  /// A module's is in [language], the English one where it has none (web D139).
  String? _title(BundleIndex? index, String language) {
    final location = widget.location;
    if (BazaarPaths.moduleOf(location) case final key?) {
      final track = BazaarPaths.trackOf(location)!;
      if (index?.module(key)?.tracks[track]?.titleIn(language) case final title?) return title;
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
  int get _selectedIndex => _tabOf(widget.location);

  static int _tabOf(String location) => switch (location) {
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
    if (index != _selectedIndex) TabSwitch.begin();
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

  /// The bar's back button goes to the page before, where the page was opened from, as Android's back and the iOS edge
  /// swipe do (the owner, 2026-11-12; from 2026-11-11 a module's arrow went to its catalog instead).
  void _back() => GoRouter.of(context).pop();

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
    final assistantShown =
        widget.assistant != null && !chromeHidden && BazaarShell.assistantPages.contains(widget.location);
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
                        title: _title(index, context.watch<LanguageCubit>().state),
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
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: Stack(
                    children: [
                      FloatingRoom(
                        // The button's height and its gap from the page's foot, so a page's end scrolls clear of it.
                        room: assistantShown ? 76 : 0,
                        child: KeyedSubtree(
                          key: _pageKey,
                          child: ReadableWidth(child: widget.child),
                        ),
                      ),
                      if (assistantShown)
                        Positioned.fill(
                          child: FloatingDock(
                            size: BazaarShell.assistantSize,
                            at: _assistantAt,
                            onRest: (at) => _assistantAt = at,
                            child: widget.assistant!,
                          ),
                        ),
                    ],
                  ),
                ),
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

/// The first vertical scrollable under [page] on the route in front, an outer one before those inside it; null when
/// there is none or it has no content yet.
@visibleForTesting
ScrollableState? frontScrollable(BuildContext page) {
  ScrollableState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element case StatefulElement(state: final ScrollableState state)
        when state.position.axis == Axis.vertical && state.position.hasContentDimensions) {
      if (ModalRoute.of(element)?.isCurrent ?? true) found = state;
      return;
    }
    element.visitChildElements(visit);
  }

  (page as Element).visitChildElements(visit);
  return found;
}

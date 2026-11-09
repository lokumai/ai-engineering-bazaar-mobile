import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The frame of every page inside the router's ShellRoute: the cobalt bar with a back button when there is a page to
/// go back to, the Lokum logo and the app title (spec 3.8: a custom widget, never on the page ground), the lattice band
/// under it, the page, and the bottom navigation (web nav labels `Home`, `Catalog` and `Progress`,
/// `src/components/shell/MainNav.tsx`; `Settings` is app copy). The track is chosen once and changed in Settings (plan
/// 1L).
///
/// Opening a page of a track remembers that track, as the web remembers the last track page opened
/// (`src/lib/tracks.ts:77-114`).
class BazaarShell extends StatefulWidget {
  const BazaarShell({super.key, required this.location, required this.child});

  /// The path of the page [child] shows.
  final String location;
  final Widget child;

  @override
  State<BazaarShell> createState() => _BazaarShellState();
}

class _BazaarShellState extends State<BazaarShell> {
  @override
  void initState() {
    super.initState();
    _rememberTrack();
  }

  @override
  void didUpdateWidget(BazaarShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _rememberTrack();
  }

  void _rememberTrack() {
    final track = BazaarPaths.trackOf(widget.location);
    if (track != null) context.read<TrackCubit>().select(track);
  }

  /// Home, Catalog (every page of a track), Progress and Settings, as the web's bar orders Home, Catalog and Progress.
  int get _selectedIndex => switch (widget.location) {
    BazaarPaths.progress => 2,
    BazaarPaths.settings => 3,
    final location when BazaarPaths.trackOf(location) != null => 1,
    _ => 0,
  };

  void _onDestinationSelected(int index) {
    final target = switch (index) {
      0 => BazaarPaths.home,
      2 => BazaarPaths.progress,
      3 => BazaarPaths.settings,
      _ => BazaarPaths.catalog(BazaarPaths.trackOf(widget.location) ?? context.read<TrackCubit>().state),
    };
    context.go(target);
  }

  /// Whether a page was pushed over the shell's first page: the shell's matches hold more than one page.
  ///
  /// Read from the router's configuration, which is already the new one when the shell rebuilds; the navigator's own
  /// `canPop` still answers for the pages it showed before.
  static bool _pushed(List<RouteMatchBase> matches) => _pages(matches) > 1;

  static int _pages(List<RouteMatchBase> matches) =>
      matches.fold(0, (count, match) => count + (match is ShellRouteMatch ? _pages(match.matches) : 1));

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      body: Column(
        children: [
          BazaarBar(
            // The bar sits above the shell's navigator, so the router pops the page it pushed.
            onBack: _pushed(GoRouter.of(context).routerDelegate.currentConfiguration.matches)
                ? () => GoRouter.of(context).pop()
                : null,
          ),
          const LatticeBand(),
          // The bar already keeps clear of the status bar.
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.nav_home),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l10n.nav_catalog),
          NavigationDestination(icon: const Icon(Icons.check_circle_outline), label: l10n.nav_progress),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.nav_settings),
        ],
      ),
    );
  }
}

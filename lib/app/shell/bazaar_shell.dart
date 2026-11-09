import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          _Bar(canPop: _pushed(GoRouter.of(context).routerDelegate.currentConfiguration.matches)),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.canPop});

  /// Whether a page was pushed over the one below it, so the bar offers the way back.
  final bool canPop;

  /// The bar's least height: thinner than the mockup's 58 (plan 1R).
  static const double _height = 48;

  /// The logo's side at text scale 1; it grows with the title.
  static const double _logo = 26;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: BazaarFixedColors.onBar);
    final logo = MediaQuery.textScalerOf(context).scale(_logo);
    // The status bar is drawn over the bar, navy in both themes, so its icons are light (plan 1J).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: BazaarFixedColors.bar,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            // A minimum, never a fixed height, so a large text scale grows the bar (spec 3.10).
            constraints: const BoxConstraints(minHeight: _height),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: canPop ? AppSpacing.xs : AppSpacing.lg,
                end: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  // The bar sits above the shell's navigator, so the router pops the page it pushed.
                  if (canPop) BackButton(color: BazaarFixedColors.onBar, onPressed: () => GoRouter.of(context).pop()),
                  // Decoration: the title beside it names the app.
                  ExcludeSemantics(
                    child: Image.asset(_logoAsset, width: logo, height: logo, filterQuality: FilterQuality.medium),
                  ),
                  Expanded(child: Text(S.of(context).app_title, style: style)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Lokum logo (`assets/brand/SOURCE.md`).
const _logoAsset = 'assets/brand/lokum_logo.webp';

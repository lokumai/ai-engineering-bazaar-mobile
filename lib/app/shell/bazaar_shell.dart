import 'package:ai_engineering_bazaar/app/shell/track_switch.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The frame of every page inside the router's ShellRoute: the cobalt bar with the app title and the track switch
/// (spec 3.8: a custom widget, never on the page ground), the page, and the bottom navigation (web nav labels
/// `Catalog` and `Progress`, `src/components/shell/MainNav.tsx`; `Settings` is app copy).
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

  int get _selectedIndex => switch (widget.location) {
    BazaarPaths.progress => 1,
    BazaarPaths.settings => 2,
    _ => 0,
  };

  void _onDestinationSelected(int index) {
    final target = switch (index) {
      1 => BazaarPaths.progress,
      2 => BazaarPaths.settings,
      _ => BazaarPaths.catalog(BazaarPaths.trackOf(widget.location) ?? context.read<TrackCubit>().state),
    };
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      body: Column(
        children: [
          _Bar(location: widget.location),
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
          NavigationDestination(icon: const Icon(Icons.view_list_outlined), label: l10n.nav_catalog),
          NavigationDestination(icon: const Icon(Icons.check_circle_outline), label: l10n.nav_progress),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.nav_settings),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: BazaarFixedColors.onBar);
    return Material(
      color: BazaarFixedColors.bar,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          // A minimum, never a fixed height, so a large text scale grows the bar (spec 3.10).
          constraints: const BoxConstraints(minHeight: BazaarLayout.bar),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(child: Text(S.of(context).app_title, style: style)),
                TrackSwitch(location: location),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

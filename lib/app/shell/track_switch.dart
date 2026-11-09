import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The two track segments in the bar, in the index's track order (web `src/components/shell/TrackSwitch.tsx`).
///
/// As the web does on a phone, each segment shows an icon only and keeps the track's label as its accessible name
/// (`TrackSwitch.tsx:30-34`). The current segment is filled with the `bar-chip` pair, which the web's contrast test
/// checks, instead of the web's untested `--color-ornament` fill (spec 3.8).
///
/// On a page of a track, a tap opens the same page in the other track (`targetsFor`) on top of the page shown; on a
/// page of neither track it only changes the remembered track.
class TrackSwitch extends StatelessWidget {
  const TrackSwitch({super.key, required this.location});

  /// The path of the page the shell shows.
  final String location;

  static Key segmentKey(Track track) => ValueKey('track-switch-${track.id}');

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // AppGate shows the router only once the content is ready.
      ContentLoading() || ContentBroken() => throw StateError('TrackSwitch needs ContentReady'),
    };
    final remembered = context.watch<TrackCubit>().state;
    final current = BazaarPaths.trackOf(location) ?? remembered;
    return Semantics(
      label: S.of(context).track_switch_label,
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          for (final info in index.tracks) _Segment(info: info, current: info.track == current, onTap: _select),
        ],
      ),
    );
  }

  /// The web's segments are links, a history entry that back returns from, so the other track's page is pushed; the
  /// segment of the page shown does nothing, since a push of the same location would open a second copy of it.
  void _select(BuildContext context, Track track) {
    final target = BazaarPaths.trackSwitchTarget(location, track);
    if (target == null) {
      context.read<TrackCubit>().select(track);
    } else if (target != location) {
      context.push(target);
    }
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.info, required this.current, required this.onTap});

  final TrackInfo info;
  final bool current;
  final void Function(BuildContext context, Track track) onTap;

  static const _radius = BorderRadius.all(BazaarRadii.md);

  @override
  Widget build(BuildContext context) {
    final size = minTapTarget(Theme.of(context).platform);
    final icon = switch (info.track) {
      Track.engineers => Icons.code,
      Track.everyone => Icons.menu_book_outlined,
    };
    return Semantics(
      key: TrackSwitch.segmentKey(info.track),
      container: true,
      button: true,
      selected: current,
      label: info.label,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: current ? BazaarFixedColors.barChip : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: current ? BorderSide.none : const BorderSide(color: BazaarFixedColors.barFieldLine),
          ),
          child: InkWell(
            borderRadius: _radius,
            onTap: () => onTap(context, info.track),
            child: Icon(icon, color: current ? BazaarFixedColors.onBarChip : BazaarFixedColors.onBar),
          ),
        ),
      ),
    );
  }
}

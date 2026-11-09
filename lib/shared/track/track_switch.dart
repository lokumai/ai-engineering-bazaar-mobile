import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The two tracks as one segmented control, in the index's track order with the index's labels (web
/// `src/components/shell/TrackSwitch.tsx`). The pages of a track place it at their top (the redesign moves it out of
/// the bar); it reads the page's path from the router, so a page passes nothing.
///
/// On a page of a track, choosing the other track opens the same page in it (`targetsFor`) on top of the page shown,
/// a history entry that back returns from, as the web's links are; on a page of neither track (Home) it only changes
/// the remembered track. The chosen segment does nothing, since a push of the same location would open a second copy.
class TrackSwitch extends StatelessWidget {
  const TrackSwitch({super.key});

  static Key segmentKey(Track track) => ValueKey('track-switch-${track.id}');

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate shows the router only once the content is ready.
      ContentLoading() || ContentBroken() => throw StateError('TrackSwitch needs ContentReady'),
    };
    final location = GoRouterState.of(context).uri.path;
    final current = BazaarPaths.trackOf(location) ?? context.watch<TrackCubit>().state;
    return BazaarSegmentedControl<Track>(
      semanticLabel: S.of(context).track_switch_label,
      selected: current,
      onSelected: (track) => _select(context, location, track),
      segments: [
        for (final info in index.tracks)
          BazaarSegment(value: info.track, label: info.label, key: segmentKey(info.track)),
      ],
    );
  }

  void _select(BuildContext context, String location, Track track) {
    final target = BazaarPaths.trackSwitchTarget(location, track);
    if (target == null) {
      context.read<TrackCubit>().select(track);
    } else {
      context.push(target);
    }
  }
}

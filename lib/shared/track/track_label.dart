import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The name of the track a page is in, small and muted, where the track switch stood (plan 1L): the track is chosen
/// once and changed in Settings, so a page only says which one it shows. A page of a track takes it from its path, a
/// page of neither track (Home) from the current track.
class TrackLabel extends StatelessWidget {
  const TrackLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate shows the router only once the content is ready.
      final state => throw StateError('TrackLabel needs ready content, not $state'),
    };
    final track = BazaarPaths.trackOf(GoRouterState.of(context).uri.path) ?? context.watch<TrackCubit>().state;
    final label = index.tracks.firstWhere((info) => info.track == track).label;
    return Text(
      label,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.bazaarColors.onSurfaceMuted),
    );
  }
}

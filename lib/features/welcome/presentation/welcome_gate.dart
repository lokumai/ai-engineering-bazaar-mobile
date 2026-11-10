import 'dart:async';

import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_intro_view.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows Welcome's steps in front of [child], the app, on the first launch only (plan Phase 1I, 1Y); the app composes it
/// over the router, so Welcome has no route of its own and the web's routes stay the app's (A9).
///
/// While the store is asked, the page ground is shown, so neither screen flashes before the other.
class WelcomeGate extends StatelessWidget {
  const WelcomeGate({super.key, required this.child, this.onFinished});

  final Widget child;

  /// Called with the chosen track once a reader on a first launch chose one and read the guide; the app opens that
  /// track's catalog, since Up next means little to someone who has read nothing yet (plan 1T). Not called on a launch
  /// that skips Welcome.
  final ValueChanged<Track>? onFinished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WelcomeBloc(store: context.read<IWelcomeStore>())..add(const WelcomeStarted()),
      child: BlocBuilder<WelcomeBloc, WelcomeState>(
        builder: (context, state) => switch (state) {
          WelcomeChecking() => ColoredBox(color: Theme.of(context).colorScheme.surface),
          WelcomeChoosingTrack() => WelcomeTrackView(
            initial: context.read<TrackCubit>().state,
            onChosen: (track) {
              unawaited(context.read<TrackCubit>().choose(track));
              context.read<WelcomeBloc>().add(const WelcomeTrackChosen());
            },
          ),
          WelcomeIntroducing() => WelcomeIntroView(
            onDone: () {
              context.read<WelcomeBloc>().add(const WelcomeIntroRead());
              onFinished?.call(context.read<TrackCubit>().state);
            },
          ),
          WelcomeDone() => child,
        },
      ),
    );
  }
}

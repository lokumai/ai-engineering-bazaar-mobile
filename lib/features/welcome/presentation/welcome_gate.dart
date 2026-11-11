import 'dart:async';

import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows Welcome's steps in front of [child], the app, on the first launch only (plan Phase 1I, 1Y); the app composes it
/// over the router, so Welcome has no route of its own and the web's routes stay the app's (A9).
///
/// While the store is asked, the page ground is shown, so neither screen flashes before the other.
///
/// Its first step is the language and the track; the story of the Bazaar follows in the language chosen (plan 3.5),
/// which the app passes as [story], since the story is a feature of its own. Content that names no story (a copy
/// from before the site published it, web D125) ends at the language and the track.
class WelcomeGate extends StatelessWidget {
  const WelcomeGate({super.key, required this.child, required this.story, this.onFinished});

  final Widget child;

  /// Welcome's first step, which calls its argument once the reader goes on.
  final Widget Function(VoidCallback onDone) story;

  /// Called with the chosen track once a reader on a first launch chose one and read or skipped the story; the app
  /// opens that track's catalog, since Up next means little to someone who has read nothing yet (plan 1T). Not called on a launch
  /// that skips Welcome.
  final ValueChanged<Track>? onFinished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WelcomeBloc(store: context.read<IWelcomeStore>())..add(WelcomeStarted(story: _hasStory(context))),
      child: BlocConsumer<WelcomeBloc, WelcomeState>(
        listenWhen: (previous, current) => current is WelcomeDone && current.chosen != null,
        listener: (context, state) => onFinished?.call((state as WelcomeDone).chosen!),
        builder: (context, state) => switch (state) {
          WelcomeChecking() => ColoredBox(color: Theme.of(context).colorScheme.surface),
          WelcomeChoosingTrack(:final story) => WelcomeTrackView(
            initial: context.read<TrackCubit>().state,
            story: story,
            onChosen: (track) {
              unawaited(context.read<TrackCubit>().choose(track));
              context.read<WelcomeBloc>().add(WelcomeTrackChosen(track));
            },
          ),
          WelcomeTellingStory() => story(() => context.read<WelcomeBloc>().add(const WelcomeStoryRead())),
          WelcomeDone() => child,
        },
      ),
    );
  }

  static bool _hasStory(BuildContext context) => switch (context.read<ContentBloc>().state) {
    ContentReady(:final index) => index.story.isNotEmpty,
    _ => false,
  };
}

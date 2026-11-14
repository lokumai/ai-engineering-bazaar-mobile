import 'dart:async';

import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows Welcome's steps in front of [child], the app, on the first launch only (plan Phase 1I, 1Y); the app composes it
/// over the router, so Welcome has no route of its own and the web's routes stay the app's (A9).
///
/// While the store is asked, the page ground is shown, so neither screen flashes before the other.
///
/// Its first step is the language and the track; Start learning opens the app on Home, as every later launch does, and
/// the story button tells the story of the Bazaar in the language chosen (plan 3.5; the owner, 2026-11-15), which the
/// app passes as [story], since the story is a feature of its own. Content that names no story (a copy from before the
/// site published it, web D125) has no story button.
class WelcomeGate extends StatelessWidget {
  const WelcomeGate({super.key, required this.child, required this.story});

  final Widget child;

  /// The story, the story button's step, which calls its argument once the reader goes on.
  final Widget Function(VoidCallback onDone) story;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WelcomeBloc(store: context.read<IWelcomeStore>())..add(WelcomeStarted(story: _hasStory(context))),
      child: BlocBuilder<WelcomeBloc, WelcomeState>(
        builder: (context, state) => switch (state) {
          WelcomeChecking() => ColoredBox(color: Theme.of(context).colorScheme.surface),
          WelcomeChoosingTrack(:final story) => WelcomeTrackView(
            initial: context.read<TrackCubit>().state,
            story: story,
            onChosen: (track, {required story}) {
              unawaited(context.read<TrackCubit>().choose(track));
              context.read<WelcomeBloc>().add(WelcomeTrackChosen(track, story: story));
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

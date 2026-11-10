import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_page.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_film.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Welcome's first step on the first launch (plan 3.5): the story of the Bazaar as a film over the whole screen, and
/// after it, or at its Skip, the way on to the language and the track, [onDone]. The app composes it into Welcome,
/// which may not import this feature.
class AboutWelcomeStep extends StatelessWidget {
  const AboutWelcomeStep({super.key, required this.onDone});

  final VoidCallback onDone;

  /// The button at the end of the story.
  static const doneKey = AboutFilm.finishKey;

  /// The Skip at the top.
  static const skipKey = AboutFilm.exitKey;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AboutStory(exit: AboutExit.skip, finishLabel: S.of(context).welcome_story_continue, onFinished: onDone),
  );
}

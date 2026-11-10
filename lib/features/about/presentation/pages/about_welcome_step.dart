import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_page.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:flutter/material.dart';

/// Welcome's first step on the first launch (plan 3.5): the story of the Bazaar under the bar of every page, and after
/// it the way on to the language and the track, [onDone]. The app composes it into Welcome, which may not import this
/// feature.
class AboutWelcomeStep extends StatelessWidget {
  const AboutWelcomeStep({super.key, required this.onDone});

  final VoidCallback onDone;

  static const doneKey = Key('welcome-about-done');

  @override
  Widget build(BuildContext context) {
    // The bar of every page, so the steps look like the app they lead into (plan 1Z).
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BazaarBar(),
            const LatticeBand(thin: true),
            Expanded(
              child: AboutStory(
                footer: FilledButton.icon(
                  key: doneKey,
                  onPressed: onDone,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.arrow_forward),
                  iconAlignment: IconAlignment.end,
                  label: Text(S.of(context).welcome_story_continue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

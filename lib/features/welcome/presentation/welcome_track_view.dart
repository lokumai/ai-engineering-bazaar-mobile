import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_art.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/theme/appearance_name.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';

import 'dart:async';

import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Welcome's second screen (plan 1L, 1S): the reader chooses the language and a track once, with the web's line for
/// each track (web `src/app/page.tsx`, the two stalls); Settings changes both later. The language takes effect at once;
/// Start learning hands the track to [onChosen] and opens the app, the story button (when there is one) hands it on to
/// the story (the owner, 2026-11-15).
class WelcomeTrackView extends StatefulWidget {
  const WelcomeTrackView({super.key, required this.initial, this.story = false, required this.onChosen});

  /// Whether there is a story to tell; the story button then stands under Start learning.
  final bool story;

  /// The track chosen when the screen opens.
  final Track initial;

  /// Called with the track chosen, and whether the reader asked for the story.
  final void Function(Track track, {required bool story}) onChosen;

  static const startKey = Key('welcome-start');

  static const storyKey = Key('welcome-story');

  static Key optionKey(Track track) => ValueKey('welcome-track-${track.id}');

  static Key languageKey(String language) => ValueKey('welcome-language-$language');

  static Key appearanceKey(ThemeMode mode) => ValueKey('welcome-appearance-${mode.name}');

  @override
  State<WelcomeTrackView> createState() => _WelcomeTrackViewState();
}

class _WelcomeTrackViewState extends State<WelcomeTrackView> {
  late Track _track = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate shows Welcome only once the content is ready.
      final state => throw StateError('Welcome needs ready content, not $state'),
    };
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
              child: ReadableWidth(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // The whole step fits a phone with no scrolling (the owner, 2026-11-14); the app icon is
                    // chosen in Settings only, so the step has room to breathe again.
                    spacing: 16,
                    children: [
                      ExcludeSemantics(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          spacing: 4,
                          children: [
                            for (final art in [WelcomeArt.cast[1], WelcomeArt.cast[3]])
                              Image(image: AssetImage(art), height: 80, filterQuality: FilterQuality.medium),
                          ],
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          s.welcome_track_title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(color: colors.onSurfaceTitle),
                        ),
                      ),
                      // The language first: choosing one turns this screen into it at once (plan 1S).
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Text(s.settings_language, style: theme.textTheme.titleSmall),
                          BazaarSegmentedControl<String>(
                            semanticLabel: s.settings_language,
                            selected: context.watch<LanguageCubit>().state,
                            onSelected: (language) => unawaited(context.read<LanguageCubit>().choose(language)),
                            segments: [
                              for (final language in LanguageCubit.supported)
                                BazaarSegment(
                                  value: language,
                                  label: LanguageCubit.names[language]!,
                                  key: WelcomeTrackView.languageKey(language),
                                ),
                            ],
                          ),
                          Text(s.settings_appearance, style: theme.textTheme.titleSmall),
                          BazaarSegmentedControl<ThemeMode>(
                            semanticLabel: s.settings_appearance,
                            selected: context.watch<ThemeChoiceCubit>().state,
                            onSelected: (mode) => unawaited(context.read<ThemeChoiceCubit>().choose(mode)),
                            segments: [
                              for (final mode in ThemeChoiceCubit.modes)
                                BazaarSegment(
                                  value: mode,
                                  label: appearanceName(s, mode),
                                  key: WelcomeTrackView.appearanceKey(mode),
                                ),
                            ],
                          ),
                        ],
                      ),
                      for (final info in index.tracks)
                        _TrackOption(
                          key: WelcomeTrackView.optionKey(info.track),
                          title: trackName(s, info.track),
                          body: switch (info.track) {
                            Track.engineers => s.welcome_track_engineers,
                            Track.everyone => s.welcome_track_everyone,
                          },
                          selected: _track == info.track,
                          onTap: () => setState(() => _track = info.track),
                        ),
                      // Start learning first; the story button under it (the owner, 2026-11-15).
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [
                          FilledButton.icon(
                            key: WelcomeTrackView.startKey,
                            onPressed: () => widget.onChosen(_track, story: false),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            icon: const Icon(Icons.arrow_forward),
                            iconAlignment: IconAlignment.end,
                            label: Text(s.welcome_start),
                          ),
                          if (widget.story)
                            OutlinedButton(
                              key: WelcomeTrackView.storyKey,
                              onPressed: () => widget.onChosen(_track, story: true),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              child: Text(s.welcome_to_story),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One track as a card to choose, framed in the primary ink while chosen; read as one of a group of radio buttons.
class _TrackOption extends StatelessWidget {
  const _TrackOption({super.key, required this.title, required this.body, required this.selected, required this.onTap});

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final radius = BazaarCard.radiusOf(BazaarCardShape.arch);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? colors.primary : colors.line, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? colors.primary : colors.onSurfaceMuted,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                      Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

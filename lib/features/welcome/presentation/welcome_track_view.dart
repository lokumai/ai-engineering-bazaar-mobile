import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_view.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Welcome's second screen (plan 1L): the reader chooses a track once, with the web's line for each (web
/// `src/app/page.tsx`, the two stalls); Settings changes it later. Start reading hands the choice to [onChosen].
class WelcomeTrackView extends StatefulWidget {
  const WelcomeTrackView({super.key, required this.initial, required this.onChosen});

  /// The track chosen when the screen opens.
  final Track initial;
  final ValueChanged<Track> onChosen;

  static Key optionKey(Track track) => ValueKey('welcome-track-${track.id}');

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LatticeBand(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 4,
                        children: [
                          for (final art in [WelcomeArt.cast[1], WelcomeArt.cast[3]])
                            Image(image: AssetImage(art), height: 96, filterQuality: FilterQuality.medium),
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
                    Text(
                      s.welcome_track_lede,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted),
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
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      key: const Key('welcome-start'),
                      onPressed: () => widget.onChosen(_track),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      icon: const Icon(Icons.arrow_forward),
                      iconAlignment: IconAlignment.end,
                      label: Text(s.welcome_start),
                    ),
                  ],
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

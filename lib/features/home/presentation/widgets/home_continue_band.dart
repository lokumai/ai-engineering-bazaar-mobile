import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The module left half read, in a band over the navigation, under the reader's thumb (plan 10.4, the owner's testers,
/// 2026-11-16: Continue reading, the likeliest tap, sat at the top of the screen): its level's dot, its title and how
/// far it was read, with a bar in its level's hue along the band's top; a tap goes on from there. With no module half
/// read on this device it takes no room. It is the same module Home's continue card goes on with (plan 1BA).
class HomeContinueBand extends StatelessWidget {
  const HomeContinueBand({super.key});

  /// The band's height, its bar included.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      RecordLoading() => null,
    };
    final places = switch (context.watch<ReadingPlacesBloc>().state) {
      ReadingPlacesReady(:final places) => places,
      ReadingPlacesLoading() => null,
    };
    if (index == null || record == null || places == null) return const SizedBox.shrink();
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final next = homeOverview(
      index,
      track,
      record,
      scores: const <String, QuizScore>{},
      places: places,
      language: language,
    ).next;
    final share = next?.share;
    if (next == null || share == null) return const SizedBox.shrink();
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final hue = levelHue(context, next.position);
    final percent = (share * 100).round();
    void open() => context.push(BazaarPaths.module(track, next.module.key));
    return Semantics(
      button: true,
      label: '${s.home_continue_reading}: ${next.title}, ${s.home_read_percent(percent)}',
      onTap: open,
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('home-continue-band'),
        color: colors.surface,
        child: InkWell(
          onTap: open,
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                // How far it was read, along the band's top edge, over a hairline.
                SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(value: share, color: hue, backgroundColor: colors.line),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      spacing: AppSpacing.md,
                      children: [
                        LevelKey(color: hue, size: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.home_continue_reading,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
                              ),
                              Text(
                                next.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          s.home_read_percent(percent),
                          style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                        ),
                        Icon(Icons.arrow_forward, size: 20, color: colors.primary),
                      ],
                    ),
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

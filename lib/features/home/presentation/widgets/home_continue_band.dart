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

/// The module to read now, in a band over the navigation, under the reader's thumb (plan 10.4, the owner's testers,
/// 2026-11-16: Continue reading, the likeliest tap, sat at the top of the screen; the owner: Up next too, and Home's card
/// goes): the module left half read on this device, with how far it was read and a bar in its level's hue along the
/// band's top, else the next module of the track not completed, with its minutes (plan 1BA). Its level's dot and its
/// title; a tap opens it, where it was left. With every module completed it takes no room.
class HomeContinueBand extends StatelessWidget {
  const HomeContinueBand({super.key});

  /// The band's least height, its bar included; it grows with the text size.
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
    if (next == null) return const SizedBox.shrink();
    final share = next.share;
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final hue = levelHue(context, next.position);
    final label = share == null ? s.home_up_next : s.home_continue_reading;
    final measure = share == null ? s.reader_minutes(next.module.minutes) : s.home_read_percent((share * 100).round());
    void open() => context.push(BazaarPaths.module(track, next.module.key));
    return Semantics(
      button: true,
      label: '$label: ${next.title}, $measure',
      onTap: open,
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('home-continue-band'),
        color: colors.surface,
        child: InkWell(
          onTap: open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: height),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // How far it was read, along the band's top edge, over a hairline; the hairline alone for a module not begun.
                SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(value: share ?? 0, color: hue, backgroundColor: colors.line),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
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
                              label,
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
                      Text(measure, style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted)),
                      Icon(Icons.arrow_forward, size: 20, color: colors.primary),
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

import 'dart:async';

import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:clock/clock.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What frames the day's card at Home's head: the [card], null while there is none to show; null for nothing at all.
typedef DailyCardFrame = Widget? Function(BuildContext context, Widget? card);

/// The card at Home's head (plan 11.1, 14.1): a section of a module, its heading, its first sentences and its module
/// with its level's hue; a tap opens the module at that section, and Show another brings the next card in turn. It has
/// no name of its own: it is what the Apprentice shows. It is handed to [frame], which the app fills with the Apprentice
/// presenting it (plan 11.2); with no frame it stands alone. Whatever stands there keeps a gap under it, and nothing
/// takes no room. While another card's module is read, the last one stays, so Home does not jump.
///
/// The day is read again at local midnight and when the app comes back from the background, so a Home left open
/// overnight shows the new day's card.
class HomeDailyCard extends StatefulWidget {
  const HomeDailyCard({super.key, this.frame});

  final DailyCardFrame? frame;

  @override
  State<HomeDailyCard> createState() => _HomeDailyCardState();
}

/// Kept alive in Home's lazy list: scrolled to the foot and back, a card built again would read its document again and
/// stand empty meanwhile, and Home would jump as it grew (the owner, 2026-11-17).
class _HomeDailyCardState extends State<HomeDailyCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late int _day = dayNumber(clock.now());

  /// How many times Show another was pressed on [_day].
  int _another = 0;

  /// The card last shown, kept while the next one is read.
  Widget? _last;
  Timer? _midnight;
  late final AppLifecycleListener _lifecycle;

  DailyCardFrame? get frame => widget.frame;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _turn);
    _wait();
  }

  /// Waits for the next local midnight, a moment past it.
  void _wait() {
    _midnight?.cancel();
    _midnight = Timer(untilLocalMidnight(clock.now()), () {
      _turn();
      _wait();
    });
  }

  /// Takes the day it is now, when it has turned.
  void _turn() {
    final day = dayNumber(clock.now());
    if (day != _day && mounted) {
      setState(() {
        _day = day;
        _another = 0;
      });
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      RecordLoading() => null,
    };
    if (index == null || record == null) return _framed(context, null);
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final choice = dailyChoice(index, track, record, language: language, day: _day, another: _another);
    // Finished since the day began, it stays the day's card, marked completed.
    final completed = choice != null && trackView(record, track).signedOff(choice.moduleKey, Track.engineers) != null;
    final position = choice == null
        ? 0
        : index.levels.indexWhere((level) => level.slug == index.module(choice.moduleKey)?.level);
    return BlocProvider(
      // A new choice, from a module completed or another track or language, reads its own document.
      key: ValueKey(choice),
      create: (context) => DailyCardCubit(repository: context.read<IContentRepository>())..load(choice),
      child: BlocBuilder<DailyCardCubit, DailyCardState>(
        builder: (context, state) => _framed(context, switch (state) {
          DailyCardShown(:final card) => _last = _Card(
            card: card,
            hue: levelHue(context, position),
            completed: completed,
            onTap: () => context.push(
              BazaarPaths.module(track, card.moduleKey),
              extra: ReaderTarget(fragment: card.sectionId, glance: true),
            ),
            onAnother: () => setState(() => _another++),
          ),
          DailyCardLoading() => _last,
          DailyCardNone() => _last = null,
        }),
      ),
    );
  }

  Widget _framed(BuildContext context, Widget? card) {
    final head = frame == null ? card : frame!(context, card);
    if (head == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      // The Apprentice's tour points at it first (plan 11.3).
      child: TourTarget(spot: TourSpots.homeHead, child: head),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.card,
    required this.hue,
    required this.completed,
    required this.onTap,
    required this.onAnother,
  });

  final DailyCard card;
  final Color hue;

  /// Whether the reader has finished its module.
  final bool completed;
  final VoidCallback onTap;

  /// Brings the next card in turn.
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final read = BazaarCard(
      key: const ValueKey('home-daily-card'),
      accent: hue,
      onTap: onTap,
      semanticLabel: [
        '${card.heading}. ${card.lead} ${card.module}',
        if (completed) '. ${s.home_daily_completed}',
      ].join(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.heading, style: displayFace(textTheme.titleMedium)?.copyWith(color: colors.onSurfaceTitle)),
          const SizedBox(height: 6),
          Text(
            card.lead,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              LevelKey(color: hue, size: 8),
              Expanded(
                child: Text(
                  card.module,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                ),
              ),
              if (completed) ...[
                const Icon(Icons.check_circle, size: 16, color: BazaarFixedColors.success),
                Text(
                  s.home_daily_completed,
                  key: const ValueKey('home-daily-completed'),
                  style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                ),
              ],
              Icon(Icons.arrow_forward, size: 18, color: colors.primary),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        read,
        // Under the card, at its start: the next card in turn (plan 14.1). The tour's Apprentice stands at the end
        // side of Home's head, so it never hides the button.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('home-daily-another'),
            onPressed: onAnother,
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: Text(s.home_daily_another),
          ),
        ),
      ],
    );
  }
}

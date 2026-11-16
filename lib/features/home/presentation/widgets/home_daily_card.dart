import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What frames the day's card at Home's head: the [card], null while there is none to show; null for nothing at all.
typedef DailyCardFrame = Widget? Function(BuildContext context, Widget? card);

/// The day's card at Home's head (plan 11.1): a section of a module, its heading, its first sentences and its module
/// with its level's hue; a tap opens the module at that section. It is handed to [frame], which the app fills with the
/// Apprentice presenting it (plan 11.2); with no frame it stands alone. Whatever stands there keeps a gap under it, and
/// nothing takes no room.
class HomeDailyCard extends StatelessWidget {
  const HomeDailyCard({super.key, this.frame});

  final DailyCardFrame? frame;

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
    if (index == null || record == null) return _framed(context, null);
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final choice = dailyChoice(index, track, record, language: language, day: dayNumber(clock.now()));
    final position = choice == null
        ? 0
        : index.levels.indexWhere((level) => level.slug == index.module(choice.moduleKey)?.level);
    return BlocProvider(
      // A new choice, from a module completed or another track or language, reads its own document.
      key: ValueKey(choice),
      create: (context) => DailyCardCubit(repository: context.read<IContentRepository>())..load(choice),
      child: BlocBuilder<DailyCardCubit, DailyCardState>(
        builder: (context, state) => _framed(context, switch (state) {
          DailyCardShown(:final card) => _Card(
            card: card,
            hue: levelHue(context, position),
            onTap: () =>
                context.push(BazaarPaths.module(track, card.moduleKey), extra: ReaderTarget(fragment: card.sectionId)),
          ),
          DailyCardLoading() || DailyCardNone() => null,
        }),
      ),
    );
  }

  Widget _framed(BuildContext context, Widget? card) {
    final head = frame == null ? card : frame!(context, card);
    if (head == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: head);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.card, required this.hue, required this.onTap});

  final DailyCard card;
  final Color hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    return BazaarCard(
      key: const ValueKey('home-daily-card'),
      accent: hue,
      onTap: onTap,
      semanticLabel: '${s.home_daily_title}: ${card.heading}. ${card.lead} ${card.module}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.home_daily_title, style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted)),
          const SizedBox(height: 6),
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
              Icon(Icons.arrow_forward, size: 18, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What is being read, at the end of the bar (plan 1R): the track and the language, as `For Engineers · EN`. A page
/// of a track names it from its path, any other page from the current track. A tap opens Settings, where both change.
class ReadingBadge extends StatelessWidget {
  const ReadingBadge({super.key});

  static const badgeKey = Key('reading-badge');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final track = BazaarPaths.trackOf(GoRouterState.of(context).uri.path) ?? context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final name = trackName(s, track);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: BazaarFixedColors.onBar);
    return Semantics(
      button: true,
      label: '$name, ${LanguageCubit.names[language]}',
      hint: s.reading_badge_hint,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(side: BorderSide(color: BazaarFixedColors.barFieldLine)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: badgeKey,
          onTap: () => context.go(BazaarPaths.settings),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Text('$name · ${language.toUpperCase()}', style: style, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

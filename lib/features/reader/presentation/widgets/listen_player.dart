import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/presentation/listen_progress.dart';

/// The player at a module's foot while it is read aloud (plan 15): the paragraph before, play or pause, the next, how
/// far along, the pace, and a way to stop. One thin row on the page's own ground, how far along as a line along its top
/// (the owner, 2026-11-18: the bar was too tall, and its ground was not the page's).
class ListenPlayer extends StatelessWidget {
  const ListenPlayer({super.key, required this.state});

  final ListenOn state;

  /// The pace as a reader reads it: `1×`, `1.25×`, in the interface's digits.
  static String rateLabel(double rate, String locale) => '${NumberFormat('0.##', locale).format(rate)}×';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final listen = context.read<ListenCubit>();
    final rate = rateLabel(state.rate, Localizations.localeOf(context).languageCode);
    return ColoredBox(
      key: const ValueKey('listen-player'),
      color: colors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenProgress(state: state),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('listen-back'),
                    tooltip: s.listen_back,
                    onPressed: listen.back,
                    icon: const Icon(Icons.skip_previous_rounded, size: 22),
                  ),
                  IconButton(
                    key: const ValueKey('listen-toggle'),
                    tooltip: state.playing ? s.listen_pause : s.listen_play,
                    onPressed: state.playing ? listen.pause : listen.resume,
                    color: colors.primary,
                    icon: Icon(state.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                    iconSize: 32,
                  ),
                  IconButton(
                    key: const ValueKey('listen-next'),
                    tooltip: s.listen_next,
                    onPressed: listen.next,
                    icon: const Icon(Icons.skip_next_rounded, size: 22),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.listen_part(state.index + 1, state.count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ),
                  Semantics(
                    label: s.listen_speed(rate),
                    button: true,
                    excludeSemantics: true,
                    onTap: listen.faster,
                    child: TextButton(
                      key: const ValueKey('listen-speed'),
                      onPressed: listen.faster,
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      child: Text(rate),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('listen-stop'),
                    tooltip: s.listen_stop,
                    onPressed: listen.stop,
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

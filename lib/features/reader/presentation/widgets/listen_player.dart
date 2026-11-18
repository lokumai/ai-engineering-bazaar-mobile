import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:ai_engineering_bazaar/features/reader/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';

/// The player at a module's foot while it is read aloud (plan 15.1): the paragraph before, play or pause, the next,
/// how far along, the pace, and a way to stop; on a raised ground under a hairline, as the page's other bars.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.lineStrong, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('listen-back'),
                tooltip: s.listen_back,
                onPressed: listen.back,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton.filled(
                key: const ValueKey('listen-toggle'),
                tooltip: state.playing ? s.listen_pause : s.listen_play,
                onPressed: state.playing ? listen.pause : listen.resume,
                icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
              IconButton(
                key: const ValueKey('listen-next'),
                tooltip: s.listen_next,
                onPressed: listen.next,
                icon: const Icon(Icons.skip_next_rounded),
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
                child: TextButton(key: const ValueKey('listen-speed'), onPressed: listen.faster, child: Text(rate)),
              ),
              IconButton(
                key: const ValueKey('listen-stop'),
                tooltip: s.listen_stop,
                onPressed: listen.stop,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
